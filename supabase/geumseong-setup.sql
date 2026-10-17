-- schema.sql
create table if not exists public.geumseong_news_posts (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 200),
  department text not null check (char_length(department) between 1 and 100),
  body_html text not null default '' check (octet_length(body_html)<=1048576),
  body_text text not null default '',
  status text not null default 'draft' check (status in ('draft','published')),
  author_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  views integer not null default 0 check (views>=0)
);
create index if not exists geumseong_news_posts_published_date on public.geumseong_news_posts(status,created_at desc);
alter table public.geumseong_news_posts enable row level security;
grant select on public.geumseong_news_posts to anon, authenticated;
grant insert, update, delete on public.geumseong_news_posts to authenticated;
drop policy if exists geumseong_news_posts_read on public.geumseong_news_posts;
drop policy if exists geumseong_news_posts_insert on public.geumseong_news_posts;
drop policy if exists geumseong_news_posts_update on public.geumseong_news_posts;
drop policy if exists geumseong_news_posts_delete on public.geumseong_news_posts;
create policy geumseong_news_posts_read on public.geumseong_news_posts for select to anon,authenticated using (status='published' or (select public.is_news_admin()));
create policy geumseong_news_posts_insert on public.geumseong_news_posts for insert to authenticated with check ((select public.is_news_admin()) and author_id=(select auth.uid()));
create policy geumseong_news_posts_update on public.geumseong_news_posts for update to authenticated using ((select public.is_news_admin())) with check ((select public.is_news_admin()));
create policy geumseong_news_posts_delete on public.geumseong_news_posts for delete to authenticated using ((select public.is_news_admin()));

create table if not exists public.geumseong_news_assets (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.geumseong_news_posts(id) on delete cascade,
  file_name text not null,
  storage_path text not null unique,
  mime text not null default 'application/octet-stream',
  size bigint not null check (size>=0 and size<=20971520),
  kind text not null check (kind in ('attachment','inline','preview')),
  preview_path text,
  created_at timestamptz not null default now()
);
create index if not exists geumseong_news_assets_post on public.geumseong_news_assets(post_id);
alter table public.geumseong_news_assets enable row level security;
grant select on public.geumseong_news_assets to anon, authenticated;
grant insert, update, delete on public.geumseong_news_assets to authenticated;
drop policy if exists geumseong_news_assets_read on public.geumseong_news_assets;
drop policy if exists geumseong_news_assets_write on public.geumseong_news_assets;
create policy geumseong_news_assets_read on public.geumseong_news_assets for select to anon,authenticated using (
  (select public.is_news_admin()) or exists(select 1 from public.geumseong_news_posts p where p.id=post_id and p.status='published')
);
create policy geumseong_news_assets_write on public.geumseong_news_assets for all to authenticated using ((select public.is_news_admin())) with check ((select public.is_news_admin()));

insert into storage.buckets(id,name,public,file_size_limit) values ('geumseong-news-files','geumseong-news-files',false,20971520)
on conflict (id) do update set public=false,file_size_limit=20971520;
drop policy if exists geumseong_news_files_read on storage.objects;
drop policy if exists geumseong_news_files_insert on storage.objects;
drop policy if exists geumseong_news_files_delete on storage.objects;
create policy geumseong_news_files_read on storage.objects for select to anon,authenticated using (
  bucket_id='geumseong-news-files' and ((select public.is_news_admin()) or exists (
    select 1 from public.geumseong_news_assets a join public.geumseong_news_posts p on p.id=a.post_id
    where a.storage_path=name and p.status='published'
  ))
);
create policy geumseong_news_files_insert on storage.objects for insert to authenticated with check (
  bucket_id='geumseong-news-files' and (select public.is_news_admin()) and split_part(name,'/',1)=(select auth.uid())::text
);
create policy geumseong_news_files_delete on storage.objects for delete to authenticated using (bucket_id='geumseong-news-files' and (select public.is_news_admin()));

create or replace function public.geumseong_record_news_view(post_uuid uuid) returns integer
language plpgsql security definer set search_path = '' as $$
declare result integer;
begin
  update public.geumseong_news_posts set views=views+1 where id=post_uuid and status='published' returning views into result;
  return result;
end;
$$;
revoke all on function public.geumseong_record_news_view(uuid) from public;
grant execute on function public.geumseong_record_news_view(uuid) to anon,authenticated;

-- After creating the admin account in Authentication > Users, run this separately:
-- insert into public.news_admins(user_id) values ('ADMIN-USER-UUID') on conflict do nothing;


