extends Kit
## 9th Precinct, Special Victims Division.
## Arrangements: "evan" and "harlan" (Interview Room 2), "booking" (the booking desk).

func build() -> void:
	env("cobblestone_street_night", 0.0, Color(0.42, 0.45, 0.42), 1.5, 0.004, Color(0.8, 0.85, 0.8))
	if stage == "booking":
		ambience = "office"
		_booking()
	else:
		_interview()

# ── Interview Room 2 ─────────────────────────────────────────────

func _interview() -> void:
	var block := tex("beige_wall_001", 0.5, Color(0.80, 0.84, 0.78))
	var lino := tex("old_linoleum_flooring_01", 0.6, Color(0.62, 0.62, 0.58))
	shell(-1.9, 1.9, -1.7, 1.7, 2.6, block, lino, tex("ceiling_interior", 0.8, Color(0.8, 0.8, 0.78)))
	# a darker painted band along the bottom of the wall, scuffed by years of chair backs
	var band := tex("beige_wall_001", 0.5, Color(0.48, 0.60, 0.56))
	for w in [[Vector3(0, 0.55, -1.69), Vector3(3.8, 1.1, 0.012)], [Vector3(0, 0.55, 1.69), Vector3(3.8, 1.1, 0.012)], [Vector3(-1.89, 0.55, 0), Vector3(0.012, 1.1, 3.4)], [Vector3(1.89, 0.55, 0), Vector3(0.012, 1.1, 3.4)]]:
		tbox(w[0], w[1], band, false)
	box(Vector3(0, 1.11, -1.685), Vector3(3.8, 0.03, 0.015), Color(0.2, 0.22, 0.2), false)
	# the mirror on the north wall, behind the suspect: you can't see through it from this side
	box(Vector3(-0.3, 1.6, -1.68), Vector3(1.7, 0.95, 0.03), Color(0.2, 0.2, 0.2), false)
	box(Vector3(-0.3, 1.6, -1.66), Vector3(1.6, 0.85, 0.01), Color.WHITE, false).material_override = mat(Color(0.10, 0.12, 0.13), 0.0, 0.08)
	# table bolted to the floor, a ring on it for cuffs
	table(Vector3(0, 0, -0.35), Vector2(1.5, 0.8), 0.74, Color(0.36, 0.37, 0.38))
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.025
	tm.outer_radius = 0.04
	ring.mesh = tm
	ring.material_override = mat(Color(0.6, 0.6, 0.62), 0.0, 0.3, 0.9)
	ring.position = Vector3(0, 0.76, -0.55)
	ring.rotation.x = PI / 2
	add_child(ring)
	prop("dining_chair_02", Vector3(0, 0, -1.05), 0.0)                 # his chair
	prop("SchoolChair_01", Vector3(-0.35, 0, 0.55), PI + 0.2, 0.9)     # yours
	prop("SchoolChair_01", Vector3(1.45, 0, 1.0), -2.2, 0.9)           # the spare, shoved in a corner
	# what gets left on an interview table
	stack(Vector3(-0.4, 0.74, -0.1), 0.06, 0.15)
	paper(Vector3(0.05, 0.742, -0.15), -0.1)
	note("9TH PCT — ADVICE OF RIGHTS\n\n1. You have the right to remain silent.\n2. Anything you say can be used\n   against you in court.\n3. You have the right to a lawyer\n   and to have one present.\n4. If you cannot afford one, one\n   will be appointed.\n\nDo you understand?  YES __  NO __\nSigned: ________________", Vector3(0.05, 0.7435, -0.15), 9).rotation = Vector3(-PI / 2, -0.1, 0)
	box(Vector3(0.2, 0.746, -0.02), Vector3(0.012, 0.012, 0.14), Color(0.1, 0.1, 0.3), false, 0.0, 0.5)   # pen
	cup(Vector3(0.55, 0.74, -0.5), Color(0.9, 0.9, 0.9))
	cup(Vector3(-0.6, 0.74, 0.05), Color(0.2, 0.3, 0.5))
	box(Vector3(0.5, 0.79, -0.15), Vector3(0.24, 0.1, 0.12), Color(0.55, 0.7, 0.8), false, 0.0, 0.3)      # tissues
	box(Vector3(0.5, 0.85, -0.15), Vector3(0.08, 0.04, 0.02), Color(0.95, 0.95, 0.95), false, 0.0, 0.3)
	# camera in the corner with its red light on, a clock, a sign, the door
	prop("security_camera_01", Vector3(1.6, 2.2, -1.5), -0.8)
	ball(Vector3(1.5, 2.3, -1.38), 0.012, Color(1, 0.1, 0.1), 4.0)
	prop("wall_clock", Vector3(1.2, 2.25, -1.69), 0.0)
	plate("THIS ROOM IS\nAUDIO AND VIDEO\nRECORDED", Vector3(1.3, 1.6, -1.685), 0.0, 0.42, 0.3, Color(0.9, 0.9, 0.85), Color(0.6, 0.1, 0.1), 34)
	door(Vector3(1.895, 0, 0.9), -PI / 2, Color(0.33, 0.36, 0.38), 0.9, 2.05, true)
	box(Vector3(-1.8, 0.35, 1.0), Vector3(0.12, 0.6, 0.9), Color(0.75, 0.74, 0.7), false)                  # radiator
	for i in 8:
		box(Vector3(-1.73, 0.35, 0.62 + i * 0.11), Vector3(0.03, 0.56, 0.015), Color(0.6, 0.6, 0.57), false)
	box(Vector3(-1.6, 0.16, -1.4), Vector3(0.26, 0.32, 0.26), Color(0.25, 0.26, 0.28), false)             # waste bin
	tube(Vector3(0, 2.56, -0.2), 1.2, true, Color(0.86, 0.95, 0.9), 3.2, 7.0, true)
	omni(Vector3(0, 1.4, 1.2), Color(0.7, 0.75, 0.8), 0.25, 4.0)
	# people
	if stage == "evan":
		actor("EVAN", "leonard", Vector3(0, -0.03, -1.0), 0.0, "sit_idle", "sit_talk")
	else:
		actor("HARLAN", "brian", Vector3(0, -0.03, -1.0), 0.0, "sit_idle", "sit_talk", {"Shirt": Color(0.5, 0.52, 0.56), "Pants": Color(0.75, 0.75, 0.8)})
	actor("REYES", "louise", Vector3(1.25, 0, -0.2), -1.2)
	shot("wide", Vector3(-1.5, 1.75, 1.45), Vector3(0.2, 0.95, -0.8), 58)
	close("EVAN", 1.35, 0.25, 1.12, 38)
	close("HARLAN", 1.35, 0.25, 1.12, 38)
	close("REYES", 1.3, -0.5, 1.6, 42)
	shot("table", Vector3(-0.1, 1.55, 0.25), Vector3(0.0, 0.74, -0.3), 50)
	shot("door", Vector3(-0.9, 1.5, -0.6), Vector3(1.9, 1.3, 0.9), 50)

