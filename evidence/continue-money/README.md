# Continue timeout and Act 1 money bags — 2026-10-25

`manifest.json` identifies the two complete-game candidate cartridges.
Earlier evidence directories describe earlier builds.

- `acceptance.json` / `automatic-acceptance.json`: all 29 CPU/pixel suites.
- `continue-rules.json`: all seven scenes, NTSC/PAL, first/last schedules,
  both HUD buffers, clock rollover, accept/decline/timeout, high score, fresh
  starts and separate two-player handoffs. Final-life setup is an explicit fixture.
- `continue-hardware-*.json`: natural last-life misses, all five countdown
  digits, automatic title return and a playable new game in every scene.
  One-life and water-entry fixtures shorten the run; game code is unchanged.
  Trampoline and horse also verify accepting a continue.
- `bold-render.json`: clipped native bag/reference comparisons plus 6,720
  checks that the dollar-sign pixels remain blue in the assembled cartridge.
- `native-full-*.json` and automatic variants: all seven demonstration scenes
  at native NTSC/PAL emulated clocks, with zero missed gameplay deadlines.
- `horse-ranked-ntsc.json`: the six horse schedules retain their timing target.
- Sound, checkpoint, full-career and pixel reports cover retained behavior.
- `reproducible-build.json`: prepared graphics regenerate identically, and
  both CAR/ROM pairs rebuild byte for byte from a separate source tree.

The native reports measure time in TV frames. Monitor pauses do not advance
emulated time. Loading/intro samples are retained but are not gameplay timing
measurements. Money-bag screenshots use an explicit paused artwork fixture.
Physical Atari hardware has not been tested.
