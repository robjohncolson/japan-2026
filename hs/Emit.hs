-- | Renders Schedule.hs back into the JS data blocks embedded in
-- index.html. All strings are emitted single-quoted with mechanical
-- escaping, which retires the hand-written-apostrophe trap for good:
-- a ' in the data becomes \' in the page, never a SyntaxError.
module Emit (renderDays, renderNights) where

import Data.List (intercalate)
import Schedule (Card, days, nights)

jsq :: String -> String
jsq s = "'" ++ concatMap esc s ++ "'"
  where
    esc '\'' = "\\'"
    esc '\\' = "\\\\"
    esc '\n' = "\\n"
    esc '\r' = "\\r"
    esc c = [c]

renderDays :: String
renderDays =
  "const DAYS = {\n"
    ++ concatMap row days
    ++ "};"
  where
    row (date, card) = "  " ++ jsq date ++ ":{" ++ intercalate ", " (map field card) ++ "},\n"
    field (k, v) = k ++ ":" ++ jsq v

renderNights :: String
renderNights =
  "const NIGHTS = [\n"
    ++ concatMap row nights
    ++ "];"
  where
    row (f, t, en, ja) =
      "  [" ++ jsq f ++ "," ++ jsq t ++ ", {en:" ++ jsq en ++ ", ja:" ++ jsq ja ++ "}],\n"
