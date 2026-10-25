> Historical report. Current gameplay requirements and remaining work are in
> [ARCADE-FIDELITY.md](ARCADE-FIDELITY.md); current results are in
> [validation.md](validation.md).

# Bold Arcade graphics pass

This document describes the v5 all-act foundation. Act 1 is superseded by the [v6 arcade timing study](ACT1-ARCADE.md), including the compact actor, four flame players, raised money hoops, new scenery and different simulation cadence. The other acts retain this treatment.

The selected Bold Arcade shapes and colours are applied to all six main acts and
the water variation. This is the full SIC cartridge, preserving the executable-
audited C64 rules and the deliberate Atari improvements documented in the feature
ledger. The graphics revision does not add or remove enemies, change collision
boxes, alter rewards, or change the four difficulty layouts.

## What changed on screen

| Scene | Treatment |
| --- | --- |
| Fire hoops | Cream/gold lion with a dark mane and readable paws; corrected Charlie poses, cyan costume accent, gold hoop cores with animated red outer fire, shaped burning pots and blue-detail prize bags. |
| Tightrope | Clear dark rigging area above the audience, a bright wire, shaped brown/pink monkeys with distinct faces and tails, and the new Charlie poses. |
| Trampolines | Green field, blue/cream trampoline rims and legs, taller shaped flames, gold prize bags and the same new acrobat. |
| Balls | Four resident animation phases of striped gold/blue balls; Charlie has the cyan costume accent and a separate finish marker. |
| Horse | Three authored galloping poses, dark red mane/tail, blue saddle, bright spring tops and gold coils; updated rider poses. |
| Trapeze | Clear upper rigging, prepared sampled rope shapes, new swinging/falling poses and blue/cream recovery trampolines. |
| Water | Blue pool, blue dolphin silhouettes with cream bellies and a small eye, rising/crest/diving poses and a white splash; matching platforms and bags. |

Ground scenes share a striped tent, Ferris wheel, audience, purple bunting and
green field. All six audience/bunting rows, including the entrance, scroll together with the camera in v7. High acts move the audience down to leave room for the acrobat.
PAL uses the prepared colour mapping from the accepted prototype; exact hues
still depend on emulator palette and display settings.

## Hardware players and missiles

| Scene | P0 | P1 | P2 | P3 |
| --- | --- | --- | --- | --- |
| Fire hoops (v7) | Hoop outer fire | Hoop outer fire | Hoop outer fire | Hoop outer fire |
| Tightrope | Monkey body/tail | Monkey body/tail | Monkey body/tail | Monkey body/tail |
| Trampolines | Spare | Spare | Spare | Charlie cyan accent |
| Balls | Charlie cyan accent | Spare | Spare | White finish marker |
| Horse | Spring coil | Spring coil | Spring coil | Spring coil |
| Trapeze | Spare | Spare | Spare | Charlie cyan accent |
| Water | Dolphin body/splash | Dolphin body/splash | Dolphin body/splash | Dolphin body/splash |

Missiles are unused and their DMA is disabled. Charlie/lion/horse base art,
hoop cores, pots, faces, flames, bags, balls, ropes, trampoline platforms and
most finish decks use ANTIC character graphics. The dolphin PM mask leaves
its cream belly/eye pixels exposed in the character layer. Slots are assigned
to visible objects each frame; no horizontal player multiplexing is required.
All PM positions, colours and DMA data switch with the completed display buffer.

In Act 1, the near half of each rim and flame is composited into Charlie/lion’s private character cells after drawing the actor. The far half remains behind the actor. This adds the missing through-the-hoop depth without assigning another player or changing collision geometry.

## Performance decisions

There is no sprite shifting, trigonometry or asset conversion during play.
Shifted actor cells are prepared offline. Hero glyphs use reserved ranges and
contiguous copies; only overlapping background cells require masking. Repeated
hoops, pots, flames, horse poses and platforms use resident glyphs. Ropes reuse
common resident patterns; balls have four immutable phase fonts.

Small ROM programs draw the crowd, fixed objects, clipped hoop/pot edges and
fixed-height hoop PM bytes. Uniform field/rigging rectangles restore with one
background read per row. The bag inside a hoop is precomposed; a reference test
checks identical pixels against the ordinary masked renderer. These changes
trade unused cartridge space for runtime cycles without reducing visible art.
Unneeded colour-change interrupts are omitted in ground scenes. The audio
register decoder also has a faster path with unchanged verified output.

For acts other than Act 1, the main loop computes the next logic batch after finishing a display buffer,
using time that would otherwise be spent waiting for its VBI publication. It
still executes two ticks per NTSC presentation and the same 2,2,3,2,3 PAL cadence.
Inputs remain VBI-sampled and fire edges remain latched. A scene transition
installs the destination assets before drawing it.

The target is one complete frame every two refreshes, nominal 30 FPS NTSC and
25 FPS PAL. See validation.md for the actual measured runs. CPU-only cycle
counts exclude ANTIC and interrupt work and are not a free-cycle allowance for
future art. Physical hardware and the Altirra emulator application have not been
run here; the tests use Atari800 with the Altirra replacement OS.

The v8 hoop revision raises the upper cap within the same canvas and shortens
the hanger, giving Charlie’s whole head room at the measured jump apex. Flame
pixels remain outside the opening. Both ordinary and shorter money hoops keep
the near/far layering; all six audience and bunting rows continue scrolling.
