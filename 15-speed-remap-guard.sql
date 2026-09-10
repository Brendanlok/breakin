-- 15-speed-remap-guard.sql
--
-- MUST BE RUN. Until it is, roughly one in ten good runs played at ×1 is refused
-- by the server and never reaches the leaderboard. The player is told the save
-- failed and keeps a local copy, so it is not silent — but the score is lost.
--
-- Run it in the Supabase SQL editor, any time after 10-score-flood-limit.sql.
-- It replaces only breakin_scores_guard(). No table or data is touched, and it
-- is safe to run twice.
--
-- WHY (2026-09-10): the slider used to set the ball speed AND the score
-- multiplier to the same number, so "a faster ball bounces more often" could be
-- written as blocks <= secs * mult * 1.5. Lok's change today broke that link:
-- the slider still reads ×1..×5 and still multiplies the score by that number,
-- but every stop now delivers the speed that sat two steps higher on the old
-- scale (×1 plays like the old ×3). The ball at ×1 is now 65% faster than the
-- rule assumes, so it builds blocks far quicker than a "×1 run" is allowed to.
--
-- MEASURED, not guessed: ten runs at ×1 driven by a near-perfect bot paddle
-- produced 1.14 to 2.19 blocks/sec. The old rule allows 1.5/sec at ×1, so one
-- of those ten (92 blocks in 42s, against a ceiling of 78) is rejected today.
-- A human cannot out-build a perfect paddle, so this is the true upper bound.
--
-- THE FIX: score the rate against the speed actually played, which is the
-- slider number plus SPEED_SHIFT (2) — the same constant index.html uses. That
-- restores exactly the relationship 06 calibrated, rather than loosening a
-- number until the failures stop. Everything else is untouched: the 198-block
-- and 900-second ceilings, the score = blocks × mult rule, the ×1..×5 stop
-- list, the 990 score ceiling and the flood limit all stay as they are.
--
-- If the speed remap is ever reverted, revert this with it: put `new.mult` back
-- in place of `(new.mult + speed_shift)` below.

create or replace function public.breakin_scores_guard()
returns trigger language plpgsql as $$
declare recent int; max_mult numeric := 5;    -- keep in step with MAX_MULT in index.html
        speed_shift numeric := 2;             -- keep in step with SPEED_SHIFT in index.html
begin
  -- multiplier must be a real slider stop: 1 to max_mult, in halves
  if new.mult is null or new.mult < 1 or new.mult > max_mult
     or new.mult * 2 <> round(new.mult * 2) then
    raise exception 'bad mult';
  end if;
  -- score must equal blocks x mult (that IS the scoring rule)
  if new.score <> round(new.blocks * new.mult) then
    raise exception 'score/blocks/mult mismatch';
  end if;
  -- blocks come from bounces, and a faster ball bounces more often. The speed
  -- played is the slider number shifted up by speed_shift — NOT the multiplier.
  if new.blocks > ceil(new.secs * (new.mult + speed_shift) * 1.5) + 15 then
    raise exception 'block rate implausible';
  end if;
  -- ceilings the arena itself imposes: 198 spawnable cells, x max_mult
  if new.blocks > 198 or new.secs > 900 or new.score > 198 * max_mult
     or new.blocks < 0 or new.secs < 0 then
    raise exception 'out of range';
  end if;
  -- a script, not a person. Only runs that scored at all count toward this.
  if new.score > 0 then
    select count(*) into recent from public.breakin_scores
      where name = new.name and score > 0
        and created_at > now() - interval '60 seconds';
    if recent >= 30 then
      raise exception 'too many scores too fast';
    end if;
  end if;
  new.ua := left(coalesce(new.ua,''), 300);
  return new;
end $$;

drop trigger if exists breakin_scores_guard on public.breakin_scores;
create trigger breakin_scores_guard before insert on public.breakin_scores
  for each row execute function public.breakin_scores_guard();

-- Sanity check: every score already on the board must still be legal.
-- This should return NO rows.
select id, name, score, blocks, secs, mult
from public.breakin_scores
where blocks > ceil(secs * (mult + 2) * 1.5) + 15
   or score <> round(blocks * mult)
   or blocks > 198 or secs > 900 or score > 990;
