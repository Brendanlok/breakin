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
| 09 | `09-speed-x5-guard.sql` | Accepts x4.5 / x5 runs. **Confirmed live 2026-09-04** — an x5 score was accepted by the real server. |
| 10 | `10-score-flood-limit.sql` | Raises the flood limit from 5 to 30 scores per name per minute. **Confirmed live 2026-09-04** — ten scores from one name inside a minute were all accepted. |
| 11 | `11-clear-dev-noise.sql` | one-off purge of the Aug 29-30 test crash reports. Optional — the inbox still holds 17 of them and every one is dev noise. |
| 12 | `12-rotate-admin-passphrase.sql` | **NOT RUN — open launch blocker.** The live passphrase is still the one written in plain text into public commit `60f88657`, re-verified 2026-09-04: anyone reading the repo can open the admin panel and wipe the leaderboard. Edit the marked line to a NEW value, run it, then put the same value in `secrets/breakin.env`. Also switches on the inbox delete buttons. |
| 13 | `13-leaderboard-grid.sql` | **NOT RUN.** `grid` column on `breakin_scores` — until it exists, tapping another player's row never shows the arena that run built. The client checks nothing and degrades silently, so nothing breaks either way; the feature is simply absent. After running it, flip `let lbGrid=false` to `true` near the leaderboard section of `index.html` and push. |
| 14 | `14-delete-test-rows.sql` | **NOT RUN — run before launch.** Removes the two test rows (OFFLIN 285, LOCTST 108) that are currently the whole leaderboard. Without it the first real player is ranked against two robots. |

### Still to run before Tuesday
12, 13 and 14 have never been applied — 11 is optional but the crash inbox is still all dev noise
without it. Re-verified against the live database on 2026-09-06.

01 → 02 are the leaderboard chain (02 needs 01). 03 → 04 → 05 are competitive (each needs 03).
Competitive works without 04/05 — the arena view and the lobby/rematch flow just fall back to the basics until they're run.

06 → 09 → 10 each replace the same `breakin_scores_guard()` function, so run them in order and
finish with 10 — whichever ran last is the one in force. 10 is the one in force now.
A missing guard migration fails silently: the player sees their score and keeps a local copy while
the server quietly drops it, so it looks like nothing at all rather than like an error — so it is
worth checking which one is installed. Do it **without writing anything to the board**.

The guard runs its checks in a fixed order (mult → score/blocks/mult → block rate → range → flood),
so a row that is deliberately illegal in a *later* check tells you whether it got past an *earlier*
one. Post a row with a real x5 multiplier and a deliberately wrong score: it can never insert, and
the message names the version.

```
curl -s -X POST "https://ekcnpuwclkjnqnntlvot.supabase.co/rest/v1/breakin_scores"   -H "apikey: sb_publishable_pfng2gwF0IdAZfwbwhWPWQ_bfHOMIAC" -H "Content-Type: application/json"   -d '{"name":"ZZPROB","score":999,"blocks":1,"secs":10,"mult":5,"ua":"guard-probe"}'
```

* `bad mult` → **06 is in force**: every x4.5 / x5 run is being silently refused. Run 09, then 10.
* `score/blocks/mult mismatch` → 09 or 10 is in force, x5 is accepted. This is the healthy answer.

Nothing is inserted either way, so it is safe to run against the live board on launch morning.
Verified 2026-09-07: all three probes rejected, board unchanged.

The 09-vs-10 difference is the flood limit (5 vs 30 scores per name per minute) and there is no
read-only way to tell those apart — reaching that check means writing a real row. Do not test it:
just re-run `10-score-flood-limit.sql`. It is `create or replace`, so it is idempotent and free.

**Do not verify the guard by posting real scores.** The old note here said to post eleven of them
and delete them afterwards from the admin panel. That is how test rows end up stuck on the public
board — OFFLIN and LOCTST are still there because nothing could remove them.

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