-- notices.sql
-- Run after schema.sql. Existing news tables and files are not changed.
begin;
create table if not exists public.geumseong_notice_posts (
  id uuid primary key default gen_random_uuid(),
  board_type text not null check (board_type in ('notice','bid','legislation','general')),
  notice_kind text not null check (char_length(notice_kind) between 1 and 100),
  issue_name text not null default '' check (char_length(issue_name)<=200),
  notice_number text not null check (char_length(notice_number) between 1 and 200),
  period_start date,
  period_end date,
  check (period_start is null or period_end is null or period_start<=period_end),
  title text not null check (char_length(title) between 1 and 200),
  department text not null check (char_length(department) between 1 and 100),
  body_html text not null default '' check (octet_length(body_html)<=1048576),
  body_text text not null default '',
  status text not null default 'draft' check (status in ('draft','published')),
  author_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  views integer not null default 0 check (views>=0)
);
create index if not exists geumseong_notice_posts_published_date on public.geumseong_notice_posts(status,created_at desc);
alter table public.geumseong_notice_posts enable row level security;
grant select on public.geumseong_notice_posts to anon, authenticated;
grant insert, update, delete on public.geumseong_notice_posts to authenticated;
drop policy if exists geumseong_notice_posts_read on public.geumseong_notice_posts;
drop policy if exists geumseong_notice_posts_insert on public.geumseong_notice_posts;
drop policy if exists geumseong_notice_posts_update on public.geumseong_notice_posts;
drop policy if exists geumseong_notice_posts_delete on public.geumseong_notice_posts;
create policy geumseong_notice_posts_read on public.geumseong_notice_posts for select to anon,authenticated using (status='published' or (select public.is_news_admin()));
create policy geumseong_notice_posts_insert on public.geumseong_notice_posts for insert to authenticated with check ((select public.is_news_admin()) and author_id=(select auth.uid()));
create policy geumseong_notice_posts_update on public.geumseong_notice_posts for update to authenticated using ((select public.is_news_admin())) with check ((select public.is_news_admin()));
create policy geumseong_notice_posts_delete on public.geumseong_notice_posts for delete to authenticated using ((select public.is_news_admin()));

create table if not exists public.geumseong_notice_assets (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.geumseong_notice_posts(id) on delete cascade,
  file_name text not null,
  storage_path text not null unique,
  mime text not null default 'application/octet-stream',
  size bigint not null check (size>=0 and size<=20971520),
  kind text not null check (kind in ('attachment','inline','preview')),
  preview_path text,
  created_at timestamptz not null default now()
);
create index if not exists geumseong_notice_assets_post on public.geumseong_notice_assets(post_id);
alter table public.geumseong_notice_assets enable row level security;
grant select on public.geumseong_notice_assets to anon, authenticated;
grant insert, update, delete on public.geumseong_notice_assets to authenticated;
drop policy if exists geumseong_notice_assets_read on public.geumseong_notice_assets;
drop policy if exists geumseong_notice_assets_write on public.geumseong_notice_assets;
create policy geumseong_notice_assets_read on public.geumseong_notice_assets for select to anon,authenticated using (
  (select public.is_news_admin()) or exists(select 1 from public.geumseong_notice_posts p where p.id=post_id and p.status='published')
);
create policy geumseong_notice_assets_write on public.geumseong_notice_assets for all to authenticated using ((select public.is_news_admin())) with check ((select public.is_news_admin()));

insert into storage.buckets(id,name,public,file_size_limit) values ('geumseong-notice-files','geumseong-notice-files',false,20971520)
on conflict (id) do update set public=false,file_size_limit=20971520;
drop policy if exists geumseong_notice_files_read on storage.objects;
drop policy if exists geumseong_notice_files_insert on storage.objects;
drop policy if exists geumseong_notice_files_delete on storage.objects;
create policy geumseong_notice_files_read on storage.objects for select to anon,authenticated using (
  bucket_id='geumseong-notice-files' and ((select public.is_news_admin()) or exists (
    select 1 from public.geumseong_notice_assets a join public.geumseong_notice_posts p on p.id=a.post_id
    where a.storage_path=name and p.status='published'
  ))
);
create policy geumseong_notice_files_insert on storage.objects for insert to authenticated with check (
  bucket_id='geumseong-notice-files' and (select public.is_news_admin()) and split_part(name,'/',1)=(select auth.uid())::text
);
create policy geumseong_notice_files_delete on storage.objects for delete to authenticated using (bucket_id='geumseong-notice-files' and (select public.is_news_admin()));

create or replace function public.geumseong_record_notice_view(post_uuid uuid) returns integer
language plpgsql security definer set search_path = '' as $$
declare result integer;
begin
  update public.geumseong_notice_posts set views=views+1 where id=post_uuid and status='published' returning views into result;
  return result;
end;
$$;
revoke all on function public.geumseong_record_notice_view(uuid) from public;
grant execute on function public.geumseong_record_notice_view(uuid) to anon,authenticated;


create index if not exists geumseong_notice_posts_board_date on public.geumseong_notice_posts(board_type,status,created_at desc);
commit;


