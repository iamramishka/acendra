// Feature-owned, lazy, same-origin Mux adapter. Bearer URLs never enter events.
let playerBundle;
async function loadPlayer() {
  playerBundle ??= import('./vendor/mux-player/mux-player.js');
  await playerBundle;
  await customElements.whenDefined('mux-player');
}

export function validateVideoLease(lease, now = Date.now()) {
  if (!lease || typeof lease.url !== 'string' || lease.url.length > 16384 ||
      !Number.isSafeInteger(lease.expiresAt) || lease.expiresAt <= now + 1000 ||
      lease.expiresAt > now + 300000) throw new Error('Video authorization unavailable');
  const url = new URL(lease.url);
  if (url.protocol !== 'https:' || url.hostname !== 'stream.mux.com' ||
      url.port || url.username || url.password || url.hash ||
      !/^\/[A-Za-z0-9]{1,255}\.m3u8$/.test(url.pathname) ||
      [...url.searchParams].length !== 1 ||
      !/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(url.searchParams.get('token') ?? '')) {
    throw new Error('Video authorization unavailable');
  }
  return url.href;
}

// Renderer seam for isolated playable-fixture tests; the production entry below
// always validates its signed Mux lease before calling this renderer.
export function createMediaSurface(host, options, emit, dependencies = {}) {
  const load = dependencies.load ?? loadPlayer;
  const makePlayer = dependencies.makePlayer ?? (() => document.createElement('mux-player'));
  let player, destroyed = false, settled = false, timeout, progressTimer;
  const listeners = [];
  let resolveReady, rejectReady;
  const ready = new Promise((resolve, reject) => {resolveReady = resolve; rejectReady = reject;});
  const notify = event => {if (!destroyed) emit(event);};
  function destroy() {
    if (destroyed) return;
    destroyed = true;
    clearTimeout(timeout);
    clearInterval(progressTimer);
    if (!settled) {settled = true; rejectReady(new Error('Video request ended'));}
    if (player) {
      for (const [name, callback] of listeners) player.removeEventListener(name, callback);
      try {player.pause();} catch {}
      player.removeAttribute('src');
      player.removeAttribute('playback-id');
      player.tokens = {};
      player.load?.();
      player.remove();
      player = undefined;
    }
  }
  function fail() {
    notify({kind: 'error'});
    destroy();
  }
  timeout = setTimeout(fail, 20000);
  Promise.resolve().then(load).then(() => {
    if (destroyed) return;
    player = makePlayer();
    player.className = 'acendra-lesson-video';
    for (const name of ['disable-tracking', 'disable-cookies', 'no-volume-pref', 'no-muted-pref']) {
      player.setAttribute(name, '');
    }
    player.setAttribute('stream-type', 'on-demand');
    player.setAttribute('playbackrates', '1 1.25 1.5 2');
    player.setAttribute('default-hidden-captions', '');
    player.setAttribute('preload', 'metadata');
    player.setAttribute('aria-label', 'Lesson video player');
    player.setAttribute('video-title', options.title ?? 'Lesson video');
    player.style.cssText = 'display:block;width:100%;height:100%;background:#000;--media-button-padding:14px;--media-button-icon-height:20px;--media-button-icon-width:20px;';
    function listen(name, callback) {listeners.push([name, callback]); player.addEventListener(name, callback);}
    listen('error', fail);
    listen('loadedmetadata', () => {
      if (destroyed || settled) return;
      if (Number.isFinite(options.resumeSeconds) && options.resumeSeconds > 0 &&
          options.resumeSeconds < player.duration) player.currentTime = options.resumeSeconds;
      settled = true;
      clearTimeout(timeout);
      resolveReady();
    });
    progressTimer = setInterval(() => {
      if (!destroyed && player && !player.paused && Number.isFinite(player.currentTime) && player.currentTime > 0) {
        notify({kind: 'progress', seconds: Math.floor(player.currentTime)});
      }
    }, 5000);
    host.append(player);
    player.src = options.src;
  }).catch(fail);
  return {ready, destroy};
}

export function mountVideoLease(host, lease, emit, dependencies = {}) {
  const now = dependencies.now ?? Date.now;
  const src = validateVideoLease(lease, now());
  const surface = createMediaSurface(host, {
    src, title: lease.title, resumeSeconds: lease.resumeSeconds,
  }, emit, dependencies);
  const expiry = setTimeout(() => {
    emit({kind: 'expired'});
    surface.destroy();
  }, Math.max(0, lease.expiresAt - now() - 1000));
  return {ready: surface.ready, destroy() {clearTimeout(expiry); surface.destroy();}};
}

if (typeof window !== 'undefined') {
  window.acendraMuxVideo = Object.freeze({mount: mountVideoLease});
}
