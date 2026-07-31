# hs/ — the Haskell schedule kernel

The itinerary's data still lives in `index.html` (the page must stay
plain JS for GitHub Pages + offline phones mid-trip), but the *reasoning*
about it now lives here in typed Haskell. `tools/check.sh` runs the whole
pipeline:

1. `tools/extract-data.mjs` — pulls the `DAYS` and `NIGHTS` literals out of
   `index.html` and writes `hs/.build/*.json`. Evaluating the literals in
   node doubles as the JS syntax check, so the apostrophe trap
   (see HANDOFF.md) dies here instead of as a white page on a phone.
2. `hs/Check.hs` (with `hs/Json.hs`, a dependency-free JSON parser) —
   decodes the day cards, lodging rows and `koko-places.json` into typed
   structures and checks:
   - **calendar coverage** — no missing day cards between first and last
   - **lodging coverage** — NIGHTS rows contiguous, no gap nights, no overlaps
   - **atlas integrity** — unique ids, hours intervals well-formed
     (closes past midnight are encoded 24:00+, allowed to 30:00)
   - **mentions vs. reality** — a day card that names a place which is
     `status:skip`, closed that weekday, or closed on that exact date
   - **explicit times vs. opening hours** — an `HH:MM` written in a ①–⑫
     step that falls outside the resolved place's hours (the
     "Honten opens at noon" class of bug)

Errors (coverage breaks, duplicate ids, malformed hours) exit non-zero.
Mention findings are **warnings** by design: cards narrate the past too,
so "mentions West Georgia (status:skip)" on a card that says the shop
does not exist is correct record, not a bug. Read warnings, don't
blindly silence them — on its first run the kernel caught a future card
sending us to 備深酒家 on a Wednesday (its closing day) and a stale
reference to the cancelled Kagaya tin.

Requires GHC (boot libraries only — no cabal, no aeson) and node.

    ./tools/check.sh

First run compiles `hs/.build/check`; artifacts stay untracked.
