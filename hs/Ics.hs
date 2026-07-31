-- | Compiles Schedule.hs into an iCalendar feed (japan-2026.ics):
--
--   * each day card  -> all-day VEVENT (EN summary; EN+JA plaintext body)
--   * each lodging   -> spanning all-day VEVENT (through checkout day)
--   * each ①–⑫ step with an explicit HH:MM -> timed VEVENT in Asia/Tokyo,
--     lasting until the day's next timed step (else an hour)
--
-- Output is deliberately deterministic (fixed DTSTAMP) so regeneration
-- only diffs when the schedule does. RFC 5545 folding is done on UTF-8
-- octet counts without ever splitting a multi-byte character.
module Ics (renderIcs) where

import Data.Char (chr, isDigit, ord)
import Data.List (sortOn)
import Data.Time.Calendar (Day, addDays)
import Data.Time.Format (defaultTimeLocale, formatTime, parseTimeM)
import Schedule (days, nights)

-- html -> plaintext ----------------------------------------------------

plain :: String -> String
plain = entities . tags
  where
    tags [] = []
    tags s@('<' : r)
      | isBr s = '\n' : tags (drop 1 (dropWhile (/= '>') r))
      | otherwise = tags (drop 1 (dropWhile (/= '>') r))
    tags (c : r) = c : tags r
    isBr s = any (`prefix` s) ["<br>", "<br/>", "<br />"]
    prefix p s = map low (take (length p) s) == p
    low c = if c >= 'A' && c <= 'Z' then chr (ord c + 32) else c
    entities [] = []
    entities ('&' : r) = case break (== ';') r of
      (name, ';' : rest)
        | length name <= 8 ->
            let out = case name of
                  "amp" -> "&"; "lt" -> "<"; "gt" -> ">"
                  "quot" -> "\""; "nbsp" -> " "
                  '#' : 'x' : hs | all isHex hs, not (null hs) -> [chr (readHex hs)]
                  '#' : ds | all isDigit ds, not (null ds) -> [chr (read ds)]
                  _ -> '&' : name ++ ";"
             in out ++ entities rest
      _ -> '&' : entities r
    entities (c : r) = c : entities r
    isHex c = isDigit c || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
    readHex = foldl (\a c -> a * 16 + hexVal c) 0
    hexVal c
      | isDigit c = ord c - ord '0'
      | c >= 'a' = ord c - ord 'a' + 10
      | otherwise = ord c - ord 'A' + 10

trim :: String -> String
trim = f . f where f = reverse . dropWhile (`elem` " \n\t")

-- ics plumbing ---------------------------------------------------------

escText :: String -> String
escText = concatMap esc
  where
    esc '\\' = "\\\\"
    esc ';' = "\\;"
    esc ',' = "\\,"
    esc '\n' = "\\n"
    esc '\r' = ""
    esc c = [c]

utf8Len :: Char -> Int
utf8Len c
  | o < 0x80 = 1
  | o < 0x800 = 2
  | o < 0x10000 = 3
  | otherwise = 4
  where
    o = ord c

