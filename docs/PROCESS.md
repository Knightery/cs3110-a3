# Development record

This record describes agent-assisted implementation on October 28, 2026. It does not claim these checks were personally performed by the student. The supplied technical design was checked against the local A3 assignment handout. The implementation uses the default rules; no customization document is required. Both reference files remain outside this project.

## Task 1: Move around tiny worlds and observe ordered state changes

**Plan and expected check.** Construct explicit maps without generation, move through floor and against walls, revisit treasure and revealed cells, and trigger pursuit/collision/escape. OUnit assertions should match manually chosen positions, scores, turns and outcomes. Rendering and separate game fixtures should not interfere with those results.

**Checks performed.** `dune test` initially ran 17 cases and reported 17 errors from explicitly unimplemented operations. After implementing World, Game and Display it reported `Ran: 17 tests ... OK`. Cases include blocked/out-of-bounds no-change, permanent cross discovery, worm visibility without fog revelation, values 1/3/5, collection once, a traversable exit below threshold, immediate collision before pickup, worm collision after wait, three tie directions, mandatory movement away, exit exclusion, victory before pursuit and immutable finished states. Independent games and repeated rendering were compared before/after mutation. A later additional case observes gold remaining visible after a worm traverses it, bringing the final core count to 18.

**Reasoning.** A tiny row with gold on the worm's position catches collecting before collision: score must remain zero after moving onto it. In a separate row, gold then silver gives scores 5 then 8; the worm is isolated behind the exit, so entering the exit must end in victory before pursuit. Explicit cases allow intermediate expectations independent of generation.

**Changes.** Initial build rejected ambiguous adjacent interface docstrings; spacing was corrected before running the tests. Public constructors reject empty/ragged layouts, duplicate or invalid loot, invalid actor placements and negative seeds with `Invalid_argument`. Tiny maps can omit an exit, making scenarios independent of generation constraints. No rule changes.

## Task 2: Reproduce varied, connected multi-room maps from seeds

**Plan and expected check.** Repeated seeds must reproduce terrain, loot and placements despite unrelated generation or global RNG use. An independent test BFS should establish connectivity, exit access, worm access while blocking exit, valid distinct placements at distance at least six, borders and enough reachable loot across 100 seeds. Terrain should vary among sampled seeds.

**Checks performed.** Four generation cases were added before implementation. `dune test` reported four errors from `Generate.create not implemented`, with the 17 core cases passing. After implementation it reported `Ran: 21 tests ... OK`. The property test checked every seed 0 through 99; repeatability separately checked 0, 1, 2, 42, 2026 and `max_int`. A later full suite with the extra core case reported `Ran: 22 tests ... OK`.

**Reasoning.** The property test implements its own breadth-first traversal and checks the returned map instead of trusting generator validation. All floor cells must connect; the worm-to-camel path is checked again treating the exit as blocked. Terrain comparison excludes treasure/actors, so variation cannot pass merely because placements vary.

**Changes.** Rather than a finite random retry budget for actors, the generator shuffles available floor cells and examines valid exit/worm candidates exhaustively, using flood fill with each exit blocked. An impossible placement produces a clear failure. Four connected randomized rooms on a 17 by 41 map and gold/silver/two copper (10 total points) retain the proposed design.

## Task 3: Play with immediate keys and restore the terminal

**Plan and expected check.** Build a small executable accepting an optional nonnegative seed. A pseudo-terminal must observe a wait turn before Return, ignore an unknown key, and restore terminal input settings after quit, interruption and exceptional unwinding. Pipes should terminate on EOF. CLI errors should give a helpful message and exit status 2.

**Checks performed.** `test/terminal_smoke.py` was written before the terminal implementation; after building a placeholder executable its CLI error-message assertion failed as expected. The final checks were:

```text
dune build @all                  -> exit 0
dune test --force                -> Ran: 22 tests ... OK
python3 test/terminal_smoke.py    -> PASS: CLI validation, pipe EOF, immediate keys,
                                   quit, SIGINT, SIGTERM, exception cleanup
```

The PTY test reads the initial frame, verifies canonical mode and echo are disabled, sends `z` and observes turn 0, sends `.` without Return and observes turn 1, then quits. Separate runs send SIGINT/SIGTERM and assert statuses 130/143 plus restored attributes. A probe calls the actual terminal guard, raises an exception during immediate-input mode, and confirms restoration afterward. CLI tests cover negative, malformed, overflowing, omitted and extra arguments, help, and input EOF. Source files were formatted with `ocamlformat` before the complete checks.

**Changes.** On macOS the initial exact termios comparison found only `PENDIN` changed. A separate Python-only switch to noncanonical mode and back reproduced it (local flags 1483 -> 536872395; the next terminal read clears it). The test now masks only that transient kernel flag while comparing every other setting, including echo, canonical mode and control characters. Production restoration still reapplies the saved Unix attributes. Terminal input also accepts uppercase controls and supports redirected input for automated checks; default gameplay rules are unchanged.

**Limits.** PTY checks exercise real Unix terminal handling but do not establish appearance in every terminal emulator. The game has no promise that every seed can be survived; the required terrain paths and sufficient reachable treasure are validated. No submission or upload was performed.

## Final review and placement

An independent code review found no important correctness findings. Its documentation-placeholder note was resolved by filling this record with the observed evidence above. The 22 project files were placed in `/Users/matthewwang/Desktop/cs3110/10:7-/a3`; reference HTML/PDF and temporary build output were excluded from the copy. Final build, full OUnit suite and PTY checks were rerun from that destination.

## Readability update

User requested color because monochrome cells were hard to see. Added optional ANSI styling to Display and enabled it automatically for terminal output. Camel uses a cyan background; worm uses a red background; walls are bright, exit green, treasure copper/silver/gold. Plain rendering remains available for redirected output. A new OUnit case first failed on absent ANSI styling, then passed after implementation; stripping color preserves the entire original frame and game state. PTY checks now also require the distinct camel/worm color sequences.
