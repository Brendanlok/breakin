-- ============================================================================
--  Breakin DB migrations — run once each, in filename order, in the Supabase
--  SQL editor (Partfinder project, ref ekcnpuwclkjnqnntlvot):
--    01-leaderboard.sql   →  breakin_scores table (this file)
--    02-backend-v2.sql    →  score guard + feedback/crash inboxes + admin RPC
--    03-rooms.sql         →  breakin_rooms table (competitive mode)
--    04-rooms-grid.sql    →  opponent-arena sync columns on breakin_rooms
--    05-rooms-lobby.sql   →  pre-match speed agreement + post-match rematch vote
--  All are idempotent (IF NOT EXISTS / OR REPLACE) — safe to re-run.
-- ============================================================================
-- [01/04] Breakin shared leaderboard.
-- Public (anon) can READ the board and INSERT one score. No update, no delete.
-- Protection is row-level security + CHECK constraints, so the anon key is safe to ship.

create table if not exists public.breakin_scores (
  id          uuid primary key default gen_random_uuid(),
  name        text        not null,
  score       integer     not null,
  secs        integer     not null default 0,
  blocks      integer     not null default 0,
  created_at  timestamptz not null default now(),
  constraint breakin_name_len    check (char_length(btrim(name)) between 1 and 14),
  constraint breakin_score_range check (score  between 0 and 100000),
  constraint breakin_secs_range  check (secs   between 0 and 100000),
  constraint breakin_block_range check (blocks between 0 and 100000)
);

create index if not exists breakin_scores_rank_idx
  on public.breakin_scores (score desc, created_at asc);

alter table public.breakin_scores enable row level security;

drop policy if exists breakin_read   on public.breakin_scores;
drop policy if exists breakin_insert on public.breakin_scores;

create policy breakin_read on public.breakin_scores
  for select to anon, authenticated
  using (true);

create policy breakin_insert on public.breakin_scores
  for insert to anon, authenticated
  with check (
    char_length(btrim(name)) between 1 and 14
    and score between 0 and 100000
  );
