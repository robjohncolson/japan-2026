# hs/ — the Haskell schedule

**The itinerary's source of truth is `hs/Schedule.hs`.** The `DAYS` and
`NIGHTS` blocks in `index.html` are generated output — do not hand-edit
them (the checker's drift check will fail the build if you do). The page
itself stays plain JS because it must run on GitHub Pages + offline
phones mid-trip; what moved to Haskell is the data and every check that
reasons about it.

## Editing the schedule

1. Edit `hs/Schedule.hs` (cards are `(field, value)` pairs; strings are
   ordinary Haskell literals, so apostrophes are safe — the emitter
   escapes everything mechanically, which retired the single-quote
   SyntaxError trap for good).
2. `./tools/apply-schedule.sh` — compiles, runs the invariant checks
   (refusing to splice a broken schedule), emits the JS blocks, splices
   them into `index.html`, and re-extracts as a syntax proof.
3. Bump `CACHE` in `sw.js`, commit.

## Checking (CI-style, run before any commit)

    ./tools/check.sh

runs: extraction (JS syntax proof) → JSON validity → `sw.js` syntax →
the kernel's invariants → emit + drift check (page blocks must equal
`Schedule.hs` output).

## What the kernel checks (`hs/Check.hs`)

- **schema** — every card has cls / label / label_ja / detail / detail_ja
- **calendar coverage** — no missing day cards between first and last
- **lodging coverage** — NIGHTS rows contiguous, no gap nights, no overlaps
- **atlas integrity** — unique ids, hours intervals well-formed
  (closes past midnight are encoded 24:00+, allowed to 30:00)
- **mentions vs. reality** — a day card naming a place that is
  `status:skip`, closed that weekday, or closed on that exact date
- **explicit times vs. opening hours** — an `HH:MM` in a ①–⑫ step that
  falls outside the resolved place's hours ("Honten opens at noon" bugs)

Errors exit non-zero. Mention findings are **warnings** by design: cards
narrate the past too, so "mentions West Georgia (status:skip)" on a card
that says the shop does not exist is correct record, not a bug. On its
first run the kernel caught a future card sending us to 備深酒家 on a
Wednesday (its closing day) and a stale reference to the cancelled
Kagaya tin.

## Calendar feed

`emit` also compiles the schedule to **`japan-2026.ics`** (linked from
the page footer: 📅 "Add the trip to your calendar"): every day card is
an all-day event (EN summary, EN+JA plaintext body), every lodging stay
a 🏨 span through checkout day, and every ①–⑫ step with a deliberate
plan time a timed event in Asia/Tokyo. Time extraction is conservative
on purpose — an `HH:MM` counts only if it appears in the step's first
80 chars, isn't either side of an hours range (`10:00–21:00`), and
keeps the day's timeline strictly increasing; shop hours and deadlines
in prose stay in the description. `tools/check.sh` fails if the
committed .ics is stale.

## Files

- `Schedule.hs` — the data (generated once from the page by
  `tools/gen-schedule-hs.py`, hand-owned since)
- `Emit.hs` — renders the JS blocks (single-quoted, mechanically escaped)
- `Ics.hs` — compiles the schedule to the iCalendar feed
- `Check.hs` — invariants + `emit` mode
- `Json.hs` — dependency-free JSON parser (surrogate pairs included)
- needs GHC (boot libraries only — no cabal) and node

A full in-browser Haskell UI (Miso / GHC-WASM) is the eventual endgame;
that is a post-trip project.
