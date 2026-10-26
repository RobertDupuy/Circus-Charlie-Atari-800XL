# Validation — distance boards, lion finish and trampoline rewards

This complete-game candidate targets a stock 64 KB Atari 800XL with a type-56
SIC! 512 KB cartridge. It includes all six main acts, the water variation,
six difficulty ranks and continuing careers. The default build has the arcade
chooser; the automatic build has no level chooser.

| Profile | CAR SHA-256 |
| --- | --- |
| Arcade chooser | `3cced8898f5dc62a97f6aa1645683a1bb2eb3092f33766feda78b02778a3ff55` |
| Automatic progression | `2ca30b4da6fdc0e3faf31502c3d173a51af2889c9163409da56ac33069b647f3` |

CAR size is 524,304 bytes; raw ROM size is 524,288 bytes. The reports and
native screenshots are in `evidence/act-details/`. Native checks use Atari800
5.0.0, the Altirra replacement OS, BASIC disabled, and NTSC/PAL timing.
Physical hardware has not been tested. The previous contact/grip report is
preserved in [validation-ball-contact-trapeze.md](validation-ball-contact-trapeze.md).

## Distance boards in every act

All seven scenes now have distance boards. The existing Act 1 approach boards
remain; its finish gains GOAL. The other acts show 10-meter steps and GOAL.
Horse signs hang along the back edge of the track, keeping the springs and
landing surfaces visible. Trapeze approach boards stay anchored while its
GOAL follows the selected final platform.

The renderer uses four private glyphs per screen buffer. Rolling balls retain
independent merge space for touching silhouettes. Main trampolines and trapeze
reserve the last four bottom-font glyphs. A per-buffer cache avoids rewriting
an unchanged board; a visible marker's world position is reused between frames.
The tests compare 70 fresh, reused and clipped sign cases across all scenes.

## Act 1 finish

A successful landing plants the entire lion on the finish platform. The
platform is drawn first so it cannot erase the lion's feet. Charlie alternates
two dance poses while the lion's legs remain planted. The bird approaches with
a sack bearing a blue dollar sign, hovers above Charlie and drops ten coins.
This animation also plays after a lost life; the extra 400-point reward remains
conditional on an unharmed performance. The existing sampled applause briefly
holds the completed picture before the celebration continues.

CPU tests reach the finish using the gameplay route, check the lion's feet
against the platform, compare both dance poses, inspect the bag's blue pixels
and count the ten drops, both with and without a prior loss. Native screenshots
use the release renderer with a finish-state fixture installed through the
emulator monitor. They sample after the applause rather than accidentally
capturing its frozen frame four times.

## Trampoline prizes and understandable losses

The main trampoline course now displays high money bags with blue dollar
signs. Two stationary bounces cannot reach them; the third reaches the bag.
Collected bags stay collected after a retry. A fourth stationary bounce now
launches Charlie visibly into the big top instead of killing him immediately
at the trampoline. Torn canvas marks the impact, followed by a fall to the
floor. The HUD distinguishes a missed trampoline, fire, blade, roof and timeout.
The help line explains the third-bounce prize and fourth-bounce roof danger.

Tests exercise 18 natural roof losses and retries across all six ranks, check
that impact occurs at height 92, preserve the impact height briefly, follow
the fall to the floor and expire the continue timer back to the title. The
fast high-bag renderer matches the generic masked renderer in 88 clipped and
aligned cases, including 1,680 blue dollar-sign pixels. Native NTSC and PAL
runs use real title/chooser controls and neutral joystick input for three
roof-hit deaths, then observe every countdown value from five to one and the
return to the title, with zero missed gameplay deadlines or renderer faults.

## Regression, timing and builds

All 33 CPU/pixel acceptance suites pass for both progression profiles. They
retain the earlier rolling-ball contact and silhouette checks, horse retries,
trapeze handlebars, chooser lockouts/navigation, independent player careers,
all seven scenes at all six ranks, and five-second continue expiry.

Both unmodified release cartridges clear the complete seven-scene native demo
on NTSC and PAL, with zero missed gameplay deadlines, zero renderer faults and
a maximum presentation interval of two TV refreshes: approximately 30 FPS NTSC
and 25 FPS PAL. The hardest NTSC trapeze route also completes with those limits.
The native demo enables sound; turbo only removes host throttling and does not
change Atari clocks or ANTIC DMA. Monitor pauses stop emulated time.

The additional presentation and trampoline-motion code occupies bank 17.
Build-time bounds checks protect all relocated audio tails. All 58 prepared
sound streams and both applause payloads still pass their exact-payload tests.
Regenerating the prepared graphics reproduces all 213 checked source/asset
files. Both cartridge profiles rebuild byte for byte from the packaged source
and prepared assets.

## Reproduction

```sh
python3 tools/build.py --chooser arcade
python3 tests/acceptance.py
python3 tests/presentation_hardware.py ntsc
python3 tests/presentation_hardware.py pal
python3 tests/mechanics_hardware.py ntsc 5:5
python3 tests/native_demo_fast.py ntsc act-details-whole-ntsc
python3 tests/native_demo_fast.py pal act-details-whole-pal
python3 tools/build.py --chooser automatic
python3 tests/acceptance.py
python3 tests/native_demo_fast.py ntsc act-details-whole-ntsc
python3 tests/native_demo_fast.py pal act-details-whole-pal
```

Use a fresh cartridge boot rather than an older save state. These checks cover
the reported behavior and measured routes, not every possible input history.
Known arcade adaptations remain in [ARCADE-FIDELITY.md](ARCADE-FIDELITY.md).
