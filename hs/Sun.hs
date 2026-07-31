-- | Sunrise/sunset from first principles (NOAA solar equations, ±2-3
-- min) — computed on the phone by MicroHs, and by GHC in the kernel if
-- ever needed. Inputs: day-of-year, latitude, longitude; output:
-- minutes-of-day JST.
module Sun (sunTimesJst) where

d2r :: Double -> Double
d2r x = x * pi / 180

r2d :: Double -> Double
r2d x = x * 180 / pi

-- day-of-year (1..366) -> (lat, lng) -> Maybe (sunrise, sunset) in JST minutes
sunTimesJst :: Int -> (Double, Double) -> Maybe (Int, Int)
sunTimesJst doy (lat, lng) =
  let g = 2 * pi / 365 * (fromIntegral doy - 1)
      eqtime =
        229.18
          * ( 0.000075 + 0.001868 * cos g - 0.032077 * sin g
                - 0.014615 * cos (2 * g) - 0.040849 * sin (2 * g)
            )
      decl =
        0.006918 - 0.399912 * cos g + 0.070257 * sin g
          - 0.006758 * cos (2 * g) + 0.000907 * sin (2 * g)
          - 0.002697 * cos (3 * g) + 0.00148 * sin (3 * g)
      cosHa =
        cos (d2r 90.833) / (cos (d2r lat) * cos decl)
          - tan (d2r lat) * tan decl
   in if cosHa > 1 || cosHa < -1
        then Nothing -- polar day/night; not a concern between Kagoshima and Tokyo
        else
          let haDeg = r2d (acos cosHa)
              riseUtc = 720 - 4 * (lng + haDeg) - eqtime
              setUtc = 720 - 4 * (lng - haDeg) - eqtime
              toJst m = (round m + 540) `mod` 1440
           in Just (toJst riseUtc, toJst setUtc)
