# Chooser, ball and horse corrections — 2026-10-25

These reports correspond to the two candidate cartridge hashes in
`manifest.json` and `../../docs/validation.md`. Earlier evidence directories
are historical; their hashes do not identify this candidate.

- `acceptance.json` and `automatic-acceptance.json`: all 28 CPU/pixel suites.
- `ball-horse-retry.json`: both players, all six ranks, floor landings,
  late horse retries, continues, recovered finishes and new-game restarts.
- `hardware-retries-*.json`: actual NTSC/PAL emulator samples through three
  natural-death/game-over/restart scenarios. The late horse scenario begins
  from an explicitly installed checkpoint produced by an ordinary-input CPU
  route. No cartridge code is patched and subsequent failures occur naturally.
- `horse-ranked-ntsc.json`: all six horse schedules complete at the two-refresh
  presentation cadence, without missed deadlines or renderer faults. Initial
  stage/rank and demonstration input are explicit fixtures.
- `hardware-full-*.json` and `automatic-hardware-full-*.json`: all seven
  complete native demonstration scenes, using the unmodified cartridges.
- `chooser-ui-*.json`: ordinary title/navigation/reset/act-entry controls and
  lossless static-menu raster checks. Only the lockout check injects counters.
- `spring-cache-check.json`: 5,058 pictures compared with independent masked
  drawing, including offscreen clipping and both display buffers.
- `hoop-depth.json`, sound reports and interrupt tests: ROM packing and
  rendering regressions, including shared animation-bank tails.
- `retry-build-repro.json`: both CAR/ROM pairs reproduce byte for byte from a
  separate source tree. `assets-repro.json` records identical regenerated
  graphics payloads and generated assembly directories.

Screenshots show floor-level game-over poses, intact spring platforms and a
fresh horse game after all lives have been lost. Emulator monitor pauses may
observe loading or intro transitions; gameplay timing assertions apply after
the first active tick. Native validation uses Atari800 5.0.0 with the Altirra
replacement OS, 64 KB and BASIC disabled. Physical hardware remains untested.
