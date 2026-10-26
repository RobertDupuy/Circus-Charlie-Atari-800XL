# Validation — horse spring-contact candidate

The type-56 SIC! cartridge targets a stock 64 KB Atari 800XL. Both profiles
contain all six main acts and the water/dolphin variation. CAR size is
524,304 bytes; raw ROM size is 524,288 bytes.

| Profile | CAR SHA-256 |
| --- | --- |
| Arcade chooser | `f9eb5408386489adaa58c434a1948f00ca55f5f51f778e45febe4296d08df162` |
| Automatic progression | `a8fb2a7d6b20c0ac6c6f3138add7673859cf0af82da43637ee40a107cab31eac` |

Current reports are in `evidence/horse-contacts/`. Earlier evidence folders
identify earlier cartridges. Native checks use Atari800 5.0.0 with the
Altirra replacement OS, 64 KB and BASIC disabled. Physical hardware has not
been tested.

## Reproduced landing failure

The investigation played through six natural losses and two continues using
emulator keyboard controls, then explored 30 varied-input CPU sessions with
328 losses. It found descending edge contacts where the previous foot height
was exactly the spring's top. The old comparison classified equality as a
side impact. The correction includes equality in a descending top landing;
feet already below the top still fail. It adds one conditional branch, without
changing the generator, retry checkpoint, speed, jump arc or artwork.

The recorded rank-zero example first loses a life at world X=390, retries,
and reaches X=1145 with its feet at Y=144. On the next tick it enters the
spring at X=1166. The previous cartridge kills Charlie at X=1147; the new
cartridge bounces at height 8 with the same two lives remaining.

`tests/fixtures/horse-edge-losses.json` stores inputs through this contact
and five further cases, one at each difficulty rank. `horse_contacts.py`
replays each case for both player records. Together they include 52 natural
losses and 14 accepted continues before the corrected contacts. All twelve
contacts preserve the life, award the spring bounce, and remain playable.
The test also checks 324 isolated combinations of width, deck height, speed,
ascending/descending motion and the positions just above/on/below the top.
These confirm that actual side and underside impacts remain fatal.

`horse_contact_hardware.py` enters Horse using actual title/chooser controls,
then supplies the recorded joystick/fire samples at the normal game-tick
boundary. The native emulator executes the loss, death animation, retry and
edge landing. No cartridge instructions, checkpoints, position, velocity or
life counts are patched. The old cartridge reproduces the failure on NTSC;
the corrected cartridge passes on NTSC and PAL. After the assertions, a
separate pause fixture freezes the resulting scene for its screenshot.

The source hash of the old failing cartridge is
`a2764cb1265c025a4794ec455ddec3907249781fb4d62bf78f71f0d15ed24b7e`.
The optional `--before` native probe expects that cartridge and its labels
in `build/horse-investigation/before-Circus-Charlie-SIC512.car` and
`before-main.lbl`; the normal probe uses the current build.

## Whole-game regression and performance

All 30 CPU/pixel acceptance suites pass for both profiles. This includes
all seven scenes' continue deadlines, both display buffers' blue dollar
sign, the earlier retry fixes, every scene/rank route, and the complete
career through 60 main performances plus five water courses into show three.
The existing ball/horse retry suite still covers repeated final-gap losses,
accepted continues and recovered finishes for both player records at all
six ranks. The new test adds the previously absent mid-course edge contacts.

Both profiles complete all seven native demonstration scenes on NTSC and
PAL with zero missed gameplay deadlines, zero renderer faults and a maximum
presentation interval of two TV refreshes: nominally 30 FPS NTSC and 25 FPS
PAL. Native edge-contact replays also retain those timing limits. Loading
and introductions are measured separately. Monitor pauses stop emulated
time; the game uses its own TV clock, not host wall-clock time.

All 58 prepared sound streams and both applause payloads retain their
existing exact-match checks. The prepared assets are unchanged by this fix.
Both CAR/ROM pairs rebuild byte for byte in a separate source tree.

The previous candidate's all-scene native continue screenshots and title
checks remain in `evidence/continue-money/` under their original hashes.
They are historical evidence, not additional native runs of this cartridge.

## Reproduction and scope

```sh
python3 tools/build.py --chooser arcade
python3 tests/acceptance.py
python3 tests/horse_contact_hardware.py ntsc
python3 tests/horse_contact_hardware.py pal
python3 tests/native_demo_fast.py ntsc horse-contact-demo-ntsc
python3 tests/native_demo_fast.py pal horse-contact-demo-pal
python3 tools/build.py --chooser automatic
python3 tests/acceptance.py
python3 tests/native_demo_fast.py ntsc horse-contact-demo-ntsc
python3 tests/native_demo_fast.py pal horse-contact-demo-pal
```

The native contact probe uses the arcade profile to test normal chooser
entry. The automatic profile contains no chooser. Python, cc65 and prepared
assets build either profile without a private arcade ROM. Tests additionally
use a C compiler, NumPy/SciPy, Atari800, Xvfb and python-xlib.
`ATARI800_ROOT` selects a non-system emulator runtime.

These checks establish the specific reproduced contact fix, not every
possible input history. Known adaptations remain documented in
[ARCADE-FIDELITY.md](ARCADE-FIDELITY.md).
