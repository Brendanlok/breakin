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

01 → 02 are the leaderboard chain (02 needs 01). 03 → 04 are competitive (04 needs 03).
Competitive works score-only without 04; the arena view stays hidden until it's run.

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