-- RFC 5545 §3.1: lines ≤75 octets; continuations start with a space.
foldLine :: String -> [String]
foldLine s0 =
  let (c0, r0) = splitBudget 74 s0
   in c0 : conts r0
  where
    conts [] = []
    conts r =
      let (c, r') = splitBudget 73 r -- 73 content octets + 1 leading space = 74
       in (' ' : c) : conts r'
    splitBudget b (c : r)
      | utf8Len c <= b =
          let (taken, rest) = splitBudget (b - utf8Len c) r
           in (c : taken, rest)
    splitBudget _ r = ([], r)

vevent :: [String] -> [String]
vevent props = ["BEGIN:VEVENT"] ++ props ++ ["END:VEVENT"]

dtstamp :: String
dtstamp = "DTSTAMP:20260731T000000Z"

parseDay :: String -> Maybe Day
parseDay = parseTimeM True defaultTimeLocale "%Y-%m-%d"

ymd :: Day -> String
ymd = formatTime defaultTimeLocale "%Y%m%d"

-- step parsing ---------------------------------------------------------

stepMarks :: String
stepMarks = "①②③④⑤⑥⑦⑧⑨⑩⑪⑫"

steps :: String -> [(Char, String)]
steps s = case break (`elem` stepMarks) s of
  (_, []) -> []
  (_, m : rest) ->
    let (body, rest') = break (`elem` stepMarks) rest
     in (m, trim body) : steps rest'

-- A step's plan time: an HH:MM in the first 80 chars that is not the
-- left side of an hours range ("11:00–20:00" is a shop listing, not a
-- rendezvous).
firstTime :: String -> Maybe Int
firstTime = go (80 :: Int) '\0' '\0'
  where
    dashes = "–—−-〜~～"
    go _ _ _ [] = Nothing
    go 0 _ _ _ = Nothing
    go n prevRaw prevNS s@(c : r)
      | isDigit c
      , not (isDigit prevRaw) -- don't start matching mid-number ("2|1:00")
      , prevRaw /= ':'
      , prevNS `notElem` dashes -- not the right side of "10:00 – 21:00"
      , (ds, rest) <- span isDigit s
      , length ds <= 2
      , ':' : m1 : m2 : after <- rest
      , isDigit m1 && isDigit m2
      , case after of d : _ -> not (isDigit d); [] -> True
      , read ds < (24 :: Int)
      , not (isRange after) =
          Just (read ds * 60 + read [m1, m2])
      | otherwise = go (n - 1) c (if c == ' ' then prevNS else c) r
    isRange after = case dropWhile (== ' ') after of
      d : rest' -> d `elem` "–—−-〜~～" && looksLikeTime (dropWhile (== ' ') rest')
      [] -> False
    looksLikeTime s = case span isDigit s of
      (ds, ':' : m1 : m2 : _) -> not (null ds) && length ds <= 2 && isDigit m1 && isDigit m2
      _ -> False

hm :: Int -> String
hm t = pad (t `div` 60) ++ pad (t `mod` 60) ++ "00"
  where
    pad n = (if n < 10 then "0" else "") ++ show n

ellipsize :: Int -> String -> String
ellipsize n s =
  let oneLine = unwords (words (map (\c -> if c == '\n' then ' ' else c) s))
   in if length oneLine <= n then oneLine else take (n - 1) oneLine ++ "…"

-- events ---------------------------------------------------------------

field :: String -> [(String, String)] -> String
field k card = maybe "" id (lookup k card)

-- sort key: (day, priority) — lodging banner, then the day card, then steps
data Ev = Ev Day Int [String]

dayEvents :: (String, [(String, String)]) -> [Ev]
dayEvents (date, card) =
  case parseDay date of
    Nothing -> []
    Just d ->
      let label = trim (plain (field "label" card))
          labelJa = trim (plain (field "label_ja" card))
          detail = trim (plain (field "detail" card))
          detailJa = trim (plain (field "detail_ja" card))
          summary = (if field "cls" card == "flight" then "✈️ " else "") ++ label
          body = detail ++ (if null detailJa then "" else "\n----\n" ++ labelJa ++ "\n" ++ detailJa)
          allday =
            Ev d 1 $
              vevent
                [ "UID:d-" ++ date ++ "@japan-2026"
                , dtstamp
                , "DTSTART;VALUE=DATE:" ++ ymd d
                , "DTEND;VALUE=DATE:" ++ ymd (addDays 1 d)
                , "SUMMARY:" ++ escText summary
                , "DESCRIPTION:" ++ escText body
                ]
          -- keep only a strictly increasing timeline: a step whose time
          -- runs backwards is narrative (a deadline, a shop's hours),
          -- not the day's schedule
          timed = increasing (-1) [(m, body', t) | (m, body') <- steps detail, Just t <- [firstTime body']]
          increasing _ [] = []
          increasing prev ((m, b, t) : r)
            | t > prev = (m, b, t) : increasing t r
            | otherwise = increasing prev r
          nexts = map (\(_, _, t) -> t) (drop 1 timed) ++ [-1]
          stepEv i ((m, body', t), next) =
            let dur = if next > t then min (next - t) 240 else 60
                endT = min (t + dur) 1439
             in Ev d (2 + i) $
                  vevent
                    [ "UID:s-" ++ date ++ "-" ++ show i ++ "@japan-2026"
                    , dtstamp
                    , "DTSTART;TZID=Asia/Tokyo:" ++ ymd d ++ "T" ++ hm t
                    , "DTEND;TZID=Asia/Tokyo:" ++ ymd d ++ "T" ++ hm endT
                    , "SUMMARY:" ++ escText ([m] ++ " " ++ ellipsize 64 body')
                    , "DESCRIPTION:" ++ escText body'
                    ]
       in allday : zipWith stepEv [0 ..] (zip timed nexts)

nightEvents :: (String, String, String, String) -> [Ev]
nightEvents (from, to, en, ja) =
  case (parseDay from, parseDay to) of
    (Just f, Just t) ->
      [ Ev f 0 $
          vevent
            [ "UID:n-" ++ from ++ "@japan-2026"
            , dtstamp
            , "DTSTART;VALUE=DATE:" ++ ymd f
            , "DTEND;VALUE=DATE:" ++ ymd (addDays 2 t) -- through checkout day
            , "SUMMARY:" ++ escText ("🏨 " ++ en)
            , "DESCRIPTION:" ++ escText ja
            ]
      ]
    _ -> []

renderIcs :: String
renderIcs =
  concatMap (\l -> concatMap (++ "\r\n") (foldLine l)) allLines
  where
    allLines =
      [ "BEGIN:VCALENDAR"
      , "VERSION:2.0"
      , "PRODID:-//japan-2026//schedule-hs//EN"
      , "CALSCALE:GREGORIAN"
      , "METHOD:PUBLISH"
      , "X-WR-CALNAME:Japan 2026"
      , "X-WR-TIMEZONE:Asia/Tokyo"
      , "BEGIN:VTIMEZONE"
      , "TZID:Asia/Tokyo"
      , "BEGIN:STANDARD"
      , "DTSTART:19700101T000000"
      , "TZOFFSETFROM:+0900"
      , "TZOFFSETTO:+0900"
      , "TZNAME:JST"
      , "END:STANDARD"
      , "END:VTIMEZONE"
      ]
        ++ concatMap (\(Ev _ _ ls) -> ls) (sortOn (\(Ev d p _) -> (d, p)) evs)
        ++ ["END:VCALENDAR"]
    evs = concatMap nightEvents nights ++ concatMap dayEvents days
