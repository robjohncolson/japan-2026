-- | The in-browser oracle: compiled BY MicroHs INSIDE the page (see
-- hs-wasm/), it reads the current unix time on stdin and answers, from
-- Schedule.hs, what today is, where we sleep tonight, and which timed
-- step is happening now / coming next — as one line of JSON on stdout.
-- Runs identically under native mhs for testing:
--   echo 1753900000 | mhs -ihs -r NowNext
-- Kept to simple Haskell2010 so both GHC and MicroHs compile it.
module NowNext (main) where

import Data.Char (chr, isDigit, ord)
import Schedule (days, nights)
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

answer :: Int -> String
answer epoch =
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
   in obj
        ( [ ("date", jstr key)
          , ("weekday", jstr (weekdayName (mWeekday mo)))
          , ("weekdayJa", jstr (weekdayJa (mWeekday mo)))
          , ("time", jstr (hmStr nowMin))
          ]
            ++ ( case card of
                   Just c ->
                     [ ("label", jstr (trim (plain (field "label" c))))
                     , ("labelJa", jstr (trim (plain (field "label_ja" c))))
                     ]
                   Nothing -> [("label", "null"), ("labelJa", "null")]
               )
            ++ ( case lodging of
                   ((en, ja) : _) -> [("lodgingEn", jstr en), ("lodgingJa", jstr ja)]
                   [] -> [("lodgingEn", "null"), ("lodgingJa", "null")]
               )
            ++ [("now", case current of s : _ -> stepJson s; [] -> "null")]
            ++ [("next", case next of s : _ -> stepJson s; [] -> "null")]
            ++ ( case tomorrow of
                   Just c -> [("tomorrow", jstr (trim (plain (field "label" c))))]
                   Nothing -> [("tomorrow", "null")]
               )
        )

-- epoch seconds via first program argument, or stdin as fallback (the
-- browser evaluator feeds the .comb through stdin, so argv is the only
-- free channel there)
main :: IO ()
main = do
  args <- getArgs
  s <- case args of
    a : _ -> return a
    [] -> getContents
  let epoch = case reads (dropWhile (== ' ') s) of
        ((n, _) : _) -> n
        [] -> 0
  putStrLn (answer epoch)
