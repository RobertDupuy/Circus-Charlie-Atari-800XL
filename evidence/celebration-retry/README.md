# Celebration/retry correction evidence

`release.json` identifies both complete cartridge profiles and the previous
cartridge used to reproduce the failures. `before-reproduction.json` records
the inherited 34-pixel fall offset and the queued blocking applause.
`before-native-celebration-ntsc.json` documents the actual pause and silence.

`celebration-ntsc.json` and `celebration-pal.json` reach a natural win using the
unmodified cartridge demonstration, sample every part of the celebration and
measure its recorded POKEY audio. They do not skip an interval or install a
finish-state fixture. Their PNG files show the emulator output.

`trampoline-retries-*.json` uses real chooser controls and neutral joystick
input. It checks Charlie's displayed restart height after each loss, captures
the two retry pictures, and expires the continue timer back to the title.

The acceptance reports cover 34 CPU/pixel suites per profile. Whole-game native
reports cover all seven scenes on both standards, and the ranked report covers
three NTSC routes. `reproducible.json` records byte-identical cartridge rebuilds.
See `docs/validation.md` for limitations and reproduction commands.
