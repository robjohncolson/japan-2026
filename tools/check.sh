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
