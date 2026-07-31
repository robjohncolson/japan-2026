-- | Renders Atlas.hs back into koko-places.json (the file the page and
-- the koko map fetch at runtime). One place per line, keys in the
-- original order, non-ASCII raw; "closed_ranges" is emitted only when
-- non-empty, matching the hand-written file's key-presence convention.
module EmitAtlas (renderAtlas) where

import Atlas
import Data.Char (ord)
import Data.List (intercalate)
import Numeric (showHex)

jstr :: String -> String
jstr s = "\"" ++ concatMap esc s ++ "\""
  where
    esc '"' = "\\\""
    esc '\\' = "\\\\"
    esc '\n' = "\\n"
    esc '\r' = "\\r"
    esc '\t' = "\\t"
    esc c
      | ord c < 32 = let h = showHex (ord c) "" in "\\u" ++ replicate (4 - length h) '0' ++ h
      | otherwise = [c]

jmstr :: Maybe String -> String
jmstr = maybe "null" jstr

jmdbl :: Maybe Double -> String
jmdbl = maybe "null" show

jbool :: Bool -> String
jbool b = if b then "true" else "false"

jlist :: [String] -> String
jlist xs = "[" ++ intercalate ", " (map jstr xs) ++ "]"

jpairs :: [(String, String)] -> String
jpairs xs = "[" ++ intercalate ", " ["[" ++ jstr a ++ ", " ++ jstr b ++ "]" | (a, b) <- xs] ++ "]"

jhours :: Hours -> String
jhours h =
  "{"
    ++ intercalate
      ", "
      ( [ "\"timezone\": " ++ jstr (hTimezone h)
        , "\"weekly\": " ++ weekly (hWeekly h)
        , "\"closed\": " ++ jlist (hClosed h)
        , "\"note\": " ++ jstr (hNote h)
        , "\"approx\": " ++ jbool (hApprox h)
        ]
          ++ ["\"closed_ranges\": " ++ jpairs (hClosedRanges h) | not (null (hClosedRanges h))]
      )
    ++ "}"
  where
    weekly Nothing = "null"
    weekly (Just ds) =
      "{" ++ intercalate ", " [jstr d ++ ": " ++ jpairs ivs | (d, ivs) <- ds] ++ "}"

renderPlace :: Place -> String
renderPlace p =
  "{"
    ++ intercalate
      ", "
      ( [ "\"id\": " ++ jstr (pId p)
      , "\"name_en\": " ++ jstr (pNameEn p)
      , "\"name_ja\": " ++ jmstr (pNameJa p)
      , "\"one_liner\": " ++ jstr (pOneLiner p)
      , "\"one_liner_ja\": " ++ jmstr (pOneLinerJa p)
      , "\"address\": " ++ jmstr (pAddress p)
      , "\"addr_geo\": " ++ jmstr (pAddrGeo p)
      , "\"plus_code\": " ++ jmstr (pPlusCode p)
      , "\"lat\": " ++ jmdbl (pLat p)
      , "\"lng\": " ++ jmdbl (pLng p)
      , "\"hubs\": " ++ jlist (pHubs p)
      , "\"tags\": " ++ jlist (pTags p)
      , "\"priority\": " ++ jstr (pPriority p)
      , "\"status\": " ++ jstr (pStatus p)
      , "\"phone\": " ++ jmstr (pPhone p)
      , "\"hours\": " ++ jhours (pHours p)
        , "\"maps_query\": " ++ jstr (pMapsQuery p)
        ]
          ++ ["\"aliases\": " ++ jlist (pAliases p) | not (null (pAliases p))]
          ++ [ "\"needs\": " ++ jlist (pNeeds p)
             , "\"vault\": " ++ jmstr (pVault p)
             , "\"kind\": " ++ jstr (pKind p)
             , "\"far\": " ++ jbool (pFar p)
             ]
      )
    ++ "}"

renderAtlas :: String
renderAtlas = "[\n" ++ intercalate ",\n" (map (("  " ++) . renderPlace) places) ++ "\n]\n"
