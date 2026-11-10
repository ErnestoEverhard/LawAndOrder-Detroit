# DEAD SIGNAL

A choice-driven interactive drama in the style of a police procedural: timed dialogue,
crime-scene investigation, quick-time action sequences, a courtroom final act, and an
end-of-chapter flowchart showing the paths you didn't take. Original story and characters.

## Play

Open `index.html` in a browser. No build step, no dependencies.

- `SPACE` / click — advance dialogue
- `1`–`3` — pick a (timed) choice
- `W A S D E SPACE` — action prompts: press, tap rapidly, or hold (prompts are also clickable)

## Structure

- `story.js` — all story nodes, state effects and flowchart definitions (pure data, no DOM)
- `art.js` — one illustrated still per location, drawn as SVG
- `game.js` — engine: stills, dialogue, choices, investigation, QTEs, flowcharts
- `tools/validate.js` — `node tools/validate.js` checks every link and plays 20,000 random runs
  to confirm there are no dead ends and every node and ending is reachable

## Your own images

To replace a still with a real image, save it as `img/<name>.jpg` (16:9 works best). Names:
`title apartment hallway dock chase interview booking yard fire dawn court house alley terminal`.
Open `index.html?gallery` to see all the built-in stills, or `index.html?at=<nodeId>` to jump to a scene.

Four chapters, six endings, and a second suspect you can wrongly charge. What you find in chapter 1 and how you cut corners in chapter 2
decide what the prosecutor has left to work with in chapter 4.

## Godot prototype (3D)

`godot/` is an experimental Godot 4 version of the chapter 1 apartment search: a first-person room you
walk around, built from simple shapes with real-time lighting. Run it with `godot --path godot`
(click to look, WASD to walk, E to examine, Esc to release the mouse). It is a look-and-feel test
only; the full story still lives in the browser version.
