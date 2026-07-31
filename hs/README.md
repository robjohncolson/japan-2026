# hs/ — the Haskell trip data

**All trip data lives in Haskell now.** The itinerary is
`hs/Schedule.hs`; the 155-place atlas (statuses, opening hours, names,
coordinates) is `hs/Atlas.hs`. The `DAYS`/`NIGHTS` blocks in
`index.html`, `koko-places.json`, and `japan-2026.ics` are all
generated output — do not hand-edit them (the checker's drift checks
fail the build if you do). The page itself stays plain JS because it
must run on GitHub Pages + offline phones mid-trip; what moved to
Haskell is the data, every check that reasons about it, and the
on-device "Right now λ" oracle.

## Editing the schedule or the atlas

1. Edit `hs/Schedule.hs` (cards are `(field, value)` pairs) or
   `hs/Atlas.hs` (typed `Place`/`Hours` records). Strings are ordinary
   Haskell literals, so apostrophes are safe — the emitters escape
   everything mechanically, which retired the single-quote SyntaxError
   trap for good.
2. `./tools/apply-schedule.sh` — compiles, runs the invariant checks
   (refusing to emit from broken data), regenerates the JS blocks +
   `koko-places.json` + the .ics + the browser combinator file, and
   re-extracts as a syntax proof.
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
plan time a timed event in Asia/Tokyo. The typed `deadlines` list in
Schedule.hs (cancel windows, return times) becomes ⏰ events with
display alarms — 3h ahead of timed deadlines, 1h ahead of the 10:00
pin for date-only ones. Time extraction is conservative
on purpose — an `HH:MM` counts only if it appears in the step's first
80 chars, isn't either side of an hours range (`10:00–21:00`), and
keeps the day's timeline strictly increasing; shop hours and deadlines
in prose stay in the description. `tools/check.sh` fails if the
committed .ics is stale.

## Files

- `Schedule.hs` — the itinerary (generated once from the page by
  `tools/gen-schedule-hs.py`, hand-owned since)
- `Atlas.hs` — the place atlas (generated once from koko-places.json by
  `tools/gen-atlas-hs.py`, hand-owned since; typed records, so a typo'd
  status or a malformed HH:MM is a compile/check error, not a silent bug)
- `Emit.hs` — renders the JS blocks (single-quoted, mechanically escaped)
- `EmitAtlas.hs` — renders koko-places.json from Atlas.hs
- `Ics.hs` — compiles the schedule to the iCalendar feed
- `Check.hs` — invariants + `emit` mode
- `Json.hs` — dependency-free JSON parser (surrogate pairs included);
  no longer on the check path now that the atlas is native Haskell —
  kept for future tooling
- needs GHC (boot libraries only — no cabal) and node

## Haskell in the browser (shipped)

The "Right now λ" section at the top of the page runs `NowNext.hs` **on
the visitor's phone** — today's card, tonight's lodging, current/next
timed step, plus the atlas layer: which places are **open right now**
(with closing times, region inferred from tonight's lodging, 24h
konbini sorted last), what **opens within 90 minutes**, and which
high-priority places are **closed today** (the "Honten is dark on
Wednesdays" mistake, caught at decision time — including explicit
closed dates and Obon ranges, and cross-midnight hours like 18:00–25:00).
With location permission the open lists sort by real haversine distance
(Geo.hs, on-device); Sun.hs adds sunrise/sunset from NOAA solar
equations; and because the oracle is a pure function of the epoch, the
◀ ⟲ ▶ buttons time-travel it — same combinators, any day of the trip.
The machinery: `tools/get-microhs.sh` builds a pinned
[MicroHs](https://github.com/augustss/MicroHs) (fetched via the Go
module proxy, since github.com is blocked in the build sandbox), the
apply script compiles `NowNext.hs` + `Schedule.hs` to combinators
(`hs-wasm/now-next.comb`), and the page lazy-loads the vendored MicroHs
evaluator (`hs-wasm/mhseval.js`, MIT, WASM) on tap — comb via
`/dev/stdin`, epoch seconds via argv, JSON on stdout. ~4 s first run,
EN/JA, precached for offline, and pure progressive enhancement: if
anything fails the panel shows one error line and the rest of the page
is untouched. `NowNext.hs` stays compilable by both GHC (checked in
check.sh) and MicroHs. As of v189 the panel's **view is Haskell too**:
NowNext.hs renders the panel HTML in both languages (html_en /
html_ja) and the page-side JS is a one-line innerHTML pipe — the first
piece of UI whose rendering logic lives in Haskell.

A full Haskell UI (Miso / GHC-WASM) would be the final step; that
remains a post-trip project — but the runtime beachhead is live.

## λ playground (repl.html)

The site is now a Haskell machine in the literal sense: `repl.html`
(footer link "λ playground") loads the **full MicroHs compiler** as
WASM and compiles whatever you type — on the phone, offline from any
server, nothing transmitted. The trip's own modules are importable
(`Schedule`, `Geo`, `Sun`; `Atlas` works but compiles slowly), so you
can query the itinerary in Haskell from a konbini parking lot.
First run: ~2 MB download + ~10 s compile. Not precached by the SW —
it's an online-first toy, the itinerary always comes first.
