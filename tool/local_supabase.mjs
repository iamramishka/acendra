import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const commands = ['prepare', 'start', 'stop', 'status', 'reset', 'test', 'lint', 'client-env'];

// Hosted diagnostics expose identifiers/categories, never raw SQL or messages.
export function safeLintSummary(output, knownFunctions) {
  let rows;
  try { rows = JSON.parse(output); } catch { return ''; }
  if (!Array.isArray(rows)) return '';
  const summaries = [];
  for (const row of rows) {
    if (!knownFunctions.has(row?.function) || !Array.isArray(row.issues)) continue;
    for (const issue of row.issues) {
      if (!['warning', 'error'].includes(issue?.level)) continue;
      const state = /^[A-Z0-9]{5}$/.test(issue.sqlState ?? '') ? issue.sqlState : 'unknown';
      const description = `${issue.message ?? ''} ${issue.detail ?? ''}`;
      const category = /unused|never read/i.test(description) ? 'unused_identifier'
        : /ambiguous/i.test(description) ? 'ambiguous_identifier' : 'other';
      const location = issue.lineNumber ?? issue.line ?? issue.lineno;
      const line = Number.isInteger(location) && location > 0 ? `:line${location}` : '';
      const type = /type|cast|convert|assign/i.test(description) ? ':type_assignment' : '';
      const staticWords = description.match(/\b(?:text|uuid|jsonb|record|row|composite|varchar|character|varying|numeric|integer|boolean|bigint|null|unknown|cast|assignment|target|source|type)\b/gi)?.join('_') ?? '';
      summaries.push(`${row.function}:${issue.level}:${state}:${category}${line}${type}${staticWords ? `:${staticWords}` : ''}`);
    }
  }
  return summaries.slice(0, 20).join(',');
}

export function allowedCommand(command) {
  if (!commands.includes(command)) throw new Error('Unsupported local command. No hosted operations are available.');
  return command;
}

export function createLayout(worktree, profile, override) {
  if (!['dev', 'test'].includes(profile)) throw new Error('Profile must be dev or test.');
  const identity = process.platform === 'win32' ? path.resolve(worktree).toLowerCase() : path.resolve(worktree);
  const id = createHash('sha256').update(identity).digest('hex').slice(0, 12);
  if (override !== undefined && (!/^\d+$/.test(override) || Number(override) < 1024 || Number(override) > 65515)) {
    throw new Error('ACENDRA_LOCAL_PORT_BASE must be an integer from 1024 to 65515.');
  }
  const base = override === undefined ? 58000 + (parseInt(id.slice(0, 6), 16) % 300) * 20 : Number(override);
  return {
    projectId: `acendra-${id}-${profile}`,
    portBase: base + (profile === 'test' ? 10 : 0),
    workdir: path.resolve(worktree, 'build', 'supabase-local', profile),
  };
}

export function renderConfig(source, layout) {
  const ports = new Map([[54321, 0], [54322, 1], [54320, 2], [54323, 3], [54324, 4], [54327, 5], [54329, 6], [54325, 7], [54326, 8], [8083, 9]]);
  return source.replace(/^project_id\s*=.*$/m, `project_id = "${layout.projectId}"`)
    .replace(/^(\s*(?:port|shadow_port|inspector_port)\s*=\s*)(\d+)\s*$/gm, (match, prefix, port) => {
      if (!ports.has(Number(port))) throw new Error('Unrecognized service port in local config.');
      return prefix + (layout.portBase + ports.get(Number(port)));
    });
}

