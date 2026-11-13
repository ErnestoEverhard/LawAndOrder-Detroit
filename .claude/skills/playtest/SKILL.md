---
name: playtest
description: Test the Godot game end to end - story graph check, automatic playthroughs, robot playthroughs with real key presses, and jumping to any scene. Use after any change to story.gd, game.gd, case_state.gd or a set, before every commit that touches them, and whenever asked whether the game works.
---

# Play-testing

Run from the repo root. Game arguments go after `--`.

| Check | Command | Pass looks like |
|---|---|---|
| Story graph | `godot --headless --path godot -s tools/validate.gd` | `OK`, plus ending rates from 20,000 random runs |
| Fast self-play | `timeout 300 godot --path godot -- --auto` | `AUTO RUN FINISHED strength=...`, no `SCRIPT ERROR` |
| Robot, real keys | `timeout 570 godot --path godot -- --robot` | same line, no errors; takes about 8 minutes |
| Old browser version | `node tools/validate.js` | `OK` |

Filter the output: `2>&1 | grep -iE "SCRIPT ERROR|ERROR|FINISHED" | grep -v "resources still\|ObjectDB"`.
The two excluded messages appear on every exit and mean nothing.

## Switches
- `--at <node>` start at a story node (ids are in `godot/story.gd`, e.g. `c4_verdict`).
- `--set k=v,...` preset state: `clue.<id>=1`, `strength=70`, `late=2`, `trust=1`, `chapter=4`, any flag.
- `--auto [skill]` random choices, instant action sequences; `skill` 0-1 is the success chance.
- `--robot` injects key presses and walks the player in search scenes. `ROBOT_DEBUG=1` prints its aims.
- `--shots <dir>` saves a picture of each shot as it is first used.

## What each mode does not cover
- `--auto` skips sound, typing speed and real input. Run it two or three times: each run takes one random path.
- `--robot` cannot hold a key, so "hold" prompts only take their failure path.
- Neither is a person playing. Pacing, timer lengths and how the prompts feel are untested until the
  owner plays; say that plainly in the report.
- One run covers one route. To cover a branch, start at it with `--at` and `--set`
  (the Evan detour, the bus terminal, the standoff and Tessa testifying are the rarely reached ones).

## After testing
State what ran, what passed and what was not run. Then commit on `dev` (the owner wants a commit at
the end of every turn).
