# Handoff — session of 29 Jul 2026 (mid-trip, Tokyo)

Written for a fresh session picking this up with no conversation history.
Live page: https://robjohncolson.github.io/japan-2026/ · everything below is on `main`.

## What this repo is

A single-file System 7-styled itinerary page (`index.html`, ~4600 lines, no build
step) plus `koko-places.json`, a 145-entry atlas of places with coordinates,
weekly opening hours, tags and hubs. `sw.js` precaches the shell for offline use
in rural Kyushu. Supabase backs per-day family notes, a message board and owner
day-edits; see `README.md` for the tables and the owner-mode secret flow.

The trip is **in progress** — the page is being read on a phone in Tokyo while
being edited. Treat every change as live.

## Non-obvious rules — read before editing `index.html`

1. **Bump `CACHE` in `sw.js` on every content commit.** It went v149 → v167
   today. `koko-places.json` is in the precached shell, so without a bump the
   change does not reach an already-installed phone. Every content commit in
   `git log` bumps it; follow that.
2. **Day `detail:` strings are single-quoted JS.** An apostrophe in one is a
   `SyntaxError` that blanks the whole page. This has bitten twice — see commit
   `db9cb98` and once again today. Write "the craving" not "that's the craving".
3. **Validate before committing.** Extract the inline `<script>` blocks and run
   `node --check` on each. A syntax error here is not a lint failure, it is a
   white page on someone's phone mid-trip.
4. **`README.md` says mid-trip changes should go through owner edit mode**
   (footer 🔒 → "Edit this day"), not by editing the file, because the baseline
   mirrors a private vault (`japan2026.tex`). Today's changes were made in the
   file at the owner's explicit request. **The vault has therefore drifted and
   should be reconciled.**
5. **Privacy line:** the page is read by family. Prices, cancel fees, booking
   codes and door PINs are owner-only or vault-only. Keep personal reasoning out
   of day text.

## The timeline validator (added today)

Bottom of today's day card. Walks the ①–⑫ stops **in their written order** from
an editable start time and reports what that order implies: doors reached before
opening, kitchens reached after last order, total dead time.

It deliberately **validates rather than optimizes**. The written order encodes
intent no solver can see — mapo lunch and Moti dinner are both intentional, Akiba
is browse-only for a bag reason. Reordering would produce two curries.

Key functions, all in `index.html`:

| Function | Role |
|---|---|
| `decorateDayPlan()` | existing step parser; now also collects `{mark, text, row}` per stop |
| `planResolveStop()` | earliest-mentioned place that can *be* a stop — has hours, not `status:skip` |
| `planLegMinutes()` | pinned pairs in `PLAN_LEGS`, else haversine + transit fudge |
| `planDwellFor()` | `~1h` / `~30分` in the step text, else tag-based default |
| `planSimulate()` | walks stops, returns arrival verdicts (`ok` / `early` / `late` / `unknown`) |
| `renderTimeline()` | draws the panel; wrapped in try/catch at the call site |

Two traps found by running it in a browser rather than reading it:

- Collect steps **while decorating**, using `span.textContent` at the point where
  the checkbox is in but the 🗺 link and open/closed chip are not. The loop
  variable `txt` is only the step's *first text node* (the ①–⑫ mark), not the
  step; and after full decoration the text starts with 🗺, not the mark.
- `planEl` can be **detached** when the day view renders, so `planEl.parentNode`
  is null. Append the panel inside `planEl`.

### Known limits

- **Leg times are estimates.** Pinned pairs are real; everything else is
  straight-line distance with a fudge, which models Tokyo transit badly. Fixing
  one is a one-line `PLAN_LEGS` edit. The footer says so in the UI — keep that.
- `dollar-ranger-shinjuku` and `muji-shinjuku-dori` have **no coordinates**
  (`needs: ["coords"]`), so legs to them fall back to a blind 20 min.
- ~~The open/closed chips were not skip-aware~~ — fixed evening of 29 Jul;
  `stepOpenChip()` now uses `planResolveStop()`.

## Data corrections made today

