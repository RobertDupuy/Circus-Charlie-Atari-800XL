> Historical report. Current gameplay requirements and remaining work are in
> [ARCADE-FIDELITY.md](ARCADE-FIDELITY.md); current results are in
> [validation.md](validation.md).

# C64 executable-audited gameplay baseline

The implementation now closes all 15 gameplay/rule deficiencies in the recovered
C64 executable audit: G01–G10, R01–R04 and R06. The reference is the disassembled
and executed WGO image documented in the audit, not the manual. Its provenance
is a preserved game image, not a verified publisher master. The supplied
`assets/c64-patterns.json` preserves the decoded difficulty tables;
`src/mechanics-tables.inc` scales them into Atari coordinates.

This is a native Atari adaptation. Hitboxes, coordinates, animation sampling and
physics remain tuned for this port; the C64's instructions are not emulated.

| Audit IDs | Implemented behavior | Acceptance evidence |
| --- | --- | --- |
| G01, G02 | Hoops move toward a stationary player; three hardware hoop slots and independent pots; bagged hoop is a single 200-point event, ordinary hoop/pot 100 | Native collision and stationary-player tests; all ranks completed |
| G03, R02 | Pink monkeys leap when they meet a brown neighbor. A safe landing pays brown-only 200, pink-only 300, mixed 1,000; multiple browns do not stack | Reactive leaps and mixed rewards reached with ordinary input; fatal-jump and grouped-reward checks |
| G04 | Horse spring chain pays 100, then 200, then 300 per rebound, capped at 300; a manual jump resets the chain; a later crash does not revoke points | Immediate payout/cap/reset tests |
| G05 | Grounded arrival at the horse's endpoint is fatal; an airborne approach enables the final landing | Native grounded/airborne fixtures; complete input routes |
| G06 | Left/right changes the held rope's pose delay with phase-dependent direction, bounded −2…+3; neutral eases it toward zero | Timing-control and neutral-return checks |
| G07 | Missed trapeze catches can rebound from visible supports; stick direction controls recovery; rank 3 removes supports | Real support contacts; rank-2 route makes four recoveries; rank-3 route clears without supports |
| G08 | Four rope geometries, 42/24-step cycles, 13 authored rope/support positions and phase-sensitive release | All rank routes; four-type assertion; renderer pixel comparison |
| G09 | Ordinary deaths and continues restore a nearby checkpoint. Ground acts use 64-pixel chunks, clamped before the endpoint; balls, trampolines and ropes restore a support | Normal-retry, independent-player and all-seven-scene continue checks |
| G10 | Four authored pattern families for hoops, monkeys, balls, horse and trapeze, including changes of type and order | Decoded reference tables; 28 successful act/rank runs |
| R01 | Same ball 0, adjacent transfer 200, skipped ball 500 in either direction | Exact landing-reward tests |
| R03 | Every clear pays remaining countdown plus 2,000, including after a death | Native score checks |
| R04 | Fresh/retry countdowns remain 8,000/5,000. Trapeze drains at half the ordinary rate | 120-tick countdown fixtures |
| R06 | Easy begins at rank 0, Hard at rank 2; per-act rank caps at 3 | Title and progression checks |

The real-time timer is an explicit Atari choice: the nominal 60 Hz simulation
subtracts 10 every six ticks (twelve in trapeze), retaining the established
8000/5000 time allowance and adding the missing twofold trapeze allowance. PAL
uses fractional tick scheduling; this is not a literal copy of the C64's 8/16-call
counter. Ropes retain precomputed images; swing control changes pose timing,
not a runtime physics simulation.

## Deliberate improvements retained

- All six main acts plus water/dolphins; arcade act selection, independent
  completion counters, six-clear lockouts and the 36-performance ending.
- Live midair steering remains in the other applicable acts. Act 1 now follows the arcade's measured takeoff momentum, as documented in `ACT1-ARCADE.md`; it is an exception to the earlier general steering choice.
- Five-second, active-port continue before player handoff, at every rank;
  score and earned-life threshold survive. Continues restore three lives and
  grant 90 logic ticks of obstacle grace; falls and timeouts still apply.
- Correct every-20,000 extra-life progression beyond 100,000, optional arcade
  schedules, and score saturation at 999,990.
- Independent two-player careers, checkpoints and progress; full-act demo;
  source-derived POKEY music/effects and intermission applause.

The earlier manual-based claims of a 1,000-point ball skip, deferred flat horse
rewards and a death-free-only 2,000 award have been removed. The separate arcade
backlog remains in `arcade-features.md`; unverified arcade secrets are not being
invented as C64 requirements.
