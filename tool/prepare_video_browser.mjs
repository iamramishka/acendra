import {cpSync, mkdirSync, writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
const root = new URL('../', import.meta.url);
const target = new URL('test/.dart_tool/video_runtime/', root);
mkdirSync(target, {recursive: true});
cpSync(fileURLToPath(new URL('web/video_player_runtime.js', root)), fileURLToPath(new URL('video_player_runtime.js', target)));
cpSync(fileURLToPath(new URL('web/video_player.css', root)), fileURLToPath(new URL('video_player.css', target)));
cpSync(fileURLToPath(new URL('web/vendor/mux-player/', root)), fileURLToPath(new URL('vendor/mux-player/', target)), {recursive: true});
writeFileSync(new URL('fixture_runner.js', target), `
import {createMediaSurface} from './video_player_runtime.js';
const stylesheet = new Promise((resolve, reject) => {
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = new URL('./video_player.css', import.meta.url).href;
  link.onload = resolve;
  link.onerror = () => reject(new Error('Player stylesheet unavailable'));
  document.head.append(link);
});
const waitFor = async (check, label) => {
  const deadline = Date.now() + 15000;
  while (!check()) {
    if (Date.now() > deadline) throw new Error('Fixture check timed out: ' + label);
    await new Promise(resolve => setTimeout(resolve, 40));
  }
};
window.com018Fixture = async function(captions) {
  await stylesheet;
  window.com018Stage = 'creating media';
  const host = document.createElement('div');
  host.style.cssText = 'position:fixed;top:0;left:0;width:390px;height:245px;z-index:999999;';
  document.body.append(host);
  const surface = createMediaSurface(host, {
    src: '/fixtures/com018/' + (captions ? 'master.m3u8' : 'video.m3u8'),
    title: 'SYNTHETIC VIDEO FIXTURE',
  }, () => {});
  try {
    await surface.ready;
    window.com018Stage = 'metadata ready';
    const player = host.querySelector('mux-player');
    player.muted = true;
    player.playbackRate = 1.5;
    player.currentTime = 3;
    await player.play();
    window.com018Stage = 'playing';
    await waitFor(() => player.currentTime > 3.2, 'actual HLS playback advancement');
    const tracks = () => [...player.textTracks].filter(t => ['captions','subtitles'].includes(t.kind));
    let cue = '';
    if (captions) {
      await waitFor(() => tracks().length > 0, 'caption track discovery');
      tracks()[0].mode = 'showing';
      await waitFor(() => tracks()[0].activeCues?.length > 0, 'real WebVTT cues');
      cue = tracks()[0].activeCues[0].text;
      tracks()[0].mode = 'disabled';
    }
    player.pause();
    window.com018Stage = 'measuring controls';
    // The embedded test page can use Mux's compact play/seek template. Measure
    // its actual primary control; fullscreen is exercised in standalone UI QA.
    function findControl(root, requireVisible = true) {
      const direct = [...root.querySelectorAll?.('media-play-button') ?? []]
        .find(button => !requireVisible || button.getBoundingClientRect().width > 0);
      if (direct) return direct;
      for (const node of [root, ...root.querySelectorAll?.('*') ?? []]) {
        if (node.shadowRoot) {const found = findControl(node.shadowRoot, requireVisible); if (found) return found;}
      }
    }
    try {await waitFor(() => {
      const target = findControl(player)?.getBoundingClientRect();
      return target && target.width >= 44 && target.height >= 44;
    }, 'accessible play control layout');} catch(error) {
      const chain = [];
      let node = findControl(player, false);
      while (node) {
        const rect = node.getBoundingClientRect();
        chain.push({tag:node.tagName,width:rect.width,height:rect.height,display:getComputedStyle(node).display,visibility:getComputedStyle(node).visibility});
        node = node.parentElement ?? node.getRootNode().host;
      }
      const tags = new Set();
      function inspect(root) {
        for (const child of root.querySelectorAll?.('*') ?? []) {
          tags.add(child.tagName + (child.shadowRoot ? ':shadow' : ''));
          if (child.shadowRoot) inspect(child.shadowRoot);
        }
        if (root.shadowRoot) inspect(root.shadowRoot);
      }
      inspect(player);
      throw new Error(error.message + ': ' + JSON.stringify({fullscreenEnabled:document.fullscreenEnabled,hostConnected:host.isConnected,playerConnected:player.isConnected,playerShadow:!!player.shadowRoot,tags:[...tags],chain}));
    }
    const target = findControl(player).getBoundingClientRect();
    return {duration: player.duration, position: player.currentTime,
      rate: player.playbackRate, paused: player.paused, captionTracks: tracks().length,
      cue, captionsDisabled: !captions || tracks()[0].mode === 'disabled',
      trackingDisabled: player.hasAttribute('disable-tracking'),
      cookiesDisabled: player.hasAttribute('disable-cookies'),
      controlTargetWidth: target.width, controlTargetHeight: target.height,
      fullscreenAvailable: typeof player.requestFullscreen === 'function'};
  } finally {
    surface.destroy(); host.remove();
  }
};
`);
console.log('Public pinned video runtime and fixture runner staged for Chrome tests');
