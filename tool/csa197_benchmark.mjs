import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createLayout, pinLocalDockerEndpoint } from './local_supabase.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export function samplesSummary(samples) {
  if (!samples.length || samples.some(x => !Number.isFinite(x) || x < 0)) throw new Error('Invalid timing samples');
  const sorted = [...samples].sort((a,b) => a-b);
  const middle = Math.floor(sorted.length / 2);
  return { count: sorted.length, median_ms: sorted.length % 2 ? sorted[middle] : (sorted[middle-1]+sorted[middle])/2,
    p95_ms: sorted[Math.ceil(sorted.length*0.95)-1] };
}
export function nativeTarget(env) {
  if (env.CSA197_DISPOSABLE !== 'csa197_benchmark' || env.CSA197_DATABASE !== 'csa197_benchmark') {
    throw new Error('Native mode requires the explicitly acknowledged csa197_benchmark disposable database');
  }
  if (!/^\d{4,5}$/.test(env.CSA197_PORT ?? '') || +env.CSA197_PORT < 1024 || +env.CSA197_PORT > 65535) throw new Error('Invalid local port');
  return ['-h','127.0.0.1','-p',env.CSA197_PORT,'-U','postgres','-d','csa197_benchmark'];
}
export function fixtureSQL() {
  return `begin;
set local statement_timeout='120s';
insert into auth.users(id,email) select md5('csa197-user-'||n)::uuid,'csa197-'||n||'@example.invalid' from generate_series(1,1000) n;
insert into public.profiles(id,display_name) select md5('csa197-user-'||n)::uuid,'Synthetic benchmark '||n from generate_series(1,1000) n on conflict(id) do nothing;
insert into public.courses(id,slug,title,price_minor,status,published_at)
 select md5('csa197-course-'||n)::uuid,'csa197-course-'||n,'Synthetic course '||n,10000,
 case when n%5=0 then 'draft' else 'published' end,case when n%5=0 then null else now()-n*interval '1 minute' end from generate_series(1,10000) n;
insert into public.orders(id,order_number,buyer_id,course_id,course_title_snapshot,amount_minor,currency_code,payment_method)
 select md5('csa197-order-'||n)::uuid,'CSA197-'||n,md5('csa197-user-'||(1+(n-1)%1000))::uuid,
 md5('csa197-course-'||(1+(n-1)%10000))::uuid,'Synthetic',10000,'LKR','online' from generate_series(1,100000) n;
insert into public.enrollments(id,user_id,course_id,status,granted_at)
 select md5('csa197-enrollment-'||n)::uuid,md5('csa197-user-'||(1+(n-1)%1000))::uuid,
 md5('csa197-course-'||n)::uuid,'active',now() from generate_series(1,10000) n;
analyze public.courses; analyze public.orders; analyze public.enrollments; analyze public.profiles; analyze auth.users;
select set_config('request.jwt.claim.sub',md5('csa197-user-1')::uuid::text,true);
select set_config('request.jwt.claims',json_build_object('sub',md5('csa197-user-1')::uuid::text,'role','authenticated')::text,true);
set local role authenticated;
set local row_security=on;
`;
}
const queries = {
  catalog: "select id,title,price_minor from public.courses where status='published' order by published_at desc,id limit 24",
  orders: 'select id,status,amount_minor from public.orders where buyer_id=(select auth.uid()) order by created_at desc,id limit 25',
  enrollments: "select id,course_id,status from public.enrollments where user_id=(select auth.uid()) and status='active' order by id limit 25",
};
export function benchmarkSQL() {
  let sql = fixtureSQL();
  sql += `do $$ begin
    if current_user <> 'authenticated' then raise exception 'RLS role missing'; end if;
    if (select count(*) from public.orders) <> 100 then raise exception 'Own orders visibility mismatch'; end if;
    if (select count(*) from public.orders where buyer_id<>auth.uid()) <> 0 then raise exception 'Cross-user order exposure'; end if;
    if (select count(*) from public.enrollments) <> 10 then raise exception 'Own enrollment visibility mismatch'; end if;
    if (select count(*) from public.courses where status='draft') <> 0 then raise exception 'Draft catalog exposure'; end if;
  end $$;
`;
  for (const [name, query] of Object.entries(queries)) {
    // First sample is a warm-up; retain its plan but exclude from summaries.
    for (let i=0;i<21;i++) sql += `\\echo CSA197:${name}:${i}\nEXPLAIN (ANALYZE,BUFFERS,FORMAT JSON) ${query};\n`;
  }
  return sql+'rollback;\n';
}
export function parseMeasurements(output) {
  const results = {};
  for (const [name] of Object.entries(queries)) {
    const blocks = [...output.matchAll(new RegExp(`CSA197:${name}:(\\d+)\\r?\\n([\\s\\S]*?)(?=CSA197:|$)`, 'g'))];
    if (blocks.length !== 21) throw new Error('Incomplete benchmark output');
    const plans = blocks.map(block => JSON.parse(block[2].trim())[0]);
    results[name] = { ...samplesSummary(plans.slice(1).map(plan => plan['Execution Time'])),
      planning: samplesSummary(plans.slice(1).map(plan => plan['Planning Time'])), plan: plans[1].Plan };
  }
  return results;
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const env = {...process.env};
    // Do not inherit libpq service, options, credentials or hosted defaults.
    for (const key of Object.keys(env)) if (key.startsWith('PG') || key.startsWith('SUPABASE_')) delete env[key];
    let executable, args;
    if (env.CSA197_NATIVE === '1') {
      executable = env.CSA197_PSQL || 'psql'; args = nativeTarget(env);
    } else {
      const dockerDir='C:/Program Files/Docker/Docker/resources/bin';
      if (process.platform==='win32' && fs.existsSync(dockerDir)) {
        env.PATH=dockerDir+path.delimiter+(env.PATH||env.Path||''); delete env.Path;
      }
      executable=process.platform==='win32'?'docker.exe':'docker';
      const call=a=>spawnSync(executable,a,{env,encoding:'utf8',timeout:20000});
      pinLocalDockerEndpoint(env,call);
      const layout=createLayout(root,'test',env.ACENDRA_LOCAL_PORT_BASE);
      const found=call(['ps','-q','--filter',`name=^/supabase_db_${layout.projectId}$`]);
      const id=found.stdout?.trim();
      if(found.status!==0 || !/^[a-f0-9]{12,64}$/.test(id??'')) throw new Error('Task-owned local test database is unavailable');
      args=['exec','-i',id,'psql','-U','postgres','-d','postgres'];
    }
    const result=spawnSync(executable,[...args,'-X','-v','ON_ERROR_STOP=1','-qAt'],{
      env,input:benchmarkSQL(),encoding:'utf8',timeout:180000,maxBuffer:16*1024*1024});
    if(result.status!==0) throw new Error('Benchmark database execution failed; no measurements accepted');
    const report={dataset:{users:1000,courses:10000,orders:100000,enrollments:10000},role:'authenticated',
      concurrency:1,warmup:1,samples:20,mode:env.CSA197_NATIVE==='1'?'native PostgreSQL with Auth/Storage shims':'local Supabase',
      timestamp:new Date().toISOString(),results:parseMeasurements(result.stdout)};
    fs.mkdirSync(path.join(root,'build'),{recursive:true});
    fs.writeFileSync(path.join(root,'build','csa197-results.json'),JSON.stringify(report,null,2)+'\n');
    console.log(JSON.stringify({...report,results:Object.fromEntries(Object.entries(report.results).map(([name,{plan,...metrics}])=>[name,metrics]))},null,2));
  } catch(error) { console.error(error.message); process.exitCode=1; }
}
