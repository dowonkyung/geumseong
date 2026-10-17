-- Run once in the shared Supabase SQL Editor. Safe to rerun; numbers are never recycled.
begin;
create table if not exists public.post_route_counters (
 site text not null, board text not null, next_number bigint not null default 1 check(next_number>0),
 primary key(site,board)
);
create table if not exists public.post_route_numbers (
 site text not null, board text not null, post_id uuid not null, number bigint not null check(number>0),
 source_table text, active boolean not null default false,
 primary key(site,board,post_id), unique(site,board,number)
);
alter table public.post_route_counters enable row level security;
alter table public.post_route_numbers enable row level security;
revoke all on public.post_route_counters, public.post_route_numbers from anon, authenticated;
create or replace function public.assign_post_route(p_site text,p_board text,p_id uuid,p_table text,p_active boolean)
returns void language plpgsql security definer set search_path=pg_catalog,public as $$
declare n bigint;
begin
 insert into public.post_route_counters(site,board) values(p_site,p_board) on conflict do nothing;
 perform 1 from public.post_route_counters where site=p_site and board=p_board for update;
 select number into n from public.post_route_numbers where site=p_site and board=p_board and post_id=p_id;
 if n is null and p_active then
  update public.post_route_counters set next_number=next_number+1 where site=p_site and board=p_board returning next_number-1 into n;
  insert into public.post_route_numbers(site,board,post_id,number,source_table,active) values(p_site,p_board,p_id,n,p_table,true);
 elsif n is not null then
  update public.post_route_numbers set active=p_active,source_table=p_table where site=p_site and board=p_board and post_id=p_id;
 end if;
end $$;
revoke all on function public.assign_post_route(text,text,uuid,text,boolean) from public,anon,authenticated;
create or replace function public.post_route_trigger()
returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$
declare rowdata jsonb; b text;
begin
 rowdata:=case when TG_OP='DELETE' then to_jsonb(OLD) else to_jsonb(NEW) end;
 b:=coalesce(nullif(TG_ARGV[1],''),rowdata->>'board_type');
 if TG_OP='UPDATE' and OLD.id<>NEW.id then raise exception 'Post identifiers cannot change'; end if;
 if TG_OP='UPDATE' and (to_jsonb(OLD)->>'board_type') is distinct from (rowdata->>'board_type') then
  perform public.assign_post_route(TG_ARGV[0],to_jsonb(OLD)->>'board_type',OLD.id,TG_TABLE_NAME,false);
 end if;
 perform public.assign_post_route(TG_ARGV[0],b,(rowdata->>'id')::uuid,TG_TABLE_NAME,
 TG_OP<>'DELETE' and coalesce(rowdata->>'status','published')='published');
 if TG_OP='DELETE' then return OLD; else return NEW; end if;
end $$;
revoke all on function public.post_route_trigger() from public,anon,authenticated;
-- Lock source tables before importing existing URLs and assigning new ones.
do $$ declare s text; t text; begin
 foreach s in array array['','geumseong_'] loop
 foreach t in array array['news_posts','notice_posts','publication_posts','photo_posts','community_posts','video_posts'] loop
 if to_regclass('public.'||s||t) is not null then execute format('lock table public.%I in share row exclusive mode',s||t); end if;
 end loop; end loop;
end $$;
insert into public.post_route_counters values('angangjin','news',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','notice',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','bid',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','legislation',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','general',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','gazette',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','press',2) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_numbers(site,board,post_id,number) values('angangjin','press','37cd191f-b946-47f2-a3d7-dbc292a7f064',1) on conflict(site,board,post_id) do nothing;
insert into public.post_route_counters values('angangjin','briefing',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','facts',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','activity',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','media',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','photo',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','video',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','free',2) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_numbers(site,board,post_id,number) values('angangjin','free','b1fd05ca-4a41-46a4-b9f5-f0f0acceeed8',1) on conflict(site,board,post_id) do nothing;
insert into public.post_route_counters values('angangjin','praise',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('angangjin','civil-board',4) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_numbers(site,board,post_id,number) values('angangjin','civil-board','34fe7af0-90e8-456d-9f05-38aad9aa1ffa',1) on conflict(site,board,post_id) do nothing;
insert into public.post_route_numbers(site,board,post_id,number) values('angangjin','civil-board','da094d1b-53a2-437a-9d96-5065143d3de4',2) on conflict(site,board,post_id) do nothing;
insert into public.post_route_numbers(site,board,post_id,number) values('angangjin','civil-board','31d1ff81-5839-47eb-9feb-b350531d4b96',3) on conflict(site,board,post_id) do nothing;
insert into public.post_route_counters values('geumseong','news',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','notice',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','bid',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','legislation',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','general',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','gazette',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','press',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','briefing',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','facts',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','activity',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','media',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','photo',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','video',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','free',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','praise',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_counters values('geumseong','civil-board',1) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);

insert into public.post_route_counters values('angangjin','press',3) on conflict(site,board) do update set next_number=greatest(post_route_counters.next_number,excluded.next_number);
insert into public.post_route_numbers(site,board,post_id,number) values('angangjin','press','97294eef-c534-4a21-aa09-c1ae9bba938c',2) on conflict(site,board,post_id) do nothing;
do $ declare s text; t text; site_name text; fixed_board text; r record; begin
 foreach s in array array['','geumseong_'] loop
 site_name:=case when s='' then 'angangjin' else 'geumseong' end;
 foreach t in array array['news_posts','notice_posts','publication_posts','photo_posts','community_posts','video_posts'] loop
 if to_regclass('public.'||s||t) is null then continue; end if;
 fixed_board:=case t when 'news_posts' then 'news' when 'photo_posts' then 'photo' when 'video_posts' then 'video' else '' end;
 execute format('drop trigger if exists post_route_number on public.%I',s||t);
 execute format('create trigger post_route_number after insert or update or delete on public.%I for each row execute function public.post_route_trigger(%L,%L)',s||t,site_name,fixed_board);
 for r in execute format('select to_jsonb(p) as j from public.%I p order by created_at,id',s||t) loop
 perform public.assign_post_route(site_name,coalesce(nullif(fixed_board,''),r.j->>'board_type'),(r.j->>'id')::uuid,s||t,coalesce(r.j->>'status','published')='published');
 end loop;
 end loop; end loop;
end $$;
-- This public function exposes only identifiers of published posts, never private author information.
create or replace function public.public_post_routes(p_site text)
returns table(board text,post_id uuid,number bigint)
language sql stable security definer set search_path=pg_catalog,public
as $$ select n.board,n.post_id,n.number from public.post_route_numbers n
where n.site=p_site and n.active order by n.board,n.number $$;
revoke all on function public.public_post_routes(text) from public;
grant execute on function public.public_post_routes(text) to anon,authenticated;
notify pgrst,'reload schema';
commit;