-- publications.sql
-- Run after schema.sql. Existing news tables and files are not changed.
begin;
create table if not exists public.geumseong_publication_posts (
  id uuid primary key default gen_random_uuid(),
  board_type text not null check (board_type in ('gazette','press','briefing','facts','activity','media')),
  contact text not null default '' check (char_length(contact)<=100),
  thumbnail_path text,
  summary text not null default '' check (char_length(summary)<=500),
  title text not null check (char_length(title) between 1 and 200),
  department text not null check (char_length(department) between 1 and 100),
  body_html text not null default '' check (octet_length(body_html)<=1048576),
  body_text text not null default '',
  status text not null default 'draft' check (status in ('draft','published')),
  author_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  views integer not null default 0 check (views>=0)
);
-- Expand the category check on projects that already created these tables.
alter table public.geumseong_publication_posts drop constraint if exists publication_posts_board_type_check;
alter table public.geumseong_publication_posts add constraint publication_posts_board_type_check check (board_type in ('gazette','press','briefing','facts','activity','media'));
create index if not exists geumseong_publication_posts_published_date on public.geumseong_publication_posts(status,created_at desc);
alter table public.geumseong_publication_posts enable row level security;
grant select on public.geumseong_publication_posts to anon, authenticated;
grant insert, update, delete on public.geumseong_publication_posts to authenticated;
drop policy if exists geumseong_publication_posts_read on public.geumseong_publication_posts;
drop policy if exists geumseong_publication_posts_insert on public.geumseong_publication_posts;
drop policy if exists geumseong_publication_posts_update on public.geumseong_publication_posts;
drop policy if exists geumseong_publication_posts_delete on public.geumseong_publication_posts;
create policy geumseong_publication_posts_read on public.geumseong_publication_posts for select to anon,authenticated using (status='published' or (select public.is_news_admin()));
create policy geumseong_publication_posts_insert on public.geumseong_publication_posts for insert to authenticated with check ((select public.is_news_admin()) and author_id=(select auth.uid()));
create policy geumseong_publication_posts_update on public.geumseong_publication_posts for update to authenticated using ((select public.is_news_admin())) with check ((select public.is_news_admin()));
create policy geumseong_publication_posts_delete on public.geumseong_publication_posts for delete to authenticated using ((select public.is_news_admin()));

create table if not exists public.geumseong_publication_assets (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.geumseong_publication_posts(id) on delete cascade,
  file_name text not null,
  storage_path text not null unique,
  mime text not null default 'application/octet-stream',
  size bigint not null check (size>=0 and size<=20971520),
  kind text not null check (kind in ('attachment','inline','preview','thumbnail')),
  preview_path text,
  created_at timestamptz not null default now()
);
create index if not exists geumseong_publication_assets_post on public.geumseong_publication_assets(post_id);
alter table public.geumseong_publication_assets enable row level security;
grant select on public.geumseong_publication_assets to anon, authenticated;
grant insert, update, delete on public.geumseong_publication_assets to authenticated;
drop policy if exists geumseong_publication_assets_read on public.geumseong_publication_assets;
drop policy if exists geumseong_publication_assets_write on public.geumseong_publication_assets;
create policy geumseong_publication_assets_read on public.geumseong_publication_assets for select to anon,authenticated using (
  (select public.is_news_admin()) or exists(select 1 from public.geumseong_publication_posts p where p.id=post_id and p.status='published')
);
create policy geumseong_publication_assets_write on public.geumseong_publication_assets for all to authenticated using ((select public.is_news_admin())) with check ((select public.is_news_admin()));

insert into storage.buckets(id,name,public,file_size_limit) values ('geumseong-publication-files','geumseong-publication-files',false,20971520)
on conflict (id) do update set public=false,file_size_limit=20971520;
drop policy if exists geumseong_publication_files_read on storage.objects;
drop policy if exists geumseong_publication_files_insert on storage.objects;
drop policy if exists geumseong_publication_files_delete on storage.objects;
create policy geumseong_publication_files_read on storage.objects for select to anon,authenticated using (
  bucket_id='geumseong-publication-files' and ((select public.is_news_admin()) or exists (
    select 1 from public.geumseong_publication_assets a join public.geumseong_publication_posts p on p.id=a.post_id
    where a.storage_path=name and p.status='published'
  ))
);
create policy geumseong_publication_files_insert on storage.objects for insert to authenticated with check (
  bucket_id='geumseong-publication-files' and (select public.is_news_admin()) and split_part(name,'/',1)=(select auth.uid())::text
);
create policy geumseong_publication_files_delete on storage.objects for delete to authenticated using (bucket_id='geumseong-publication-files' and (select public.is_news_admin()));

