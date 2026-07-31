#!/usr/bin/env bash
# The edit flow now that hs/Schedule.hs owns the itinerary:
#   1. edit hs/Schedule.hs
#   2. ./tools/apply-schedule.sh   (build, check, emit, splice into index.html)
#   3. bump CACHE in sw.js, commit
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p hs/.build
ghc -O0 -outputdir hs/.build -o hs/.build/check -ihs hs/Check.hs 1>/dev/null
hs/.build/check            # invariants first — refuse to splice a broken schedule
hs/.build/check emit
node tools/splice-schedule.mjs
node tools/extract-data.mjs  # re-extract = JS syntax proof of the spliced page
echo "done — remember to bump CACHE in sw.js before committing"
