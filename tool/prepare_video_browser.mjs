import {cpSync, mkdirSync, writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
const root = new URL('../', import.meta.url);
const target = new URL('test/.dart_tool/video_runtime/', root);
mkdirSync(target, {recursive: true});
cpSync(fileURLToPath(new URL('web/video_player_runtime.js', root)), fileURLToPath(new URL('video_player_runtime.js', target)));
cpSync(fileURLToPath(new URL('web/vendor/mux-player/', root)), fileURLToPath(new URL('vendor/mux-player/', target)), {recursive: true});
writeFileSync(new URL('fixture_runner.js', target), `
import {createMediaSurface} from './video_player_runtime.js';
const waitFor = async (check, label) => {
  const deadline = Date.now() + 15000;
  while (!check()) {
    if (Date.now() > deadline) throw new Error('Fixture check timed out: ' + label);
    await new Promise(resolve => setTimeout(resolve, 40));
  }
};
window.com018Fixture = async function(captions) {
  const host = document.createElement('div');
  host.style.cssText = 'position:fixed;top:0;left:0;width:390px;height:245px;z-index:999999;';
  document.body.append(host);
  const surface = createMediaSurface(host, {
    src: '/fixtures/com018/' + (captions ? 'master.m3u8' : 'video.m3u8'),
    title: 'SYNTHETIC VIDEO FIXTURE',
  }, () => {});
  try {
    await surface.ready;
    const player = host.querySelector('mux-player');
    player.muted = true;
    player.playbackRate = 1.5;
    player.currentTime = 3;
    await player.play();
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
    return {duration: player.duration, position: player.currentTime,
      rate: player.playbackRate, paused: player.paused, captionTracks: tracks().length,
      cue, captionsDisabled: !captions || tracks()[0].mode === 'disabled',
      trackingDisabled: player.hasAttribute('disable-tracking'),
      cookiesDisabled: player.hasAttribute('disable-cookies'),
      fullscreenAvailable: typeof player.requestFullscreen === 'function'};
  } finally {surface.destroy(); host.remove();}
};
`);
console.log('Public pinned video runtime and fixture runner staged for Chrome tests');