function isPublicKey(key) {
  if (typeof key !== 'string') return false;
  if (/^sb_publishable_[^\s]+$/.test(key)) return true;
  const parts = key.split('.');
  if (parts.length !== 3 || parts.some(part => !part)) return false;
  try { return JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8')).role === 'anon'; }
  catch { return false; }
}

export function publicClientConfig(status, expectedUrl) {
  if (status.API_URL !== expectedUrl) throw new Error('Local API URL does not match the prepared stack.');
  const key = status.PUBLISHABLE_KEY || status.ANON_KEY;
  if (!isPublicKey(key)) throw new Error('Local status did not return a public client key.');
  return { APP_ENV: 'development', SUPABASE_URL: expectedUrl, SUPABASE_PUBLISHABLE_KEY: key };
}

export function isLocalDockerEndpoint(endpoint) {
  return typeof endpoint === 'string' && (/^unix:\/\/\//.test(endpoint) || /^npipe:\/{3,4}\.\/pipe\/[^/]+$/.test(endpoint));
}

export function pinLocalDockerEndpoint(env, call) {
  let endpoint = env.DOCKER_HOST;
  // Docker gives DOCKER_CONTEXT precedence over DOCKER_HOST. Resolve that same
  // effective target, then remove the override so Docker and Supabase agree.
  if (env.DOCKER_CONTEXT || !endpoint) {
    const context = call(['context', 'inspect', ...(env.DOCKER_CONTEXT ? [env.DOCKER_CONTEXT] : [])]);
    if (context.status !== 0) throw new Error('Docker CLI/context unavailable. Start a local Docker Linux engine.');
    endpoint = JSON.parse(context.stdout)[0]?.Endpoints?.docker?.Host;
  }
  if (!isLocalDockerEndpoint(endpoint)) throw new Error('Only a local Docker socket is allowed; remote Docker endpoints are rejected.');
  env.DOCKER_HOST = endpoint;
  delete env.DOCKER_CONTEXT;
}

function localDocker(layout, env) {
  const docker = process.platform === 'win32' ? 'docker.exe' : 'docker';
  function call(args) {
    return spawnSync(docker, args, { env, encoding: 'utf8' });
  }
  pinLocalDockerEndpoint(env, call);
  const info = call(['info', '--format', '{{.OSType}}']);
  if (info.status !== 0 || info.stdout.trim() !== 'linux') {
    throw new Error('Local Docker Linux engine is unavailable. Start Docker Desktop in Linux-container mode before running database commands.');
  }
  const network = layout.projectId + '-loopback';
  if (call(['network', 'inspect', network]).status !== 0) {
    const created = call(['network', 'create', '--driver', 'bridge', '--opt', 'com.docker.network.bridge.host_binding_ipv4=127.0.0.1', network]);
    if (created.status !== 0) throw new Error('Unable to create the isolated loopback Docker network.');
  }
  return network;
}

export function prepareSnapshot(worktree, layout) {
  const target = path.join(layout.workdir, 'supabase');
  fs.mkdirSync(target, { recursive: true });
  // Mirror only allowlisted repository inputs, never links or secret files.
  for (const directory of ['migrations', 'tests', 'functions']) {
    const source = path.join(worktree, 'supabase', directory);
    const destination = path.join(target, directory);
    fs.mkdirSync(destination, { recursive: true });
    mirrorSql(source, destination, directory === 'functions' ? /\.(ts|mjs|json)$/ : /\.(sql|pg)$/);
  }
  fs.copyFileSync(path.join(worktree, 'supabase', 'seed.sql'), path.join(target, 'seed.sql'));
  fs.writeFileSync(path.join(target, 'config.toml'), renderConfig(fs.readFileSync(path.join(worktree, 'supabase', 'config.toml'), 'utf8'), layout));
}

function mirrorSql(source, destination, allowed) {
  const inputs = (fs.existsSync(source) ? fs.readdirSync(source, { withFileTypes: true }) : [])
    .filter(input => input.isDirectory() || input.isSymbolicLink() || allowed.test(input.name));
  for (const input of inputs) {
    if (input.isSymbolicLink()) throw new Error('SQL inputs must not contain symbolic links.');
    const from = path.join(source, input.name);
    const to = path.join(destination, input.name);
    if (fs.existsSync(to) && fs.lstatSync(to).isSymbolicLink()) throw new Error('Snapshot must not contain symbolic links.');
    if (input.isDirectory()) {
      fs.mkdirSync(to, { recursive: true });
      mirrorSql(from, to, allowed);
    } else {
      fs.copyFileSync(from, to);
    }
  }
  // Remove stale snapshot files individually; never recursively delete folders.
  for (const entry of fs.readdirSync(destination, { withFileTypes: true })) {
    if (entry.isSymbolicLink()) throw new Error('Snapshot must not contain symbolic links.');
    if (entry.isDirectory() && !inputs.some(input => input.name === entry.name)) {
      mirrorSql('', path.join(destination, entry.name), allowed);
    } else if (entry.isFile() && !inputs.some(input => input.name === entry.name)) {
      fs.unlinkSync(path.join(destination, entry.name));
    }
  }
}

function run(layout, args, { json = false } = {}) {
  // Explicit local targets only; never inherit hosted project credentials/URLs.
  const env = { ...process.env };
  for (const name of Object.keys(env)) if (name.startsWith('SUPABASE_')) delete env[name];
  const dockerDir = 'C:/Program Files/Docker/Docker/resources/bin';
  if (process.platform === 'win32' && fs.existsSync(dockerDir)) {
    const originalPath = env.PATH || env.Path || '';
    delete env.Path;
    env.PATH = dockerDir + path.delimiter + originalPath;
  }
  const network = localDocker(layout, env);
  const executable = path.join(root, 'node_modules', 'supabase', 'dist', 'supabase.js');
  if (!fs.existsSync(executable)) throw new Error('Pinned Supabase CLI is missing. Run npm ci first.');
  const result = spawnSync(process.execPath, [executable, ...args, '--workdir', layout.workdir, '--network-id', network], {
    cwd: root, env, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024,
  });
  if (result.error) throw new Error('Unable to execute local Supabase CLI.');
  if (result.status !== 0) {
    // CLI status/start can contain private local keys: avoid echoing output.
    const logPath = path.join(layout.workdir, 'last-command.log');
      const diagnostics = result.stdout + '\n' + result.stderr;
      fs.writeFileSync(logPath, diagnostics, { mode: 0o600 });
      // Report only bounded machine identifiers from the known local snapshot;
      // never print arbitrary CLI messages, SQL values, keys or provider payloads.
      const states = [...new Set([...diagnostics.matchAll(/SQLSTATE ([A-Z0-9]{5})\b/g)].map(match => match[1]))];
      const migrations = [...diagnostics.matchAll(/Applying migration ([0-9]{14}_[a-z0-9_]+\.sql)\b/g)].map(match => match[1]);
      const knownFunctions = new Set();
      if (args.includes('lint')) {
        for (const file of fs.readdirSync(path.join(root, 'supabase', 'migrations'))) {
          if (!file.endsWith('.sql')) continue;
          const source = fs.readFileSync(path.join(root, 'supabase', 'migrations', file), 'utf8');
          for (const match of source.matchAll(/create\s+(?:or\s+replace\s+)?function\s+([a-z_][a-z0-9_]*\.[a-z_][a-z0-9_]*)\s*\(/gi)) knownFunctions.add(match[1]);
        }
      }
      const lint = args.includes('lint') ? safeLintSummary(result.stdout, knownFunctions) : '';
      // Only surface literal synthetic assertion labels from repository tests.
      // Arbitrary database diagnostics can include credentials or row values.
      const testFailures = [];
      if (args.includes('test')) {
        const knownIdentifiers = new Set();
        for (const file of fs.readdirSync(path.join(root, 'supabase', 'migrations'))) {
          const source = fs.readFileSync(path.join(root, 'supabase', 'migrations', file), 'utf8');
          for (const word of source.matchAll(/\b[a-z_][a-z0-9_]*\b/g)) knownIdentifiers.add(word[0]);
        }
        for (const error of diagnostics.matchAll(/ERROR:\s+(permission denied for (?:table|schema)|relation|column|record|new row for relation|insert or update on table|update or delete on table|violates check constraint) ["']?([a-z_][a-z0-9_]*)/g)) {
          if (knownIdentifiers.has(error[2])) testFailures.push(`${error[1]} ${error[2]}`);
        }
        for (const location of diagnostics.matchAll(/(csa(?:127|133|136|139|158_172|164|165|168)_[a-z_]+\.test\.sql):(\d+):/g)) {
          testFailures.push(`SQL location ${location[1]}:${location[2]}`);
        }
        for (const file of fs.readdirSync(path.join(root, 'supabase', 'tests', 'database'))) {
          if (!/^csa(?:127|133|136|139|158_172|164|165|168)_[a-z_]+\.test\.sql$/.test(file)) continue;
          const source = fs.readFileSync(path.join(root, 'supabase', 'tests', 'database', file), 'utf8');
          for (const match of source.matchAll(/raise exception '([A-Za-z0-9 _-]{1,100})'/g)) {
            if (diagnostics.includes(`ERROR:  ${match[1]}`)) testFailures.push(`${file}: ${match[1]}`);
          }
        }
      }
      const summary = `${states.length ? ` SQLSTATE: ${states.join(',')}.` : ''}${migrations.length ? ` Last migration: ${migrations.at(-1)}.` : ''}${lint ? ` Lint: ${lint}.` : ''}${testFailures.length ? ` Test assertions: ${testFailures.join('; ')}.` : ''}`;
      throw new Error(`Supabase ${args[0]} failed (exit ${result.status}).${summary} Private diagnostics: ${logPath}. Check Docker health and port availability.`);
  }
  if (json) {
    try { return JSON.parse(result.stdout); }
    catch { throw new Error('Local CLI status was not valid JSON.'); }
  }
  console.log(`PASS: local ${args.join(' ')} (${layout.projectId})`);
}

export function main(args) {
  if (args.length !== 2) throw new Error('Usage: node tool/local_supabase.mjs <command> <dev|test>');
  const command = allowedCommand(args[0]);
  const profile = args[1];
  const layout = createLayout(root, profile, process.env.ACENDRA_LOCAL_PORT_BASE);
  prepareSnapshot(root, layout);
  if (command === 'prepare') {
    console.log(`Prepared ${layout.projectId}: ${layout.workdir}; API port ${layout.portBase}`);
  } else if (command === 'test' || command === 'lint') {
    if (profile !== 'test') throw new Error('Tests and lint require the disposable test profile.');
    run(layout, ['start']);
    run(layout, ['db', 'reset', '--local']);
    if (command === 'test') run(layout, ['test', 'db', '--local']);
    else run(layout, ['db', 'lint', '--local', '--level', 'warning', '--fail-on', 'warning']);
  } else if (command === 'reset') {
    run(layout, ['db', 'reset', '--local']);
  } else if (command === 'status' || command === 'client-env') {
    const status = run(layout, ['status', '--output', 'json'], { json: true });
    const config = publicClientConfig(status, `http://127.0.0.1:${layout.portBase}`);
    if (command === 'client-env') {
      const output = path.join(root, 'config', 'development.local.json');
      fs.writeFileSync(output, JSON.stringify(config, null, 2) + '\n');
      console.log(`Wrote public Flutter configuration: ${output}`);
    } else console.log(`Local API: ${config.SUPABASE_URL}; project: ${layout.projectId}`);
  } else run(layout, [command]);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { main(process.argv.slice(2)); }
  catch (error) { console.error(error.message); process.exitCode = 1; }
}
