# Synthetic playable video fixture

Original generated color-bar/motion and sine-wave footage, 12 seconds, 320x180,
H.264 baseline + AAC. There are no students, purchased course materials, external
provider accounts or uploaded/billable assets. Caption text explicitly labels
the fixture SYNTHETIC.

Generate video.m3u8 and its six transport-stream segments with FFmpeg 7.1:

```text
ffmpeg -f lavfi -i testsrc2=size=320x180:rate=24 -f lavfi -i sine=frequency=440:sample_rate=44100 -t 12 -c:v libx264 -profile:v baseline -pix_fmt yuv420p -g 48 -keyint_min 48 -sc_threshold 0 -c:a aac -b:a 64k -f hls -hls_time 2 -hls_playlist_type vod -hls_segment_filename segment%02d.ts video.m3u8
```

master.m3u8 adds the English WebVTT subtitle rendition. video.m3u8 intentionally
has no caption track. Browser checks use the same self-hosted Mux renderer as
production with these local public test fixtures. They do not bypass or activate
the production authorization entry, invent entitlements, verify real Mux
signatures, or prove hosted renewal/revocation/privacy behavior.
