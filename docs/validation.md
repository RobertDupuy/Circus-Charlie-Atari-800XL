# Validation — complete-game candidate

The delivered type-56 SIC! cartridge targets a stock 64 KB Atari 800XL.
CAR: 524,304 bytes; raw ROM: 524,288 bytes.
CAR SHA-256: `b134ba00c0ce68cb5b6ae361143ad1c0dd980632a6d17d35b5dc753c2381fd55`.

Current reports are in `evidence/complete-candidate/`. Earlier root-level
reports and `act3-revision/` describe historical builds.

## Complete career and gameplay

All 24 suites in `tests/acceptance.py` pass against this exact cartridge.
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

Additional fixtures test ordinary-input clears of horse ranks 5 and 6,
trapeze rank 6, and water ranks 1 and 6 on NTSC; water rank 6 also passes on
PAL. Every final fixture records zero missed deadlines, zero renderer faults,
and at least three lives. These fixtures replace the initial rank/stage
state and replay packet data, while retaining the release gameplay and
rendering code. An earlier candidate's isolated hard-water delay was addressed
by bounding water player DMA to the visible dolphin spans.

The title/player-selection, START/fire, reset and inter-act selection controls
pass in Atari800. Native screenshots were reviewed for all seven scenes,
the title and trapeze celebration. Green shading appears in all five ground
scenes; highwire/trapeze retain their black upper rigging area.

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

A clean source copy, full graphics regeneration and fresh assembly reproduce
this CAR byte for byte. No arcade ROM is needed for these steps:

```sh
python3 tools/assets.py
python3 tools/build.py
python3 tests/acceptance.py
```

Install Python 3, cc65, a C compiler, Pillow, NumPy and SciPy. Atari800 tests
additionally require Atari800, Xvfb and python-xlib; set `ATARI800_ROOT` to
the installation's `usr` directory. See README for cartridge loading and controls.

Physical Atari hardware and other OS revisions were not tested. This is a
complete playable candidate, with known arcade-fidelity differences in
`docs/ARCADE-FIDELITY.md`, including later lion layout/secret-trigger accuracy
and special hidden rewards that are not implemented. Those differences are
not represented as verified arcade behavior.
