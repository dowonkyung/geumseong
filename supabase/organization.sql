-- Geumseong staff names and portraits. Safe to rerun; existing directory rows are preserved.
begin;

create table if not exists public.geumseong_organization_directory (
 department text primary key check(char_length(department) between 1 and 100),
 sections jsonb not null default '[]' check(jsonb_typeof(sections)='array'),
 version integer not null default 1 check(version>0),
 updated_at timestamptz not null default now()
);
alter table public.geumseong_organization_directory enable row level security;
revoke all on public.geumseong_organization_directory from anon,authenticated;
grant select on public.geumseong_organization_directory to anon,authenticated;
drop policy if exists geumseong_organization_directory_read on public.geumseong_organization_directory;
create policy geumseong_organization_directory_read on public.geumseong_organization_directory
 for select to anon,authenticated using(true);

create or replace function public.geumseong_save_organization_directory(
 p_department text,p_sections jsonb,p_expected_version integer
) returns integer
language plpgsql security definer set search_path='' as $function$
declare
 section jsonb;
 member jsonb;
 total integer := 0;
 result integer;
 portrait_path text;
begin
 if not coalesce(public.is_news_admin(),false) then
  raise exception '관리자만 편집할 수 있습니다.' using errcode='42501';
 end if;
 if p_department is null or char_length(btrim(p_department)) not between 1 and 100
    or p_department='경애하는 도원경수령님' then
  raise exception '올바른 조직을 선택해 주세요.';
 end if;
 if p_expected_version is null or p_expected_version<0 then
  raise exception '목록 버전을 확인해 주세요.';
 end if;
 if p_sections is null or jsonb_typeof(p_sections)<>'array'
    or octet_length(p_sections::text)>2097152 then
  raise exception '목록 형식 또는 용량을 확인해 주세요.';
 end if;
 if jsonb_array_length(p_sections)>50 then
  raise exception '표 묶음은 50개까지 등록할 수 있습니다.';
 end if;
 for section in select value from jsonb_array_elements(p_sections) loop
  if jsonb_typeof(section)<>'object'
     or jsonb_typeof(section->'title') is distinct from 'string'
     or char_length(btrim(coalesce(section->>'title',''))) not between 1 and 100
     or jsonb_typeof(section->'rows') is distinct from 'array' then
   raise exception '부서·팀 제목과 행 목록을 확인해 주세요.';
  end if;
  total := total+jsonb_array_length(section->'rows');
  if total>500 then
   raise exception '한 조직에 500행까지 등록할 수 있습니다.';
  end if;
  for member in select value from jsonb_array_elements(section->'rows') loop
   if jsonb_typeof(member)<>'object'
      or jsonb_typeof(member->'position') is distinct from 'string'
      or char_length(btrim(coalesce(member->>'position',''))) not between 1 and 100
      or jsonb_typeof(member->'phone') is distinct from 'string'
      or char_length(member->>'phone')>100
      or jsonb_typeof(member->'duties') is distinct from 'string'
      or char_length(member->>'duties')>3000 then
    raise exception '직위(100자), 전화번호(100자), 담당업무(3000자)를 확인해 주세요.';
   end if;
   if member ? 'name' then
    if jsonb_typeof(member->'name') is distinct from 'string'
       or char_length(member->>'name')>100 then
     raise exception '성명은 100자 이하로 입력해 주세요.';
    end if;
   end if;
   if member ? 'photo_path' then
    if jsonb_typeof(member->'photo_path') is distinct from 'string' then
     raise exception '사진 경로를 확인해 주세요.';
    end if;
   end if;
   portrait_path := coalesce(member->>'photo_path','');
   if portrait_path<>'' then
    if portrait_path !~ '^[0-9a-f-]{36}\.(png|jpg|webp)$' then
     raise exception '사진 경로를 확인해 주세요.';
    end if;
    if not exists(
     select 1 from storage.objects
     where bucket_id='geumseong-org-portraits' and name=portrait_path
    ) then
     raise exception '사진을 먼저 업로드해 주세요.';
    end if;
   end if;
  end loop;
 end loop;
 if p_expected_version=0 then
  insert into public.geumseong_organization_directory(department,sections)
  values(p_department,p_sections)
  on conflict do nothing returning version into result;
 else
  update public.geumseong_organization_directory
  set sections=p_sections,version=version+1,updated_at=now()
  where department=p_department and version=p_expected_version
  returning version into result;
 end if;
 if result is null then
  raise exception '다른 관리자가 목록을 변경했습니다. 새로고침 후 다시 편집해 주세요.' using errcode='40001';
 end if;
 return result;
end;
$function$;

revoke all on function public.geumseong_save_organization_directory(text,jsonb,integer) from public,anon;
grant execute on function public.geumseong_save_organization_directory(text,jsonb,integer) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('geumseong-org-portraits','geumseong-org-portraits',true,5242880,
 array['image/png','image/jpeg','image/webp'])
on conflict(id) do update
set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists geumseong_org_portraits_read on storage.objects;
create policy geumseong_org_portraits_read on storage.objects
 for select to anon,authenticated using(bucket_id='geumseong-org-portraits');

drop policy if exists geumseong_org_portraits_insert on storage.objects;
create policy geumseong_org_portraits_insert on storage.objects
 for insert to authenticated with check(
  bucket_id='geumseong-org-portraits'
  and coalesce(public.is_news_admin(),false)
  and name ~ '^[0-9a-f-]{36}\.(png|jpg|webp)$'
 );

drop policy if exists geumseong_org_portraits_delete on storage.objects;
create policy geumseong_org_portraits_delete on storage.objects
 for delete to authenticated using(
  bucket_id='geumseong-org-portraits'
  and coalesce(public.is_news_admin(),false)
  and not exists(
   select 1 from public.geumseong_organization_directory d
   cross join lateral jsonb_array_elements(d.sections) as s(value)
   cross join lateral jsonb_array_elements(s.value->'rows') as r(value)
   where r.value->>'photo_path'=storage.objects.name
  )
 );

commit;