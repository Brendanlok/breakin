-- 11-clear-dev-noise.sql
-- Optional, run any time before or after launch. Nothing depends on it.
--
-- WHY: the crash + feedback inboxes still hold ~17 rows that Claude generated while
-- building and testing the game. On launch day the admin panel is the place you look
-- to see what real players hit, and a real report is easy to miss among test rows.
-- This deletes ONLY the known test rows, matched exactly, so a genuine report from a
-- player can never be caught by it. Verified on 2026-09-03: every row this removes is
-- dev noise, and the crash reporter itself was confirmed working the same day.
--
-- Run the two SELECTs first if you want to see what goes.

-- 1. Crash reports. Three sources of noise, all Claude's own:
--    a) anything logged from a data: URL   - a local test build, never the live site
--    b) the prompt() rejections            - fixed on 29.08, cannot recur
--    c) the deliberately injected crashes  - used to test the loop watchdog
--    d) the reporter self-test from 03.09  - used to prove the inbox still receives
select created_at, msg, url from public.breakin_errors
where url like 'data:%'
   or msg = 'unhandledrejection: prompt() is not supported.'
   or msg like 'loop crash: injected%'
   or msg like '%__reporter-selftest__%';

delete from public.breakin_errors
where url like 'data:%'
   or msg = 'unhandledrejection: prompt() is not supported.'
   or msg like 'loop crash: injected%'
   or msg like '%__reporter-selftest__%';

-- 2. Feedback. Only the two automated send-path checks, matched on their marker.
select created_at, name, message from public.breakin_feedback
where message like '%__selftest__%' or name = '__selftest__';

delete from public.breakin_feedback
where message like '%__selftest__%' or name = '__selftest__';

-- Anything left in either table after this is from a real player. Read it.
