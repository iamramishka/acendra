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
-- Sample published catalog for manual testing (marketplace, course details, checkout).
-- Metadata only: no media, PDFs or lesson bodies. IDs use the 0810...004x-007x block.
insert into public.categories(id,name,slug,description,sort_order,is_active) values
 ('08100000-0000-0000-0000-000000000003','Sample programming','sample-programming','Sample programming courses for local testing.',2,true),
 ('08100000-0000-0000-0000-000000000004','Sample business','sample-business','Sample business courses for local testing.',3,true)
on conflict do nothing;
insert into public.courses(id,category_id,slug,title,short_description,description,price_minor,currency_code,status,published_at) values
 ('08100000-0000-0000-0000-000000000041','08100000-0000-0000-0000-000000000003','sample-flutter-web-basics','Flutter Web Basics','Build your first responsive Flutter web app','Sample course: widgets, layout, state and navigation for the web. Synthetic content for local testing.',450000,'LKR','published','2026-10-12T00:00:00Z'),
 ('08100000-0000-0000-0000-000000000042','08100000-0000-0000-0000-000000000003','sample-sql-for-beginners','SQL for Beginners','Query and design relational data with confidence','Sample course: SELECT, joins, grouping and table design. Synthetic content for local testing.',275000,'LKR','published','2026-10-13T00:00:00Z'),
 ('08100000-0000-0000-0000-000000000043','08100000-0000-0000-0000-000000000004','sample-intro-to-marketing','Introduction to Marketing','Free starter course on marketing fundamentals','Sample free course (price 0): audience, positioning and channels. Synthetic content for local testing.',0,'LKR','published','2026-10-14T00:00:00Z')
on conflict do nothing;
insert into public.course_sections(id,course_id,title,description,position,is_published) values
 ('08100000-0000-0000-0000-000000000051','08100000-0000-0000-0000-000000000041','Getting started','Setup and first app',0,true),
 ('08100000-0000-0000-0000-000000000052','08100000-0000-0000-0000-000000000041','Layouts and state','Responsive layout and Riverpod basics',1,true),
 ('08100000-0000-0000-0000-000000000053','08100000-0000-0000-0000-000000000042','Querying data','SELECT, WHERE and joins',0,true),
 ('08100000-0000-0000-0000-000000000054','08100000-0000-0000-0000-000000000042','Designing tables','Keys, constraints and indexes',1,true),
 ('08100000-0000-0000-0000-000000000055','08100000-0000-0000-0000-000000000043','Marketing foundations','Audience and positioning',0,true)
on conflict do nothing;
insert into public.lessons(id,section_id,title,description,lesson_type,position,duration_seconds,is_preview,is_published) values
 ('08100000-0000-0000-0000-000000000061','08100000-0000-0000-0000-000000000051','Welcome and tooling','Course overview','video',0,300,true,true),
 ('08100000-0000-0000-0000-000000000062','08100000-0000-0000-0000-000000000051','Your first widget','Build a hello-world screen','video',1,840,false,true),
 ('08100000-0000-0000-0000-000000000063','08100000-0000-0000-0000-000000000052','Responsive layouts','Breakpoints and adaptive widgets','video',0,1080,false,true),
 ('08100000-0000-0000-0000-000000000064','08100000-0000-0000-0000-000000000052','Layout cheat sheet','Printable reference','pdf',1,null,false,true),
 ('08100000-0000-0000-0000-000000000065','08100000-0000-0000-0000-000000000053','Your first SELECT','Reading rows from a table','video',0,600,true,true),
 ('08100000-0000-0000-0000-000000000066','08100000-0000-0000-0000-000000000053','Joins explained','Inner and outer joins','text',1,null,false,true),
 ('08100000-0000-0000-0000-000000000067','08100000-0000-0000-0000-000000000054','Keys and constraints','Primary and foreign keys','video',0,720,false,true),
 ('08100000-0000-0000-0000-000000000068','08100000-0000-0000-0000-000000000054','Schema diagram','Sample entity diagram','image',1,null,false,true),
 ('08100000-0000-0000-0000-000000000069','08100000-0000-0000-0000-000000000055','What is marketing?','Core concepts','video',0,420,true,true),
 ('08100000-0000-0000-0000-00000000006a','08100000-0000-0000-0000-000000000055','Positioning worksheet','Exercise handout','pdf',1,null,false,true)
on conflict do nothing;
-- Local dev seed: test student enrollments so My Courses screen is non-empty.
-- Login:  student@acendra.local / Student1
-- NEVER run against production.
begin;
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
) values (
  '00000000-0000-0000-0000-000000000000',
  '08100000-0000-0000-0001-000000000001',
  'authenticated', 'authenticated', 'student@acendra.local',
  '$2b$10$bIuECIe7/J7P0nRDPRGpPORHiNaONLMOUTdBBvgyForWl2IxiVuIi',
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Sample Student"}',
  now(), now(), '', '', '', ''
), (
  '00000000-0000-0000-0000-000000000000',
  '08100000-0000-0000-0001-000000000002',
  'authenticated', 'authenticated', 'granter@acendra.local',
  '$2b$10$bIuECIe7/J7P0nRDPRGpPORHiNaONLMOUTdBBvgyForWl2IxiVuIi',
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Seed Granter"}',
  now(), now(), '', '', '', ''
) on conflict do nothing;
-- profiles auto-created by csa060_auth_signup_profile trigger on auth.users insert
insert into public.enrollments (id, user_id, course_id, status, granted_at) values
  ('08100000-0000-0000-0002-000000000001','08100000-0000-0000-0001-000000000001','08100000-0000-0000-0000-000000000041','active',now()),
  ('08100000-0000-0000-0002-000000000002','08100000-0000-0000-0001-000000000001','08100000-0000-0000-0000-000000000042','active',now()),
  ('08100000-0000-0000-0002-000000000003','08100000-0000-0000-0001-000000000001','08100000-0000-0000-0000-000000000043','active',now())
on conflict do nothing;
insert into public.enrollment_grants (id, enrollment_id, user_id, course_id, source_type, granted_by, reason, valid_from) values
  ('08100000-0000-0000-0003-000000000001','08100000-0000-0000-0002-000000000001','08100000-0000-0000-0001-000000000001','08100000-0000-0000-0000-000000000041','admin_grant','08100000-0000-0000-0001-000000000002','Local development seed enrollment',now()),
  ('08100000-0000-0000-0003-000000000002','08100000-0000-0000-0002-000000000002','08100000-0000-0000-0001-000000000001','08100000-0000-0000-0000-000000000042','admin_grant','08100000-0000-0000-0001-000000000002','Local development seed enrollment',now()),
  ('08100000-0000-0000-0003-000000000003','08100000-0000-0000-0002-000000000003','08100000-0000-0000-0001-000000000001','08100000-0000-0000-0000-000000000043','admin_grant','08100000-0000-0000-0001-000000000002','Local development seed enrollment',now())
on conflict do nothing;
commit;
