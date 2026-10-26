# Arcade fidelity study and remaining differences

The target is the original `circusc` arcade game. C64 behavior is no longer an acceptable reason to retain different controls, spacing or difficulty.

## Why horse and trapeze previously differed

The earlier version retained simplified C64-based mechanics while concentrating on presentation, music and bounded rendering. That was a scope decision, not a demonstrated Atari hardware limit, and it did not satisfy the requested arcade-port target. Those differences should have been called unfinished work. This revision replaces both apparatus models and measures the resulting cost in Atari800.

## Evidence and method

The study used the user's existing `circusc.zip` with MAME. The archive SHA-256 is `a3356f8a621b7b234b8a8342bcfce03a89e64775259621f25c05ddd0f67280c0`. It is not included in the source distribution.

All six main arcade acts were completed in fresh MAME replays using coin/start, the act-selection controls and recorded joystick/fire input. The replays did not suppress collisions or write completion flags. Frame-by-frame RAM observations and screenshots were compared with the KONAMI-1 instructions and data tables. The title was captured separately without input.

The native tests execute the assembled 6502 cartridge. Search tools may save and restore test states while finding a route; each accepted route is then replayed from a fresh stage with ordinary input. Atari800 supplies the ANTIC/GTIA/POKEY and display-deadline checks. Its ranked fixtures install only an initial rank/stage state and an input stream; they do not change active gameplay code or collision handling.

The native candidate covers seven scenes at six ranks, and an uninterrupted 65-course career clears two shows and opens the third. The water integrator is also compared against 543 transitions captured from MAME. This is not a claim that all 36 original arcade performances have been independently replayed.

## Recovered behavior

| Course | Evidence applied in this revision |
| --- | --- |
| Lion | Existing 64-sample measured jump and fixed takeoff momentum; final raised-platform landing; GREAT/FAROUT messages |
| Tightrope | ROM group schedules, four brown/three pink object slots, faster pink motion, close-neighbor leap trigger, fixed jump arc |
| Trampolines | Original bounce motion and pedestal spacing; rank-specific fire-breather/juggler waves, 65-tick fire flight, 114-tick sword flight and 16-tick catch pause; complete normal course and bounded final landing |
| Balls | Exact 57-frame observed height sequence; 52-pixel apex; fixed takeoff direction; original spawn schedule and free/abandoned-ball drift; 100-point transfer and 500-point skip |
| Horse | 104-entry width/height/gap arrays; original opening run; 1/2/3 arcade-pixel travel speeds at 3/4 display scale; fixed airborne speed; velocity reflection and input resampling at spring contact |
| Trapeze | 32–60-pixel rope lengths; original pivot construction, sine/angle/period tables; phase-dependent amplitude pumping; four-frame position-history release velocity; gravity; automatic catches and recovery contacts |

The first normal trapeze pivots in Atari color pixels are 84, 183, 282, 378, 474, 567, 660, 750, 840, 936, 1032, 1125 and 1218. Their lengths are 60, 56, 60, 52, 60, 48, 60, 44, 60, 52, 60, 48 and 60. Recovery trampolines are present at the hardest implemented rank; removing them was an earlier adaptation.

## Presentation and speed

The title uses 32 procedural particles and palette cycling. It includes the original lettering adapted to the Atari resolution, a big top, KONAMI and copyright text, and player selection. START and fire open the optional arcade chooser, or begin Act 1 directly in the automatic build.

The horizontal marks above rolling balls had two concrete causes addressed here: an audio allocation could overwrite the common ball flags, and CHBASE changed too late at a font boundary. The packer now protects that data and the display code writes CHBASE before the scanline wait.

Trapeze ropes use prepared angle tiles, clipped endpoints and immutable glyphs. Hero composites and springboards use cached or native drawing paths with generic reference paths retained for pixel comparison. Finish-platform legs use two player objects so they do not paste static rectangles over the moving crowd. Graphics optimizations do not change the input or physics rules.

Video review also found stray player graphics when DMA was disabled without disabling the corresponding GTIA graphics input. DMACTL and GRACTL now change together, and an interrupt-level regression checks both registers. A separate title raster test caught and fixed the tent-pole pixel retaining a HUD color. The retained applause reference has a corrected two-scanline clock, but it is no longer triggered: its blocking playback paused the new celebration. Continuous command-1C victory music now accompanies the animation.

