-- | The in-browser oracle: compiled BY MicroHs INSIDE the page (see
-- hs-wasm/), it reads the current unix time on stdin and answers, from
-- Schedule.hs, what today is, where we sleep tonight, and which timed
-- step is happening now / coming next — as one line of JSON on stdout.
-- Runs identically under native mhs for testing:
--   echo 1753900000 | mhs -ihs -r NowNext
-- Kept to simple Haskell2010 so both GHC and MicroHs compile it.
module NowNext (main) where

import Atlas (Hours (..), Place (..), places)
import Data.Char (chr, isDigit, ord)
import Data.List (isInfixOf, sortOn)
import Geo (haversineKm)
import Schedule (days, deadlines, nights)
import Sun (sunTimesJst)
import System.Environment (getArgs)

-- civil date from unix epoch (Howard Hinnant's algorithm), JST --------

jstOffset :: Int
jstOffset = 9 * 3600

data Moment = Moment {mDate :: (Int, Int, Int), mWeekday :: Int, mMinute :: Int}

moment :: Int -> Moment
moment epoch =
  let t = epoch + jstOffset
      z = t `div` 86400
      secs = t `mod` 86400
      z' = z + 719468
      era = z' `div` 146097
      doe = z' `mod` 146097
      yoe = (doe - doe `div` 1460 + doe `div` 36524 - doe `div` 146096) `div` 365
      y = yoe + era * 400
      doy = doe - (365 * yoe + yoe `div` 4 - yoe `div` 100)
      mp = (5 * doy + 2) `div` 153
      d = doy - (153 * mp + 2) `div` 5 + 1
      m = if mp < 10 then mp + 3 else mp - 9
      y' = if m <= 2 then y + 1 else y
   in Moment (y', m, d) ((z + 3) `mod` 7) (secs `div` 60) -- day 0 = Thu; +3 makes 0 = Mon

weekdayName :: Int -> String
weekdayName w = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] !! w

weekdayJa :: Int -> String
weekdayJa w = ["月", "火", "水", "木", "金", "土", "日"] !! w

pad2 :: Int -> String
pad2 n = if n < 10 then '0' : show n else show n

dateKey :: (Int, Int, Int) -> String
dateKey (y, m, d) = show y ++ "-" ++ pad2 m ++ "-" ++ pad2 d

dayOfYear :: (Int, Int, Int) -> Int
dayOfYear (y, m, d) =
  d + sum (take (m - 1) [31, feb, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31])
  where
    feb = if (y `mod` 4 == 0 && y `mod` 100 /= 0) || y `mod` 400 == 0 then 29 else 28

-- html -> plaintext (same rules as Ics.hs) ----------------------------

plain :: String -> String
plain = entities . tags
  where
    tags [] = []
    tags ('<' : r) =
      let rest = drop 1 (dropWhile (/= '>') r)
       in if take 2 r == "br" then '\n' : tags rest else tags rest
    tags (c : r) = c : tags r
    entities [] = []
    entities ('&' : r) = case break (== ';') r of
      (name, ';' : rest)
        | length name <= 8 ->
            let out = case name of
                  "amp" -> "&"; "lt" -> "<"; "gt" -> ">"
                  "quot" -> "\""; "nbsp" -> " "
                  '#' : ds | all isDigit ds, not (null ds) -> [chr (read ds)]
                  _ -> '&' : name ++ ";"
             in out ++ entities rest
      _ -> '&' : entities r
    entities (c : r) = c : entities r

trim :: String -> String
trim = f . f where f = reverse . dropWhile (`elem` " \n\t")

-- timed steps (same conservative rules as Ics.hs) ---------------------

stepMarks :: String
stepMarks = "①②③④⑤⑥⑦⑧⑨⑩⑪⑫"

steps :: String -> [(Char, String)]
steps s = case break (`elem` stepMarks) s of
  (_, []) -> []
  (_, m : rest) ->
    let (body, rest') = break (`elem` stepMarks) rest
     in (m, trim body) : steps rest'

firstTime :: String -> Maybe Int
firstTime = go (80 :: Int) '\0' '\0'
  where
    dashes = "–—−-〜~～"
    go _ _ _ [] = Nothing
    go 0 _ _ _ = Nothing
    go n prevRaw prevNS s@(c : r)
      | isDigit c
      , not (isDigit prevRaw)
      , prevRaw /= ':'
      , prevNS `notElem` dashes
      , (ds, rest) <- span isDigit s
      , length ds <= 2
      , ':' : m1 : m2 : after <- rest
      , isDigit m1 && isDigit m2
      , case after of d : _ -> not (isDigit d); [] -> True
      , (read ds :: Int) < 24
      , not (isRange after) =
          Just (read ds * 60 + read [m1, m2])
      | otherwise = go (n - 1) c (if c == ' ' then prevNS else c) r
    isRange after = case dropWhile (== ' ') after of
      d : rest' -> d `elem` dashes && looksLikeTime (dropWhile (== ' ') rest')
      [] -> False
    looksLikeTime s = case span isDigit s of
      (ds, ':' : m1 : m2 : _) -> not (null ds) && length ds <= 2 && isDigit m1 && isDigit m2
      _ -> False

timeline :: String -> [(Char, String, Int)]
timeline detail = increasing (-1) [(m, b, t) | (m, b) <- steps (plain detail), Just t <- [firstTime b]]
  where
    increasing _ [] = []
    increasing prev ((m, b, t) : r)
      | t > prev = (m, b, t) : increasing t r
      | otherwise = increasing prev r

-- what's open right now ------------------------------------------------

data Region = Kyushu | TokyoSide deriving (Eq)

-- tonight's lodging tells us which side of the country we're on
regionOf :: String -> Region
regionOf lodging =
  if any (`isInfixOf` lodging) ["Hakata", "Kanzaki", "Kuma", "Hitoyoshi", "Kumamoto", "Kagoshima", "Aso", "Fukuoka"]
    then Kyushu
    else TokyoSide

inRegion :: Region -> Place -> Bool
inRegion r p = case r of
  Kyushu -> "kyushu" `elem` pHubs p
  TokyoSide -> "kyushu" `notElem` pHubs p

-- a place someone might walk into with free time
walkIn :: Place -> Bool
walkIn p = pStatus p /= "skip" && pKind p `elem` ["food", "activity", "sight", "errand"]

hmMin :: String -> Maybe Int
hmMin s = case span isDigit s of
  (ds, ':' : m1 : m2 : _)
    | not (null ds), length ds <= 2, isDigit m1, isDigit m2 ->
        Just (read ds * 60 + read [m1, m2])
  _ -> Nothing

ivMins :: [(String, String)] -> [(Int, Int)]
ivMins ivs = [(x, y) | (a, b) <- ivs, Just x <- [hmMin a], Just y <- [hmMin b]]

dowKeys :: [String]
dowKeys = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]

