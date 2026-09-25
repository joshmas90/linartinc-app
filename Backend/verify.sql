-- Rollback-only isolation and receipt checks. No customer data is read or changed.
begin;
create temporary table ios_test_ids(owner_id uuid, other_id uuid, submission_id uuid, other_submission_id uuid) on commit drop;
insert into ios_test_ids values(gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),gen_random_uuid());
grant select on ios_test_ids to authenticated,anon,service_role;
insert into auth.users(id,email) select owner_id,owner_id::text||'@example.invalid' from ios_test_ids
union all select other_id,other_id::text||'@example.invalid' from ios_test_ids;
insert into public.linart_ios_submissions(id,user_id,payload,payload_hash)
select submission_id,owner_id,'{"photos":[]}'::jsonb,repeat('a',64) from ios_test_ids
union all select other_submission_id,other_id,'{"photos":[]}'::jsonb,repeat('b',64) from ios_test_ids;
select set_config('request.jwt.claims',jsonb_build_object('sub',owner_id,'role','authenticated')::text,true) from ios_test_ids;
set local role authenticated;
do $$ begin
  if (select count(*) from public.linart_ios_submissions where id in (select submission_id from ios_test_ids union all select other_submission_id from ios_test_ids)) <> 1 then raise exception 'RLS owner isolation failed'; end if;
  if has_table_privilege('authenticated','public.linart_ios_submissions','INSERT') then raise exception 'Client insert grant present'; end if;
  if has_function_privilege('authenticated','public.linart_ios_finalize(uuid,uuid)','EXECUTE') then raise exception 'Client finalize grant present'; end if;
end $$;
reset role;
do $$ declare ids record; receipt jsonb; again jsonb; failed boolean := false;
begin
  select * into ids from ios_test_ids;
  receipt := public.linart_ios_finalize(ids.submission_id,ids.owner_id);
  again := public.linart_ios_finalize(ids.submission_id,ids.owner_id);
  if receipt <> again or receipt->>'submitted_at' is null then raise exception 'Idempotent receipt failed'; end if;
  begin perform public.linart_ios_finalize(ids.submission_id,ids.other_id); exception when others then failed:=true; end;
  if not failed then raise exception 'Foreign owner finalized'; end if;
  if has_table_privilege('anon','public.linart_ios_submissions','SELECT') then raise exception 'Anonymous read grant present'; end if;
  if (select public from storage.buckets where id='linart-ios-studio') then raise exception 'Bucket is public'; end if;
end $$;
do $$ declare ids record; first_request jsonb; repeated_request jsonb; blocked boolean := false;
begin
  select * into ids from ios_test_ids;
  for i in 1..4 loop
    perform public.linart_ios_begin(gen_random_uuid(),ids.owner_id,'{"photos":[]}'::jsonb,repeat('c',64));
  end loop;
  begin perform public.linart_ios_begin(gen_random_uuid(),ids.owner_id,'{"photos":[]}'::jsonb,repeat('d',64));
  exception when others then blocked := sqlerrm like 'Submission limit reached%'; end;
  if not blocked then raise exception 'Daily quota was not enforced'; end if;
  first_request := public.linart_ios_request_deletion(ids.owner_id);
  repeated_request := public.linart_ios_request_deletion(ids.owner_id);
  if first_request->>'id' <> repeated_request->>'id' then raise exception 'Deletion request is not idempotent'; end if;
  if exists(select 1 from public.linart_ios_submissions where user_id=ids.owner_id and status<>'deleting') then raise exception 'Deletion did not close own uploads'; end if;
  if (select status from public.linart_ios_submissions where id=ids.other_submission_id) <> 'draft' then raise exception 'Deletion touched another user'; end if;
  blocked := false;
  begin perform public.linart_ios_begin(gen_random_uuid(),ids.owner_id,'{"photos":[]}'::jsonb,repeat('e',64));
  exception when others then blocked := sqlerrm='Account deletion is pending'; end;
  if not blocked then raise exception 'Deletion did not block new uploads'; end if;
  if not exists(select 1 from auth.users where id=ids.owner_id) then raise exception 'Shared identity was removed'; end if;
  if has_function_privilege('authenticated','public.linart_ios_request_deletion(uuid)','EXECUTE') then raise exception 'Client can call privileged deletion'; end if;
end $$;
set local role authenticated;
do $$ begin
  if (select count(*) from public.linart_ios_deletion_requests where user_id in (select owner_id from ios_test_ids union all select other_id from ios_test_ids)) <> 1 then raise exception 'Deletion request owner visibility failed'; end if;
end $$;
reset role;
select 'PASS: owner isolation, no anonymous/client writes, stable receipts, private bucket, quota, deletion idempotency/isolation and upload block; fixture changes rolled back' as verification;
rollback;
