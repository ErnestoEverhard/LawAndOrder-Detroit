# Asset manifest

Downloaded for the night-time apartment scene. Layout: `models/<id>/`, `textures/<id>/`, `hdri/`, `fonts/`.

## Models (Poly Haven, CC0, glTF 1k)

Each model directory holds the `.gltf`, its `.bin` buffer, and a `textures/` subfolder with the maps the glTF references.

| Id | What it is | Source | Licence | Files saved | Size |
|---|---|---|---|---|---|
| `modern_arm_chair_01` | Modern armchair (armchair) | https://polyhaven.com/a/modern_arm_chair_01 | CC0 | `.gltf`, `.bin`, 6 textures | 2.6 MB |
| `vintage_day_bed` | Vintage day bed / sofa-bed (bed substitute) | https://polyhaven.com/a/vintage_day_bed | CC0 | `.gltf`, `.bin`, 3 textures | 2.4 MB |
| `SchoolDesk_01` | Single-seat school desk (desk) | https://polyhaven.com/a/SchoolDesk_01 | CC0 | `.gltf`, `.bin`, 3 textures | 420 KB |
| `SchoolChair_01` | Metal/plastic school chair (desk chair) | https://polyhaven.com/a/SchoolChair_01 | CC0 | `.gltf`, `.bin`, 3 textures | 480 KB |
| `sofa_02` | Sofa (fabric/leather) | https://polyhaven.com/a/sofa_02 | CC0 | `.gltf`, `.bin`, 3 textures | 432 KB |
| `Shelf_01` | Wooden bookshelf (bookshelf) | https://polyhaven.com/a/Shelf_01 | CC0 | `.gltf`, `.bin`, 3 textures | 604 KB |
| `side_table_01` | Modern side table (nightstand) | https://polyhaven.com/a/side_table_01 | CC0 | `.gltf`, `.bin`, 3 textures | 500 KB |
| `desk_lamp_arm_01` | Arm-mounted desk lamp | https://polyhaven.com/a/desk_lamp_arm_01 | CC0 | `.gltf`, `.bin`, 3 textures | 2.8 MB |
| `modern_ceiling_lamp_01` | Modern hanging ceiling lamp | https://polyhaven.com/a/modern_ceiling_lamp_01 | CC0 | `.gltf`, `.bin`, 3 textures | 436 KB |
| `classic_laptop` | Old beige laptop (electronics; dated styling) | https://polyhaven.com/a/classic_laptop | CC0 | `.gltf`, `.bin`, 3 textures | 2.1 MB |
| `potted_plant_02` | Potted plant (terracotta pot) | https://polyhaven.com/a/potted_plant_02 | CC0 | `.gltf`, `.bin`, 6 textures | 2.6 MB |
| `book_encyclopedia_set_01` | Encyclopedia book set (books/clutter) | https://polyhaven.com/a/book_encyclopedia_set_01 | CC0 | `.gltf`, `.bin`, 6 textures | 3.2 MB |

Notes on the picks: no modern bed, rug or curtain model exists in the Poly Haven models listing, so the bed is a vintage day bed and there is no rug or curtain. The laptop is dated (beige, CRT-era styling).

## Textures (Poly Haven, CC0, 1k JPG)

Each texture directory has the diffuse/colour, normal (GL), roughness and ARM maps. AO and displacement maps were not downloaded.

| Id | What it is | Source | Licence | Files saved | Size |
|---|---|---|---|---|---|
| `old_wooden_floor_01` | Worn wood floor | https://polyhaven.com/a/old_wooden_floor_01 | CC0 | `_diff`, `_nor_gl`, `_rough`, `_arm` (1k JPG) | 2.4 MB |
| `beige_wall_001` | Painted plaster / interior wall | https://polyhaven.com/a/beige_wall_001 | CC0 | `_diff`, `_nor_gl`, `_rough`, `_arm` (1k JPG) | 424 KB |
| `brick_wall_001` | Red brick wall | https://polyhaven.com/a/brick_wall_001 | CC0 | `_diffuse`, `_nor_gl`, `_rough`, `_arm` (1k JPG) | 1.2 MB |
| `concrete_floor_worn_001` | Worn concrete floor | https://polyhaven.com/a/concrete_floor_worn_001 | CC0 | `_diff`, `_nor_gl`, `_rough`, `_arm` (1k JPG) | 564 KB |
| `dirty_carpet` | Carpet / fabric floor covering | https://polyhaven.com/a/dirty_carpet | CC0 | `_diff`, `_nor_gl`, `_rough`, `_arm` (1k JPG) | 3.4 MB |

## HDRIs (Poly Haven, CC0, 2k HDR)

| Id | What it is | Source | Licence | File | Size |
|---|---|---|---|---|---|
| `cobblestone_street_night` | Night cobblestone street, lamps | https://polyhaven.com/a/cobblestone_street_night | CC0 | `hdri/cobblestone_street_night_2k.hdr` | 6.7 MB |
| `hansaplatz` | Night city square, urban | https://polyhaven.com/a/hansaplatz | CC0 | `hdri/hansaplatz_2k.hdr` | 6.5 MB |

## Fonts

| Id | What it is | Source | Licence | File | Size |
|---|---|---|---|---|---|
| `SpecialElite` | Typewriter-style display font | https://github.com/google/fonts/tree/main/apache/specialelite | Apache 2.0 | `fonts/SpecialElite-Regular.ttf` | 162 KB |

## Failed

None. Every requested item downloaded.

Not found (not a download failure): no modern bed, rug or curtain model exists in the Poly Haven models listing. The day bed and the absence of a rug/curtain are noted above.

## Mixamo (not in git)

`assets/mixamo/` holds characters and animations downloaded from mixamo.com with the project owner's
Adobe account. They are free to use in a game but may not be redistributed as raw files, and the
characters are about 300 MB, so the folder is git-ignored. Without it the game still runs; people are
simply absent.

- characters/: louise, leonard, james, megan, kate, remy, the_boss (FBX, T-pose, with skin)
- animations/: idle, walk (in place), run (in place), sit_idle, sit_talk, talk, argue, terrified
  (FBX, without skin, exported on Leonard)