create or replace function public.geumseong_record_publication_view(post_uuid uuid) returns integer
language plpgsql security definer set search_path = '' as $$
declare result integer;
begin
  update public.geumseong_publication_posts set views=views+1 where id=post_uuid and status='published' returning views into result;
  return result;
end;
$$;
revoke all on function public.geumseong_record_publication_view(uuid) from public;
grant execute on function public.geumseong_record_publication_view(uuid) to anon,authenticated;


create index if not exists geumseong_publication_posts_board_date on public.geumseong_publication_posts(board_type,status,created_at desc);
commit;


-- photos.sql
-- Run after schema.sql. Existing news tables and files are not changed.
begin;
create table if not exists public.geumseong_photo_posts (
  id uuid primary key default gen_random_uuid(),
  board_type text not null check (board_type in ('photo')),
  shot_date text not null default '' check (char_length(shot_date)<=100),
  thumbnail_path text,
  summary text not null default '' check (char_length(summary)<=500),
  title text not null check (char_length(title) between 1 and 200),
  department text not null check (char_length(department) between 1 and 100),
  body_html text not null default '' check (octet_length(body_html)<=1048576),
  body_text text not null default '',
  status text not null default 'draft' check (status in ('draft','published')),
  author_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  views integer not null default 0 check (views>=0)
);
-- Expand the category check on projects that already created these tables.
alter table public.geumseong_photo_posts drop constraint if exists photo_posts_board_type_check;
alter table public.geumseong_photo_posts add constraint photo_posts_board_type_check check (board_type in ('photo'));
create index if not exists geumseong_photo_posts_published_date on public.geumseong_photo_posts(status,created_at desc);
alter table public.geumseong_photo_posts enable row level security;
grant select on public.geumseong_photo_posts to anon, authenticated;
grant insert, update, delete on public.geumseong_photo_posts to authenticated;
drop policy if exists geumseong_photo_posts_read on public.geumseong_photo_posts;
drop policy if exists geumseong_photo_posts_insert on public.geumseong_photo_posts;
drop policy if exists geumseong_photo_posts_update on public.geumseong_photo_posts;
drop policy if exists geumseong_photo_posts_delete on public.geumseong_photo_posts;
create policy geumseong_photo_posts_read on public.geumseong_photo_posts for select to anon,authenticated using (status='published' or (select public.is_news_admin()));
create policy geumseong_photo_posts_insert on public.geumseong_photo_posts for insert to authenticated with check ((select public.is_news_admin()) and author_id=(select auth.uid()));
create policy geumseong_photo_posts_update on public.geumseong_photo_posts for update to authenticated using ((select public.is_news_admin())) with check ((select public.is_news_admin()));
create policy geumseong_photo_posts_delete on public.geumseong_photo_posts for delete to authenticated using ((select public.is_news_admin()));

create table if not exists public.geumseong_photo_assets (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.geumseong_photo_posts(id) on delete cascade,
  file_name text not null,
  storage_path text not null unique,
  mime text not null default 'application/octet-stream',
  size bigint not null check (size>=0 and size<=20971520),
  kind text not null check (kind in ('attachment','inline','preview','thumbnail')),
  preview_path text,
  created_at timestamptz not null default now()
);
create index if not exists geumseong_photo_assets_post on public.geumseong_photo_assets(post_id);
alter table public.geumseong_photo_assets enable row level security;
grant select on public.geumseong_photo_assets to anon, authenticated;
grant insert, update, delete on public.geumseong_photo_assets to authenticated;
drop policy if exists geumseong_photo_assets_read on public.geumseong_photo_assets;
drop policy if exists geumseong_photo_assets_write on public.geumseong_photo_assets;
create policy geumseong_photo_assets_read on public.geumseong_photo_assets for select to anon,authenticated using (
  (select public.is_news_admin()) or exists(select 1 from public.geumseong_photo_posts p where p.id=post_id and p.status='published')
);
create policy geumseong_photo_assets_write on public.geumseong_photo_assets for all to authenticated using ((select public.is_news_admin())) with check ((select public.is_news_admin()));

insert into storage.buckets(id,name,public,file_size_limit) values ('geumseong-photo-files','geumseong-photo-files',false,20971520)
on conflict (id) do update set public=false,file_size_limit=20971520;
drop policy if exists geumseong_photo_files_read on storage.objects;
drop policy if exists geumseong_photo_files_insert on storage.objects;
drop policy if exists geumseong_photo_files_delete on storage.objects;
create policy geumseong_photo_files_read on storage.objects for select to anon,authenticated using (
  bucket_id='geumseong-photo-files' and ((select public.is_news_admin()) or exists (
    select 1 from public.geumseong_photo_assets a join public.geumseong_photo_posts p on p.id=a.post_id
    where a.storage_path=name and p.status='published'
  ))
);
create policy geumseong_photo_files_insert on storage.objects for insert to authenticated with check (
  bucket_id='geumseong-photo-files' and (select public.is_news_admin()) and split_part(name,'/',1)=(select auth.uid())::text
);
create policy geumseong_photo_files_delete on storage.objects for delete to authenticated using (bucket_id='geumseong-photo-files' and (select public.is_news_admin()));

