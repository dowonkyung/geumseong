insert into auth.users(id,email,raw_user_meta_data) values
('11111111-1111-1111-1111-111111111111','one@example.test','{"display_name":"첫 회원","status":"approved","admin":true}'),
('22222222-2222-2222-2222-222222222222','two@example.test','{"display_name":"둘째"}');
do $$begin
 if (select status from membership_requests where user_id='11111111-1111-1111-1111-111111111111')<>'pending' then raise exception 'Untrusted metadata approved member';end if;
 if (select count(*) from news_admins)<>1 then raise exception 'Signup granted admin';end if;
end $$;
set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
do $$begin
 if (select count(*) from public.membership_requests)<>1 then raise exception 'Applicant can read other applicants';end if;
 if public.is_approved_member() then raise exception 'Pending user accepted';end if;
 begin
 perform public.review_membership('11111111-1111-1111-1111-111111111111','approved','pending');
 raise exception 'Applicant self-approved';
 exception when insufficient_privilege then null;end;
 begin
 update public.membership_requests set status='approved';
 raise exception 'Applicant directly approved';
 exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',false);
do $$begin
 if (select count(*) from public.membership_requests)<>3 then raise exception 'Admin cannot view applications';end if;
end $$;
select public.review_membership('11111111-1111-1111-1111-111111111111','approved','pending');
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
do $$begin
 if not public.is_approved_member() then raise exception 'Approved user blocked';end if;
 if public.is_news_admin() then raise exception 'Member became admin';end if;
end $$;
select set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',false);
select public.review_membership('11111111-1111-1111-1111-111111111111','rejected','approved');
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
do $$begin if public.is_approved_member() then raise exception 'Rejected member accepted';end if;end $$;
reset role;
update auth.users set email='changed@example.test' where id='11111111-1111-1111-1111-111111111111';
do $$begin
 if (select email from membership_requests where user_id='11111111-1111-1111-1111-111111111111')<>'changed@example.test' then raise exception 'Email did not synchronize';end if;
end $$;
set role anon;
select public.membership_ready();
do $$begin
 begin
 perform * from public.membership_requests;raise exception 'Anonymous list exposed';
 exception when insufficient_privilege then null;end;
end $$;
reset role;
