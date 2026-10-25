# Original arcade study

MAME 0.251 and the user's original `circusc` set were used to clear all six
main acts with ordinary coin/start/joystick/fire input. See
`../docs/ARCADE-FIDELITY.md` for scope and remaining differences. The original
ROM archive and disassembly are not included in the release package.

`arcade-replay.lua` replays an input sequence from a fresh boot. It writes no
arcade RAM. It logs the original work RAM every frame and saves a screenshot
every six frames. `arcade-title.lua` captures the title without input.
`arcade-act1.lua` preserves the earlier measured lion scenarios; only its
explicit `sweep` scenario changes state to isolate spacing and is not used as
playthrough proof.

```sh
MAME_BIN=/path/to/mame MAME_ROM_DIR=/path/to/roms \
ARCADE_INPUT_FILE=/absolute/path/to/inputs.txt \
ARCADE_SCRIPT=arcade-replay.lua python3 research/run_arcade.py replay
```

The input file stores one integer per frame: bit 0 left, bit 1 right, bit 4
fire. Coin/start are fixed by the replay script. Initial act selection is part
of the input stream. Each accepted search route was replayed independently;
savestates used while finding a route do not bypass collisions in the replay.

Selected completion frames, input sequences and frame logs are preserved in
`../evidence/mame-main-acts/`. The title reference is also retained there.
The first normal pass was studied, not all 36 arcade performances. Water and
later repeated-round patterns remain unverified.

MAME's `circusc` driver snapshot is retained with its licence. The native
Atari build requires neither MAME nor the original arcade ROM.