create or replace function public.geumseong_record_photo_view(post_uuid uuid) returns integer
language plpgsql security definer set search_path = '' as $$
declare result integer;
begin
  update public.geumseong_photo_posts set views=views+1 where id=post_uuid and status='published' returning views into result;
  return result;
end;
$$;
revoke all on function public.geumseong_record_photo_view(uuid) from public;
grant execute on function public.geumseong_record_photo_view(uuid) to anon,authenticated;


create index if not exists geumseong_photo_posts_board_date on public.geumseong_photo_posts(board_type,status,created_at desc);
commit;


-- videos.sql
-- Run after schema.sql. Reuses the existing administrator check.
begin;
create table if not exists public.geumseong_video_posts (
 id uuid primary key default gen_random_uuid(),
 title text not null check(char_length(title) between 1 and 200),
 youtube_id text not null check(youtube_id ~ '^[A-Za-z0-9_-]{11}$'),
 published_on date not null,
 views integer not null default 0 check(views>=0),
 created_at timestamptz not null default now()
);
create index if not exists geumseong_video_posts_date on public.geumseong_video_posts(published_on desc,created_at desc);
alter table public.geumseong_video_posts enable row level security;
grant select on public.geumseong_video_posts to anon,authenticated;
grant insert,update,delete on public.geumseong_video_posts to authenticated;
drop policy if exists geumseong_video_posts_read on public.geumseong_video_posts;
create policy geumseong_video_posts_read on public.geumseong_video_posts for select to anon,authenticated using(true);
drop policy if exists geumseong_video_posts_write on public.geumseong_video_posts;
create policy geumseong_video_posts_write on public.geumseong_video_posts for all to authenticated using((select public.is_news_admin())) with check((select public.is_news_admin()));
create or replace function public.geumseong_record_video_view(post_uuid uuid) returns integer
language plpgsql security definer set search_path='' as $$
declare result integer;
begin
 update public.geumseong_video_posts set views=views+1 where id=post_uuid returning views into result;
 return result;
end;
$$;
revoke all on function public.geumseong_record_video_view(uuid) from public;
grant execute on function public.geumseong_record_video_view(uuid) to anon,authenticated;
commit;


-- organization.sql
-- Run after schema.sql. Directory information is public; only existing admins may edit.
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
create policy geumseong_organization_directory_read on public.geumseong_organization_directory for select to anon,authenticated using(true);

create or replace function public.geumseong_save_organization_directory(p_department text,p_sections jsonb,p_expected_version integer) returns integer
language plpgsql security definer set search_path='' as $$
declare section jsonb; member jsonb; total integer=0; result integer;
begin
 if not public.is_news_admin() then raise exception '관리자만 편집할 수 있습니다.';end if;
 if p_department is null or char_length(btrim(p_department)) not between 1 and 100 or p_department='경애하는 도원경수령님' then raise exception '올바른 조직을 선택해 주세요.';end if;
 if p_sections is null or jsonb_typeof(p_sections)<>'array' or octet_length(p_sections::text)>2097152 then raise exception '목록 형식 또는 용량을 확인해 주세요.';end if;
 if jsonb_array_length(p_sections)>50 then raise exception '표 묶음은 50개까지 등록할 수 있습니다.';end if;
 for section in select value from jsonb_array_elements(p_sections) loop
  if jsonb_typeof(section)<>'object' or jsonb_typeof(section->'title') is distinct from 'string' or char_length(btrim(coalesce(section->>'title',''))) not between 1 and 100 or jsonb_typeof(section->'rows') is distinct from 'array' then raise exception '부서·팀 제목과 행 목록을 확인해 주세요.';end if;
  total=total+jsonb_array_length(section->'rows');
  if total>500 then raise exception '한 조직에 500행까지 등록할 수 있습니다.';end if;
  for member in select value from jsonb_array_elements(section->'rows') loop
   if jsonb_typeof(member)<>'object' or jsonb_typeof(member->'position') is distinct from 'string' or char_length(btrim(coalesce(member->>'position',''))) not between 1 and 100 or jsonb_typeof(member->'phone') is distinct from 'string' or char_length(member->>'phone')>100 or jsonb_typeof(member->'duties') is distinct from 'string' or char_length(member->>'duties')>3000 then raise exception '직위(100자), 전화번호(100자), 담당업무(3000자)를 확인해 주세요.';end if;
  end loop;
 end loop;
 if p_expected_version=0 then
  insert into public.geumseong_organization_directory(department,sections) values(p_department,p_sections) on conflict do nothing returning version into result;
 else
  update public.geumseong_organization_directory set sections=p_sections,version=version+1,updated_at=now() where department=p_department and version=p_expected_version returning version into result;
 end if;
 if result is null then raise exception '다른 관리자가 목록을 변경했습니다. 새로고침 후 다시 편집해 주세요.';end if;
 return result;
