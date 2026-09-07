-- ============================================================================
--  BREAKIN — everything the database still needs before launch, in one paste.
--  Written 2026-09-07 (Claude). Launch is Tuesday 8 September.
--
--  Four .sql files in this folder are still pending (11, 12, 13, 14) and there
--  is one evening left. Three of them are safe exactly as written, so they are
--  copied into this one file. The fourth (12, the passphrase) needs you to type
--  a new value first, so it is deliberately NOT in here.
--
--  STEP 1  Do 12-rotate-admin-passphrase.sql on its own, first. See below.
--  STEP 2  Paste this whole file into the Supabase SQL editor and Run.
--  STEP 3  Tell Claude step 2 is done (one flag, one push — see the end).
--
--  All of step 2 is safe to run twice. Every DELETE matches either an exact row
--  id or a marker string Claude wrote — none of them can reach a real player's
--  row. Project: ekcnpuwclkjnqnntlvot (the Partfinder project).
-- ============================================================================


-- ============================================================================
--  STEP 1 — NOT IN THIS FILE. Do this one first, by hand.
-- ============================================================================
--  The admin passphrase that is live right now was committed in plain text to
--  the PUBLIC repo on 2026-09-01 and is still readable in the git history.
--  Anyone reading the repo can open the admin panel, read every crash report
--  and feedback message, and delete scores. Treat the current value as burned.
--
--  Open 12-rotate-admin-passphrase.sql, change the one marked line to a NEW
--  passphrase, run it, then put that same value into
--  C:\Users\starw\.claude\secrets\breakin.env so the automated sessions keep
--  working. Do not paste the new passphrase into any file in this repo.
-- ============================================================================


-- ============================================================================
--  STEP 2a — take the three robot rows off the live leaderboard      (was 14)
-- ============================================================================
--  The board holds exactly three rows and all three are Claude's, from testing
--  the save path: OFFLIN 285 (offline/retry path) and LOCTST 108 (local save
--  path) on 2026-09-05, plus ZZTST3 80 on 2026-09-07. Without this the first
--  real player is ranked behind three robots and the "N players so far" line
--  counts Claude three times. Matches three exact ids, nothing else.
--
--  ZZTST3 was an accident, 2026-09-07 4pm: a session was testing that a score
--  the SERVER REJECTS still warns the player instead of failing silently. It
--  does — that check passed. But a rejected save is also queued for retry, and
--  when the test released its stubbed network the queue drained to the real
--  board. Harmless, and it goes away with the other two here.

select id, name, score, mult, secs, created_at
from public.breakin_scores
where id in ('2fa52329-5eca-451c-8f55-5f5b2703a950',
             '924f66dd-a72f-4c1b-9169-1af387664184',
             '562f1f7f-f416-4406-ba29-263c60c51b99');

delete from public.breakin_scores
where id in ('2fa52329-5eca-451c-8f55-5f5b2703a950',
             '924f66dd-a72f-4c1b-9169-1af387664184',
             '562f1f7f-f416-4406-ba29-263c60c51b99');

select count(*) as scores_left from public.breakin_scores;   -- expect 0


-- ============================================================================
--  STEP 2b — empty the crash + feedback inboxes of test traffic      (was 11)
-- ============================================================================
--  Re-audited row by row on 2026-09-07 against the live admin RPC: 17 crash
--  reports, 3 feedback messages, every single one Claude's own, nothing new
--  since 03.09. This matters because the admin panel is where you look on
--  launch day — the first genuine crash would arrive as row 18 in a list of
--  noise that looks just like it.
--
--  Classes of crash noise, all diagnosed:
--    a) url like 'data:%'       a local test build, never the live site
--    b) prompt() rejections     fixed 29.08, cannot recur (no native dialogs)
--    c) 'loop crash: injected%' thrown on purpose to test the loop watchdog
--    d) '?v=session%'/'?v=launch%'  Claude's cache-busters, never a player URL
--    e) __selftest__ markers    thrown to prove the inbox still receives
--  Plus one genuine-looking crash that is already fixed:
--    f) "null (reading 'role')" from a ?join= link, 30.08 — a competitive match
--       that ended mid-poll left vs null while the poll still read it. Fixed
--       01.09 (commit 60f8865). Bounded to before that fix on purpose, so a
--       recurrence after it survives this delete and still reaches you.

