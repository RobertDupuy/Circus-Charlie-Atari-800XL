# Circus Charlie — Atari 800XL complete-game candidate

[Download cartridge (.car)](build/Circus-Charlie-SIC512.car?raw=1) · [Download raw ROM (.rom)](build/Circus-Charlie-SIC512.rom?raw=1)

**Front-facing victory celebration:** Charlie stands upright on the lion,
faces the audience and waves both raised arms. Dedicated poses keep his head,
body and feet still. Continuous victory music, the reward bird, blue-dollar
bag and falling coins remain. Trampoline retries still restore Charlie to
the pedestal. Start from a fresh cartridge boot.

A native 6502 game for a stock 64 KB Atari 800XL and a 512 KB SIC! cartridge. This candidate contains all six main acts, the dolphin/water variation, six difficulty ranks, and continuing careers with 30 main performances per show.

The original arcade game is the gameplay reference. This is a complete playable career candidate, with known arcade-fidelity differences recorded in [ARCADE-FIDELITY.md](docs/ARCADE-FIDELITY.md); it is not a claim of bit-for-bit arcade equivalence.

## Run

Load `build/Circus-Charlie-SIC512.car` as a type-56 SIC! 512 KB cartridge. Select Atari 800XL, 64 KB, BASIC disabled, PAL or NTSC. The cartridge detects the television standard. `build/Circus-Charlie-SIC512.rom` is the raw 524,288-byte image for a SIC! cartridge programmer.

Verification uses Atari800 5.0.0 with its Altirra replacement OS. Physical hardware has not been tested.

| Control | Action |
| --- | --- |
| SELECT or left/right on the title | Select one/two players |
| START or fire on the title | Start |
| Left/right during play | Walk, choose horse speed, pump the held trapeze |
| Fire during play | Jump or release the trapeze |
| Arrows/stick, then fire on the arcade chooser | Choose an available act; up/down changes rows in the same column |
| OPTION on the title | Play the demonstration |
| OPTION during play | Pause/resume |
| Fire during the demonstration | Return to the title |
| Fire during continue | Continue with three lives |
| SELECT during continue | Decline; pass to the other surviving player |

The continue prompt shows **5, 4, 3, 2, 1**. With no response it returns to the
title after 300 NTSC or 250 PAL TV frames. SELECT declines immediately. In a
two-player game, a surviving player receives their turn before the game ends.
The high score is retained, and a fresh game can then be started from the title.

With the included Atari800 configuration, arrows/right Ctrl control player 1; WASD/left Ctrl control player 2. F3 is SELECT, F2 is OPTION, F4 is START. The title uses port 1. Players alternate after a lost life and retain independent scores, progress and checkpoints. Reset returns to the title.

The arcade chooser appears before the first act and after each completed performance. Each act can be chosen five times per show. Its five progress dots fill after successful performances; an exhausted act displays **NO MORE** and navigation skips it. Losing a life retries the current performance without using another selection. Each player keeps separate progress.

After all six acts have been completed five times, the counters reset and play continues with score and lives intact. The first show uses difficulty schedules 1–5; later shows use schedule 6, the hardest implemented source schedule. Difficulty saturates there rather than returning to easy. Water follows every second ordinary trampoline clear across show boundaries. The default extra-life schedule is 20,000, 90,000, then every 70,000 points; score saturates at 999,990.

The chooser remains an experimental build option. `python3 tools/build.py --chooser automatic` removes its code and artwork and starts Act 1 directly, then advances 1→2→3→4→5→6 automatically, with the same water rounds and continuing shows. It offers no act-selection controls. The default `--chooser arcade` builds the testing chooser. See [chooser design and reference notes](docs/chooser.md).


## Changes in this candidate

