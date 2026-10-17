create role anon; create role authenticated;
do $$ declare s text;t text;begin
foreach s in array array['','geumseong_'] loop
foreach t in array array['news_posts','notice_posts','publication_posts','photo_posts','community_posts','video_posts'] loop
execute format('create table public.%I(id uuid primary key default gen_random_uuid(),created_at timestamptz default now(),board_type text,status text default ''published'')',s||t);
end loop;end loop;end $$;
