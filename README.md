# Lambda Labyrinth

OCaml terminal game for CS 3110 A3. Collect at least eight lambda points and enter the exit before the sandworm catches you.

## Run

From this folder, in a terminal with the course OCaml environment active:

```sh
dune exec bin/main.exe -- 42
```

Omit `42` to choose a seed automatically. The displayed seed reproduces the same initial world. Use `--help` for usage. Requires OCaml, Dune and OUnit2; Unix ships with OCaml.

Color is enabled automatically in a terminal: the camel has a cyan background, the worm a red background, the exit is green, and treasure uses copper/silver/gold colors. Redirected output stays plain text.

## Controls

- `w`, `a`, `s`, `d`: move up, left, down, right, immediately without Return.
- `.`: wait one turn; `q`: quit.
- `C`: camel; `W`: worm; `?`: undiscovered; `#`: wall; `.`: floor.
- `c`, `s`, `g`: copper (1), silver (3), gold (5); `>`: exit.
- `X`: defeat; `^`: victory. Ctrl-C also exits and restores input mode.

The worm moves once after each legal move or wait. Blocked moves and unknown keys spend no turn. It chooses the closest legal neighboring cell, breaking ties north/east/south/west; it cannot enter the exit. A win ends the turn before it moves.

## Check

```sh
dune build @all
dune test
python3 test/terminal_smoke.py
```

The OUnit suite tests explicit tiny maps and generator properties across 100 seeds. The Python smoke check uses a pseudo-terminal to verify immediate input and restoration after quit, signals and an exception; Python 3 is needed only for this extra check. Run in a terminal at least 80 columns wide and 26 rows high for comfortable display.

## Code map

`lib/world.ml` owns the private mutable arrays; `game.ml` owns the turn engine and permanent discovery; `generate.ml` builds four connected rooms with a local seeded RNG; `display.ml` renders without mutation. Each has a documented `.mli`. `bin/terminal.ml` owns Unix terminal settings, input and cleanup. `bin/main.ml` validates the seed and starts the game.

`docs/PROCESS.md` records actual development checks. The supplied HTML and assignment handout are external references and are not copied into this project.
