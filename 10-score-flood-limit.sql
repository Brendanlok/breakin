-- 10-score-flood-limit.sql
-- Raise the per-name flood limit so real players stop losing scores.
--
-- MUST BE RUN BEFORE LAUNCH. Run it in the Supabase SQL editor, any time after
-- 09-speed-x5-guard.sql. It replaces only breakin_scores_guard() - no table,
-- no data, no admin passphrase touched.
--
-- WHY: the rule from 06 refused a 6th score from one name inside 60 seconds.
-- That was written against a scripted burst of 16 runs in 25s. But the MEDIAN
-- REAL RUN IS ABOUT 5 SECONDS - one life, one miss, over. A player on a streak
-- of short runs crosses 5 in a minute without trying, and every score after
-- that was silently refused. It gets more likely the more people play, i.e.
-- exactly at launch.
--
-- What changes, vs 09:
--   flood   5 rows per name / 60s   ->  30 rows per name / 60s
--           30 is still far below a script (16 in 25s = ~38/min) but well
--           above any human on a hot streak of 5-second runs.
--   Only scores that could actually reach the board count toward the limit:
--           a 0-block run cannot displace anyone, so it no longer burns a slot.
-- Everything else is unchanged from 09.

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

-- Sanity check: nothing already on the board becomes illegal. Should return NO rows.
select name, score, blocks, secs, mult, created_at from public.breakin_scores
where mult is null or mult < 1 or mult > 5 or mult * 2 <> round(mult * 2)
   or score <> round(blocks * mult)
   or blocks > ceil(secs * mult * 1.5) + 15
   or blocks > 198 or secs > 900 or score > 990;
