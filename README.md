# Japan 2026 — family itinerary page

A single-file shareable itinerary for Robert's Japan 2026 trip, styled after
classic Mac OS System 7 ("Platinum"), with a calendar + agenda view, a family
message board, and per-day notes.

- **Live page:** https://robjohncolson.github.io/japan-2026/
- **Source of truth for the itinerary:** the private `japan` vault (`japan2026.tex`).
  The page's baseline `DAYS` data mirrors it; mid-trip changes are made through
  the owner edit mode below, not by editing this file.

## Backend (Supabase project `hgvnytaqmuybzbotosyj`)

| Table / RPC | Purpose | Access |
|---|---|---|
| `japan_notes` | per-day family notes | anon SELECT + INSERT; owner delete via `delete_japan_note` RPC |
| `japan_board` | general message board | anon SELECT + INSERT; owner delete via `delete_japan_board_msg` RPC |
| `japan_day_edits` | owner overrides merged over the baseline `DAYS` | anon SELECT; writes only via secret-gated `upsert_japan_day` / `delete_japan_day_edit` RPCs |

Setup SQL lives in the private vault: `japan/share/supabase-japan-notes.sql`
(v1, notes) and `japan/share/supabase-japan-v2.sql` (day edits, board,
`device_id` column). Both are idempotent. The owner secret lives only in the
SQL (server-side) and the owner's browser localStorage — never in this repo.

## Owner mode

The footer 🔒 button prompts for the owner secret. With it set, the page shows
delete buttons on notes/board messages and an "✏️ Edit this day" form in each
day's sheet — edits land in `japan_day_edits` and reach every reader on the
next 45s poll. "Revert to original" removes the override.

## Notes

- The page polls Supabase every 45s (backoff on failure, pause when hidden).
- Senders get a deterministic color from a djb2 hash of a per-browser
  `device_id` (localStorage), so the same relative looks the same everywhere.
- `robots.txt` + a `noindex` meta tag keep the page out of search engines.
  Booking confirmation codes and door PINs were **stripped from the page on
  2026-07-02** (they live only in the private vault + the owner's email);
  the URL is still treated as the access control, so don't post it publicly.
- **Privacy line (2026-07-02):** where-I'm-staying / what-night is public;
  booking codes/PINs, gift plans and anything surprise-sensitive live only in
  the private vault and must never appear on this page — the recipients read it.
