---
name: mixamo-assets
description: Download Mixamo characters or animations for the Godot game and cast them in scenes. Use whenever the game needs a new person (judge, officer, witness, bystander), a new pose or animation (lying, kneeling, climbing), a recast, or when a character looks wrong on screen (bulging eyes, floating, wrong size, missing).
---

# Mixamo characters and animations

Files live in `godot/assets/mixamo/` (`characters/<name>.fbx`, `animations/<name>.fbx`). The folder is
git-ignored: Mixamo files may be used in a game but not redistributed raw. Record additions in
`godot/assets/MANIFEST.md`.

## Before downloading
- Mixamo needs the owner's Adobe sign-in in Brave. You cannot sign in for them. If the page shows a
  sign-in prompt, stop and ask the owner to sign in.
- Choose the characters yourself first: open `https://www.mixamo.com/#/?page=1&type=Character&limit=96`,
  scroll the grid and pick by look. Realistic people that match the current cast: Joe, Josh, Brian, Martha,
  Roth, Elizabeth, Jody, Alex (uniformed officer), Chad (scrubs), Louise, Leonard, Megan, Kate. Avoid the
  stylised ones (Aj, Claire, Timmy, Big Vegas, monsters).
- The owner wants downloads done by a cheaper model: spawn an Agent with `model: haiku` and give it the
  recipe below, the exact names, and the target paths. Keep working while it runs.

## Download recipe (for the helper)
- Use its own new browser tab. Confirm button positions with a screenshot; do not trust coordinates.
- Character: `https://www.mixamo.com/#/?page=1&query=NAME&type=Character` → click the tile labelled NAME →
  confirm the "change character" dialog → wait ~10 s → orange DOWNLOAD (top right) → keep "FBX Binary" and
  "T-pose" → DOWNLOAD.
- Animation: first select the character **Leonard** so every clip is exported on the same skeleton. Then
  `https://www.mixamo.com/#/?page=1&query=WORDS&type=Motion%2CMotionPack` → click a tile → DOWNLOAD → set
  Skin to **Without Skin**, 30 fps, no keyframe reduction. Tick "In Place" for walks and runs.
- Files land in `~/Downloads`. Characters arrive under an internal name (`Ch33_nonPBR.fbx`), not the
  character's name, so move each one straight after its own download: `mv` to
  `godot/assets/mixamo/characters/<lowercase name>.fbx`. Check with `ls -la` before reporting.
- Searches that found no plain clip: hands up / surrender, arms crossed, stand up, sit down. Ask for
  the exact Mixamo clip name in the helper's report.

## After downloading
1. Import: `godot --headless --path godot --import`. A clip that exists but is not yet imported is
   treated as missing by `Kit.clip()`, so always import before rendering.
2. Look at them: `godot --path godot -s tools/lineup.gd -- <out.png> joe martha brian`. It prints each
   model's height and mesh part names (`Ch33_Suit`, `Ch33_Hair`, ...). Those part names are the keys for
   recolouring.
3. Check a clip's length and hip height before using it (a "lying" clip can keep its hips at 1.0 m, so
   the actor must be placed about 1 m lower). Print the first and last hip position key of the clip.

## Casting in a scene (`godot/sets/*.gd`)
`actor(who, model, pos, rot_y, idle, talk, look)`:
- `who` is the story speaker ("HARLAN") or "" for an extra.
- `look` recolours parts by substring of the mesh name: `{"Suit": Color(0.12, 0.12, 0.13), "Hair": Color(2.4, 2.4, 2.4)}`.
  Values above 1 brighten. Reused models need a tint so two people in one room don't look identical.
- Use `clip("kneel", "idle")` for an animation that may not be installed.
- A face close-up is `close(who, dist, side, head_height, fov)`. Head height is about 1.58 standing,
  1.1 kneeling or sitting.
- A model in different units gets a scale in `HEIGHT` in `kit.gd`.

## Telling people apart
- Two named characters must never share a model, and a named character's model must not appear as an
  extra in the same scene (the jury once held doubles of Reyes and three witnesses).
- `look` keys: a part name recolours it (`"Hair"`, `"Body"` for skin, `"Suit"`, `"Shirt"`, `"Pants"`, `"Heels"`).
  Add `!` to drop the printed pattern as well (`"Shirt!"` turns a striped top into a plain one).
  Hair textures are dark brown, so grey needs a cool multiplier around `Color(2.7, 2.9, 3.1)`.
- `badge(actor)` clips a detective shield to the belt (automatic for REYES and OKONKWO); `robe(actor)` is the
  judge's robe; `foil_wrap(pos, rot, neck_y)` is an emergency blanket. Bone-attached cones look wrong in a
  close-up; build a draped mesh instead.
- `godot --path godot -s tools/costumes.gd -- out.png` shows the principal cast in costume side by side.
- Wardrobe reference (SVU): detectives in dark plain clothes or dark suits with a belt badge; lawyers in dark
  tailored suits; judge in a black robe; uniformed officers in dark navy.

## Action clips
- Clips that travel (jump, vault, slide, tackle) are pinned in place automatically by `Kit._anim`; the game
  moves the person. `game.gd` `ACT_CLIPS` maps a word in a step's label to the clip shown on success;
  `stumble` plays on failure.

## Known faults
- **Thin, see-through hair:** hair cards drawn one-sided. `actor()` now draws hair two-sided with a low alpha
  cut-off; do not set hair back to depth pre-pass.
- **Bulging eyes, dark rings round the eyes:** the file marks skin as see-through. `actor()` already
  forces non-hair materials opaque and hides lashes that point at the skin texture. If a new model still
  shows it, inspect its materials' `transparency` and albedo texture names before blaming the model.
- **Extra blocks a shot:** check the set's `shot("wide", ...)` camera line and move the extra off it.

Finish with the `scene-check` skill on every scene you touched.
