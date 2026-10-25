# Circus Charlie — Atari 800XL complete-game candidate

[Download cartridge (.car)](build/Circus-Charlie-SIC512.car?raw=1) · [Download raw ROM (.rom)](build/Circus-Charlie-SIC512.rom?raw=1)

A native 6502 game for a stock 64 KB Atari 800XL and a 512 KB SIC! cartridge. This candidate contains all six main acts, the dolphin/water variation, six difficulty ranks, and a complete career through the final completion screen: 36 main performances plus three water rounds.

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
| Left/right, then fire between acts | Choose an unfinished act |
| OPTION on the title | Play the demonstration |
| OPTION during play | Pause/resume |
| Fire during the demonstration | Return to the title |
| Fire during continue | Continue with three lives |
| SELECT during continue | Decline; pass to the other surviving player |

With the included Atari800 configuration, arrows/right Ctrl control player 1; WASD/left Ctrl control player 2. F3 is SELECT, F2 is OPTION, F4 is START. The title uses port 1. Players alternate after a lost life and retain independent scores, progress and checkpoints. Reset returns to the title.

Each act can be completed six times. Its difficulty follows that act's own completion count. Water follows every second ordinary trampoline clear. Clearing the last main performance reaches the final completion screen. The default extra-life schedule is 20,000, 90,000, then every 70,000 points; score saturates at 999,990.

## Changes in this candidate

- All six difficulty ranks are enabled and have complete joystick/fire replay routes.
- Water uses the recovered four-slot dolphin integrator, source schedules for all six ranks, tall pedestals, original trampoline jump arcs, collisions, prizes and retry checkpoints. An independent MAME trace supplies 543 matching dolphin state transitions.
- Neutral trampoline input now correctly selects the higher stationary bounces. A fourth stationary bounce fails; moving on resets the sequence.
- Money hoops pay 1,000 through 5,000 points. Third-bounce prizes increase from 300 to 900. Clear awards the remaining countdown; the old unconditional 2,000-point payment is removed.
- The lion has a reverse-jump collectible and a conditional bird/coin celebration. The horse departs after the finish, and the trapeze has an approaching partner and kiss celebration. Retry geometry no longer advances the pendulums an extra frame.
- Green field shading continues through trampolines, rolling balls, horse and water. The black sky remains appropriate to the highwire and trapeze. The water retains its blue pool.
- Rendering caches and packed audio make room for these additions without dropping any of the 58 prepared PAL/NTSC sound streams. Gameplay remains native 6502 code with active collisions.

## Build and test

Install Python 3 and cc65. Prepared assets are included; building the cartridge does not require an arcade ROM.

```sh
python3 tools/build.py
python3 tests/acceptance.py
```

Set `CC65_BIN` if ca65/ld65 are outside PATH. `tools/assets.py` regenerates graphics using Pillow and NumPy. `tools/make_demo.py` regenerates the demonstration from the included input routes; rebuild afterward. Tests also use a C compiler, NumPy and SciPy. Hardware-emulator checks require Atari800, Xvfb and python-xlib; set `ATARI800_ROOT` to the installation's `usr` directory.

The complete-career test starts at the title and clears all 39 courses through the actual selection, scoring and progression code. It uses normal input and does not force clears or disable collisions. Tests that inject isolated states are labelled separately. See [validation](docs/validation.md) for exact results and limitations. Older C64 and visual-pass reports are historical records, not the specification for this candidate.

## Credits

Original game: Konami, 1984. This independent Atari conversion was developed with OpenAI Codex. It is not affiliated with or endorsed by Konami. Original game names, artwork and audio remain the property of their respective rights holders. Third-party test-core attribution is retained in `vendor/chips-LICENSE`.
