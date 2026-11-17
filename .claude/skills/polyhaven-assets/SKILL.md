---
name: polyhaven-assets
description: Fetch furniture, props, surface textures and sky images from Poly Haven for the Godot game and place them in a set. Use whenever a room looks empty or fake, a scene needs a prop or a wall or floor material, or a new location is being built.
---

# Poly Haven models, textures and skies

All CC0, committed to git under `godot/assets/` (`models/<id>/`, `textures/<id>/`, `hdri/`).

## Fetch
1. Find the asset id on polyhaven.com (the last part of `https://polyhaven.com/a/<id>`).
2. Add the id to the `MODELS`, `TEXTURES` or `HDRIS` list in `tools/fetch_assets.py`.
3. Run `python3 tools/fetch_assets.py` (skips what is already there; `--list` shows present/missing).
   For a long list, hand this step to a cheaper model (Agent, `model: haiku`).
4. `godot --headless --path godot --import`, then add the id to `godot/assets/MANIFEST.md`.

Some models have no glTF (`decorative_book_set_01`) or exceed the size cap; the script reports them. Pick another.

## Use in a set (`godot/sets/*.gd`, helpers in `godot/kit.gd`)
- `prop(id, pos, rot_y, height, solid)` places a model; `height` 0 keeps its real size.
- `tex(id, scale, tint)` gives a material for `tbox`, `wall_x`, `wall_z`. Tint above 1 lightens.
- `env(hdri, ...)` sets the sky and ambient light.
- Sizes and centres of every model: `godot --headless --path godot -s tools/sizes.gd`. Check before
  placing, because some models are much larger or have an off-centre origin.

## Things that went wrong before
- A texture can look nothing like its name at 1k (`painted_concrete` read as green marble). Render it.
- Dark wood panelling swallows a room; tint it up (about `Color(1.45, 1.3, 1.15)`).
- Rooms should look lived in, not staged: add the small things (coats, mail, cups, a wet-floor sign),
  not only the furniture. Look at reference stills of real precincts and courtrooms first.

Finish with the `scene-check` skill.

## Things Poly Haven does not have
Vehicles and soft items are built in `godot/kit.gd`: `van(pos, rot, colour, open, text, stripe, lightbar, kind)`
with `kind` one of van, car, truck, coach (outlines in `VEHICLES`); `blanket()`, `tape_roll()`, `sneaker()`.
Preview all vehicles with `godot --path godot -s tools/vehicles.gd -- out.png`.