# ── booking desk ─────────────────────────────────────────────────

func _booking() -> void:
	var block := tex("beige_wall_001", 0.5, Color(0.86, 0.84, 0.74))
	shell(-4, 4, -3, 3, 2.9, block, tex("old_linoleum_flooring_01", 0.6, Color(0.55, 0.57, 0.55)), tex("ceiling_interior", 0.8, Color(0.8, 0.8, 0.78)))
	# the desk: a chest-high counter with a scratched plastic screen on top
	tbox(Vector3(-0.6, 0.55, -1.2), Vector3(4.2, 1.1, 0.6), tex("wooden_panels", 0.7, Color(0.5, 0.42, 0.36)))
	box(Vector3(-0.6, 1.12, -1.2), Vector3(4.3, 0.05, 0.75), Color(0.25, 0.25, 0.27))
	box(Vector3(0.6, 1.6, -1.3), Vector3(1.8, 0.9, 0.02), Color(0.7, 0.8, 0.85, 0.16), false)
	plate("BOOKING", Vector3(-0.6, 2.5, -2.94), 0.0, 1.4, 0.3, Color(0.12, 0.16, 0.25), Color(0.9, 0.9, 0.85), 80)
	plate("ALL PRISONERS WILL BE SEARCHED.\nPROPERTY IS INVENTORIED IN YOUR PRESENCE.", Vector3(-0.6, 2.0, -2.94), 0.0, 1.5, 0.36, Color(0.9, 0.9, 0.85), INK, 34)
	plate("NO FIREARMS\nBEYOND THIS POINT", Vector3(3.3, 1.7, -2.94), 0.0, 0.8, 0.4, Color(0.75, 0.1, 0.1), Color(0.95, 0.95, 0.9), 44)
	# height chart, where the photograph gets taken
	box(Vector3(2.0, 1.25, -2.94), Vector3(1.0, 2.1, 0.01), Color(0.88, 0.87, 0.82), false)
	for i in 9:
		box(Vector3(2.0, 1.2 + i * 0.1, -2.93), Vector3(1.0, 0.006, 0.01), INK, false)
		note("%d'%d\"" % [(47 + i * 4) / 12, (47 + i * 4) % 12], Vector3(1.6, 1.23 + i * 0.1, -2.925), 12)
	# behind the desk: property shelves, the sergeant's clutter
	prop("steel_frame_shelves_03", Vector3(-2.6, 0, -2.6), 0.0, 2.2)
	for b in [[-3.2, 0.12, 0.2], [-2.5, 0.12, -0.3], [-2.0, 0.84, 0.1], [-3.0, 0.84, 0.4], [-2.7, 1.55, 0.0]]:
		prop("cardboard_box_01", Vector3(b[0], b[1], -2.6), b[2])
	prop("classic_laptop", Vector3(0.6, 1.145, -1.3), PI, 0.38)
	prop("plastic_thermos", Vector3(1.2, 1.145, -1.3), 0.5)
	cup(Vector3(1.0, 1.145, -1.1), Color(0.85, 0.85, 0.8))
	prop("clipboard", Vector3(0.0, 1.145, -1.05), 0.4)
	prop("wall_clock", Vector3(0.9, 2.5, -2.94))
	# the property tray on the counter
	box(Vector3(-0.9, 1.16, -1.05), Vector3(0.5, 0.03, 0.34), Color(0.5, 0.47, 0.4), false)
	box(Vector3(-1.05, 1.19, -1.1), Vector3(0.11, 0.02, 0.09), Color(0.2, 0.13, 0.08), false, 0.0, 0.3)     # wallet
	box(Vector3(-0.9, 1.185, -1.0), Vector3(0.07, 0.01, 0.14), Color(0.05, 0.05, 0.06), false, 0.0, -0.2)   # phone
	box(Vector3(-1.02, 1.182, -0.96), Vector3(0.085, 0.004, 0.055), Color(0.85, 0.85, 0.9), false, 0.0, 0.1)  # university ID
	for i in 5:                                                                                               # work keys
		box(Vector3(-0.76 + i * 0.012, 1.182, -1.12 + i * 0.004), Vector3(0.008, 0.003, 0.05), Color(0.6, 0.6, 0.62), false, 0.0, i * 0.3)
	box(Vector3(-0.74, 1.183, -0.98), Vector3(0.012, 0.004, 0.07), Color.WHITE, false, 0.0, 0.7).material_override = mat(Color(0.72, 0.55, 0.2), 0.0, 0.35, 0.8)  # the brass key
	box(Vector3(-0.71, 1.182, -0.93), Vector3(0.035, 0.002, 0.05), Color(0.9, 0.86, 0.7), false, 0.0, 0.4)  # its paper tag
	# the public side: a bench with a cuff rail, a bin, the mop sign nobody moved
	prop("painted_wooden_bench", Vector3(3.5, 0, 0.6), -PI / 2, 0.0, true)
	box(Vector3(3.92, 0.95, 0.6), Vector3(0.04, 0.04, 1.4), Color(0.6, 0.6, 0.62), false)
	prop("WetFloorSign_01", Vector3(-3.0, 0, 1.4), 0.6)
	prop("korean_fire_extinguisher_01", Vector3(-3.8, 0, -0.4), PI / 2)
	prop("fire_alarm", Vector3(-3.94, 1.5, 0.3), PI / 2)
	box(Vector3(3.0, 0.3, -2.6), Vector3(0.4, 0.6, 0.4), Color(0.3, 0.32, 0.34), false)
	door(Vector3(-3.945, 0, 2.0), PI / 2, Color(0.33, 0.36, 0.38), 1.0, 2.1, true)
	box(Vector3(1.0, 1.7, 2.94), Vector3(1.8, 1.1, 0.03), Color(0.5, 0.36, 0.22), false)                  # notice board
	for i in 7:
		box(Vector3(0.35 + (i % 4) * 0.42, 1.45 + (i / 4) * 0.42 + (i % 2) * 0.05, 2.92), Vector3(0.21, 0.297, 0.004), Color(0.9, 0.89, 0.85) if i % 3 else Color(0.95, 0.85, 0.5), false)
	tube(Vector3(-1, 2.86, -0.5), 1.2, true, Color(0.9, 0.96, 0.92), 3.0, 9.0, true)
	tube(Vector3(2, 2.86, 1.0), 1.2, true, Color(0.9, 0.96, 0.92), 2.2, 8.0)
	actor("HARLAN", "brian", Vector3(-0.3, 0, -0.45), PI + 0.3, "idle", "talk", {"Shirt": Color(0.5, 0.52, 0.56), "Pants": Color(0.75, 0.75, 0.8)})
	actor("REYES", "louise", Vector3(-1.3, 0, -0.5), PI - 0.5)
	actor("", "alex", Vector3(2.6, 0, 1.6), PI + 0.9, "idle", "idle")                                    # the desk officer
	shot("wide", Vector3(1.6, 1.7, 2.2), Vector3(-0.8, 1.1, -1.2), 55)
	shot("tray", Vector3(-1.2, 1.62, -0.55), Vector3(-0.85, 1.16, -1.03), 48)
	close("HARLAN", 1.3, 0.4, 1.58, 40)
	close("REYES", 1.3, -0.4, 1.6, 42)
