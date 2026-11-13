---
name: scene-check
description: Render the Godot game's scenes to pictures and look at them. Use after any change to a set, a character, lighting, camera shot or prop, and whenever asked how a scene looks - do not report a visual change as done without rendering and viewing it.
---

# Render and look

Code that runs is not proof a scene looks right. Faces, floating people, blocked cameras and dark rooms
only show in a picture.

## Render
    godot/tools/shots.sh <out-dir> precinct:harlan courthouse:trial yard:dawn_hurt

Each argument is `<set>:<stage>`; it saves every named camera shot and every action-sequence camera
step as PNG, and prints script errors. Use a scratch folder for `<out-dir>`, not the repo.
Stages are the `match stage` / `if stage ==` names in `godot/sets/<set>.gd`
(apartment, precinct, library, delancey, yard, terminal, courthouse).
Story state that changes a scene can be preset: `godot --path godot -- --stage library:fence --set fled=1 --shots <dir>`.

## Look
- Contact sheets: `godot/tools/sheet.sh <dir>` writes `sheet_N.jpg` (6 pictures each). Copy only the
  shots you care about into a folder first; reading every PNG one by one is slow and costly.
- Read the sheet image. For a face or a detail, read the single PNG.
- People only: `godot --path godot -s tools/lineup.gd -- <out.png> joe martha`.

## What to check
- Faces in every close-up (eyes, skin, the right person).
- Feet on the floor, seated people on their seat, nobody inside furniture or walls.
- Nothing between the camera and its subject in the `wide` shot.
- Readable signs and enough light to see the room.
- A black frame usually means the snapshot fell in a fade: a test artefact, re-render before fixing.

## Shell traps on this machine
- Run `godot --headless --path godot --import` after adding assets, before rendering.
- Don't use `pkill -f` with a pattern that also appears later in the same command line; it kills the shell.
- Chained foreground `sleep` and `rm $VAR/*` are blocked.
