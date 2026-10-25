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
| Act-clear intermission | Converted original DAC command 80 applause |

All 11 music commands and 18 effect commands have prepared PAL and NTSC
streams (58 in total), including cues not yet assigned to gameplay events.
Command 1C is retained in the catalogue; the act-clear state initially selects
it, then the intermission applause takes over and leaves silence afterward.
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

## Sampled applause

The actual command-80 DAC waveform is centred, quantised to four bits and packed
into 14,478 bytes. Its 28,956 samples play once per two scanlines using POKEY's
volume-only mode. It lasts about 3.69 seconds on NTSC and 3.72 seconds on PAL;
the shared sample has the small line-clock pitch/duration difference. It is
restricted to act-clear/completion intermissions. The completed playfield and
GREAT/FAROUT remain visible, with normal DMA and display interrupts. Playback
starts after an eight-VBI presentation delay. Its two-scanline clock catches up
after interruptions instead of stretching the sample timeline. The complete
payload is checked under PAL/NTSC VBI interrupts, and a recorded POKEY waveform
is checked against the original prepared sample.
There is no PCM decoding or sample interrupt during active gameplay.

This preserves the audience cue without using the game's collision/rendering
budget. The longer command-81 and shorter command-82 variants are not separately
implemented. The four-bit conversion has less dynamic range than the arcade
DAC. Physical-hardware listening and subjective mix approval remain necessary
before describing the audio as release-final.

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
