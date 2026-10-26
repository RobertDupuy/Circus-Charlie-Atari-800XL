# Complete candidate evidence

`release.json` identifies the source revision and both CAR profiles.
`arcade-acceptance.json` and `automatic-acceptance.json` contain the 33 CPU/pixel
suite results for their exact cartridge hashes. `presentation-details.json`
covers meter glyphs, trampoline prize/roof losses and the planted lion dance.

The four `*-demo-*.json` reports execute the unmodified release cartridges
through all seven scenes in Atari800 with sound enabled. All scenes complete
with no missed deadlines or renderer faults, at one presentation per two TV
refreshes. `trapeze-hardest-ntsc.json` checks the hardest trapeze route.

`trampoline-retries-*.json` uses real title/chooser/joystick controls, observes
three roof-hit deaths and every continue countdown value, then returns to the
title without input. `lion-finish-*.json` records distinct native screenshots
of an installed finish-state fixture; the renderer and cartridge are unchanged.
PNG files show the actual emulator output. The finish screenshot helper waits
for the sampled applause to end before taking the animation snapshots.

`reproducible.json` records prepared-asset and cartridge rebuild comparisons.
See `docs/validation.md` for interpretation, limitations and reproduction.