end $$;
revoke all on function public.geumseong_save_organization_directory(text,jsonb,integer) from public,anon;
grant execute on function public.geumseong_save_organization_directory(text,jsonb,integer) to authenticated;
commit;


-- community.sql
-- Run after schema.sql in the Supabase SQL Editor.
begin;
create extension if not exists pgcrypto with schema extensions;
create table if not exists public.geumseong_community_posts (
 id uuid primary key default gen_random_uuid(),
 board_type text not null check(board_type in ('free','praise','civil-board')),
 title text not null check(char_length(title) between 1 and 200),
 author_mask text not null,
 body_html text not null check(octet_length(body_html)<=1048576),
 attachments jsonb not null default '[]',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists geumseong_community_posts_date on public.geumseong_community_posts(board_type,created_at desc);
create table if not exists public.geumseong_community_private (
 post_id uuid primary key references public.geumseong_community_posts(id) on delete cascade,
 author_name text not null, identity_kind text not null check(identity_kind in ('naver','minecraft')),
 identity_value text not null, pin_hash text not null,
 failed_attempts integer not null default 0, blocked_until timestamptz
);
create table if not exists public.geumseong_community_edit_tokens (
 token_hash bytea primary key, post_id uuid not null references public.geumseong_community_posts(id) on delete cascade,
 expires_at timestamptz not null
);
alter table public.geumseong_community_posts enable row level security;
alter table public.geumseong_community_private enable row level security;
alter table public.geumseong_community_edit_tokens enable row level security;
revoke all on public.geumseong_community_posts,public.geumseong_community_private,public.geumseong_community_edit_tokens from anon,authenticated;
grant select on public.geumseong_community_posts to anon,authenticated;
grant select(post_id,author_name,identity_kind,identity_value) on public.geumseong_community_private to authenticated;
drop policy if exists geumseong_community_public_read on public.geumseong_community_posts;
create policy geumseong_community_public_read on public.geumseong_community_posts for select to anon,authenticated using(true);
drop policy if exists geumseong_community_admin_read on public.geumseong_community_private;
create policy geumseong_community_admin_read on public.geumseong_community_private for select to authenticated using((select public.is_news_admin()));

create or replace function public.geumseong_community_validate(p_title text,p_body text,p_assets jsonb) returns void
language plpgsql set search_path='' as $$
declare a jsonb;
begin
 if char_length(btrim(coalesce(p_title,''))) not between 1 and 200 or char_length(btrim(coalesce(p_body,'')))=0 or octet_length(p_body)>1048576 then raise exception '제목과 본문을 확인해 주세요.'; end if;
 if p_assets is null or jsonb_typeof(p_assets)<>'array' then raise exception '첨부파일 형식이 올바르지 않습니다.';end if;
 if jsonb_array_length(p_assets)>10 or octet_length(p_assets::text)>7340032 then raise exception '첨부파일은 10개, 전체 5MB 이내로 등록해 주세요.';end if;
 for a in select value from jsonb_array_elements(p_assets) loop
  if jsonb_typeof(a)<>'object' or char_length(coalesce(a->>'name','')) not between 1 and 200 or coalesce(a->>'name','') !~* '\.(hwp|hwpx|pdf|png|jpg|jpeg|webp|gif|txt|doc|docx|xls|xlsx|ppt|pptx|zip)$' or coalesce(a->>'data','') !~ '^data:[a-zA-Z0-9.+/-]+;base64,[A-Za-z0-9+/]*={0,2}$' or char_length(a->>'data')>2796500 then raise exception '지원하지 않는 첨부파일이거나 파일당 2MB를 초과했습니다.';end if;
 end loop;
end $$;
revoke all on function public.geumseong_community_validate(text,text,jsonb) from public,anon,authenticated;

create or replace function public.geumseong_community_create(p_board text,p_title text,p_author text,p_identity_kind text,p_identity text,p_pin text,p_body text,p_assets jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare new_id uuid;
begin
 perform public.geumseong_community_validate(p_title,p_body,p_assets);
 if p_board not in ('free','praise','civil-board') or p_author is null or char_length(btrim(p_author)) not between 1 and 40 or p_identity_kind not in ('naver','minecraft') or p_identity is null or char_length(btrim(p_identity)) not between 1 and 100 or p_pin is null or p_pin !~ '^[0-9]{4}$' then raise exception '작성자명, 네이버 아이디 또는 마인크래프트 닉네임, 4자리 비밀번호를 확인해 주세요.';end if;
 insert into public.geumseong_community_posts(board_type,title,author_mask,body_html,attachments) values(p_board,btrim(p_title),left(btrim(p_author),1)||repeat('*',greatest(char_length(btrim(p_author))-1,0)),p_body,p_assets) returning id into new_id;
 insert into public.geumseong_community_private(post_id,author_name,identity_kind,identity_value,pin_hash) values(new_id,btrim(p_author),p_identity_kind,btrim(p_identity),extensions.crypt(p_pin,extensions.gen_salt('bf',10)));
 return new_id;
end $$;

create or replace function public.geumseong_community_unlock(p_id uuid,p_pin text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare secret public.geumseong_community_private; token text; attempts integer;
begin
 select * into secret from public.geumseong_community_private where post_id=p_id for update;
 if not found then return jsonb_build_object('ok',false,'error','게시글을 찾을 수 없습니다.');end if;
 if not public.is_news_admin() then
  if secret.blocked_until>now() then return jsonb_build_object('ok',false,'error','인증 시도가 많습니다. 15분 후 다시 시도해 주세요.');end if;
  if p_pin is null or p_pin !~ '^[0-9]{4}$' or extensions.crypt(p_pin,secret.pin_hash)<>secret.pin_hash then
   attempts=case when secret.blocked_until is not null and secret.blocked_until<=now() then 1 else secret.failed_attempts+1 end;
   update public.geumseong_community_private set failed_attempts=attempts,blocked_until=case when attempts>=5 then now()+interval '15 minutes' else null end where post_id=p_id;
   return jsonb_build_object('ok',false,'error','비밀번호가 일치하지 않습니다. 5회 실패하면 15분간 제한됩니다.');
  end if;
 end if;
 update public.geumseong_community_private set failed_attempts=0,blocked_until=null where post_id=p_id;
 delete from public.geumseong_community_edit_tokens where expires_at<now();
 token=encode(extensions.gen_random_bytes(32),'hex');
 insert into public.geumseong_community_edit_tokens values(extensions.digest(token,'sha256'),p_id,now()+interval '30 minutes');
 return jsonb_build_object('ok',true,'token',token);
end $$;

create or replace function public.geumseong_community_save(p_id uuid,p_token text,p_title text,p_body text,p_assets jsonb) returns void
language plpgsql security definer set search_path='' as $$
begin
 -- Lock the post so token checks and modifications cannot race deletion.
 perform 1 from public.geumseong_community_posts where id=p_id for update;
 if not found then raise exception '게시글을 찾을 수 없습니다.';end if;
 if not public.is_news_admin() and not exists(select 1 from public.geumseong_community_edit_tokens where post_id=p_id and token_hash=extensions.digest(coalesce(p_token,''),'sha256') and expires_at>now()) then raise exception '비밀번호를 다시 확인해 주세요.';end if;
 perform public.geumseong_community_validate(p_title,p_body,p_assets);
 update public.geumseong_community_posts set title=btrim(p_title),body_html=p_body,attachments=p_assets,updated_at=now() where id=p_id;
end $$;
create or replace function public.geumseong_community_delete(p_id uuid,p_token text) returns void
language plpgsql security definer set search_path='' as $$
begin
 perform 1 from public.geumseong_community_posts where id=p_id for update;
 if not found then raise exception '게시글을 찾을 수 없습니다.';end if;
 if not public.is_news_admin() and not exists(select 1 from public.geumseong_community_edit_tokens where post_id=p_id and token_hash=extensions.digest(coalesce(p_token,''),'sha256') and expires_at>now()) then raise exception '비밀번호를 다시 확인해 주세요.';end if;
 delete from public.geumseong_community_posts where id=p_id;
end $$;
revoke all on function public.geumseong_community_create(text,text,text,text,text,text,text,jsonb),public.geumseong_community_unlock(uuid,text),public.geumseong_community_save(uuid,text,text,text,jsonb),public.geumseong_community_delete(uuid,text) from public;
grant execute on function public.geumseong_community_create(text,text,text,text,text,text,text,jsonb),public.geumseong_community_unlock(uuid,text),public.geumseong_community_save(uuid,text,text,text,jsonb),public.geumseong_community_delete(uuid,text) to anon,authenticated;
commit;


-- civil-board.sql
-- Run after supabase/community.sql. Safe to run again; existing posts are preserved.
begin;
alter table public.geumseong_community_posts drop constraint if exists community_posts_board_type_check;
alter table public.geumseong_community_posts add constraint community_posts_board_type_check check(board_type in ('free','praise','civil-board'));
create or replace function public.geumseong_community_create(p_board text,p_title text,p_author text,p_identity_kind text,p_identity text,p_pin text,p_body text,p_assets jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare new_id uuid;
begin
 perform public.geumseong_community_validate(p_title,p_body,p_assets);
 if p_board not in ('free','praise','civil-board') or p_author is null or char_length(btrim(p_author)) not between 1 and 40 or p_identity_kind not in ('naver','minecraft') or p_identity is null or char_length(btrim(p_identity)) not between 1 and 100 or p_pin is null or p_pin !~ '^[0-9]{4}$' then raise exception '작성자명, 네이버 아이디 또는 마인크래프트 닉네임, 4자리 비밀번호를 확인해 주세요.';end if;
 insert into public.geumseong_community_posts(board_type,title,author_mask,body_html,attachments) values(p_board,btrim(p_title),left(btrim(p_author),1)||repeat('*',greatest(char_length(btrim(p_author))-1,0)),p_body,p_assets) returning id into new_id;
 insert into public.geumseong_community_private(post_id,author_name,identity_kind,identity_value,pin_hash) values(new_id,btrim(p_author),p_identity_kind,btrim(p_identity),extensions.crypt(p_pin,extensions.gen_salt('bf',10)));
 return new_id;
end $$;


create table if not exists public.geumseong_civil_replies(
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.geumseong_community_posts(id) on delete cascade,
 department text not null check(char_length(btrim(department)) between 1 and 100),
 body text not null check(char_length(btrim(body)) between 1 and 10000),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists geumseong_civil_replies_post_date on public.geumseong_civil_replies(post_id,created_at,id);
alter table public.geumseong_civil_replies enable row level security;
revoke all on public.geumseong_civil_replies from anon,authenticated;
grant select on public.geumseong_civil_replies to anon,authenticated;
drop policy if exists geumseong_civil_replies_read on public.geumseong_civil_replies;
create policy geumseong_civil_replies_read on public.geumseong_civil_replies for select to anon,authenticated
 using(exists(select 1 from public.geumseong_community_posts p where p.id=post_id and p.board_type='civil-board'));
create or replace function public.geumseong_civil_reply_save(p_post_id uuid,p_reply_id uuid,p_department text,p_body text) returns uuid
language plpgsql security definer set search_path='' as $$
declare saved_id uuid;
begin
 if auth.uid() is null or not coalesce(public.is_news_admin(),false) then raise exception '관리자만 답변을 작성할 수 있습니다.';end if;
 perform 1 from public.geumseong_community_posts where id=p_post_id and board_type='civil-board' for update;
 if not found then raise exception '민원 게시글을 찾을 수 없습니다.';end if;
 if p_department is null or char_length(btrim(p_department)) not between 1 and 100 or p_body is null or char_length(btrim(p_body)) not between 1 and 10000 then raise exception '담당 부서와 답변 내용을 확인해 주세요.';end if;
 if p_reply_id is null then
  insert into public.geumseong_civil_replies(post_id,department,body) values(p_post_id,btrim(p_department),btrim(p_body)) returning id into saved_id;
 else
  update public.geumseong_civil_replies set department=btrim(p_department),body=btrim(p_body),updated_at=now() where id=p_reply_id and post_id=p_post_id returning id into saved_id;
  if not found then raise exception '답변을 찾을 수 없습니다.';end if;
 end if;
 return saved_id;
end $$;
create or replace function public.geumseong_civil_reply_delete(p_post_id uuid,p_reply_id uuid) returns void
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not coalesce(public.is_news_admin(),false) then raise exception '관리자만 답변을 삭제할 수 있습니다.';end if;
 perform 1 from public.geumseong_community_posts where id=p_post_id and board_type='civil-board' for update;
 if not found then raise exception '민원 게시글을 찾을 수 없습니다.';end if;
 delete from public.geumseong_civil_replies where id=p_reply_id and post_id=p_post_id;
 if not found then raise exception '답변을 찾을 수 없습니다.';end if;
end $$;
revoke all on function public.geumseong_civil_reply_save(uuid,uuid,text,text),public.geumseong_civil_reply_delete(uuid,uuid) from public,anon,authenticated;
grant execute on function public.geumseong_civil_reply_save(uuid,uuid,text,text),public.geumseong_civil_reply_delete(uuid,uuid) to authenticated;
commit;


-- activity.sql
-- Run after supabase/publications.sql. Existing publications are preserved.
begin;
alter table public.geumseong_publication_posts drop constraint if exists publication_posts_board_type_check;
alter table public.geumseong_publication_posts add constraint publication_posts_board_type_check check(board_type in ('gazette','press','briefing','facts','activity','media'));
commit;


-- media-articles.sql
-- Run after publications.sql; preserves all existing posts and permissions.
begin;
alter table public.geumseong_publication_posts drop constraint if exists publication_posts_board_type_check;
alter table public.geumseong_publication_posts add constraint publication_posts_board_type_check check(board_type in ('gazette','press','briefing','facts','activity','media'));
commit;
