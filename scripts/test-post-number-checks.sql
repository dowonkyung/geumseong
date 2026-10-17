do $$ declare first_id uuid:=gen_random_uuid(); second_id uuid:=gen_random_uuid(); n bigint;begin
 insert into publication_posts(id,board_type,status) values(first_id,'press','draft');
 if exists(select 1 from post_route_numbers where post_id=first_id) then raise exception 'Draft consumed number';end if;
 update publication_posts set status='published' where id=first_id;
 select number into n from post_route_numbers where post_id=first_id;
 if n<>2 then raise exception 'Existing press number was not preserved: %',n;end if;
 delete from publication_posts where id=first_id;
 insert into publication_posts(id,board_type) values(second_id,'press');
 if (select number from post_route_numbers where post_id=second_id)<>3 then raise exception 'Deleted number reused';end if;
 if exists(select 1 from public_post_routes('angangjin') where post_id=first_id) then raise exception 'Deleted post exposed';end if;
 insert into geumseong_publication_posts(board_type) values('press');
 if (select min(number) from public_post_routes('geumseong') where board='press')<>1 then raise exception 'Sites share counters';end if;
end $$;
set role anon;
select * from public_post_routes('angangjin');
reset role;
do $$begin
 if has_table_privilege('anon','post_route_numbers','select') or has_function_privilege('anon','assign_post_route(text,text,uuid,text,boolean)','execute') then raise exception 'Private allocation permissions exposed';end if;
end $$;
