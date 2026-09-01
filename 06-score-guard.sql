-- [06] Tighten the leaderboard score guard.  Run this on its own, any time
-- after 02-backend-v2.sql.  It only replaces breakin_scores_guard() — it does
-- NOT touch the admin RPC, so you do not have to re-enter the passphrase.
--
-- WHY: on 2026-09-01 sixteen automated runs were posted to the live board in
-- 25 seconds, topping out at 309, and the old guard accepted every one.
--
-- Two separate problems, and only one of them is "cheating":
--
--   1. A 309 is a REAL, reachable score.  A perfect paddle plays by the rules;
--      it just survives longer than a person does.  No server-side rule can
--      reject it without also rejecting the human who eventually gets there.
--      So the plausibility checks below are tightened to what the arena can
--      physically hold, and no further.  This is a sanity filter against
--      hand-crafted POSTs, not an anti-bot system, and it should not pretend
--      to be one.
--
--   2. Sixteen rows in 25 seconds is not a plausible human session, whatever
--      the scores are.  THAT is the part worth blocking, and it is what the
--      new flood check does.
--
-- BEFORE / AFTER
--   rate      blocks <= secs*3.5 + 12 (flat)   ->  blocks <= secs*mult*1.5 + 15
--             The old rule ignored ball speed: 3.5 blocks/s is ~4x too generous
--             at the slowest setting and slightly too tight at the fastest.
--   blocks    <= 230                           ->  <= 198
--             198 is every spawnable cell (11 cols x 18 rows); at 198 the game
--             ends with "Arena sealed", so 230 was unreachable by definition.
--   secs      <= 3600                          ->  <= 900
--             A rally that places nothing for 10s now ends the run, so an hour
--             was never possible.
--   score     <= 25000                         ->  <= 800
--             score = blocks x mult is already enforced, so the real ceiling is
--             198 x 4 = 792.  25000 could never fire.
--   flood     (none)                           ->  max 5 rows per name / 60s

create or replace function public.breakin_scores_guard()
returns trigger language plpgsql as $$
declare recent int;
begin
  -- multiplier must be one of the slider stops
  if new.mult is null or new.mult not in (1,1.5,2,2.5,3,3.5,4) then
    raise exception 'bad mult';
  end if;
  -- score must equal blocks x mult (that IS the scoring rule)
  if new.score <> round(new.blocks * new.mult) then
    raise exception 'score/blocks/mult mismatch';
  end if;
  -- blocks come from bounces, and a faster ball bounces more often
  if new.blocks > ceil(new.secs * new.mult * 1.5) + 15 then
    raise exception 'block rate implausible';
  end if;
  -- ceilings the arena itself imposes
  if new.blocks > 198 or new.secs > 900 or new.score > 800 or new.blocks < 0 or new.secs < 0 then
    raise exception 'out of range';
  end if;
  -- nobody plays six qualifying runs in a minute; that is a script
  select count(*) into recent from public.breakin_scores
    where name = new.name and created_at > now() - interval '60 seconds';
  if recent >= 5 then
    raise exception 'too many scores too fast';
  end if;
  new.ua := left(coalesce(new.ua,''), 300);
  return new;
end $$;

-- trigger already exists from 02; recreate it only if this file is run standalone
drop trigger if exists breakin_scores_guard on public.breakin_scores;
create trigger breakin_scores_guard before insert on public.breakin_scores
  for each row execute function public.breakin_scores_guard();

-- Checked against all 33 rows currently on the live board:
--   * the plausibility rules flag NOTHING, including the 309 - which is the
--     point above, that run was legitimate play.
--   * the flood rule flags 11 of the 16 rows from the 2026-09-01 burst (the
--     first 5 are inside the allowance, by design).
-- Re-run this before the create above if the board has grown, and loosen the
-- 1.5 if it ever flags a real run:
--   select name, score, blocks, secs, mult, created_at from breakin_scores
--   where blocks > ceil(secs * mult * 1.5) + 15
--      or blocks > 198 or secs > 900 or score > 800
--   order by created_at desc;
