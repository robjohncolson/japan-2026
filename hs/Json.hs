-- Minimal JSON parser, GHC boot libraries only (no aeson).
-- Handles \uXXXX escapes including surrogate pairs (the atlas and day
-- cards are full of Japanese text and emoji).
module Json (JValue (..), parseJson, jLookup, jString, jArray, jObject) where

import Data.Char (chr, isDigit, isHexDigit, isSpace)
import Numeric (readHex)

data JValue
  = JNull
  | JBool Bool
  | JNum Double
  | JStr String
  | JArr [JValue]
  | JObj [(String, JValue)]
  deriving (Eq, Show)

type P a = String -> Either String (a, String)

parseJson :: String -> Either String JValue
parseJson s = do
  (v, rest) <- pValue (dropWhile isSpace s)
  if all isSpace rest then Right v else Left ("trailing garbage: " ++ take 40 rest)

pValue :: P JValue
pValue s = case dropWhile isSpace s of
  'n' : 'u' : 'l' : 'l' : r -> Right (JNull, r)
  't' : 'r' : 'u' : 'e' : r -> Right (JBool True, r)
  'f' : 'a' : 'l' : 's' : 'e' : r -> Right (JBool False, r)
  '"' : r -> do (str, r') <- pString r; Right (JStr str, r')
  '[' : r -> pArray (dropWhile isSpace r)
  '{' : r -> pObject (dropWhile isSpace r)
  r@(c : _) | c == '-' || isDigit c -> pNumber r
  r -> Left ("unexpected input: " ++ take 40 r)

pArray :: P JValue
pArray (']' : r) = Right (JArr [], r)
pArray s = go [] s
  where
    go acc t = do
      (v, r) <- pValue t
      case dropWhile isSpace r of
        ',' : r' -> go (v : acc) r'
        ']' : r' -> Right (JArr (reverse (v : acc)), r')
        r' -> Left ("array: expected , or ] at " ++ take 40 r')

pObject :: P JValue
pObject ('}' : r) = Right (JObj [], r)
pObject s = go [] s
  where
    go acc t = case dropWhile isSpace t of
      '"' : r -> do
        (k, r1) <- pString r
        case dropWhile isSpace r1 of
          ':' : r2 -> do
            (v, r3) <- pValue r2
            case dropWhile isSpace r3 of
              ',' : r4 -> go ((k, v) : acc) r4
              '}' : r4 -> Right (JObj (reverse ((k, v) : acc)), r4)
              r4 -> Left ("object: expected , or } at " ++ take 40 r4)
          r2 -> Left ("object: expected : at " ++ take 40 r2)
      r -> Left ("object: expected key at " ++ take 40 r)

pString :: P String -- input starts after the opening quote
pString = go []
  where
    go acc ('"' : r) = Right (reverse acc, r)
    go acc ('\\' : c : r) = case c of
      '"' -> go ('"' : acc) r
      '\\' -> go ('\\' : acc) r
      '/' -> go ('/' : acc) r
      'b' -> go ('\b' : acc) r
      'f' -> go ('\f' : acc) r
      'n' -> go ('\n' : acc) r
      'r' -> go ('\r' : acc) r
      't' -> go ('\t' : acc) r
      'u' -> case hex4 r of
        Just (hi, r1)
          | hi >= 0xD800 && hi <= 0xDBFF -> case r1 of
              '\\' : 'u' : r2 -> case hex4 r2 of
                Just (lo, r3)
                  | lo >= 0xDC00 && lo <= 0xDFFF ->
                      let cp = 0x10000 + (hi - 0xD800) * 0x400 + (lo - 0xDC00)
                       in go (chr cp : acc) r3
                _ -> Left "bad low surrogate"
              _ -> Left "lone high surrogate"
          | otherwise -> go (chr hi : acc) r1
        Nothing -> Left "bad \\u escape"
      _ -> Left ("bad escape: \\" ++ [c])
    go acc (c : r) = go (c : acc) r
    go _ [] = Left "unterminated string"
    hex4 s = case splitAt 4 s of
      (h, r) | length h == 4 && all isHexDigit h -> case readHex h of
        [(n, "")] -> Just (n, r)
        _ -> Nothing
      _ -> Nothing

pNumber :: P JValue
pNumber s =
  let (tok, r) = span (\c -> isDigit c || c `elem` "+-.eE") s
   in case reads tok :: [(Double, String)] of
        [(n, "")] -> Right (JNum n, r)
        _ -> Left ("bad number: " ++ tok)

-- helpers -------------------------------------------------------------

jLookup :: String -> JValue -> Maybe JValue
jLookup k (JObj kvs) = lookup k kvs
jLookup _ _ = Nothing

jString :: JValue -> Maybe String
jString (JStr s) = Just s
jString _ = Nothing

jArray :: JValue -> Maybe [JValue]
jArray (JArr xs) = Just xs
jArray _ = Nothing

jObject :: JValue -> Maybe [(String, JValue)]
jObject (JObj kvs) = Just kvs
jObject _ = Nothing