- Rolling-ball collision now compares the two ball centres using their 14-pixel visible diameter. It no longer takes a life with a six-pixel gap or mistakes Charlie's landing offset for ball contact.
- Shared edge cells blend nearby balls without erasing their rims. Each display buffer owns its merged glyphs, so drawing the next frame cannot change the visible front frame.
- Trapeze ropes have five-pixel gold grips at their exact endpoints. A one-scanline drawing path, tighter actor glyph reservation and faster rope-cache lookup keep the added work small.
- Horse landings at a spring's exact top boundary now bounce instead of being classified as a side impact. Side and underside collisions still cause a loss.
- Act 1 money bags display a legible blue `$`, preserved through character colour conversion.
- The continue deadline uses the TV clock in every act, including horse and water. Timeout or SELECT returns to the title when both players are out; late fire cannot accept an expired continue.
- Trampoline retry/continue restores the system cartridge bank before returning to stage setup.
- Up/down moves between the chooser panels in the same column. It does not wrap vertically or enter an exhausted panel.
- Ball misses animate down to the arena floor and retain the fallen pose until the continue prompt ends.
- Horse retries rebuild the scrolling state, clear the old airborne velocity, and provide a safe approach. Repeated misses at the final gap can be recovered with an ordinary jump.
- Horse death and continue rendering reserve enough character graphics to keep the platforms intact. Losing all lives and starting a new game are covered by native NTSC/PAL checks.
- Horse apparatus now has an upper deck, two coils, a lower deck and legs down to the floor. Its supports use prepared native drawing code.
- Optional six-panel arcade chooser with independent player progress, five-use lockouts and continuing shows. The former text selector and fixed career ending are removed.
- Tightrope retries now rebuild from a valid checkpoint, including early deaths and repeated falls near the finishing platform. The shared rolling-ball restart arithmetic is corrected too. Tightrope display interrupts reach the NTSC scanline boundary on time and keep hardware sprite DMA synchronized.
- Act 1 checkpoints now retain their hoops and fire pots through deaths, continues and alternating players. Display interrupts meet the NTSC scanline deadline, the three green shades stay consistent, and loading blanks graphics before changing the live display lists.
- All six difficulty ranks are enabled and have complete joystick/fire replay routes.
- Water uses the recovered four-slot dolphin integrator, source schedules for all six ranks, tall pedestals, original trampoline jump arcs, collisions, prizes and retry checkpoints. An independent MAME trace supplies 543 matching dolphin state transitions.
- Neutral trampoline input selects higher stationary bounces. The third reaches a visible blue-dollar bag; the fourth launches into the big top, tears the canvas, and shows a fall. Moving on resets the sequence. Fire, blade, missed-pedestal, roof and timeout failures have distinct messages in this act. The water variation retains its existing bounce rules.
- Money hoops pay 1,000 through 5,000 points. Third-bounce prizes increase from 300 to 900. Clear awards the remaining countdown; the old unconditional 2,000-point payment is removed.
- The lion has a reverse-jump collectible and a bird/coin celebration after every finish. The additional 400-point coin reward remains conditional on an unharmed run. The horse departs after the finish, and the trapeze has an approaching partner and kiss celebration. Retry geometry no longer advances the pendulums an extra frame.
- Green field shading continues through trampolines, rolling balls, horse and water. The black sky remains appropriate to the highwire and trapeze. The water retains its blue pool.
- Rendering caches and packed audio make room for these additions without dropping any of the 58 prepared PAL/NTSC sound streams. Gameplay remains native 6502 code with active collisions.

## Build and test

Install Python 3 and cc65. Prepared assets are included; building the cartridge does not require an arcade ROM.

```sh
python3 tools/build.py
python3 tests/acceptance.py
# To compile the version with no chooser:
python3 tools/build.py --chooser automatic
```

`tests/presentation_details.py` checks every act's meter boards, clipped high-bag pixels, blue dollar signs, planted lion feet, upright front-facing victory poses, and 18 natural roof-hit/retry sequences. `tests/presentation_hardware.py ntsc` / `pal` capture native pictures and three neutral-input losses followed by continue expiry.

Retry regressions include deliberate collisions, continues and successful
finishes after recovery. With Atari800 and FFmpeg installed, run
`python3 tests/tightrope_hardware.py ntsc` and the same command with `pal`
to check joystick recovery, post-retry timing and the bottom raster.
`tests/lion_hardware.py ntsc` / `pal` check the earlier Act 1 correction.
`tests/ball_horse_hardware.py ntsc` / `pal` check ball/horse deaths, late horse checkpoints, continue expiry and playable new games.
`tests/ball_contacts.py` checks 918 contact boundaries, 18 natural losses and 784 pixel/reference cases, including clipping and front-buffer retention.
`tests/ball_contact_hardware.py ntsc` / `pal` reproduce contact through actual title, chooser and joystick controls in Atari800.
`tests/trapeze_bars.py` compares the scanline grips against an independent prepared sprite in 1,440 cases and renders every input tick across all six trapeze ranks.
`tests/horse_contacts.py` replays the mid-course landing failures after 52 prior losses and 14 continues across both player records, plus 324 isolated collision-boundary cases.
`tests/horse_contact_hardware.py ntsc` / `pal` replay a natural loss, retry and formerly fatal landing on the native emulator, supplying only joystick/fire inputs at the game-tick boundary.
`tests/continue_hardware.py ntsc` / `pal` exercise natural last-life misses,
the visible countdown and automatic title return in every scene.
`tests/xl_ui.py ntsc` / `pal` check the chooser controls, all six stage
entries, reset, icon preservation and static menu raster.

Set `CC65_BIN` if ca65/ld65 are outside PATH. `tools/assets.py` regenerates graphics using Pillow and NumPy. `tools/make_demo.py` regenerates the demonstration from the included input routes; rebuild afterward. Tests also use a C compiler, NumPy and SciPy. Hardware-emulator checks require Atari800, Xvfb and python-xlib; set `ATARI800_ROOT` to the installation's `usr` directory.

The complete-career test starts at the title and clears two full shows: 60 main acts plus five water courses, then enters the third show. A separate route repeats Act 1 five times through the chooser and checks its lockout. It uses normal input and does not force clears or disable collisions. Tests that inject isolated states are labelled separately. See [validation](docs/validation.md) for exact results and limitations. Older C64 and visual-pass reports are historical records, not the specification for this candidate.

## Credits

Original game: Konami, 1984. This independent Atari conversion was developed with OpenAI Codex. It is not affiliated with or endorsed by Konami. Original game names, artwork and audio remain the property of their respective rights holders. Third-party test-core attribution is retained in `vendor/chips-LICENSE`.
