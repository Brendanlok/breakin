-- Breakin backend v2 — run once in the Supabase SQL editor (Partfinder project).
-- Adds: score plausibility guard, a feedback inbox, a crash-report inbox,
-- and extends the admin RPC to read them.
--
-- >>> BEFORE RUNNING: in section 4 below, replace 'adminadmin' with the SAME
--     passphrase you set in admin.sql, otherwise you'll reset it. <<<

-- ---------- 1. score columns + plausibility ----------
alter table public.breakin_scores add column if not exists mult numeric;
alter table public.breakin_scores add column if not exists ua   text;

create or replace function public.breakin_scores_guard()
returns trigger language plpgsql as $$
begin
  -- multiplier must be one of the slider stops
  if new.mult is null or new.mult not in (1,1.5,2,2.5,3,3.5,4) then
    raise exception 'bad mult';
  end if;
  -- score must equal blocks x mult (that IS the scoring rule)
  if new.score <> round(new.blocks * new.mult) then
    raise exception 'score/blocks/mult mismatch';
  end if;
  -- can't generate blocks faster than the ball physically allows (~3.5/s + slack)
  if new.blocks > ceil(new.secs * 3.5) + 12 then
    raise exception 'block rate implausible';
  end if;
  -- hard ceilings (grid holds ~187 spawnable cells)
  if new.blocks > 230 or new.secs > 3600 or new.score > 25000 then
    raise exception 'out of range';
  end if;
  new.ua := left(coalesce(new.ua,''), 300);
  return new;
end $$;

drop trigger if exists breakin_scores_guard on public.breakin_scores;
create trigger breakin_scores_guard before insert on public.breakin_scores
  for each row execute function public.breakin_scores_guard();

-- ---------- 2. feedback inbox ----------
create table if not exists public.breakin_feedback (
  id uuid primary key default gen_random_uuid(),
  name text, message text not null,
  meta jsonb, created_at timestamptz not null default now(),
  constraint breakin_fb_len check (char_length(message) between 1 and 2000)
);
alter table public.breakin_feedback enable row level security;
drop policy if exists breakin_fb_insert on public.breakin_feedback;
create policy breakin_fb_insert on public.breakin_feedback
  for insert to anon, authenticated with check (char_length(message) between 1 and 2000);

-- ---------- 3. crash-report inbox ----------
create table if not exists public.breakin_errors (
  id uuid primary key default gen_random_uuid(),
  msg text, stack text, ua text, url text,
  extra jsonb, created_at timestamptz not null default now()
);
alter table public.breakin_errors enable row level security;
drop policy if exists breakin_err_insert on public.breakin_errors;
create policy breakin_err_insert on public.breakin_errors
  for insert to anon, authenticated with check (true);

-- ---------- 4. extend the admin RPC (feedback / errors / delete) ----------
create or replace function public.breakin_admin(action text, secret text, target uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if secret is null or secret <> 'adminadmin' then    -- keep in sync with admin.sql
    return jsonb_build_object('ok', false, 'error', 'bad passphrase');
  end if;

  if action = 'stats' then
    return jsonb_build_object('ok', true,
      'scores', (select count(*) from breakin_scores),
      'top',    (select max(score) from breakin_scores),
      'feedback',(select count(*) from breakin_feedback),
      'errors', (select count(*) from breakin_errors));

  elsif action = 'list' then
    return coalesce((select jsonb_agg(row_to_json(t)) from (
      select id,name,score,blocks,secs,mult,created_at
      from breakin_scores order by created_at desc limit 40) t), '[]'::jsonb);

  elsif action = 'feedback' then
    return coalesce((select jsonb_agg(row_to_json(t)) from (
      select id,name,message,meta,created_at
      from breakin_feedback order by created_at desc limit 60) t), '[]'::jsonb);

  elsif action = 'errors' then
    return coalesce((select jsonb_agg(row_to_json(t)) from (
      select id,msg,stack,ua,url,extra,created_at
      from breakin_errors order by created_at desc limit 60) t), '[]'::jsonb);

  elsif action = 'delete_one' then
    delete from breakin_scores where id = target;
    get diagnostics n = row_count;
    return jsonb_build_object('ok', true, 'deleted', n);

  elsif action = 'reset' then
    delete from breakin_scores;
    get diagnostics n = row_count;
    return jsonb_build_object('ok', true, 'deleted', n);

  else
    return jsonb_build_object('ok', false, 'error', 'unknown action');
  end if;
end $$;

revoke all on function public.breakin_admin(text, text, uuid) from public;
grant execute on function public.breakin_admin(text, text, uuid) to anon, authenticated;