Two entries in the itinerary were **confidently wrong**, both verified on the
ground. Same failure shape: precise address, precise access note, wrong reality.

1. **West Georgia St.** (恵比寿南2-3-15 OKA7ビル3F) — walked to it, no such
   shop. Now `status: skip`, hours zeroed. Replaced in the breakfast slot by
   **EBISU FOOD HALL** (恵比寿南1-1-9, from 9:00) — visited, verdict "would
   repeat, food good not remarkable, the draw is AC and a chill room".
2. **Dollar Ranger** (西新宿7-1-2 川安ビル1F) — the plan called it cheap
   packing/sundries. It is a **foreign-currency exchange**, confirmed in person,
   sharing the 1F with チケットレンジャー, a 金券 shop. Opens 10:00. Used 29 Jul:
   160.55 JPY/USD on a 161.8 mid-market, 0.77% spread, no commission.
3. **Yodobashi Akiba stocked NEITHER target item** — no Casio SXC-1, no
   Whitewings gliders (walked 29 Jul). The browse-today/buy-tomorrow structure
   was moot. Fallbacks: instrument shops (Ishibashi/Shimamura) for the Casio,
   紙飛行機協会 03-3639-5698 for the gliders. No Akiba leg on 30 Jul.
4. **Kinokuniya does not stock okozukai / ポチ袋** — walked 29 Jul. Solved the
   same day at the Daiso in the Yodobashi Akiba building; socks likewise done
   at the Uniqlo there. Shoes errand closed (current pair fine).
5. **Diptyque ×8 bottles are GIFTS for the Kyushu relatives** — so they must be
   in hand 31 Jul–23 Aug; buying on the Tokyo tail is wrong. Plan: call
   DIPTYQUE 福岡 (天神2-8-35, opened 27 Feb 2026, only Kyushu source — Iwataya
   does not carry the brand) to confirm 8 bottles; if not, buy at Isetan 30 Jul.

**Resolved later the same day:** the packing-materials "errand" was an artifact
of the wrong Dollar Ranger description and was deleted, not re-homed.

Also corrected: **SXC-1 is a Casio drum machine, not a watch** — the day card
said "×2 watches". No watches are being bought on this trip.

**If other stops came from whatever produced these two, they are worth spot
checking.** The validator catches wrong *hours*; it cannot catch a place that is
the wrong *kind of thing*.

## Logistics state

- **do-c Ebisu**: overnight bag storage across a multi-night booking is fine.
  What tightened is the **11:00–15:00 clean-out** — a bag parked outside a locker
  during the gap used to be tolerated, now reads as take-it-with-you. Observed,
  not confirmed with staff. Working answer: Ebisu Stn coin locker.
- **29 Jul evening**: the 50L sat in an Ebisu Stn coin locker through the
  clean-out and must be collected tonight (lockers bill by calendar day).
- **30 Jul (tomorrow)**: Yamanote loop on a rental bike, 09:30 pickup, ~17:15
  return. **The 50L rides the loop**, so the clean-out gap does not apply to it.
  **No Akiba leg** — the haul dissolved when Yodobashi had neither item. Evening
  is Shinjuku: Indenya wallet at Isetan (+ メンズ館), Kagaya tin before 19:00,
  and Diptyque only if the Fukuoka call fails.

## Suggested next steps

1. Call DIPTYQUE 福岡 to confirm 8 bottles (phone number still needed — not in
   the atlas yet); that call decides where the gift soap is bought.
2. Verification sweep of the Kyushu-leg places: five itinerary items failed on
   contact in one Tokyo day (West Georgia, Dollar Ranger, SXC-1, Whitewings,
   Kinokuniya ポチ袋). The Kyushu data comes from the same source and a phantom
   stop costs far more by car.
3. Add coordinates for the six entries with `coords` in `needs`.
4. Reconcile the private vault with the file edits made today.
5. Correct `PLAN_LEGS` from experience as legs are actually travelled.
6. The errands panel (ERR_SEED) is per-phone localStorage — seed edits do not
   reach an already-seeded phone, so the owner's list may still show stale
   items like "SXC-1 ×2 (Yodobashi)". A seed-version migration would fix it.
