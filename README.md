# Japan 2026 — family itinerary page

A single-file shareable itinerary for Robert's Japan 2026 trip, with an
editable calendar where family can leave notes on individual days.

- **Live page:** https://robjohncolson.github.io/japan-2026/
- **Source of truth for the itinerary:** the private `japan` vault (`japan2026.tex`).
- **Notes backend:** Supabase project `hgvnytaqmuybzbotosyj`, table `japan_notes`
  (anon SELECT + INSERT; owner-only delete via the `delete_japan_note` RPC).
  Setup SQL lives in the private vault at `japan/share/supabase-japan-notes.sql`.

`robots.txt` + a `noindex` meta tag keep the page out of search engines.
The page contains booking codes/PINs by design (owner's choice) — the URL is
the access control, so don't post it publicly.