dayIvs :: Place -> Int -> [(Int, Int)]
dayIvs p w = case hWeekly (pHours p) of
  Just ds -> maybe [] ivMins (lookup (dowKeys !! w) ds)
  Nothing -> []

closedOn :: String -> Place -> Bool
closedOn date p =
  date `elem` hClosed h || any (\(a, b) -> a <= date && date <= b) (hClosedRanges h)
  where
    h = pHours p

-- Just closing-minute if open at `now` (today's intervals, plus
-- yesterday's that spill past midnight, e.g. 18:00–25:00)
openUntil :: Int -> Int -> Place -> Maybe Int
openUntil w now p =
  case [b | (a, b) <- dayIvs p w, a <= now, now < b]
    ++ [b - 1440 | (a, b) <- dayIvs p ((w + 6) `mod` 7), b > 1440, a <= now + 1440, now + 1440 < b] of
    b : _ -> Just b
    [] -> Nothing

-- Just opening-minute if it opens within 90 min
opensSoon :: Int -> Int -> Place -> Maybe Int
opensSoon w now p =
  case [a | (a, _) <- dayIvs p w, now < a, a <= now + 90] of
    a : _ -> Just a
    [] -> Nothing

priRank :: Place -> Int
priRank p = case pPriority p of "high" -> 0; "medium" -> 1; _ -> 2

coord :: Place -> Maybe (Double, Double)
coord p = case (pLat p, pLng p) of (Just a, Just b) -> Just (a, b); _ -> Nothing

distKm :: Maybe (Double, Double) -> Place -> Maybe Double
distKm here p = haversineKm <$> here <*> coord p

fmtKm :: Double -> String
fmtKm k
  | k < 10 = show (fromIntegral (round (k * 10) :: Int) / 10 :: Double)
  | otherwise = show (round k :: Int)

untilStr :: Int -> String
untilStr t = if t >= 1440 then hmStr (t - 1440) ++ "+1" else hmStr t

placeJson :: Place -> [(String, String)] -> String
placeJson p extra =
  obj
    ( [ ("en", jstr (pNameEn p))
      , ("ja", jstr (maybe (pNameEn p) id (pNameJa p)))
      ]
        ++ [(k, jstr v) | (k, v) <- extra]
    )

-- json ----------------------------------------------------------------

jstr :: String -> String
jstr s = "\"" ++ concatMap esc s ++ "\""
  where
    esc '"' = "\\\""
    esc '\\' = "\\\\"
    esc '\n' = "\\n"
    esc '\r' = ""
    esc c = if ord c < 32 then "" else [c]

obj :: [(String, String)] -> String
obj kvs = "{" ++ intercalate "," [jstr k ++ ":" ++ v | (k, v) <- kvs] ++ "}"
  where
    intercalate sep = foldr1 (\a b -> a ++ sep ++ b)

hmStr :: Int -> String
hmStr t = pad2 (t `div` 60) ++ ":" ++ pad2 (t `mod` 60)

oneLine :: Int -> String -> String
oneLine n s =
  let w = unwords (words (map (\c -> if c == '\n' then ' ' else c) s))
   in if length w <= n then w else take (n - 1) w ++ "…"

-- the oracle -----------------------------------------------------------

field :: String -> [(String, String)] -> String
field k card = case lookup k card of Just v -> v; Nothing -> ""

answer :: Int -> Maybe (Double, Double) -> String
answer epoch here =
  let mo = moment epoch
      key = dateKey (mDate mo)
      nowMin = mMinute mo
      card = lookup key days
      lodging = [(en, ja) | (f, t, en, ja) <- nights, f <= key, key <= t]
      tl = case card of Just c -> timeline (field "detail" c); Nothing -> []
      current = [s | s@(_, _, t) <- tl, t <= nowMin, nowMin < t + 120]
      next = [s | s@(_, _, t) <- tl, t > nowMin]
      stepJson (m, b, t) = obj [("mark", jstr [m]), ("time", jstr (hmStr t)), ("text", jstr (oneLine 90 b))]
      nextKey = dateKey (mDate (moment (epoch + 86400)))
      tomorrow = lookup nextKey days
      wd = mWeekday mo
      region = case lodging of ((en, _) : _) -> Just (regionOf en); [] -> Nothing
      candidates r = [p | p <- places, walkIn p, inRegion r p, not (closedOn key p)]
      -- always-open places (konbini) sort last: knowing they're open is
      -- no news — unless we know where you are, in which case pure
      -- distance wins (the nearest konbini IS the answer sometimes)
      allDayish p = any (\(a, b) -> b - a >= 20 * 60) (dayIvs p wd)
      openKey p = case distKm here p of
        Just d -> (d, priRank p, pNameEn p)
        Nothing -> case here of
          Just _ -> (9999, priRank p, pNameEn p) -- no coords: sink when sorting by distance
          Nothing -> (if allDayish p then 1 else 0, priRank p, pNameEn p)
      openNow r =
        sortOn (\(p, _) -> openKey p) [(p, b) | p <- candidates r, Just b <- [openUntil wd nowMin p]]
      soonList r =
        sortOn (\(p, a) -> (priRank p, a)) $
          [(p, a) | p <- candidates r, openUntil wd nowMin p == Nothing, Just a <- [opensSoon wd nowMin p]]
      closedToday r =
        [ p
        | p <- places
        , walkIn p
        , inRegion r p
        , pPriority p == "high"
        , hWeekly (pHours p) /= Nothing
        , null (dayIvs p wd) || closedOn key p
        ]
      due =
        [(dl, False) | dl@(dt, _, _, _) <- deadlines, dt == key]
          ++ [(dl, True) | dl@(dt, _, _, _) <- deadlines, dt == nextKey]
      intercalate sep = foldr (\a b -> if null b then a else a ++ sep ++ b) ""
      -- solar geometry: your position if known, else the region's rough center
      sunSpot = case (here, region) of
        (Just c, _) -> Just c
        (Nothing, Just Kyushu) -> Just (33.45, 130.4)
        (Nothing, Just TokyoSide) -> Just (35.68, 139.77)
        (Nothing, Nothing) -> Nothing
      sunTimes' = sunSpot >>= sunTimesJst (dayOfYear (mDate mo))
      -- view: the panel's HTML itself, rendered here in both languages —
      -- the page-side JS is just `innerHTML = html_xx`
      htmlEsc = concatMap esc'
        where
          esc' '&' = "&amp;"; esc' '<' = "&lt;"; esc' '>' = "&gt;"; esc' '"' = "&quot;"
          esc' c = [c]
      dim s = "<span style=\"opacity:.6\">" ++ s ++ "</span>"
      joinDot = intercalate " · "
      labelOf ja c = trim (plain (field (if ja then "label_ja" else "label") c))
      pName ja p = if ja then maybe (pNameEn p) id (pNameJa p) else pNameEn p
      kmTag p = case distKm here p of Just d -> fmtKm d ++ "km · "; Nothing -> ""
      htmlFor ja =
        let tr en jaS = if ja then jaS else en
            stepBody (m, b, t) = [m] ++ " " ++ hmStr t ++ " — " ++ htmlEsc (oneLine 90 b)
            headerLine =
              "<b>" ++ htmlEsc (case card of Just c -> labelOf ja c; Nothing -> "—") ++ "</b> · "
                ++ key ++ " (" ++ (if ja then weekdayJa wd else weekdayName wd) ++ ") "
                ++ hmStr nowMin ++ " JST"
            sunLine = case sunTimes' of
              Just (r, s) -> ["🌅 " ++ hmStr r ++ " · 🌇 " ++ hmStr s]
              Nothing -> []
            lodgingLine = case lodging of
              (en, lj) : _ -> ["🏨 " ++ tr "Tonight" "今夜" ++ ": " ++ htmlEsc (if ja then lj else en)]
              [] -> []
            nowLine = case current of
              s : _ -> ["▶ " ++ tr "Now" "進行中" ++ " " ++ stepBody s]
              [] -> []
            nextLine = case next of
              s : _ -> ["⏭ " ++ tr "Next" "つぎ" ++ " " ++ stepBody s]
              [] -> []
            tomorrowLine = case tomorrow of
              Just c -> ["→ " ++ tr "Tomorrow" "明日" ++ ": " ++ htmlEsc (labelOf ja c)]
              Nothing -> []
            openLine = case region of
              Nothing -> []
              Just r ->
                case openNow r of
                  [] -> []
                  os ->
                    [ "🟢 " ++ tr "Open now" "営業中" ++ " (" ++ show (length os) ++ "): "
                        ++ joinDot [htmlEsc (pName ja p) ++ " " ++ dim (kmTag p ++ "~" ++ untilStr b) | (p, b) <- take 6 os]
                    ]
            soonLine = case region of
              Nothing -> []
              Just r ->
                case take 3 (soonList r) of
                  [] -> []
                  ss ->
                    [ "🔜 " ++ tr "Opens soon" "まもなく開店" ++ ": "
                        ++ joinDot [htmlEsc (pName ja p) ++ " " ++ dim (kmTag p ++ hmStr a) | (p, a) <- ss]
                    ]
            closedLine = case region of
              Nothing -> []
              Just r ->
                case take 4 (closedToday r) of
                  [] -> []
                  cs -> ["🚫 " ++ tr "Closed today" "本日定休" ++ ": " ++ joinDot (map (htmlEsc . pName ja) cs)]
            dlLine = case due of
              [] -> []
              ds ->
                [ "⏰ <b>" ++ tr "Deadline" "期限" ++ "</b>: "
                    ++ joinDot
                      [ htmlEsc (if ja then djA else den)
                          ++ (if tm /= "" then " <b>" ++ tm ++ "</b>" else "")
                          ++ (if tmrw then " " ++ dim (tr "(tomorrow)" "（明日）") else "")
                      | ((_, tm, den, djA), tmrw) <- ds
                      ]
                ]
         in intercalate
              "<br>"
              ( [headerLine] ++ sunLine ++ lodgingLine ++ nowLine ++ nextLine
                  ++ tomorrowLine ++ openLine ++ soonLine ++ closedLine ++ dlLine
              )
   in obj
        [ ("date", jstr key)
        , ("html_en", jstr (htmlFor False))
        , ("html_ja", jstr (htmlFor True))
        ]

-- argv: epoch [lat lng] — or epoch on stdin (the browser evaluator
-- feeds the .comb through stdin, so argv is the only free channel
-- there; coordinates are optional and processed entirely on-device)
main :: IO ()
main = do
  args <- getArgs
  s <- case args of
    a : _ -> return a
    [] -> getContents
  let num v = case reads (dropWhile (== ' ') v) of ((n, _) : _) -> Just n; [] -> Nothing
      epoch = case num s of Just n -> n; Nothing -> 0 :: Int
      here = case args of
        _ : la : lo : _ -> (,) <$> num la <*> num lo
        _ -> Nothing
  putStrLn (answer epoch here)
