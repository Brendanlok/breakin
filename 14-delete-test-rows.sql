-- 14-delete-test-rows.sql
-- RUN THIS BEFORE LAUNCH. Takes a second, and it is the difference between the first real
-- player landing on an honest empty board and landing on a board where the two names above
-- them are robots.
--
-- WHY: the live leaderboard holds exactly two rows and both are mine, not players'.
-- OFFLIN 285 and LOCTST 108 were both written on 2026-09-05 while testing that a score
-- actually reaches the server (OFFLIN came from the offline/retry path, LOCTST from the
-- local save path). They are the ONLY rows on the board, so at launch every real run would
-- be ranked against two test entries — and "2 players so far" under the board would be
-- counting me twice.
--
-- Claude could not delete these itself: the admin RPC call is blocked by the permission
-- classifier on this machine, so it has to be you. Either run this file, or open the admin
-- panel (#admin) and delete the two rows by hand — same result.
--
-- Safe to run more than once. Narrow on purpose: it matches the two exact row ids, so it
-- cannot take a real score even if a player happens to pick one of those names.

-- Look first — this should return exactly the two rows described above and nothing else.
select id, name, score, mult, secs, created_at
from public.breakin_scores
where id in ('2fa52329-5eca-451c-8f55-5f5b2703a950',    -- OFFLIN 285, ball x5, 31s
             '924f66dd-a72f-4c1b-9169-1af387664184');   -- LOCTST 108, ball x3, 23s

delete from public.breakin_scores
where id in ('2fa52329-5eca-451c-8f55-5f5b2703a950',
             '924f66dd-a72f-4c1b-9169-1af387664184');

-- Should come back 0. From here, every row on the board is a real player.
select count(*) as rows_left from public.breakin_scores;
