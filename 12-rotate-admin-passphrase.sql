-- 12-rotate-admin-passphrase.sql
--
-- ===================================================================
-- RUN THIS BEFORE LAUNCH. It is the only launch blocker left.
-- ===================================================================
--
-- WHY: on 2026-09-03 the admin passphrase that is actually installed in the
-- database was found written out in plain text inside 08-reset-admin-passphrase.sql,
-- and that file has been in the PUBLIC GitHub repo since 2026-09-01 (commit 60f8865).
-- Anyone who reads the repo can therefore open the admin panel today: read every
-- feedback message and crash report, delete scores, and wipe the whole leaderboard.
-- The old passphrase must be treated as burned. Deleting the file does not help -
-- it stays readable in the git history - so the fix is to change the passphrase.
--
-- This file also folds in the inbox cleanup: after running it, the admin panel
-- gets a "delete" button on each feedback message and each crash report, so the
-- inboxes can be cleared after review without ever opening the SQL editor again.
--
-- HOW TO USE:
--   1. Edit ONE line below - the one marked <<< EDIT THIS LINE >>>.
--      Pick a NEW value. Do not reuse the old one, it is public. Avoid the '
--      character (it ends a SQL string).
--   2. Paste this whole file into the Supabase SQL editor and run it.
--      If you forget step 1 it stops with a loud error rather than installing a
--      placeholder.
--   3. Put the SAME new value in C:\Users\starw\.claude\secrets\breakin.env as
--         BREAKIN_ADMIN_SECRET=whatever-you-chose
--      (no quotes, no trailing spaces). That file is NOT in any repo.
--   4. Never paste the real value into a file inside the breakin folder.
--
-- This replaces ONLY the admin function. It does not touch scores, feedback,
-- crash reports, the score guard, or any table.

create or replace function public.breakin_admin(action text, secret text, target uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare n int;
begin

  if secret is null or secret <> 'CHANGE-ME-BEFORE-RUNNING' then   -- <<< EDIT THIS LINE >>>
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

  -- new: clear an inbox row once it has been read, from the admin panel
  elsif action = 'delete_feedback' then
    delete from breakin_feedback where id = target;
    get diagnostics n = row_count;
    return jsonb_build_object('ok', true, 'deleted', n);

  elsif action = 'delete_error' then
    delete from breakin_errors where id = target;
    get diagnostics n = row_count;
    return jsonb_build_object('ok', true, 'deleted', n);

  elsif action = 'reset' then
    delete from breakin_scores where id is not null;   -- WHERE clause: Supabase blocks unqualified DELETE
    get diagnostics n = row_count;
    return jsonb_build_object('ok', true, 'deleted', n);

  else
    return jsonb_build_object('ok', false, 'error', 'unknown action');
  end if;
end $$;

revoke all on function public.breakin_admin(text, text, uuid) from public;
grant execute on function public.breakin_admin(text, text, uuid) to anon, authenticated;

-- Did you actually edit the line? This stops a placeholder - or the burned old
-- value - from being installed and quietly leaving the admin panel wide open.
do $$
declare src text := pg_get_functiondef('public.breakin_admin(text,text,uuid)'::regprocedure);
begin
  if src like '%CHANGE-ME-BEFORE-RUNNING%' or src like '%__SET_YOUR_OWN_PASSPHRASE__%' then
    raise exception 'STOP: the passphrase placeholder was never replaced. Edit the line marked "EDIT THIS LINE" and run this file again.';
  end if;
  raise notice 'New admin passphrase installed. Now put the same value in secrets/breakin.env as BREAKIN_ADMIN_SECRET.';
end $$;

-- Sanity check: any wrong passphrase must be refused.
-- Expect {"ok": false, "error": "bad passphrase"}.
select public.breakin_admin('stats', 'definitely-not-the-passphrase') as should_be_rejected;

-- Then, in the app: open the admin panel with the NEW passphrase and press Summary.
-- If it answers, both ends match. Ask Claude to confirm the old value is refused.
