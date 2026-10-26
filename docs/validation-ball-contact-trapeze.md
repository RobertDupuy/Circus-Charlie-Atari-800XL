# Validation — rolling-ball contact and trapeze grips

This complete-game candidate targets a stock 64 KB Atari 800XL with a type-56
SIC! 512 KB cartridge. It contains all six main acts, the water variation,
six difficulty ranks, continuing careers and both progression build options.

| Profile | CAR SHA-256 |
| --- | --- |
| Arcade chooser | `ce8a7c3c4b2877558a281fa35f1e730c93c3a8a862ff37402241007d77bd1c0e` |
| Automatic progression | `343d89fd8554b64caef4129fc90cd22716ca1f31dd69b2147461ec2bb6ec1b68` |

CAR size is 524,304 bytes; raw ROM size is 524,288 bytes. Current reports
are in `evidence/ball-contact-trapeze/`. Native runs use Atari800 5.0.0 with
the Altirra replacement OS, BASIC disabled, and NTSC/PAL timing. Physical
hardware has not been tested. The previous horse-contact report is retained
in [validation-horse-contacts.md](validation-horse-contacts.md).

## Act 4: visible ball contact

Holding right without jumping reproduced the old failure at simulation tick
122: the ridden ball's centre was X=151 and its neighbour was X=171. The
14-pixel silhouettes still had a six-pixel gap. The old collision compared
Charlie with the other ball and accepted distances below 21. Charlie can
also be offset from his support while a recently caught ball converges.

The correction compares both ball centres and accepts contact at a distance
of 14 or less. The same natural input now reaches X=155 versus X=169 before
losing a life. Atari800 reproduces the old gap on NTSC and the corrected
visible contact on both standards, using actual title, chooser and joystick
controls. Only the post-assertion screenshot freezes the game state.

The previous rectangular ball writer also replaced transparent edge cells
belonging to a nearby ball. The updated writer blends those shared cells.
Deduplicating the prepared ball fonts leaves a private merge range for each
display buffer; rendering the next frame cannot change the front frame.

`ball_contacts.py` verifies 918 boundary cases, including Charlie's landing
offset and crossings of a 256-pixel page boundary. It also plays through 18
natural collisions/retries across all six ranks. Its 784 pixel cases compare
the rendered silhouettes against the source artwork at touching, overlapping
and separated positions, all four animation phases, both buffers and clipped
screen edges. The earlier falling-to-the-floor and game-over checks remain.

## Act 6: small gold handlebars

Every visible rope now carries a five-colour-pixel horizontal grip at its
actual endpoint, including the fractional subtraction for a leftward swing.
The grip is drawn before Charlie so his hands and body retain their normal
foreground ordering. The runtime writes a single scanline and reuses an
existing private endpoint glyph where possible.

The top-font actor reservation now follows the actual prepared silhouette
and vertical position, including falls. A direct rope-cache lookup and a
contiguous-scanline endpoint clipper recover time for the grips. The fast
clipper is compared with the original per-scanline path on every simulation
tick across all six trapeze routes: 22,450 identical rendered frames.
The independent prepared handlebar sprite matches the scanline writer in
1,440 clipping, alignment, palette and buffer cases.

## Regression and timing

All 32 CPU/pixel acceptance suites pass for both progression profiles.
They include the horse spring-edge fix, repeated losses and continues,
all seven scenes at all six ranks, five-second continue expiry, blue dollar
signs, chooser navigation/lockouts, both screen buffers and a career through
60 main performances plus five water courses into the third show.

All six trapeze difficulty routes complete in native NTSC and PAL emulation
with zero missed gameplay deadlines, zero renderer faults and a maximum
presentation interval of two TV refreshes. The ranked fixtures install the
initial rank/state and input packets; the active game code, graphics, audio,
collisions and buffering are the release bytes.

Both complete cartridges also clear all seven native demonstration scenes
on both standards with those timing limits: nominally 30 FPS NTSC and 25 FPS
PAL. These whole-game demonstrations execute the unmodified release CARs.
Emulator monitor pauses stop emulated time; host turbo only removes wall-clock
throttling and does not change Atari clocks or ANTIC DMA.

All 58 prepared sound streams and both applause payloads retain their
exact-match checks. Both profiles rebuild byte for byte from the packaged
source and prepared assets. The test harness waits for monitor responses
and restores focus after SDL replaces its X window, avoiding stale memory
dumps and lost test controls.

## Reproduction

```sh
python3 tools/build.py --chooser arcade
python3 tests/acceptance.py
python3 tests/ball_contact_hardware.py ntsc
python3 tests/ball_contact_hardware.py pal
python3 tests/mechanics_hardware.py ntsc 5:0,5:1,5:2,5:3,5:4,5:5
python3 tests/mechanics_hardware.py pal 5:0,5:1,5:2,5:3,5:4,5:5
python3 tests/native_demo_fast.py ntsc ball-bars-demo-ntsc
python3 tests/native_demo_fast.py pal ball-bars-demo-pal
python3 tools/build.py --chooser automatic
python3 tests/acceptance.py
python3 tests/native_demo_fast.py ntsc ball-bars-demo-ntsc
python3 tests/native_demo_fast.py pal ball-bars-demo-pal
```

The optional `ball_contact_hardware.py ntsc --before` expects the previous
horse-fix cartridge and its labels in `build/ball-bars/before.car` and
`before.lbl`. Its SHA-256 is recorded in `release.json`.

These checks establish the reproduced contact correction, pixel agreement
and the measured timing; they do not enumerate every possible input history.
Known arcade adaptations remain in [ARCADE-FIDELITY.md](ARCADE-FIDELITY.md).
