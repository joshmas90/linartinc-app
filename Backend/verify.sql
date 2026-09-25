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
select 'PASS: owner isolation, no anonymous/client writes, receipt idempotency, private bucket; fixture changes rolled back' as verification;
rollback;
