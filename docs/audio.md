# Arcade-derived audio on one POKEY

This build replaces the placeholder march with a prepared arrangement of the
original arcade sound-driver output. It targets a stock 64 KB 800XL with one
POKEY and the same 512 KB SIC! cartridge. Stereo hardware is not required.

## Source and conversion

The examined arcade set is `circusc`. Its audio CPU runs the supplied
`380_l14.5c` and `380_l15.7c` programs, driving two SN76489A chips and a DAC.
`tools/arcade_sound.c` executes that Z80 program offline using the retained,
licensed `vendor/z80.h`. Its clock, timer and chip-write memory map follow
MAME's `src/mame/konami/circusc.cpp`. `tools/arcade_probe.lua` records actual
MAME commands/chip writes while selecting and playing each of the six acts.
The opening lead-note/envelope sequence agrees with the independent MAME log.
The full original ROM files are not included and are not required to build.

The runtime does not execute the arcade CPUs. `prepare_arcade_audio.py` projects
recorded chip states into POKEY registers and produces duration/mask packets.
The prepared JSON streams are the canonical build inputs. `pack_audio.py`
places complete packets in verified unused cartridge ranges and resolves
cross-bank links, loop destinations and one-shot endings. The candidate stores the ninth mask bit in duration bit 7, splitting waits longer than 127 updates. All 58 decoded streams retain the same register frames; packet storage drops from 106,924 to 89,930 bytes.

| Situation | Arcade source command(s) used |
| --- | --- |
| Lion / horse music | 13 |
| Tightrope / balls music | 14 |
| Land and water trampolines | 15 |
| Trapeze | 16 |
| Death | 17 plus impact 4F |
| Hurry music | 18, 19, 1A, 1B by act |
| Selection | 1D; cursor tick 52 |
| Introduction | 4C whistle over the act arrangement |
| Lion jump | 47 |
| Other jump/release / trampoline bounce | 44 / 45 |
| Horse jump/rebound arrangement | 4B |
| Point reward / extra life | 49 / 50 |
| Animated act-clear celebration | Source command 1C through the ordinary music stream |

All 11 music commands and 18 effect commands have prepared PAL and NTSC
streams (58 in total), including cues not yet assigned to gameplay events.
Command 1C now plays continuously throughout the act-clear animation. It is
not interrupted by the blocking DAC player, and the stream is not discarded
halfway through the celebration.
Some event assignments are port arrangements; this is not a claim of exact
arcade mixing or an exact transcription of every event trigger.
The death pause lasts 2.5 seconds so its 2.32-second tune finishes before retry.

## Channel decisions

The usual allocation is lead, harmony, percussion/doubled melody and bass.
A low harmony part can exchange positions with bass. Whenever the lowest part
falls below the ordinary 8-bit divisor range, channels 3+4 join with a fast
clock to retain its pitch. No two retained low parts require that pair at the
same time in the captured material. Effects temporarily own that pair, leaving
the first two musical voices audible. The music cursor continues underneath,
so the other parts return in time when the effect ends. Extra-life cues have
priority over ordinary jump/reward interruptions. Pause freezes both streams
and silences all four channels.

The arcade's eight PSG voices, noise generators, DAC and analogue filtering
cannot be reproduced literally by four POKEY channels. The prepared conversion
keeps the original notes, source envelopes and sequencing, but reduces voices,
uses POKEY timbres and approximates noise. PAL/NTSC music has separately tuned
divisors and event rates; it is not played at the wrong television tempo.

Playback runs twice per video refresh (about 119.85 / 99.72 updates per second).
Updates are separated by the existing VBI and the DLI at playfield scanline 24, so spacing within a
refresh is not exactly uniform. The decoder now uses unrolled register-mask and output paths, with identical verified register output. A full register change is bounded; the measured
maximum in the simultaneous music/effect CPU test is 607 cycles, excluding
ANTIC DMA. Active-play timing is validated in the complete hardware-emulator
runs, with the audio engine enabled, rather than inferred from this number.
Both interrupts restore the complete SIC control byte and use private scratch
state. An interrupt test covers 136 positions during all seven scene renderers
and decimal scoring.

## Retained applause reference

The original command-80 DAC waveform and its four-bit player remain in the
source and cartridge for reference, with the standalone PAL/NTSC payload test.
They are no longer triggered by normal gameplay or celebrations. That player
held the foreground for about 3.7 seconds and then cleared the music state,
which caused the reported animation freeze and silence. Animated celebrations
now use the existing interrupt-driven command-1C arrangement throughout.

This changes the clear-state mix: the sampled crowd applause is not played.
No music notes or event-stream payloads were changed. The 58 source-derived
POKEY streams, death cue, jump sounds and scoring cues remain. There is no PCM
decoding or sample interrupt during active gameplay or the celebration.

## Validation and remaining sound work

`tests/arcade_audio.py` executes every complete prepared stream through the
assembled 6502 decoder and compares every output register, including all bank
links and loop points. It also tests simultaneous playback, effect restoration
and pause. `tests/interrupt_audio.py` tests interrupted graphics and decimal
scoring. The MP4 uses native Atari800 AVI capture and contains its actual POKEY
audio, not a separately overlaid arcade soundtrack.

Remaining audio polish includes comparing every gameplay cue trigger, refining
voice priorities and noise timbres, the layered 4C/4D opening, additional sample
variants, and listening on physical POKEY hardware. Those are recorded rather
than being labelled complete merely because the soundtrack is now recognisable.
