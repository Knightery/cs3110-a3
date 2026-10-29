# Lambda Labyrinth Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task by task.

**Goal:** Build the default A3 terminal game in the user's a3 folder.
**Architecture:** World owns private mutable terrain/treasure arrays. Game owns discovery, actors and strict turn order. Generate creates connected rooms with local seeded randomness. Display observes Game; Terminal handles Unix input and cleanup.
**Tech Stack:** OCaml 5.3, Dune 3, OUnit2, Unix.
**Spec:** /Users/matthewwang/Downloads/TECHNICAL_DESIGN.html; checked against the adjacent A3 assignment PDF. Reference documents stay outside a3.

## Global Constraints
- Default escape threshold 8; copper/silver/gold values 1/3/5.
- At most 20 rows by 70 columns; proposed map 17 by 41.
- Collision before collection; victory before worm movement; worm ties N/E/S/W, excludes exit and must move if possible.
- Every library implementation has a documented interface; constructors defensively copy arrays.
- Immediate WASD, period wait, q quit; blocked/unknown input changes nothing.

## Review Focus
- Ragged/empty layouts and invalid placements reject with Invalid_argument.
- No state change after game over or on a blocked move.
- Fog persists and worm visibility does not reveal terrain.
- Seed validation and independent RNG state preserve repeatability.
- Terminal restoration on quit, EOF, interruption and exceptions.

### Task 1: Tiny worlds move, reveal, collect, and resolve outcomes
**Files:** lib/world.ml[i], lib/game.ml[i], lib/display.ml[i], test/test_labyrinth.ml.
**Interfaces:** World.position = {row:int; col:int}; World.of_layout copies input; Game.start copies world; Game.apply mutates in place; Display.render returns string.
- [x] Write OUnit sequence tests with literal positions/scores/outcomes for movement, fog, collection, collision order, victory and deterministic worm behavior.
- [x] Run dune test and confirm placeholder implementations fail.
- [x] Implement World, Game and Display with private arrays and read-only accessors.
- [x] Run dune test; all core tests pass.

### Task 2: Seeds create valid varied connected mazes
**Files:** lib/generate.ml[i], test/test_labyrinth.ml.
**Interface:** Generate.create : seed:int -> World.t * World.position * World.position.
- [x] Add reproducibility and independent BFS property tests over 100 seeds; verify dimensions, unique placements, distance >=6, reachable exit/worm/loot, total loot >=8, wall borders, terrain variation.
- [x] Run tests with a placeholder generator; observe failure.
- [x] Implement four connected randomized rooms; choose actors and exit only from validated candidates; place one gold, one silver and two copper.
- [x] Run dune test; generator properties and core suite pass.

### Task 3: Immediate terminal play and documented delivery
**Files:** bin/main.ml, bin/terminal.ml, bin/dune, README.md, docs/PROCESS.md, test/terminal_smoke.py.
**Interfaces:** Terminal.run : Game.t -> unit. Main parses optional nonnegative integer seed and builds the game.
- [x] Add executable smoke checks for CLI errors and PTY input/quit/EOF/SIGINT/exception cleanup, before writing terminal code.
- [x] Implement the executable using Fun.protect and saved terminal/signal attributes.
- [x] Build, run dune test and PTY smoke checks; record actual results in PROCESS.md.
- [x] Review implementation against references and copy only project files into the requested a3 directory.
