# Validation — complete-game candidate

The delivered type-56 SIC! cartridge targets a stock 64 KB Atari 800XL.
CAR: 524,304 bytes; raw ROM: 524,288 bytes.
CAR SHA-256: `3d40b11a0997c3b054397ce8a2e9f82464881b4289559b76f41d5fa5aa26fca4`.

Current reports are in `evidence/act1-fix/`. `complete-candidate/`, earlier
root-level reports and `act3-revision/` describe previous builds.

## Act 1 retry and NTSC raster correction

The previous checkpoint dispatch never copied Act 1's 64-byte lion state.
A natural death restored an empty pot list, including a zero pot count;
the drawing/collision loops then wrapped through 256 entries. In the
reproduction, mean CPU-only tick-plus-render cost rose from 16,597 to
52,195 cycles. The corrected dispatch saves the lion block for both players.

`tests/lion_retry.py` exercises 52 natural collisions, both checkpoint pages,
all six ranks, 12 continues and real two-player switching. Saved hoops,
gap clocks and pot state survive each retry. The largest measured restored
tick-plus-picture cost is 24,985 CPU cycles; no renderer faults occur.
CPU cycle counts exclude ANTIC DMA and are not an FPS measurement.

The original NTSC recording also shows two static background boundaries
changing between TV frames. The DLI now reaches WSYNC earlier by removing
unused stripe arithmetic and deferring the background load. Its green
shade changes agree with the regular three-band gradient. Stage loading
now disables DLIs, DMA and GTIA player output before replacing the live
display lists or copying shared data; this removes transitional corruption
and the vertical stripes produced by enabled player latches without DMA.

`tests/lion_hardware.py` uses the unmodified cartridge, ordinary keyboard
joystick/fire controls and read-only monitor observations in Atari800.
It deliberately walks into fire, retries at least four times and continues
after exhausting three lives. NTSC and PAL retain two television refreshes
per gameplay picture after each retry, with zero missed gameplay deadlines
or renderer faults. Lossless video checks the green background across the
field, the fixed highlight at the character boundary, and all three shades.
Stage loading deliberately blanks the screen; partial loading frames are
excluded from the static-background comparison. Exact frame counts and
observations are in the two `lion-hardware-*.json` reports.

## Complete career and gameplay

All 25 suites in `tests/acceptance.py` pass against this exact cartridge.
The uninterrupted career test starts at the title and clears 36 main
performances plus three water courses: 39 in total. It reaches the final
completion state after 90,535 simulation ticks and 45,268 rendered pictures,
with no deaths or renderer faults. The runner supplies ordinary controller
input and invokes the same stage loader used by the main loop. It does not
force completion, change collision handling, or edit lives or progression.

All 42 individual scene/rank routes pass. A separate sweep renders every
simulation tick, including phases skipped by a two-tick NTSC picture,
introductions and natural clear sequences: 90,708 pictures, plus the initial
introduction buffers. These checks cover font capacity and live-object
limits; they do not exhaust every possible input history.

The reward tests check the capped 1,000–5,000 money-hoop ladder, reverse-jump
collectible contact, countdown awards, conditional lion coins, departing
pony and all 14 unharmed/hurt celebration cases. They also populate both
live trapeze player buffers before clearing, then verify the old blue hero
accent is hidden. Neutral input is checked against the stationary bounce
rules in both trampoline and water courses.

## Hardware-emulator timing

Atari800 5.0.0 uses XL/64 KB, the Altirra replacement OS, BASIC disabled,
POKEY sound, native ANTIC/GTIA DMA, and the cartridge's own VBI/DLIs.
Both complete demonstrations use the unmodified delivery cartridge.

| Course | NTSC FPS | PAL FPS | Missed deadlines | Renderer faults |
| --- | ---: | ---: | ---: | ---: |
| Fire hoops | 29.961 | 24.930 | 0 | 0 |
| Tightrope | 29.961 | 24.930 | 0 | 0 |
| Trampolines | 29.942 | 24.930 | 0 | 0 |
| Rolling balls | 29.945 | 24.930 | 0 | 0 |
| Horse | 29.943 | 24.930 | 0 | 0 |
| Trapeze | 29.961 | 24.930 | 0 | 0 |
| Water/dolphins | 29.940 | 24.909 | 0 | 0 |

Each active picture is presented for two television refreshes: nominal
30 FPS NTSC / 25 FPS PAL. Small aggregate differences reflect completion
being recorded before the pending picture is published. Introductory
loading, title/menu screens and intermission applause have separate timing
contracts. Host acceleration does not change emulated clocks, DMA or sound.

The previous complete-candidate fixtures tested ordinary-input clears of horse ranks 5 and 6,
trapeze rank 6, and water ranks 1 and 6 on NTSC; water rank 6 also passes on
PAL. Those reports record zero missed deadlines, zero renderer faults,
and at least three lives; they were not rerun for this correction. These fixtures replace the initial rank/stage
state and replay packet data, while retaining the release gameplay and
rendering code. An earlier candidate's isolated hard-water delay was addressed
by bounding water player DMA to the visible dolphin spans.

The previous title/player-selection, START/fire, reset and inter-act selection
checks remain in `evidence/complete-candidate/`. Both complete demonstrations
were rerun for this correction, and native screenshots were reviewed for all
seven scenes. Green shading appears in all five ground scenes;
highwire/trapeze retain their black upper rigging area.

## Independent references

- Water: 543 dolphin state transitions match the MAME observation fixture;
  all six source schedules, collisions, retry and prize cases pass.
- Act 3: the observed performer/attack schedules and integer projectile
  motion retain their existing reference checks.
- Hero compositors and sprite-row caching each match 41,157 reference
  pictures; spring caching matches 5,058 and monkey caching 5,706 pictures.
- Normal/water prize caches match 3,600 generic-renderer pixel cases.
- Disabled DMA windows are checked against actual player data on all six
  ranks of the five relevant scenes. All 560 interrupt/register cases pass.
- All 58 PAL/NTSC prepared audio streams and the applause payload pass their
  register/sample checks.

The private arcade ROM and full disassembly are not distributed. Compact
observations, prepared assets and test routes are included.

## Reproduction and limits

A clean source copy and fresh assembly with the included prepared assets
reproduce this CAR byte for byte. Graphics assets are unchanged from the
previous regeneration-verified candidate. No arcade ROM is needed:

```sh
python3 tools/build.py
python3 tests/acceptance.py
python3 tests/lion_hardware.py ntsc
python3 tests/lion_hardware.py pal
```

Install Python 3, cc65, a C compiler, Pillow, NumPy and SciPy. Atari800 tests
additionally require Atari800, Xvfb, python-xlib and FFmpeg; set `ATARI800_ROOT` to
the installation's `usr` directory. See README for cartridge loading and controls.

Physical Atari hardware and other OS revisions were not tested. This is a
complete playable candidate, with known arcade-fidelity differences in
`docs/ARCADE-FIDELITY.md`, including later lion layout/secret-trigger accuracy
and special hidden rewards that are not implemented. Those differences are
not represented as verified arcade behavior.
