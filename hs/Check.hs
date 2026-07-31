-- The schedule kernel: typed model + invariant checks for the itinerary.
--
-- Reads the day cards and lodging rows extracted from index.html
-- (tools/extract-data.mjs) plus koko-places.json, and re-checks the
-- things that have actually bitten this trip:
--
--   * calendar coverage      — every date between first and last card exists
--   * lodging coverage       — NIGHTS rows are contiguous, no gap nights
--   * atlas integrity        — unique ids, well-formed opening hours
--   * mention vs. reality    — day cards that mention a place marked
--                              status:skip, closed that weekday, or closed
--                              on that specific date
--   * time vs. hours         — an explicit HH:MM in a step that falls
--                              outside the resolved place's opening hours
--                              (the "Honten opens at noon" class of bug)
--
-- Errors exit 1 (coverage breaks, duplicate ids, malformed hours).
-- Mention/time findings are warnings: the cards narrate the past as well
-- as the future, so a mentioned skip-place may be intentional record.
module Main (main) where

import Data.Char (isDigit)
import Data.List (isPrefixOf, sort, sortOn)
import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe, isJust, mapMaybe)
import Data.Time.Calendar (Day, DayOfWeek (..), addDays, dayOfWeek)
import Data.Time.Format (defaultTimeLocale, formatTime, parseTimeM)
import Json
import System.Exit (exitFailure, exitSuccess)
import System.IO

-- domain ---------------------------------------------------------------

data Card = Card {cDate :: Day, cText :: String} -- label + detail, EN+JA, tags stripped

data NightRow = NightRow {nFrom, nTo :: Day, nName :: String}

data Place = Place
  { pId :: String
  , pNames :: [String] -- name_ja, maps_query, name_en: the strings a card would use
  , pStatus :: String
  , pWeekly :: Maybe (M.Map String [(Int, Int)]) -- "mon".."sun" -> minute intervals
  , pClosed :: [String] -- explicit closed dates, "YYYY-MM-DD"
  }

-- decoding -------------------------------------------------------------

parseDay :: String -> Maybe Day
parseDay = parseTimeM True defaultTimeLocale "%Y-%m-%d"

fmtDay :: Day -> String
fmtDay = formatTime defaultTimeLocale "%Y-%m-%d"

dowKey :: Day -> String
dowKey d = case dayOfWeek d of
  Monday -> "mon"; Tuesday -> "tue"; Wednesday -> "wed"; Thursday -> "thu"
  Friday -> "fri"; Saturday -> "sat"; Sunday -> "sun"

stripTags :: String -> String
stripTags [] = []
stripTags ('<' : r) = stripTags (drop 1 (dropWhile (/= '>') r))
stripTags (c : r) = c : stripTags r

decodeCards :: JValue -> Either String [Card]
decodeCards v = do
  kvs <- maybe (Left "DAYS: not an object") Right (jObject v)
  mapM one kvs
  where
    one (k, o) = do
      d <- maybe (Left ("bad date key: " ++ k)) Right (parseDay k)
      let s field = fromMaybe "" (jLookup field o >>= jString)
          txt = stripTags (unwords [s "label", s "label_ja", s "detail", s "detail_ja"])
      Right (Card d txt)

decodeNights :: JValue -> Either String [NightRow]
decodeNights v = do
  rows <- maybe (Left "NIGHTS: not an array") Right (jArray v)
  mapM one rows
  where
    one (JArr [JStr a, JStr b, names]) = do
      f <- maybe (Left ("bad date: " ++ a)) Right (parseDay a)
      t <- maybe (Left ("bad date: " ++ b)) Right (parseDay b)
      let nm = fromMaybe "?" (jLookup "en" names >>= jString)
      Right (NightRow f t nm)
    one _ = Left "NIGHTS: row shape unexpected"

