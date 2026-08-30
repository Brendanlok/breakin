-- Breakin — competitive mode: sync each player's arena so the opponent can watch it fill.
-- Adds two text columns to breakin_rooms holding a packed 11x19 bitfield of the board
-- (format "11:19:<row-int>.<row-int>...", ~90 chars). Pushed with the score on the
-- existing ~900ms tick. Run once in the Supabase SQL editor (Partfinder project,
-- ref ekcnpuwclkjnqnntlvot). Safe to run more than once.
--
-- Until this runs, competitive still works exactly as before — the client detects
-- the missing columns and just keeps the opponent-arena view hidden.

alter table public.breakin_rooms add column if not exists host_grid  text;
alter table public.breakin_rooms add column if not exists guest_grid text;

-- The existing "breakin_rooms open" policy is `for all`, so it already covers these columns.
