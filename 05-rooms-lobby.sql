-- [05/05] Breakin — competitive lobby: pre-match speed agreement + post-match rematch vote.
-- Run after 03-rooms.sql (adds columns to breakin_rooms). Safe to run more than once.
--
-- guest_ready  : guest has seen the host's ball speed and confirmed. Host's "Start" waits on it.
-- host_choice / guest_choice : post-match vote — null | 'again' | 'settings' | 'end'.
-- rematch_at   : deadline for the post-match vote (~30s); match ends if it lapses.
--
-- Until this runs the client falls back to the old flow (host starts whenever;
-- host-only rematch button) — it checks for guest_ready before touching any of these.

alter table public.breakin_rooms add column if not exists guest_ready  boolean not null default false;
alter table public.breakin_rooms add column if not exists host_choice  text;
alter table public.breakin_rooms add column if not exists guest_choice text;
alter table public.breakin_rooms add column if not exists rematch_at   timestamptz;