decodePlaces :: JValue -> Either String [Place]
decodePlaces v = do
  rows <- maybe (Left "places: not an array") Right (jArray v)
  mapM one rows
  where
    one o = do
      pid <- maybe (Left "place without id") Right (jLookup "id" o >>= jString)
      let s field = jLookup field o >>= jString
          names = [n | Just n <- [s "name_ja", s "maps_query", s "name_en"], n /= ""]
          status = fromMaybe "want" (s "status")
          hours = jLookup "hours" o
          weekly = hours >>= jLookup "weekly" >>= jObject >>= traverse dayIv
          dayIv (k, JArr ivs) = (,) k <$> traverse iv ivs
          dayIv (k, JNull) = Just (k, [])
          dayIv _ = Nothing
          iv (JArr [JStr a, JStr b]) = (,) <$> hhmm a <*> hhmm b
          iv _ = Nothing
          closed = fromMaybe [] (hours >>= jLookup "closed" >>= jArray >>= traverse jString)
      Right (Place pid names status (M.fromList <$> weekly) closed)

hhmm :: String -> Maybe Int
hhmm s = case break (== ':') s of
  (h, ':' : m)
    | all isDigit h, all isDigit m, not (null h), length m == 2 ->
        Just (read h * 60 + read m)
  _ -> Nothing

-- checks ---------------------------------------------------------------

data Finding = Err String | Warn String

render :: Finding -> String
render (Err m) = "  ✗ " ++ m
render (Warn m) = "  ⚠ " ++ m

isErr :: Finding -> Bool
isErr (Err _) = True
isErr _ = False

checkCoverage :: [Card] -> [Finding]
checkCoverage cards =
  let ds = sort (map cDate cards)
      gaps = [d | (a, b) <- zip ds (drop 1 ds), b /= addDays 1 a, d <- [addDays 1 a]]
   in [Err ("day-card gap starting " ++ fmtDay d) | d <- gaps]

checkNights :: [NightRow] -> [Finding]
checkNights rows =
  let rs = sortOn nFrom rows
      bad (a, b)
        | nFrom b == addDays 1 (nTo a) = Nothing
        | nFrom b <= nTo a = Just (Err ("lodging overlap: " ++ nName a ++ " / " ++ nName b))
        | otherwise = Just (Err ("gap night after " ++ fmtDay (nTo a) ++ " (" ++ nName a ++ " → " ++ nName b ++ ")"))
   in mapMaybe bad (zip rs (drop 1 rs))
        ++ [Err ("lodging row reversed: " ++ nName r) | r <- rs, nTo r < nFrom r]

checkAtlas :: [Place] -> [Finding]
checkAtlas ps =
  let ids = map pId ps
      dups = M.keys (M.filter (> (1 :: Int)) (M.fromListWith (+) (map (\i -> (i, 1)) ids)))
      badIv p =
        [ Err (pId p ++ ": interval " ++ show a ++ ".." ++ show b ++ " (" ++ dk ++ ") not increasing")
        | w <- maybe [] M.toList (pWeekly p)
        , let (dk, ivs) = w
        , (a, b) <- ivs
        , b <= a || b > 30 * 60 -- closes past midnight are encoded as 24:00+ (29:00 = 5am)
        ]
   in map (Err . ("duplicate atlas id: " ++)) dups ++ concatMap badIv ps

-- places a card's text mentions, with the position of the first mention
mentionsIn :: String -> [Place] -> [(Int, Place)]
mentionsIn txt ps =
  sortOn fst
    [ (i, p)
    | p <- ps
    , Just i <- [firstHit (pNames p)]
    ]
  where
    firstHit names =
      case [idx | n <- names, Just idx <- [infixPos n txt]] of
        [] -> Nothing
        xs -> Just (minimum xs)
    infixPos needle = go 0
      where
        go _ [] = Nothing
        go i s
          | needle `isPrefixOf` s = Just i
          | otherwise = go (i + 1) (drop 1 s)

