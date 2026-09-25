-- Additive iOS boundary. Does not modify existing LINART website tables or policies.
create table public.linart_ios_submissions (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  payload jsonb not null check (jsonb_typeof(payload) = 'object' and octet_length(payload::text) <= 131072),
  payload_hash text not null check (payload_hash ~ '^[a-f0-9]{64}$'),
  status text not null default 'draft' check (status in ('draft','submitted','deleting')),
  created_at timestamptz not null default now(),
  submitted_at timestamptz,
  constraint linart_ios_submission_status_time check ((status <> 'submitted') or submitted_at is not null)
);
create index linart_ios_submissions_owner on public.linart_ios_submissions(user_id, created_at desc);
create index linart_ios_submissions_cleanup on public.linart_ios_submissions(created_at) where status = 'draft';
alter table public.linart_ios_submissions enable row level security;
revoke all on public.linart_ios_submissions from anon, authenticated;
grant select on public.linart_ios_submissions to authenticated;
grant all on public.linart_ios_submissions to service_role;
create policy linart_ios_read_own_submissions on public.linart_ios_submissions for select to authenticated using (user_id = (select auth.uid()));

create table public.linart_ios_attachments (
  submission_id uuid not null references public.linart_ios_submissions(id) on delete cascade,
  id uuid not null,
  object_path text not null unique,
  byte_count integer not null check (byte_count between 1 and 5000000),
  sha256 text not null check (sha256 ~ '^[a-f0-9]{64}$'),
  primary key (submission_id, id)
);
alter table public.linart_ios_attachments enable row level security;
revoke all on public.linart_ios_attachments from anon, authenticated;
grant select on public.linart_ios_attachments to authenticated;
grant all on public.linart_ios_attachments to service_role;
create policy linart_ios_read_own_attachments on public.linart_ios_attachments for select to authenticated
using (exists (select 1 from public.linart_ios_submissions s where s.id = submission_id and s.user_id = (select auth.uid())));

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('linart-ios-studio', 'linart-ios-studio', false, 5000000, array['image/jpeg']);
-- No public/client storage policies. Only the authenticated Edge API handles objects.

create function public.linart_ios_finalize(p_id uuid, p_user uuid) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare s public.linart_ios_submissions; expected integer; actual integer;
begin
  select * into s from public.linart_ios_submissions where id = p_id and user_id = p_user for update;
  if not found then raise exception 'Not found'; end if;
  if s.status = 'deleting' then raise exception 'Deletion in progress'; end if;
  if s.status = 'submitted' then return jsonb_build_object('id', s.id, 'submitted_at', s.submitted_at); end if;
  expected := jsonb_array_length(s.payload->'photos');
  select count(*) into actual from public.linart_ios_attachments a
    join jsonb_array_elements(s.payload->'photos') p on (p->>'id')::uuid = a.id
    where a.submission_id = p_id and a.sha256 = p->>'sha256' and a.byte_count = (p->>'bytes')::integer;
  if actual <> expected then raise exception 'Some photos are not uploaded'; end if;
  update public.linart_ios_submissions set status = 'submitted', submitted_at = now() where id = p_id returning * into s;
  return jsonb_build_object('id', s.id, 'submitted_at', s.submitted_at);
end $$;
revoke all on function public.linart_ios_finalize(uuid,uuid) from public, anon, authenticated;
grant execute on function public.linart_ios_finalize(uuid,uuid) to service_role;

create schema linart_ios_private;
revoke all on schema linart_ios_private from public, anon, authenticated;
create function linart_ios_private.session_active(p_user uuid, p_session uuid) returns boolean
language sql security definer set search_path = '' as $$
  select ((select auth.uid()) = p_user or (select auth.jwt()->>'role') = 'service_role')
    and exists(select 1 from auth.sessions where id = p_session and user_id = p_user and (not_after is null or not_after > now()));
$$;
revoke all on function linart_ios_private.session_active(uuid,uuid) from public, anon, authenticated;
grant usage on schema linart_ios_private to service_role;
grant execute on function linart_ios_private.session_active(uuid,uuid) to service_role;
create function public.linart_ios_session_active(p_user uuid, p_session uuid) returns boolean
language sql security invoker set search_path = '' as $$ select linart_ios_private.session_active(p_user,p_session); $$;
revoke all on function public.linart_ios_session_active(uuid,uuid) from public, anon, authenticated;
grant execute on function public.linart_ios_session_active(uuid,uuid) to service_role;

create function public.linart_ios_begin(p_id uuid, p_user uuid, p_payload jsonb, p_hash text) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare s public.linart_ios_submissions;
begin
  -- Serialize quota checks and retries from the same verified user.
  perform pg_advisory_xact_lock(hashtextextended(p_user::text, 94721));
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
revoke all on function public.linart_ios_begin(uuid,uuid,jsonb,text) from public,anon,authenticated;
grant execute on function public.linart_ios_begin(uuid,uuid,jsonb,text) to service_role;
