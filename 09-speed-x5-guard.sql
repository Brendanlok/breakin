-- 09-speed-x5-guard.sql
-- The ball-speed slider now goes up to x5 (was x4). Run this so the leaderboard
-- accepts scores played at the new speeds.
--
-- MUST BE RUN. Until it is, every run played at x4.5 or x5 is refused by the
-- server with 'bad mult' and never reaches the board. The player still sees
-- their score and keeps a local copy, so it fails quietly rather than visibly -
-- which is exactly why this is worth running now rather than later.
--
-- Run it in the Supabase SQL editor, any time after 06-score-guard.sql.
-- It replaces only breakin_scores_guard(). No table or data is touched.
--
-- What changes, vs 06:
--   mult    hard list (1 .. 4)          ->  any 0.5 step from 1 to 5
--           Expressed as a range now, so the next slider change does not need
--           a new migration - only a change to the top stop below.
--   score   <= 800  (198 blocks x 4)    ->  <= 990  (198 blocks x 5)
--           The old ceiling would have refused a legitimate high x5 run.
-- Everything else is unchanged. The block-rate rule already scales with mult,
-- the 198-block and 900-second ceilings are properties of the arena, and the
-- 5-scores-per-name-per-minute flood rule is untouched.

create or replace function public.breakin_scores_guard()
returns trigger language plpgsql as $$
declare recent int; max_mult numeric := 5;   -- keep in step with MAX_MULT in index.html
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
  -- blocks come from bounces, and a faster ball bounces more often
  if new.blocks > ceil(new.secs * new.mult * 1.5) + 15 then
    raise exception 'block rate implausible';
  end if;
  -- ceilings the arena itself imposes: 198 spawnable cells, x max_mult
  if new.blocks > 198 or new.secs > 900 or new.score > 198 * max_mult
     or new.blocks < 0 or new.secs < 0 then
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

drop trigger if exists breakin_scores_guard on public.breakin_scores;
create trigger breakin_scores_guard before insert on public.breakin_scores
  for each row execute function public.breakin_scores_guard();

-- Sanity check: every score already on the board must still be legal under the
-- new rules. This should return NO rows.
select name, score, blocks, secs, mult, created_at from public.breakin_scores
where mult is null or mult < 1 or mult > 5 or mult * 2 <> round(mult * 2)
   or score <> round(blocks * mult)
   or blocks > ceil(secs * mult * 1.5) + 15
   or blocks > 198 or secs > 900 or score > 990;
