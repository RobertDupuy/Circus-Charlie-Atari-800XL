# Validation — continuous celebration and correct trampoline retries

Complete game for a 64 KB Atari 800XL with a type-56 SIC! 512 KB cartridge.
NTSC is the primary target; PAL is also checked. The default cartridge uses
the arcade chooser. The alternative progresses automatically without a chooser.

| Profile | CAR SHA-256 |
| --- | --- |
| Arcade chooser | `8ae71ec9314cc6ab49fa63c3159f4da8c5e40ce4dcaa29dbe35853f5697aa2f1` |
| Automatic progression | `88b8979592a3960a2c5087a1ce0c2b8c9fca92ea96c95356f3a9e38ee9f76cef` |

Reports and screenshots are in `evidence/celebration-retry/`. The preceding
candidate is documented in [validation-act-details.md](validation-act-details.md);
its celebration/retry claims are superseded by the findings here.

## Reproduced failures

The previous cartridge queued a foreground PCM applause eight television
frames after entering the victory state. Its player stopped animation for
about 3.7 seconds, then discarded the victory music stream. A continuous,
unmodified-cartridge NTSC run measured a sampled 3.59-second animation stop
and a 1.9-second silent stretch. The former snapshot helper waited until after
applause, so it did not detect this behavior.

After a trampoline roof hit, Charlie correctly fell to feet Y=164, but the
34-pixel death offset survived the stage reload. His next life therefore
started at Y=164 instead of the trampoline's Y=130. The earlier retry test
checked progression but not the restored feet position.

## Corrections

Normal act-clear playback now keeps command-1C victory music running through
the existing audio interrupts. It never schedules blocking PCM. The original
applause payload/player remain as a reference and a standalone payload check;
the sampled crowd applause is no longer part of the animated celebration mix.
No music/effect register-stream contents changed.

The continuous recording also exposed slow drawing during the coin shower.
Victory text glyphs are now cached separately for both display buffers. In
Act 1, nothing in the celebration overlaps the text, so its static screen cells
stay mapped until the next stage load. The first two buffers may each take
four TV refreshes while installing the text; subsequent drawing maintains
its normal two-refresh cadence. This removes the mid-animation slowdown
without changing the lion, bird, blue-dollar bag or coin artwork.

Stage loading now clears the death-only vertical offset before restoring any
checkpoint. The natural roof-hit tests check the retry introduction, the first
playable frame and every subsequent trampoline movement frame. Collected bags
stay collected, and the five-second continue countdown still returns to title.

## Evidence and scope

Both profiles pass all 34 CPU/pixel acceptance suites, including 98 comparisons
between cached and freshly drawn victory text, 18 natural roof-hit/retry
sequences across all six ranks, and continuous victory music/animation in
all seven scenes on both standards. Existing collision, horse retry, trapeze,
chooser, independent-player and complete-career checks remain in the suite.

`celebration_hardware.py` reaches the Act 1 finish through the unmodified
cartridge's normal demonstration, with no installed finish state and no skipped
applause interval. The NTSC and PAL recordings contain uninterrupted animation
and audible music throughout; measured 50-ms audio windows have no silent run.
The captures cover approximately 3.61 seconds NTSC and 3.69 seconds PAL.

`presentation_hardware.py` uses actual title/chooser/joystick controls. On each
standard it loses three lives through neutral-input roof hits, verifies both
restarts after new frames have been published, captures Charlie back on the
pedestal, and observes countdown 5 through 1 followed by the title. Reading a
scratch coordinate in the middle of stage loading is excluded from the visual
position assertion; the first completed retry pictures are checked instead.

Both cartridge profiles also complete all seven native demonstration scenes
on NTSC and PAL. Gameplay retains zero missed deadlines and renderer faults,
with at most two TV refreshes per presentation. The hardest NTSC trapeze and
higher-rank trampoline routes are checked separately. Both profiles rebuild
byte for byte from the source and prepared assets.

Native tests use Atari800 5.0.0 with its Altirra replacement OS, BASIC disabled,
and sound enabled. Host turbo in the whole-game/ranked checks does not change
Atari clocks or ANTIC DMA. The focused celebration audio captures run at normal
speed. The automatic NTSC whole-game run was repeated after a test-harness
monitor-entry timeout; its complete rerun passed. Physical hardware has not been tested; these checks do not enumerate
every possible input history.

## Reproduction

```sh
python3 tools/build.py --chooser arcade
python3 tests/acceptance.py
python3 tests/celebration_hardware.py ntsc
python3 tests/celebration_hardware.py pal
python3 tests/presentation_hardware.py ntsc
python3 tests/presentation_hardware.py pal
python3 tests/mechanics_hardware.py ntsc 2:4,2:5,5:5
python3 tests/native_demo_fast.py ntsc celebration-retry-whole-ntsc
python3 tests/native_demo_fast.py pal celebration-retry-whole-pal
python3 tools/build.py --chooser automatic
python3 tests/acceptance.py
python3 tests/native_demo_fast.py ntsc celebration-retry-whole-ntsc
python3 tests/native_demo_fast.py pal celebration-retry-whole-pal
```

The optional `--before` celebration check uses the previous CAR stored at
`build/celebration-retry/before.car`. Its hash is recorded in `release.json`.
Use a fresh cartridge boot; old save states contain the superseded program.