checkMentions :: [Place] -> Card -> [Finding]
checkMentions ps (Card d txt) =
  concat
    [ [Warn (fmtDay d ++ " mentions " ++ pId p ++ " which is status:skip") | pStatus p == "skip"]
        ++ [ Warn (fmtDay d ++ " mentions " ++ pId p ++ " — closed " ++ dowKey d ++ "s")
           | pStatus p /= "skip"
           , Just w <- [pWeekly p]
           , null (M.findWithDefault [] (dowKey d) w)
           ]
        ++ [ Warn (fmtDay d ++ " mentions " ++ pId p ++ " — explicit closed date")
           | fmtDay d `elem` pClosed p
           ]
    | (_, p) <- mentionsIn txt ps
    ]

-- ①..⑫ step split, then: first explicit HH:MM in a step vs. the hours of
-- the earliest-mentioned open-able place in that step (planResolveStop's rule)
checkStepTimes :: [Place] -> Card -> [Finding]
checkStepTimes ps (Card d txt) =
  concatMap stepCheck (steps txt)
  where
    marks = "①②③④⑤⑥⑦⑧⑨⑩⑪⑫"
    steps s = case break (`elem` marks) s of
      (_, []) -> []
      (_, m : rest) ->
        let (body, rest') = break (`elem` marks) rest
         in (m, body) : steps rest'
    stepCheck (m, body) =
      case (resolve body, firstTime body) of
        (Just p, Just t)
          | Just w <- pWeekly p
          , let ivs = M.findWithDefault [] (dowKey d) w
          , not (null ivs)
          , not (any (\(a, b) -> t >= a && t <= b) ivs) ->
              [ Warn
                  ( fmtDay d ++ " step " ++ [m] ++ ": " ++ show (t `div` 60) ++ ":" ++ pad (t `mod` 60)
                      ++ " is outside " ++ pId p ++ " hours"
                  )
              ]
        _ -> []
    pad n = if n < 10 then '0' : show n else show n
    resolve body =
      case [p | (_, p) <- mentionsIn body ps, pStatus p /= "skip", isJust (pWeekly p)] of
        (p : _) -> Just p
        [] -> Nothing
    firstTime body = go body
      where
        go [] = Nothing
        go s@(c : r)
          | isDigit c
          , (digits, rest) <- span isDigit s
          , length digits <= 2
          , ':' : m1 : m2 : _ <- rest
          , isDigit m1 && isDigit m2 =
              Just (read digits * 60 + read [m1, m2])
          | otherwise = go r

-- main -----------------------------------------------------------------

main :: IO ()
main = do
  mapM_ (`hSetEncoding` utf8) [stdout, stderr]
  let readU p = do h <- openFile p ReadMode; hSetEncoding h utf8; hGetContents h
  daysRaw <- readU "hs/.build/days.json"
  nightsRaw <- readU "hs/.build/nights.json"
  placesRaw <- readU "koko-places.json"
  let decoded = do
        cards <- parseJson daysRaw >>= decodeCards
        nights <- parseJson nightsRaw >>= decodeNights
        places <- parseJson placesRaw >>= decodePlaces
        Right (cards, nights, places)
  case decoded of
    Left e -> hPutStrLn stderr ("decode error: " ++ e) >> exitFailure
    Right (cards, nights, places) -> do
      let sections =
            [ ("calendar coverage (" ++ show (length cards) ++ " cards)", checkCoverage cards)
            , ("lodging coverage (" ++ show (length nights) ++ " rows)", checkNights nights)
            , ("atlas integrity (" ++ show (length places) ++ " places)", checkAtlas places)
            , ("mentions vs. reality", concatMap (checkMentions places) cards)
            , ("explicit times vs. opening hours", concatMap (checkStepTimes places) cards)
            ]
          findings = concatMap snd sections
          errs = length (filter isErr findings)
          warns = length findings - errs
      mapM_
        ( \(title, fs) -> do
            putStrLn (title ++ if null fs then " ✓" else "")
            mapM_ (putStrLn . render) fs
        )
        sections
      putStrLn ("-- " ++ show errs ++ " error(s), " ++ show warns ++ " warning(s)")
      if errs > 0 then exitFailure else exitSuccess
