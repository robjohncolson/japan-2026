-- | Great-circle distance over the atlas coordinates. Compiled by both
-- GHC (kernel step-geometry check) and MicroHs (in-browser
-- nearest-open sorting — the visitor's coordinates never leave the
-- phone; the whole computation runs in local WASM).
module Geo (haversineKm) where

haversineKm :: (Double, Double) -> (Double, Double) -> Double
haversineKm (la1, lo1) (la2, lo2) =
  let d2r x = x * pi / 180
      dla = d2r (la2 - la1)
      dlo = d2r (lo2 - lo1)
      a = sin (dla / 2) ^ (2 :: Int) + cos (d2r la1) * cos (d2r la2) * sin (dlo / 2) ^ (2 :: Int)
   in 6371.0088 * 2 * atan2 (sqrt a) (sqrt (1 - a))
