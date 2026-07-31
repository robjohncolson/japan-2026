-- The schedule kernel. Two modes:
--
--   check (default) — run invariant checks over Schedule.hs (the source
--                     of truth) plus koko-places.json:
--                       * every card has the five required fields
--                       * calendar coverage — no missing day cards
--                       * lodging coverage — NIGHTS contiguous, no gaps
--                       * atlas integrity — unique ids, well-formed hours
--                       * mentions vs. reality — cards naming a place
--                         that is status:skip / closed that weekday /
--                         closed that exact date
--                       * explicit HH:MM step times vs. opening hours
--   emit            — render the JS DAYS/NIGHTS blocks to hs/.build/,
--                     for tools/splice-schedule.mjs to put into
--                     index.html
--
-- Errors exit 1. Mention findings are warnings: the cards narrate the
-- past as well as the future, so a mentioned skip-place may be
-- deliberate record ("West Georgia does not exist").
module Main (main) where

import qualified Atlas
import Data.Char (isDigit)
import Data.List (isPrefixOf, sort, sortOn)
import qualified Data.Map.Strict as M
import Data.Maybe (isJust, mapMaybe)
import Data.Time.Calendar (Day, DayOfWeek (..), addDays, dayOfWeek)
import Data.Time.Format (defaultTimeLocale, formatTime, parseTimeM)
import Emit (renderDays, renderNights)
import EmitAtlas (renderAtlas)
import Ics (renderIcs)
import qualified Schedule
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)
import System.IO

-- domain ---------------------------------------------------------------

data DayText = DayText {cDate :: Day, cText :: String} -- all fields, EN+JA, tags stripped

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

requiredFields :: [String]
requiredFields = ["cls", "label", "label_ja", "detail", "detail_ja"]

checkSchema :: [Finding]
checkSchema =
  [ Err (date ++ " card missing field " ++ f)
  | (date, card) <- Schedule.days
  , f <- requiredFields
  , f `notElem` map fst card
  ]
    ++ [Err ("bad date key in Schedule.days: " ++ date) | (date, _) <- Schedule.days, cDate' date == Nothing]
    ++ [ Err ("bad date in Schedule.nights: " ++ d)
       | (f, t, _, _) <- Schedule.nights
       , d <- [f, t]
       , cDate' d == Nothing
       ]
  where
    cDate' = parseDay

scheduleCards :: [DayText]
scheduleCards =
  [ DayText d (stripTags (unwords (map snd card)))
  | (date, card) <- Schedule.days
  , Just d <- [parseDay date]
  ]

scheduleNights :: [NightRow]
scheduleNights =
  [ NightRow f t en
  | (a, b, en, _) <- Schedule.nights
  , Just f <- [parseDay a]
  , Just t <- [parseDay b]
  ]

-- the checker's view of Atlas.hs: names a card would use, status, and
-- hours in minutes
placesFromAtlas :: [Place]
placesFromAtlas = map conv Atlas.places
  where
    conv ap =
      Place
        { pId = Atlas.pId ap
        , pNames = [n | Just n <- [Atlas.pNameJa ap, Just (Atlas.pMapsQuery ap), Just (Atlas.pNameEn ap)], n /= ""]
        , pStatus = Atlas.pStatus ap
        , pWeekly = M.fromList . map (fmap minutes) <$> Atlas.hWeekly (Atlas.pHours ap)
        , pClosed = Atlas.hClosed (Atlas.pHours ap)
        }
    minutes ivs = [(x, y) | (a, b) <- ivs, Just x <- [hhmm a], Just y <- [hhmm b]]

-- every HH:MM literal in Atlas.hs must actually parse (the minutes
-- conversion above silently drops broken ones, so catch them here)
checkHoursSyntax :: [Finding]
checkHoursSyntax =
  [ Err (Atlas.pId p ++ ": unparseable time " ++ show t ++ " (" ++ d ++ ")")
  | p <- Atlas.places
  , Just w <- [Atlas.hWeekly (Atlas.pHours p)]
  , (d, ivs) <- w
  , (a, b) <- ivs
  , t <- [a, b]
  , hhmm t == Nothing
  ]

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

checkCoverage :: [DayText] -> [Finding]
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

checkMentions :: [Place] -> DayText -> [Finding]
checkMentions ps (DayText d txt) =
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
checkStepTimes :: [Place] -> DayText -> [Finding]
checkStepTimes ps (DayText d txt) =
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

writeU :: FilePath -> String -> IO ()
writeU p s = withFile p WriteMode (\h -> hSetEncoding h utf8 >> hPutStr h s)

emitMain :: IO ()
emitMain = do
  writeU "hs/.build/days.js" (renderDays ++ "\n")
  writeU "hs/.build/nights.js" (renderNights ++ "\n")
  writeU "hs/.build/japan-2026.ics" renderIcs
  writeU "hs/.build/koko-places.json" renderAtlas
  putStrLn ("emitted hs/.build/days.js (" ++ show (length Schedule.days) ++ " cards), nights.js (" ++ show (length Schedule.nights) ++ " rows), japan-2026.ics, koko-places.json (" ++ show (length Atlas.places) ++ " places)")

checkMain :: IO ()
checkMain = do
  let places = placesFromAtlas
      cards = scheduleCards
      nights = scheduleNights
      sections =
        [ ("schedule schema (" ++ show (length Schedule.days) ++ " cards)", checkSchema)
        , ("calendar coverage", checkCoverage cards)
        , ("lodging coverage (" ++ show (length nights) ++ " rows)", checkNights nights)
        , ("atlas integrity (" ++ show (length places) ++ " places)", checkHoursSyntax ++ checkAtlas places)
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

main :: IO ()
main = do
  mapM_ (`hSetEncoding` utf8) [stdout, stderr]
  args <- getArgs
  case args of
    ["emit"] -> emitMain
    _ -> checkMain
