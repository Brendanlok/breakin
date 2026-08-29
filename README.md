# Breakin

Atari's Breakout, inverted. The ball never breaks anything — every time it bounces
off a wall, a block, or the paddle, the grid cell it left turns **permanently**
solid. Nothing is ever cleared. The arena crusts over and closes in; survive as
long as you can.

**Play:** https://brendanlok.github.io/breakin/

## What's here

- `index.html` — the whole game. Vanilla JS + canvas, no dependencies, no build step.
- `leaderboard.sql` — one-time Supabase setup for the shared leaderboard.

## Leaderboard

Top-10, shared across everyone, no sign-in. Enter a name at the end if your score
qualifies. Backed by a single Supabase table (`breakin_scores`) with row-level
security: anyone may read the board and insert one score, nobody can edit or delete.
If the backend is unreachable the game falls back to a per-device board kept in
`localStorage`.

To wire it up: run `leaderboard.sql` in the Supabase SQL editor, then set `LB_URL`
and `LB_KEY` near the top of the `<script>` in `index.html`.

## Deploy

GitHub Pages, "Deploy from a branch" → `main` → `/` (root). Every push to `main`
publishes.
