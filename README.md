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

## Godot version (3D) — the main game

`godot/` holds the full game in Godot 4: every chapter, played over 3D locations.

```
godot --path godot
```

- **Controls:** SPACE advances dialogue, 1–3 pick a timed choice, W A S D E SPACE answer action prompts, mouse and WASD walk in the search scenes, ESC pauses.
- **Characters:** the people are Mixamo models, which are not in this repository (licence). Put them in `godot/assets/mixamo/` as described in `godot/assets/MANIFEST.md`; without them the game still runs, with empty rooms.
- **Assets:** furniture, surfaces and skies are Poly Haven (CC0), fetched by `tools/fetch_assets.py` and listed in the manifest.

| File | What it is |
|---|---|
| `godot/story.gd` | The story graph: scenes, choices, searches, action sequences, endings, flowcharts |
| `godot/case_state.gd` | What a playthrough remembers: evidence, flags, case strength |
| `godot/game.gd` | Plays the story: dialogue and camera cuts, timers, prompts, searches, interface |
| `godot/kit.gd` | Building blocks shared by the locations |
| `godot/sets/*.gd` | One script per location, each with several arrangements |

Checks:

```
godot --headless --path godot -s tools/validate.gd     # story graph: links, dead ends, every ending reachable
godot --path godot -- --auto 0.8 --shots /tmp/shots    # plays itself with random choices and saves a picture of each shot
godot/tools/shots.sh /tmp/shots courthouse:trial        # renders every camera shot of one arrangement
```

The browser version above is the earlier 2D prototype. Its story is older than the Godot one.
