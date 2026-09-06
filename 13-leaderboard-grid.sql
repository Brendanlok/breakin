-- [13] Breakin — show the arena each leaderboard run built.
-- Run any time after 02-backend-v2.sql. Safe to run more than once.
--
-- WHY: the board is a list of numbers, but the arena a run leaves behind IS the character of
-- that run — a tidy sealed block and a scattered mess can score the same. The game already
-- packs the finished board as a ~90-char string (encGrid) and already draws it (drawMini, used
-- by the share card, the opponent view and your own run history). This column is the only
-- missing piece: somewhere to keep that string alongside the score so OTHER players' arenas
-- can be shown too.
--
-- Until this runs the board behaves exactly as it does today: the client asks for the column
-- once, and if the server refuses it, it drops the field from every read and write and stops
-- offering the arena view. Nothing breaks, nothing is lost, no score fails to save.

alter table public.breakin_scores add column if not exists grid text;

-- The column is written by anon inserts, so it needs a size ceiling like every other public
-- field. A real grid is "11:19:<19 ints>" — about 90 characters; 400 leaves generous headroom
-- for a bigger arena without leaving an open-ended text field on a public table.
do $$ begin
  alter table public.breakin_scores
    add constraint breakin_scores_grid_len check (grid is null or length(grid) <= 400);
exception when duplicate_object then null; end $$;

-- The existing insert policy on breakin_scores is column-agnostic, so it already covers this.
