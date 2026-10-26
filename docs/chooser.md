# Optional arcade chooser

This candidate has exactly two build profiles:

| Build command | Progression |
| --- | --- |
| `python3 tools/build.py --chooser arcade` (default) | Six-panel arcade chooser before the first act and after clears |
| `python3 tools/build.py --chooser automatic` | Act 1 starts directly; acts advance automatically in order, without a chooser |

The former text selector is removed. The build option is not a player-facing menu. The test feature is isolated in `src/chooser.s`; its code, prepared artwork, entry hooks and ROM reservation are omitted by the automatic build. To remove it later, choose the automatic profile. Gameplay, checkpoints and audio use the same source modules in both builds.

## Progress and controls

Left/right advances one available panel per stick press and wraps around. Up/down moves to the panel in the same column on the other row. It does not wrap vertically; an exhausted destination leaves the cursor in place. Releasing the stick does not move the cursor. Fire commits the highlighted act. The six panels retain the supplied arcade layout and labels: EASY, NORMAL, NORMAL, HARD, HARDER, HARDEST. A white outline identifies the current choice, while the footer gives the act name, next performance out of five, and show number.

Every successful main performance fills a progress dot. Five filled dots replace the panel caption with **NO MORE**; left/right skip the panel. A lost life retries that performance without consuming another pick. Water/dolphins is a trampoline variation, not a seventh selectable panel: it follows every second ordinary trampoline completion, including across show boundaries.

Completing all six acts five times clears the availability counters for a new show. Score, lives and the water cadence continue; there is no 30- or 36-act ending. Each player retains independent counters, show, score, lives and retry state. A player's first turn opens the chooser; later lost-life turns resume that player's current act.

The first five performances use each act's source schedules 1–5. All later shows use schedule 6, the hardest implemented schedule. Several source tables already plateau before that. This build does not invent indefinitely faster hazards beyond the recovered schedules. The show display caps at 99 while play remains available.

## Supplied arcade reference

The attached `circusc 2.zip` matches the existing level-select reference set. The six-panel arrangement and captions were checked against the supplied screenshot and fresh MAME captures using ordinary coin/start/stick input. The source set uses `NO MORE` for exhausted activities.

Compact disassembly observations (KONAMI-1 addresses):

- `$220E` through `$2213`: the six per-act selection counts.
- `$C364` through `$C383`: chooser navigation checks counts against five and skips exhausted activities.
- `$BFFC` through `$C05D`: chooser text draws the exhaustion caption for counts of five or more.
- `$FD14`: the `NO MORE` caption, with the source's space code.

The source increments a count on selection, then keeps that performance through retries. This port records it on successful completion; availability at each normal chooser visit is equivalent. The all-thirty reset follows the requested behavior; the exact rollover behavior of every arcade ROM/DIP variant has not been independently established. The white cursor frame and five progress dots adapt the presentation to Atari resolution.

No private arcade ROM or full disassembly is included. The prepared icon extracts and packed character artwork are sufficient to rebuild. `python3 tools/chooser_assets.py` regenerates those character assets with Pillow and NumPy.

## Verification

`tests/chooser_rules.py` checks all six starts, held/released stick input, horizontal wrap, all three vertical columns, vertical lockouts, locked captions and dots, frozen gameplay while choosing, exact asset decoding, and five consecutive Act 1 clears using ordinary controls. `tests/arcade_rules.py` separately checks transition fixtures and independent player progress.

`tests/complete_campaign.py` clears 60 main acts and five water courses with ordinary input, reaching the third show without forced clears or disabled collisions. The same test runs against both build profiles. `tests/interrupt_audio.py` checks menu rendering and asset loading while native audio interrupts occur.

`tests/xl_ui.py ntsc` and `pal` use an unmodified Atari800 cartridge for title controls, reset, all six stage entries and static-raster checks. A separately identified counter fixture checks locked panels. Saved icon pixels are compared across every selection, reset and lockout.

See [validation.md](validation.md) and `evidence/chooser/` for the candidate's exact build hashes and results.
