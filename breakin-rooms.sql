-- Breakin — competitive match rooms.
-- Model: two players each play their own board, scores sync live, highest total wins.
-- Transport is plain REST + ~1.3s client polling (no realtime/websocket), so this one
-- table is all the backend competitive mode needs. Run this once in the Supabase SQL editor
-- (Partfinder project, ref ekcnpuwclkjnqnntlvot). Until it exists the client fails soft:
-- the invite code + QR still work as a share, live play just says it's not switched on yet.

create table if not exists public.breakin_rooms (
  code         text primary key,                       -- 6-char share code (unguessable: 30^6 ≈ 730M)
  created_at   timestamptz not null default now(),
  phase        text        not null default 'lobby',   -- lobby | countdown | live
  mult         numeric      not null default 2,         -- score multiplier, host's slider, locked for the match
  start_at     timestamptz,                             -- host stamps the shared countdown target here

  host_name    text        not null default 'Host',
  host_score   integer     not null default 0,
  host_done    boolean     not null default false,
  host_seen    timestamptz not null default now(),      -- last heartbeat; stale > ~12s ⇒ treated as dropped

  guest_name   text,                                    -- null until someone joins
  guest_score  integer     not null default 0,
  guest_done   boolean     not null default false,
  guest_seen   timestamptz
);

alter table public.breakin_rooms enable row level security;

-- Casual friend matches, unguessable codes, nothing sensitive: let the anon key do everything.
-- (Scores here never touch the public leaderboard, so there's nothing to cheat that matters.)
drop policy if exists "breakin_rooms open" on public.breakin_rooms;
create policy "breakin_rooms open" on public.breakin_rooms
  for all to anon using (true) with check (true);

-- Optional housekeeping: rooms are tiny (~200 bytes) so this is not urgent, but if pg_cron
-- is enabled you can keep the table swept:
--   select cron.schedule('breakin-rooms-sweep', '17 * * * *',
--     $$delete from public.breakin_rooms where created_at < now() - interval '3 hours'$$);
