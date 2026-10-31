import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {createMediaSurface, mountVideoLease, validateVideoLease} from '../web/video_player_runtime.js';

const now = Date.now();
const lease = {url: 'https://stream.mux.com/Synthetic123.m3u8?token=a.b.c', expiresAt: now + 120000};

test('default lazy loader retries after failure and shares in-flight and successful imports', () => {
  // Exercise the unchanged production module, intercepting only the browser
  // import boundary. A separate VM process keeps its module cache isolated.
  execFileSync(process.execPath, ['--experimental-vm-modules', '--input-type=module', '-e', `
    import assert from 'node:assert/strict';
    import {readFileSync} from 'node:fs';
    import vm from 'node:vm';
    let attempts = 0, release;
    const gate = new Promise(resolve => {release = resolve;});
    const context = vm.createContext({
      setTimeout, clearTimeout, setInterval, clearInterval,
      customElements: {whenDefined: async () => {}},
    });
    const bundle = new vm.SyntheticModule([], () => {}, {context});
    await bundle.link(() => {});
    await bundle.evaluate();
    const module = new vm.SourceTextModule(readFileSync(process.argv[1], 'utf8'), {
      context,
      importModuleDynamically: async () => {
        attempts++;
        if (attempts === 1) {await gate; throw Error('temporary network failure');}
        return bundle;
      },
    });
    await module.link(() => {});
    await module.evaluate();
    let creates = 0;
    class Player extends EventTarget {
      constructor() {super(); this.style = {};}
      setAttribute() {} removeAttribute() {} pause() {} load() {} remove() {}
    }
    function mount() {
      return module.namespace.createMediaSurface({append(player) {
        queueMicrotask(() => player.dispatchEvent(new Event('loadedmetadata')));
      }}, {src: 'synthetic'}, () => {}, {makePlayer() {creates++; return new Player();}});
    }
    const first = mount(), concurrent = mount();
    const failed = Promise.all([assert.rejects(first.ready), assert.rejects(concurrent.ready)]);
    await new Promise(resolve => setTimeout(resolve, 0));
    assert.equal(attempts, 1, 'concurrent mounts share an in-flight import');
    release();
    await failed;
    assert.equal(creates, 0);
    const retry = mount();
    try {await assert.doesNotReject(retry.ready, 'Retry must recover after the network returns');} finally {retry.destroy();}
    assert.equal(attempts, 2, 'Retry performs a fresh import after failure');
    const cached = mount();
    try {await cached.ready;} finally {cached.destroy();}
    assert.equal(attempts, 2, 'successful bundle remains cached');
    assert.equal(creates, 2);
  `, fileURLToPath(new URL('../web/video_player_runtime.js', import.meta.url))], {stdio: 'pipe'});
});

test('Mux vendor is pinned to the reviewed exact distribution', () => {
  assert.equal(createHash('sha256').update(readFileSync(new URL('../web/vendor/mux-player/mux-player.js', import.meta.url))).digest('hex'),
    '8c20096c3370a05e7ce09d797b4ca8da0db7485850a6c3bec6f420864a8ee24d');
});

test('production lease requires exact signed Mux HLS identity and a bounded expiry', () => {
  assert.equal(validateVideoLease(lease, now), lease.url);
  for (const url of [
    'http://stream.mux.com/id.m3u8?token=a.b.c',
    'https://evil.example/id.m3u8?token=a.b.c',
    'https://stream.mux.com/id.mp4?token=a.b.c',
    'https://stream.mux.com/id.m3u8?token=a.b.c&token=a.b.c',
    'https://stream.mux.com/id.m3u8?token=a.b.c&extra=1',
    'https://user:pass@stream.mux.com/id.m3u8?token=a.b.c',
    'https://stream.mux.com/id.m3u8?token=a.b.c#fragment',
    'https://stream.mux.com/id.m3u8?token=unsigned',
  ]) assert.throws(() => validateVideoLease({...lease, url}, now));
  for (const expiresAt of [now, now - 1, now + 301000, NaN, Infinity]) {
    assert.throws(() => validateVideoLease({...lease, expiresAt}, now));
  }
});

class FakePlayer extends EventTarget {
  constructor() {super(); this.attributes = new Map(); this.style = {}; this.tokens = {}; this.duration = 60; this.currentTime = 0; this.paused = true;}
  setAttribute(key, value) {this.attributes.set(key, value);}
  removeAttribute(key) {this.attributes.delete(key); if (key === 'src') this.src = '';}
  pause() {this.paused = true; this.pauseCalls = (this.pauseCalls ?? 0) + 1;}
  load() {}
  remove() {this.removed = true;}
}

test('player sets privacy/controls before source and cleans every media reference', async () => {
  const player = new FakePlayer();
  const host = {append(value) {assert.equal(value, player);}};
  const surface = createMediaSurface(host, {src: lease.url, title: 'Synthetic lesson', resumeSeconds: 8}, () => {},
    {load: async () => {}, makePlayer: () => player});
  await new Promise(resolve => setTimeout(resolve, 0));
  assert.equal(player.attributes.get('disable-tracking'), '');
  assert.equal(player.attributes.get('disable-cookies'), '');
  assert.equal(player.attributes.get('playbackrates'), '1 1.25 1.5 2');
  assert.equal(player.attributes.has('metadata-viewer-user-id'), false);
  player.dispatchEvent(new Event('loadedmetadata'));
  await surface.ready;
  assert.equal(player.currentTime, 8);
  surface.destroy();
  assert.equal(player.src, '');
  assert.equal(player.removed, true);
  assert.deepEqual(player.tokens, {});
  assert.equal(player.pauseCalls, 1);
});

test('dispose before lazy bundle loading prevents a late source request', async () => {
  let finish;
  const loading = new Promise(resolve => {finish = resolve;});
  let creates = 0;
  const surface = createMediaSurface({append() {throw Error('late append');}}, {src: lease.url}, () => {},
    {load: () => loading, makePlayer: () => {creates++; return new FakePlayer();}});
  const failed = assert.rejects(surface.ready);
  surface.destroy();
  finish();
  await failed;
  await new Promise(resolve => setTimeout(resolve, 0));
  assert.equal(creates, 0);
});

test('expiry stops loaded media and emits no signed URL in public events', async () => {
  const player = new FakePlayer();
  const events = [];
  const clock = Date.now();
  const expiresAt = clock + 1100;
  const surface = mountVideoLease({append() {}}, {...lease, expiresAt}, event => events.push(event),
    {load: async () => {}, makePlayer: () => player, now: () => clock});
  await new Promise(resolve => setTimeout(resolve, 0));
  player.dispatchEvent(new Event('loadedmetadata'));
  await surface.ready;
  await new Promise(resolve => setTimeout(resolve, 200));
  assert.equal(events[0].kind, 'expired');
  assert.equal(player.removed, true);
  assert.doesNotMatch(JSON.stringify(events), /token|https|playback_url/);
  surface.destroy();
});
