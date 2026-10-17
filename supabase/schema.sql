-- Run once in the Supabase SQL Editor. Safe to rerun for this initial schema.
create table if not exists public.news_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.news_admins enable row level security;
revoke all on public.news_admins from anon, authenticated;
grant select on public.news_admins to authenticated;
drop policy if exists news_admins_self on public.news_admins;
create policy news_admins_self on public.news_admins for select to authenticated using (user_id=(select auth.uid()));

create or replace function public.is_news_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.news_admins where user_id=(select auth.uid()));
$$;
revoke all on function public.is_news_admin() from public;
grant execute on function public.is_news_admin() to anon, authenticated;

create table if not exists public.news_posts (
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
create index if not exists news_posts_published_date on public.news_posts(status,created_at desc);
alter table public.news_posts enable row level security;
grant select on public.news_posts to anon, authenticated;
grant insert, update, delete on public.news_posts to authenticated;
drop policy if exists news_posts_read on public.news_posts;
drop policy if exists news_posts_insert on public.news_posts;
drop policy if exists news_posts_update on public.news_posts;
drop policy if exists news_posts_delete on public.news_posts;
create policy news_posts_read on public.news_posts for select to anon,authenticated using (status='published' or (select public.is_news_admin()));
create policy news_posts_insert on public.news_posts for insert to authenticated with check ((select public.is_news_admin()) and author_id=(select auth.uid()));
create policy news_posts_update on public.news_posts for update to authenticated using ((select public.is_news_admin())) with check ((select public.is_news_admin()));
create policy news_posts_delete on public.news_posts for delete to authenticated using ((select public.is_news_admin()));

create table if not exists public.news_assets (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.news_posts(id) on delete cascade,
  file_name text not null,
  storage_path text not null unique,
  mime text not null default 'application/octet-stream',
  size bigint not null check (size>=0 and size<=20971520),
  kind text not null check (kind in ('attachment','inline','preview')),
  preview_path text,
  created_at timestamptz not null default now()
);
create index if not exists news_assets_post on public.news_assets(post_id);
alter table public.news_assets enable row level security;
grant select on public.news_assets to anon, authenticated;
grant insert, update, delete on public.news_assets to authenticated;
drop policy if exists news_assets_read on public.news_assets;
drop policy if exists news_assets_write on public.news_assets;
create policy news_assets_read on public.news_assets for select to anon,authenticated using (
  (select public.is_news_admin()) or exists(select 1 from public.news_posts p where p.id=post_id and p.status='published')
);
create policy news_assets_write on public.news_assets for all to authenticated using ((select public.is_news_admin())) with check ((select public.is_news_admin()));

insert into storage.buckets(id,name,public,file_size_limit) values ('news-files','news-files',false,20971520)
on conflict (id) do update set public=false,file_size_limit=20971520;
drop policy if exists news_files_read on storage.objects;
drop policy if exists news_files_insert on storage.objects;
drop policy if exists news_files_delete on storage.objects;
create policy news_files_read on storage.objects for select to anon,authenticated using (
  bucket_id='news-files' and ((select public.is_news_admin()) or exists (
    select 1 from public.news_assets a join public.news_posts p on p.id=a.post_id
    where a.storage_path=name and p.status='published'
  ))
);
create policy news_files_insert on storage.objects for insert to authenticated with check (
  bucket_id='news-files' and (select public.is_news_admin()) and split_part(name,'/',1)=(select auth.uid())::text
);
create policy news_files_delete on storage.objects for delete to authenticated using (bucket_id='news-files' and (select public.is_news_admin()));

create or replace function public.record_news_view(post_uuid uuid) returns integer
language plpgsql security definer set search_path = '' as $$
declare result integer;
begin
  update public.news_posts set views=views+1 where id=post_uuid and status='published' returning views into result;
  return result;
end;
$$;
revoke all on function public.record_news_view(uuid) from public;
grant execute on function public.record_news_view(uuid) to anon,authenticated;

-- After creating the admin account in Authentication > Users, run this separately:
-- insert into public.news_admins(user_id) values ('ADMIN-USER-UUID') on conflict do nothing;
