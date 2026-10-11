-- CSA-081: deterministic, synthetic marketplace metadata for LOCAL development.
-- Never run this seed against production. No accounts, roles, payment evidence,
-- entitlements, private media references or lesson bodies are installed.
-- Dedicated IDs and do-nothing conflicts preserve local edits on repeat resets.
begin;
insert into public.categories(id,name,slug,description,sort_order,is_active) values
 ('08100000-0000-0000-0000-000000000001','Synthetic development','synthetic-development','Synthetic catalog category; no real students or instructors.',0,true),
 ('08100000-0000-0000-0000-000000000002','Synthetic inactive','synthetic-inactive','Inactive category for local empty-state checks.',1,false)
on conflict do nothing;
insert into public.courses(id,category_id,slug,title,short_description,description,price_minor,currency_code,status,published_at) values
 ('08100000-0000-0000-0000-000000000011','08100000-0000-0000-0000-000000000001','synthetic-published-course','Synthetic published course','Development catalog fixture','Synthetic public marketing description.',125000,'LKR','published','2026-10-11T00:00:00Z'),
 ('08100000-0000-0000-0000-000000000012','08100000-0000-0000-0000-000000000001','synthetic-draft-course','Synthetic draft course','Must remain hidden','Synthetic draft metadata.',0,'LKR','draft',null),
 ('08100000-0000-0000-0000-000000000013','08100000-0000-0000-0000-000000000001','synthetic-archived-course','Synthetic archived course','Must remain hidden','Synthetic archived metadata.',250000,'LKR','archived','2026-10-11T00:00:00Z')
on conflict do nothing;
insert into public.course_sections(id,course_id,title,position,is_published) values
 ('08100000-0000-0000-0000-000000000021','08100000-0000-0000-0000-000000000011','Synthetic published curriculum',0,true),
 ('08100000-0000-0000-0000-000000000022','08100000-0000-0000-0000-000000000011','Synthetic hidden curriculum',1,false),
 ('08100000-0000-0000-0000-000000000023','08100000-0000-0000-0000-000000000012','Synthetic draft parent curriculum',0,true),
 ('08100000-0000-0000-0000-000000000024','08100000-0000-0000-0000-000000000013','Synthetic archived parent curriculum',0,true)
on conflict do nothing;
insert into public.lessons(id,section_id,title,lesson_type,position,duration_seconds,is_preview,is_published) values
 ('08100000-0000-0000-0000-000000000031','08100000-0000-0000-0000-000000000021','Synthetic video metadata','video',0,120,true,true),
 ('08100000-0000-0000-0000-000000000032','08100000-0000-0000-0000-000000000021','Synthetic PDF metadata','pdf',1,null,false,true),
 ('08100000-0000-0000-0000-000000000033','08100000-0000-0000-0000-000000000021','Synthetic hidden lesson','text',2,null,false,false),
 ('08100000-0000-0000-0000-000000000034','08100000-0000-0000-0000-000000000022','Synthetic hidden section lesson','image',0,null,false,true),
 ('08100000-0000-0000-0000-000000000035','08100000-0000-0000-0000-000000000023','Synthetic draft course lesson','text',0,null,false,true),
 ('08100000-0000-0000-0000-000000000036','08100000-0000-0000-0000-000000000024','Synthetic archived course lesson','text',0,null,false,true)
on conflict do nothing;
commit;
