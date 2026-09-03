-- 11-clear-dev-noise.sql
-- Optional, run any time. Nothing in the game depends on it.
--
-- WHY: on launch day the admin panel is where you look to see what real players hit.
-- Right now both inboxes hold only rows Claude generated while building and testing,
-- and a genuine report would be easy to miss among them. Audited row by row on
-- 2026-09-03: there is not one real player report in either table yet.
--
-- Every DELETE below is paired with a SELECT that shows exactly what it takes. Run the
-- SELECTs first if you want to look before it goes. Each clause is narrow on purpose -
-- a real report cannot be caught by any of them.

-- ---------------------------------------------------------------- crash reports
-- Five classes of noise, all Claude's own, all diagnosed:
--   a) url like 'data:%'         a local test build, never the live site
--   b) prompt() rejections       fixed 29.08, cannot recur (no native dialogs remain)
--   c) 'loop crash: injected%'   crashes deliberately thrown to test the loop watchdog
--   d) '?v=session%'             Claude's own cache-buster URLs, never a player's link
--   e) reporter self-test 03.09  thrown on purpose to prove the inbox still receives
-- Plus one genuine-looking crash that is already fixed:
--   f) "null (reading 'role')" from a ?join= link, 30.08. Cause: a competitive match
--      that ended mid-poll left vs null while the poll still dereferenced it. Fixed
--      01.09 in commit 60f8865, which added the null guards in vsTick/applyRoom.
--      Bounded to before that fix, so a recurrence after it would survive this delete.

select created_at, msg, url from public.breakin_errors
where url like 'data:%'
   or url like '%?v=session%'
   or msg = 'unhandledrejection: prompt() is not supported.'
   or msg like 'loop crash: injected%'
   or msg like '%__reporter-selftest__%'
   or (msg like '%null (reading ''role'')%' and created_at < '2026-09-01');

delete from public.breakin_errors
where url like 'data:%'
   or url like '%?v=session%'
   or msg = 'unhandledrejection: prompt() is not supported.'
   or msg like 'loop crash: injected%'
   or msg like '%__reporter-selftest__%'
   or (msg like '%null (reading ''role'')%' and created_at < '2026-09-01');

-- ---------------------------------------------------------------- feedback
-- Only the two automated checks that the send path reaches the inbox, by their marker.
select created_at, name, message from public.breakin_feedback
where message like '%__selftest__%' or name = '__selftest__';

delete from public.breakin_feedback
where message like '%__selftest__%' or name = '__selftest__';

-- Both tables should now be empty. Anything that appears from here is a real player.
