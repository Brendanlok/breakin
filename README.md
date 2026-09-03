# Breakin

Atari's Breakout, inverted. The ball never breaks anything — every time it bounces
off a wall, a block, or the paddle, the grid cell it left turns **permanently**
solid. Nothing is ever cleared. The arena crusts over and closes in; survive as
long as you can.

**Play:** https://brendanlok.github.io/breakin/

## What's here

- `index.html` — the whole game. Vanilla JS + canvas, no dependencies, no build step.
  A bot plays a live demo behind the start menu; hit Play to take over.
- `manifest.json`, `icon-192.png`, `icon-512.png` — PWA / add-to-home-screen.

### Database migrations

Run once each in the Supabase SQL editor (Partfinder project), **in number order**.
All are idempotent — safe to re-run.

| # | File | Adds |
|---|------|------|
| 01 | `01-leaderboard.sql` | `breakin_scores` table + RLS |
| 02 | `02-backend-v2.sql` | score plausibility guard, feedback + crash-report inboxes, admin RPC. **Set your own passphrase in section 4 before running; never commit the real value.** |
| 03 | `03-rooms.sql` | `breakin_rooms` table — competitive mode |
| 04 | `04-rooms-grid.sql` | `host_grid` / `guest_grid` columns — the opponent-arena view |
| 05 | `05-rooms-lobby.sql` | pre-match speed agreement + post-match rematch vote |
| 06 | `06-score-guard.sql` | tighter score plausibility + per-name flood rule |
| 07 | `07-delete-bot-scores.sql` | one-off cleanup of the 2026-09-01 bot scores (already applied) |
| 08 | `08-reset-admin-passphrase.sql` | re-sets the admin passphrase. **Edit the marked line first.** |
| 09 | `09-speed-x5-guard.sql` | **MUST BE RUN.** Accepts x4.5 / x5 runs. Until it is, every run at those speeds is refused with `bad mult` and never reaches the board — silently. |
| 10 | `10-score-flood-limit.sql` | **MUST BE RUN.** Raises the flood limit from 5 to 30 scores per name per minute. Until it is, a player on a streak of short runs loses every score after the 5th — silently, and most likely at launch. |

01 → 02 are the leaderboard chain (02 needs 01). 03 → 04 → 05 are competitive (each needs 03).
Competitive works without 04/05 — the arena view and the lobby/rematch flow just fall back to the basics until they're run.

06 → 09 → 10 each replace the same `breakin_scores_guard()` function, so run them in order and
finish with 10 — whichever ran last is the one in force. **09 and 10 are required before launch.**
Both fail silently: the player sees their score and keeps a local copy while the server quietly
drops it, so a missing migration looks like nothing at all rather than like an error.
There is no read-only way to check which one is installed — if in doubt, re-run 10 (it is idempotent).

## Leaderboard

Top-10, shared, no sign-in. Enter a name at the end if you qualify. Backed by the
Supabase table `breakin_scores` (RLS: anyone reads / inserts one score, nobody
edits or deletes). A BEFORE-INSERT trigger rejects implausible scores. If the
backend is unreachable the game falls back to a per-device `localStorage` board.

## Admin

On the menu, **type `admin`** (or open `…/#admin`, or tap the "Breakout, in
reverse" badge 5×). A prompt asks for the passphrase; if it checks out
server-side the panel opens. The passphrase lives only in the `breakin_admin`
function — never in this repo.
Stats / view scores / view feedback / view crash reports / delete a row / reset.

## Deploy

GitHub Pages, "Deploy from a branch" → `main` → `/` (root). Every push to `main`
publishes.
