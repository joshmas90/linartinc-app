-- App-only deletion requests; shared identities are reviewed by LINART before removal.
create table public.linart_ios_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users(id) on delete set null,
  requested_at timestamptz not null default now(),
  uploads_removed_at timestamptz,
  completed_at timestamptz
);
alter table public.linart_ios_deletion_requests enable row level security;
revoke all on public.linart_ios_deletion_requests from anon, authenticated;
grant select on public.linart_ios_deletion_requests to authenticated;
grant all on public.linart_ios_deletion_requests to service_role;
create policy ios_deletion_owner_read on public.linart_ios_deletion_requests
  for select to authenticated using ((select auth.uid()) = user_id);

create function public.linart_ios_request_deletion(p_user uuid) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare r public.linart_ios_deletion_requests;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user::text, 94721));
  insert into public.linart_ios_deletion_requests(user_id) values(p_user)
    on conflict(user_id) do update set user_id=excluded.user_id returning * into r;
  update public.linart_ios_submissions set status='deleting' where user_id=p_user;
  return to_jsonb(r);
end $$;
revoke all on function public.linart_ios_request_deletion(uuid) from public,anon,authenticated;
grant execute on function public.linart_ios_request_deletion(uuid) to service_role;

-- Serializes with the deletion request, preventing a new brief after the request.
create or replace function public.linart_ios_begin(p_id uuid, p_user uuid, p_payload jsonb, p_hash text) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare s public.linart_ios_submissions;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user::text, 94721));
  if exists(select 1 from public.linart_ios_deletion_requests where user_id=p_user) then
    raise exception 'Account deletion is pending';
  end if;
  select * into s from public.linart_ios_submissions where id=p_id and user_id=p_user;
  if found then
    if s.payload_hash <> p_hash then raise exception 'Reference belongs to another brief'; end if;
    if s.status = 'deleting' then raise exception 'Submission is being removed'; end if;
    return jsonb_build_object('id',s.id,'status',s.status,'submitted_at',s.submitted_at);
  end if;
  if (select count(*) from public.linart_ios_submissions where user_id=p_user and created_at > now()-interval '1 day') >= 5
     or (select count(*) from public.linart_ios_submissions where user_id=p_user) >= 20 then
    raise exception 'Submission limit reached. Remove unused app submissions or try tomorrow.';
  end if;
  insert into public.linart_ios_submissions(id,user_id,payload,payload_hash) values(p_id,p_user,p_payload,p_hash) returning * into s;
  return jsonb_build_object('id',s.id,'status',s.status,'submitted_at',s.submitted_at);
end $$;
