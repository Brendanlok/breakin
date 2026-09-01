-- 08-reset-admin-passphrase.sql
-- Set (or reset) the admin passphrase that guards public.breakin_admin.
--
-- WHY THIS EXISTS: the value installed in the database and the value in
-- secrets/breakin.env drifted apart, so breakin_admin has been answering
-- 'bad passphrase' and the feedback + crash-report inboxes have been
-- unreadable. This resets both ends to the same thing.
--
-- HOW TO USE:
--   1. Edit ONE line below - the one marked <<< EDIT THIS LINE >>>.
--      Pick anything you like. Avoid the ' character (it ends a SQL string).
--   2. Paste this whole file into the Supabase SQL editor and run it.
--      If you forget step 1 it stops with a loud error instead of installing
--      a placeholder - that is the mistake that caused this problem.
--   3. Put the SAME value in C:\Users\starw\.claude\secrets\breakin.env as
--         BREAKIN_ADMIN_SECRET=whatever-you-chose
--      (no quotes, no trailing spaces).
--   4. Tell Claude, and it will call the RPC and confirm both ends match.
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

-- Did you actually edit the line? This is the check that stops a placeholder
-- from being installed and quietly breaking the inboxes again.
do $$
declare src text := pg_get_functiondef('public.breakin_admin(text,text,uuid)'::regprocedure);
begin
  if src like '%CHANGE-ME-BEFORE-RUNNING%' or src like '%__SET_YOUR_OWN_PASSPHRASE__%' then
    raise exception 'STOP: the passphrase placeholder was never replaced. Edit the line marked "EDIT THIS LINE" and run this file again.';
  end if;
  raise notice 'Admin passphrase installed. Now put the same value in secrets/breakin.env as BREAKIN_ADMIN_SECRET.';
end $$;

-- Sanity check: a wrong passphrase must still be refused. Expect {"ok": false, "error": "bad passphrase"}.
select public.breakin_admin('stats', 'definitely-not-the-passphrase') as should_be_rejected;
