-- Breakin admin RPC — run once in the Supabase SQL editor (Partfinder project).
-- The game's hidden admin panel calls this. It runs as the function owner (bypasses RLS)
-- but does nothing unless the caller passes the passphrase, which is checked here and
-- lives ONLY in this function — never in the shipped HTML.
--
-- >>> Replace CHANGE_ME_TO_A_LONG_RANDOM_PASSPHRASE below with your own secret <<<

create or replace function public.breakin_admin(action text, secret text, target uuid default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
begin
  if secret is null or secret <> 'CHANGE_ME_TO_A_LONG_RANDOM_PASSPHRASE' then
    return jsonb_build_object('ok', false, 'error', 'bad passphrase');
  end if;

  if action = 'stats' then
    return jsonb_build_object(
      'ok', true,
      'count', (select count(*) from breakin_scores),
      'top',   (select max(score) from breakin_scores),
      'latest',(select max(created_at) from breakin_scores));

  elsif action = 'list' then
    return coalesce((
      select jsonb_agg(row_to_json(t))
      from (select id, name, score, secs, blocks, created_at
            from breakin_scores order by created_at desc limit 40) t
    ), '[]'::jsonb);

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
end;
$$;

revoke all on function public.breakin_admin(text, text, uuid) from public;
grant execute on function public.breakin_admin(text, text, uuid) to anon, authenticated;