select created_at, msg, url from public.breakin_errors
where url like 'data:%'
   or url like '%?v=session%'
   or url like '%?v=launch%'
   or msg = 'unhandledrejection: prompt() is not supported.'
   or msg like 'loop crash: injected%'
   or msg like '%__reporter-selftest__%'
   or msg like '%__selftest__%'
   or (msg like '%null (reading ''role'')%' and created_at < '2026-09-01');

delete from public.breakin_errors
where url like 'data:%'
   or url like '%?v=session%'
   or url like '%?v=launch%'
   or msg = 'unhandledrejection: prompt() is not supported.'
   or msg like 'loop crash: injected%'
   or msg like '%__reporter-selftest__%'
   or msg like '%__selftest__%'
   or (msg like '%null (reading ''role'')%' and created_at < '2026-09-01');

select created_at, name, message from public.breakin_feedback
where message like '%__selftest__%' or name = '__selftest__';

delete from public.breakin_feedback
where message like '%__selftest__%' or name = '__selftest__';

select (select count(*) from public.breakin_errors)   as crashes_left,   -- expect 0
       (select count(*) from public.breakin_feedback) as feedback_left;  -- expect 0


-- ============================================================================
--  STEP 2c — room for the arena picture on each leaderboard row      (was 13)
-- ============================================================================
--  The game already packs a finished arena into a ~90-character string and
--  already draws it (share card, opponent view, your own run history). This
--  column is the only missing piece: somewhere to keep that string next to the
--  score so OTHER players' arenas can be shown when a row is tapped.
--
--  Nothing breaks if this never runs — the client asks once and drops the field
--  if the server refuses it — but the feature stays invisible.

alter table public.breakin_scores add column if not exists grid text;

-- Written by anonymous inserts, so it needs a size ceiling like every other
-- public field. A real grid is "11:19:<19 ints>", about 90 characters; 400
-- leaves headroom for a bigger arena without an open-ended public text column.
do $$ begin
  alter table public.breakin_scores
    add constraint breakin_scores_grid_len check (grid is null or length(grid) <= 400);
exception when duplicate_object then null; end $$;

-- The existing insert policy is column-agnostic, so it already covers this.


-- ============================================================================
--  STEP 2d - sweep the abandoned competitive rooms                    (new)
-- ============================================================================
--  breakin_rooms has no expiry. A room row is deleted only when the host
--  cancels or leaves cleanly; a host who just closes the tab leaves the row
--  behind for good. Six such rows from Claude's own 01-03.09 testing are
--  sitting in the live table right now.
--
--  Nothing player-facing breaks either way - the codes are random and a stale
--  row is never shown to anyone - so this is housekeeping, not a fix. It is
--  safe to re-run any time: a live match is minutes old, never hours.

delete from public.breakin_rooms
 where created_at < now() - interval '6 hours';


-- ============================================================================
--  STEP 2e - keep it swept, so 2d never has to be run again      (OPTIONAL)
-- ============================================================================
--  2d clears the table once. Rooms will start piling up again from the first
--  competitive match, because nothing expires them. This is the fix, and it is
--  the ONE line from 03-rooms.sql that was left commented out.
--
--  It is left commented here too, on purpose: if pg_cron is not enabled on the
--  project the statement errors, and an error part-way through a paste aborts
--  everything after it. So run it on its own, AFTER the rest of this file, and
--  simply ignore it if it complains - nothing depends on it.
--
--  Why not do this from the game instead: the client would have to compute the
--  cutoff from the device clock, and a phone whose clock is a day fast would
--  then delete every LIVE room in the table for everyone. Server-side or not
--  at all.
--
--    select cron.schedule('breakin-rooms-sweep', '17 * * * *',
--      $$delete from public.breakin_rooms where created_at < now() - interval '6 hours'$$);
--
--  To check it later:   select * from cron.job;
--  To remove it:        select cron.unschedule('breakin-rooms-sweep');


-- ============================================================================
--  STEP 3 — why nothing looks different straight away
-- ============================================================================
--  index.html has `let lbGrid=false;` in the leaderboard section. It is false
--  so that a database without the column above never logs a 400 in a player's
--  console. Claude probes the live column at the start of every session and
--  flips the flag in a commit once the column is really there — so after step
--  2c the arena view turns up on the next session, not instantly.
-- ============================================================================
