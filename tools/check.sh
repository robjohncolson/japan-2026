#!/usr/bin/env bash
# Full pre-commit check: JS syntax (via extraction), JSON validity, and the
# Haskell schedule kernel's invariants. Run from anywhere in the repo.
set -euo pipefail
cd "$(dirname "$0")/.."

node tools/extract-data.mjs
python3 -c "import json; json.load(open('koko-places.json'))" && echo "koko-places.json valid"
node --check sw.js && echo "sw.js valid"

mkdir -p hs/.build
ghc -O0 -outputdir hs/.build -o hs/.build/check -ihs hs/Check.hs 1>/dev/null
hs/.build/check
hs/.build/check emit
node tools/splice-schedule.mjs --check   # page data blocks must match hs/Schedule.hs
cmp -s hs/.build/japan-2026.ics japan-2026.ics || { echo "DRIFT: japan-2026.ics is stale — run tools/apply-schedule.sh" >&2; exit 1; }
echo "japan-2026.ics matches hs/Schedule.hs ✓"
ghc -fno-code -outputdir hs/.build/nowcheck -ihs hs/NowNext.hs 1>/dev/null && echo "NowNext.hs compiles under GHC ✓"
if [ -x hs/.microhs/bin/mhs ]; then
  MHSDIR=hs/.microhs/root hs/.microhs/bin/mhs -ihs NowNext -ohs/.build/now-next.comb 2>/dev/null
  cmp -s hs/.build/now-next.comb hs-wasm/now-next.comb || { echo "DRIFT: hs-wasm/now-next.comb is stale — run tools/apply-schedule.sh" >&2; exit 1; }
  echo "hs-wasm/now-next.comb matches hs/Schedule.hs ✓"
else
  echo "(skipped comb drift check — tools/get-microhs.sh to enable)"
fi
