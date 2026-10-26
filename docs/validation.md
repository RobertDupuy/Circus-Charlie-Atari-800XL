# Validation — upright, front-facing Act 1 celebration

Complete game for Atari 800XL, 64 KB, SIC! 512 KB cartridge type 56.
NTSC is the primary target; the same cartridge also detects PAL.

| Profile | CAR SHA-256 |
| --- | --- |
| Arcade chooser | `4aac136f2b8b6602dac4a0d457e8b12d149a5e5450de1a2fbb2d3e8a57418809` |
| Automatic progression | `d32df3e45124b6adf3c8f4e532cb39fe6225e3e0ff46f7c97f4047ad45d77b97` |

## Correction

The former animation alternated resized side-facing action poses, making
Charlie's body and legs move inappropriately during the celebration. Two
dedicated front-facing poses now keep his head, upright torso and feet fixed;
only his raised arms wave. Both eyes face the audience. His taller silhouette
preserves the lion's planted feet and the platform contact.

The composite has a fixed goal anchor in all six difficulty ranks, so unused
horizontal and vertical alignments share the prepared pixels. This keeps the
new artwork within cartridge capacity without removing any sound streams.
Music, the reward bird, blue-dollar sack and coin shower remain active.

## Checks

Both progression profiles pass all 34 CPU/pixel acceptance suites. The
presentation checks verify two visible eyes, a fixed head/body/leg region,
planted shoes, moving raised arms, the unchanged lion feet, the blue dollar
sign and ten coin drops, including a victory after a lost life. Every rank's
fixed goal anchor is checked. Existing tests cover 18 natural trampoline
roof-hit/retry sequences and the earlier continue, collision and timing fixes.

Normal-speed NTSC and PAL recordings reach the victory through the unmodified
cartridge's demonstration. They show continuous animation and audible music,
with no detected silent 50-ms windows or animation stalls. The static victory
text can take four TV refreshes to install in the first two NTSC buffers;
steady rendering advances every two refreshes.

Native control tests on both standards lose all three trampoline lives,
verify both restarts on the pedestal, and wait through countdown 5 to 1 back
to the title. Both progression profiles complete all seven native demo scenes
on both standards with zero gameplay deadline misses or renderer faults.
The hardest NTSC trapeze route also passes with a two-refresh cadence.
Prepared assets regenerate identically, and both cartridges rebuild byte for
byte from the source package.

Reports and actual emulator screenshots are in `evidence/upright-celebration/`.
The previous correction is archived in
[validation-celebration-retry.md](validation-celebration-retry.md).

These are Atari800 5.0.0 tests using the Altirra replacement OS with BASIC
disabled and sound enabled. Whole-game and ranked runs accelerate host time
without changing Atari clocks or ANTIC DMA. Physical hardware was not tested,
and the checks do not enumerate every possible input history.

## Reproduction

```sh
python3 tools/assets.py
python3 tools/build.py --chooser arcade
python3 tests/acceptance.py
python3 tests/celebration_hardware.py ntsc
python3 tests/celebration_hardware.py pal
python3 tests/presentation_hardware.py ntsc
python3 tests/presentation_hardware.py pal
python3 tests/native_demo_fast.py ntsc upright-whole-ntsc
python3 tests/native_demo_fast.py pal upright-whole-pal
python3 tests/mechanics_hardware.py ntsc 5:5
python3 tools/build.py --chooser automatic
python3 tests/acceptance.py
python3 tests/native_demo_fast.py ntsc upright-whole-ntsc
python3 tests/native_demo_fast.py pal upright-whole-pal
```

Use a fresh cartridge boot; older save states retain the previous program.
