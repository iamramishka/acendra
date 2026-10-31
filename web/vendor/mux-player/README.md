# Pinned Mux Player

Self-hosted, unmodified standalone browser distribution from official npm
`@mux/mux-player` 3.14.1, `dist/mux-player.js`. Provenance and SHA256 are recorded
in integrity.json and checked by tool/com018_video_runtime.test.mjs. The Mux MIT
license is copied from the exact upstream git commit recorded in that file;
bundled legal comments are retained. Additional dependency notices are retained
under licenses/.

The existing approved CSA-011 / ADR-010 selected a pinned Mux web component.
It is lazy-loaded by the feature runtime; no root npm/Dart dependency manifest,
CDN script origin or global CSP expansion is required. Optional Mux Data tracking,
cookies and volume/mute preference persistence are disabled before source setup.
No student identifiers are passed in provider metadata. Hosted privacy/network,
token-renewal and compatibility acceptance remain separate release gates.

An isolated npm lock resolution of this exact package reported zero known
vulnerabilities on 2026-10-27. This registry audit is a point-in-time dependency
check, not proof of every behavior in the prebuilt distribution. Changes require
fresh source/version/license/integrity/audit and playable browser verification.

Sources: https://www.mux.com/docs/guides/player-api-reference/html and
https://github.com/muxinc/elements/tree/ef41d8beebc55644e63b5279feca173b164c764e.