## Act 3 attack revision

The normal arcade replay was observed again through the ending. The actor
schedule at F56E and intervals at FB02 are retained as small data tables in
`assets/act3-arcade.json`. `evidence/act3-mame.json` contains 12 observed actor
spawns, all 65 fire-height samples and 113 observed sword-height samples. The
sword's remaining flight step and catch/rethrow state follow the recovered
integer integrator. Six native ranks select the source schedules, saturating at the last schedule, and
57/56/52/48/44/40-tick launch intervals. The normal finish is at Atari world X=1656.

The native renderer uses the original performer tile poses adapted to Atari
colours. Harmless performer bodies use two-pixel horizontal alignment; sword
art uses double-width hardware pixels. Physics and collisions retain their
full native coordinate precision. Each performer's projectiles share a player
bitmap, keeping six simultaneously visible shots present. This is a display
adaptation, not a reduction of the active projectile pool.

Act 1's missing flames were a separate regression: a prior display band could
leave GRACTL disabled. VBI now explicitly restores it with DMACTL, with a test
that begins from the disabled state.

## Completion work in this candidate

Water now uses four independent arcade dolphin slots, the original fixed-point vertical integrator and six rank schedules. The source observation fixture is `evidence/water-mame.json`; the compact schedule data is `assets/water-arcade.json`. Upright/inverted phases, normal and high bounces, retry, collision and prize rules are active. Its pedestal artwork and dolphin silhouettes remain scaled Atari artwork.

All six native ranks are selectable through actual act progression. Normal trampoline and monkey schedules were extended from source tables; balls use the last source schedule where it saturates. The complete-career regression clears 60 main performances and five water courses without forcing completion.

The pony departs during the clear picture. The trapeze partner approaches for a kiss, using adapted source frames. Retry reattachment recomputes geometry while freezing pendulum phase. Clear pays the remaining countdown, with an authored upright, front-facing Charlie wave, bird, blue-dollar sack and coin shower after every win. The extra 400 coin points still require an unharmed run. Meter boards now cover all acts and water; the horse boards sit along the back edge of its track. Trapeze approach boards stay fixed while GOAL follows the selected final platform. Main trampoline bags are placed above the second-bounce apex; the third bounce collects them, and the fourth visibly tears the big top before Charlie falls. This compressed Atari roof-impact sequence is an adaptation of the arcade's scrolling high jump. Money hoops now use the 1,000–5,000 ladder; third-bounce prizes use 300–900. A reverse-jump collectible, score cap and existing extra-life/continue careers are active.

The ground-level green palette uses existing display boundaries for its brighter-to-darker bands. Water pedestals and prizes use clipped/precomposed drawing paths; their gameplay coordinates are unchanged. Horse spring artwork is aligned to two colour pixels; collision and motion keep their full native precision.

## Known arcade-fidelity differences

The playable career is complete, but the following are not established as exact arcade reproductions:

| Area | Candidate behavior / remaining accuracy gap |
| --- | --- |
| Lion repeat courses | Later pot positions extend the earlier measured layouts; the entire reverse-travel/repeat-pot allocator has not been translated. Hoop variation uses a deterministic seed. |
| Hidden rewards | Reverse-jump/doll and bird/coin sequences are implemented, but their complete arcade trigger/reset choreography is not exhaustively reproduced. The special extra-life hoop and every act-specific hidden/end reward are not implemented. |
| Trapeze finish | The goal position still uses the earlier inferred construction/rounding. All six ranks have valid ordinary-input routes and a rendered celebration. |
| Career/continue | Independent two-player progress, five-use chooser lockouts and continuing harder shows work. The all-30 reset follows the requested policy; every arcade set/DIP-specific progression and continue policy has not been exhaustively mapped. |
| Horse retry | Restarts rebuild an earlier scrolling page and clear stale airborne state/overlapping objects. This supplies a recoverable approach; the exact arcade checkpoint policy has not been established. |
| Presentation | Character resolution, palette, transition pacing and some art are Atari adaptations. Music is a POKEY arrangement, not sound-chip emulation. Pictures update every two Atari refreshes. |

These notes distinguish a complete playable candidate from a claim of perfect arcade parity. They remain visible so unverified or absent arcade details cannot silently become accepted specifications.
