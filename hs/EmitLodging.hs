-- | Renders the lodging table from Schedule.stays: the tbody rows
-- (English inline, data-i18n attributes for the runtime toggle) and the
-- generated LODGING_I18N dict that carries both languages. Both are
-- spliced into index.html between LODGING:GEN / LODGING_I18N:GEN
-- markers by tools/splice-schedule.mjs.
module EmitLodging (renderLodgingRows, renderLodgingI18n) where

import Data.List (intercalate)
import Emit (jsq)
import Schedule (Stay (..), stays)

renderLodgingRows :: String
renderLodgingRows = intercalate "\n" (map row stays)
  where
    row st =
      "            <tr><td data-i18n=\"lo.dt" ++ stKey st ++ "\">" ++ stDatesEn st
        ++ "</td><td>" ++ show (stNt st)
        ++ "</td><td data-i18n=\"lo.prop" ++ stKey st ++ "\">" ++ stPropEn st
        ++ "</td><td>" ++ phoneCell (stPhone st)
        ++ "</td><td class=\"owner-only\" data-i18n=\"lo.pr" ++ stKey st ++ "\">" ++ stPriceEn st
        ++ "</td></tr>"
    phoneCell Nothing = "—"
    phoneCell (Just p) = "<code>" ++ p ++ "</code>"

renderLodgingI18n :: String
renderLodgingI18n =
  "const LODGING_I18N = {\n"
    ++ concatMap entries stays
    ++ "};\nObject.assign(T, LODGING_I18N);"
  where
    entries st =
      concat
        [ one ("lo.dt" ++ stKey st) (stDatesEn st) (stDatesJa st)
        , one ("lo.prop" ++ stKey st) (stPropEn st) (stPropJa st)
        , one ("lo.pr" ++ stKey st) (stPriceEn st) (stPriceJa st)
        ]
    one k en ja = "  " ++ jsq k ++ ":{en:" ++ jsq en ++ ", ja:" ++ jsq ja ++ "},\n"
