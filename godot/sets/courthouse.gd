extends Kit
## Calder County Courthouse.
## Arrangements: "office" and "plea" (ADA Cole's office), "hearing" (suppression hearing, no jury),
## "trial", "tessa", "okonkwo" (who is on the witness stand) and "closing".

# Pruitt: silver hair and a pale suit, so she cannot be mistaken for Reyes (dark hair, navy suit).
const PRUITT_LOOK := {"Suit": Color(1.55, 1.5, 1.45), "Pants": Color(0.95, 0.92, 0.9), "Hair": Color(2.4, 2.4, 2.45)}
const JUDGE_LOOK := {"Suit": Color(0.12, 0.12, 0.13), "Pants": Color(0.2, 0.2, 0.2), "Tie": Color(0.5, 0.15, 0.15), "Hair": Color(2.4, 2.4, 2.4)}

func build() -> void:
	ambience = "courtroom"
	if stage in ["office", "plea"]:
		ambience = "office"
		_office()
	else:
		_courtroom()

# ── the District Attorney's office, fourth floor ─────────────────

func _office() -> void:
	env("freight_station", 1.2, Color(0.5, 0.5, 0.52), 1.1, 0.004, Color(1, 0.95, 0.9), 0.5)
	var paint := tex("beige_wall_001", 0.5, Color(0.74, 0.78, 0.76))
	var carpet := tex("dirty_carpet", 0.7, Color(0.42, 0.46, 0.55))
	tbox(Vector3(0, -0.05, 0), Vector3(5, 0.1, 4.4), carpet)
	tbox(Vector3(0, 2.85, 0), Vector3(5, 0.1, 4.4), tex("ceiling_interior", 0.8, Color(0.82, 0.82, 0.8)))
	wall_z(-2.55, -2.2, 2.2, 0, 2.8, paint)
	wall_z(2.55, -2.2, 2.2, 0, 2.8, paint)
	wall_x(2.25, -2.5, 2.5, 0, 2.8, paint)
	# north wall with the window: grey winter daylight through half-shut blinds
	wall_x(-2.25, -2.5, 0.4, 0, 2.8, paint)
	wall_x(-2.25, 2.0, 2.5, 0, 2.8, paint)
	wall_x(-2.25, 0.4, 2.0, 0, 0.95, paint)
	wall_x(-2.25, 0.4, 2.0, 2.3, 2.8, paint)
	box(Vector3(1.2, 0.97, -2.15), Vector3(1.7, 0.04, 0.25), Color(0.85, 0.84, 0.8), false)
	for i in 12:
		box(Vector3(1.2, 1.05 + i * 0.105, -2.2), Vector3(1.6, 0.012, 0.06), Color(0.82, 0.8, 0.74), false).rotation.x = 0.5
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.95, 0.95, 1.0)
	sun.light_energy = 2.2
	sun.rotation_degrees = Vector3(-28, 200, 0)
	sun.shadow_enabled = true
	add_child(sun)
	tube(Vector3(0, 2.76, 0.6), 1.2, true, Color(1.0, 0.96, 0.88), 1.0, 6.0)
	# the desk, and the Harlan file in three stacks
	prop("metal_office_desk", Vector3(0, 0, 0.75), PI, 0.0, true)
	stack(Vector3(-0.65, 0.79, 0.7), 0.18, 0.1)
	stack(Vector3(-0.3, 0.79, 0.85), 0.09, -0.2)
	stack(Vector3(0.62, 0.79, 0.55), 0.24, 0.3)
	note("USE", Vector3(-0.65, 0.975, 0.7), 18, Color(0.1, 0.4, 0.15)).rotation.x = -PI / 2
	note("MIGHT\nLOSE", Vector3(-0.3, 0.885, 0.85), 16, Color(0.6, 0.4, 0.05)).rotation.x = -PI / 2
	note("WISH IT\nWEREN'T\nTRUE", Vector3(0.62, 1.035, 0.55), 15, Color(0.65, 0.1, 0.1)).rotation.x = -PI / 2
	papers(Vector3(0.1, 0.79, 0.6), 5, 0.22, 7)
	prop("classic_laptop", Vector3(0.15, 0.79, 1.05), 0.1, 0.36)
	prop("desk_lamp_arm_01", Vector3(-0.85, 0.79, 1.1), 2.2)
	omni(Vector3(-0.6, 1.2, 0.85), Color(1.0, 0.8, 0.5), 0.7, 2.5)
	cup(Vector3(0.45, 0.79, 0.95), Color(0.15, 0.2, 0.35))
	box(Vector3(-0.2, 0.83, 1.12), Vector3(0.22, 0.07, 0.2), Color(0.1, 0.1, 0.11), false, 0.0, 0.2)           # desk phone
	box(Vector3(-0.27, 0.875, 1.12), Vector3(0.06, 0.04, 0.2), Color(0.12, 0.12, 0.13), false, 0.0, 0.2)
	box(Vector3(0, 0.83, 0.33), Vector3(0.36, 0.06, 0.05), Color(0.25, 0.18, 0.1), false)                       # nameplate, facing the visitor
	note("I. COLE · ASST. DISTRICT ATTORNEY", Vector3(0, 0.83, 0.303), 6, Color(0.85, 0.75, 0.4), 0.0, PI)
	prop("GreenChair_01", Vector3(0, 0, 1.55), PI, 0.0)
	prop("dining_chair_02", Vector3(-0.45, 0, -0.5), 0.0)
	prop("dining_chair_02", Vector3(0.55, 0, -0.6), -0.3)
	# law reports, a credenza with the coffee things, diplomas
	var shelf := prop("Shelf_01", Vector3(2.48, 0, 0.3), -PI / 2, 0.0, true)
	for y in [0.1, 0.38, 0.66, 0.94, 1.22, 1.51]:
		for bx in [-0.44, 0.0]:
			if not (y == 0.94 and bx == 0.0):
				var b: Node3D = _load("res://assets/models/book_encyclopedia_set_01/book_encyclopedia_set_01_1k.gltf").instantiate()
				b.position = Vector3(bx, y + 0.01, 0.1)
				b.scale = Vector3(0.8, 0.95, 1.0)
				shelf.add_child(b)
	prop("ClassicConsole_01", Vector3(-1.4, 0, -1.95), 0.0, 0.0, true)
	prop("vintage_electric_kettle", Vector3(-1.8, 0.95, -1.95), 0.4, 0.22)
	cup(Vector3(-1.45, 0.95, -1.9))
	cup(Vector3(-1.3, 0.95, -2.0), Color(0.6, 0.2, 0.2))
	prop("mantel_clock_01", Vector3(-0.95, 0.95, -1.98), 0.0)
	prop("hanging_picture_frame_01", Vector3(-1.75, 1.85, -2.19), 0.0, 0.5)
	prop("hanging_picture_frame_01", Vector3(-1.25, 1.85, -2.19), 0.0, 0.5)
	prop("fancy_picture_frame_01", Vector3(-2.49, 1.7, 1.2), PI / 2)
	# the case on the wall: a timeline in index cards and string
	box(Vector3(-2.48, 1.5, -0.4), Vector3(0.03, 1.1, 1.9), Color(0.5, 0.36, 0.22), false)
	var times := ["SEPT 22\nCampus report", "SEPT 23\n\"He hasn't done\nanything\"", "OCT 14  9:02\nHarlan punches out", "9:14\nRide ordered", "9:16\nRide cancelled", "11:42\nApartment", "OCT 15\nTower 6"]
	for i in times.size():
		box(Vector3(-2.46, 1.75 - (i % 2) * 0.42, -1.2 + i * 0.27), Vector3(0.004, 0.16, 0.22), Color(0.93, 0.92, 0.86), false)
		note(times[i], Vector3(-2.455, 1.75 - (i % 2) * 0.42, -1.2 + i * 0.27), 7, INK, 0.0, PI / 2)
	box(Vector3(-2.455, 1.55, -0.4), Vector3(0.003, 0.006, 1.7), Color(0.7, 0.1, 0.1), false)
	# banker's boxes, a coat, a plant that is mostly alive
	for i in 4:
		var bx := prop("cardboard_box_01", Vector3(1.9 - (i % 2) * 0.45, (i / 2) * 0.34, 1.8), (i % 2) * 0.1 + PI / 2)
	note("PEOPLE v. HARLAN\nBOX 3 OF 6", Vector3(1.68, 0.5, 1.53), 12, INK, 0.0, PI)
	box(Vector3(-2.4, 1.75, 1.9), Vector3(0.06, 0.06, 0.3), Color(0.3, 0.25, 0.2), false)
	box(Vector3(-2.3, 1.2, 1.9), Vector3(0.14, 1.1, 0.45), Color(0.18, 0.18, 0.22), false)
	prop("potted_plant_01", Vector3(2.1, 0, -1.8), 0.5, 1.1)
	prop("wall_clock", Vector3(0.2, 2.35, 2.19), PI)
	door(Vector3(-1.5, 0, 2.2), PI, Color(0.36, 0.28, 0.2), 0.9, 2.05, true)
	# people: you are behind the desk
	if stage == "office":
		actor("OKONKWO", Kit.OKONKWO_MODEL, Vector3(-0.45, -0.03, -0.45), 0.0, "sit_idle", "sit_talk", OKONKWO_LOOK)
		close("OKONKWO", 1.35, 0.3, 1.1, 38)
	else:
		actor("PRUITT", "martha", Vector3(0.3, 0, -0.9), 0.1, "idle", "talk", PRUITT_LOOK)
		close("PRUITT", 1.5, 0.35, 1.58, 40)
	shot("wide", Vector3(1.5, 1.6, 2.0), Vector3(-0.4, 0.95, -0.7), 56)
	shot("desk", Vector3(0.5, 1.45, 1.5), Vector3(-0.1, 0.8, 0.85), 50)

# ── Part 31 ──────────────────────────────────────────────────────

func _seat(pos: Vector3, rot_y: float, color := Color(0.35, 0.16, 0.12)) -> void:
	box(pos + Vector3(0, 0.44, 0), Vector3(0.5, 0.08, 0.5), color, false, 0.0, rot_y)
	box(pos + Vector3(0, 0.22, 0), Vector3(0.08, 0.44, 0.08), Color(0.15, 0.15, 0.16), false)
	var back := box(pos + Vector3(-sin(rot_y) * 0.24, 0.78, -cos(rot_y) * 0.24), Vector3(0.5, 0.6, 0.07), color, false, 0.0, rot_y)
	back.material_override = mat(color, 0.0, 0.5)

func _courtroom() -> void:
	env("freight_station", 1.0, Color(0.46, 0.44, 0.42), 1.6, 0.012, Color(1.0, 0.95, 0.85), 0.5)
	var panel := tex("wooden_panels", 0.6, Color(1.45, 1.3, 1.15))
	var plaster := tex("beige_wall_001", 0.5, Color(0.86, 0.84, 0.76))
	var wood := tex("old_wooden_floor_01", 0.5, Color(0.7, 0.6, 0.52))
	tbox(Vector3(0, -0.05, 0), Vector3(14, 0.1, 18), wood)
	tbox(Vector3(0, 0.005, 5.5), Vector3(1.6, 0.012, 7.0), tex("dirty_carpet", 0.7, Color(0.4, 0.2, 0.2)), false)   # aisle runner
	box(Vector3(0, 6.05, 0), Vector3(14, 0.1, 18), Color(0.78, 0.76, 0.7))
	# walls: panelling to door height, plaster above
	for w in [[Vector3(0, 1.3, -9.05), Vector3(14, 2.6, 0.1)], [Vector3(0, 1.3, 9.05), Vector3(14, 2.6, 0.1)], [Vector3(7.05, 1.3, 0), Vector3(0.1, 2.6, 18)], [Vector3(-7.05, 1.3, 0), Vector3(0.1, 2.6, 18)]]:
		tbox(w[0], w[1], panel)
	box(Vector3(0, 2.63, -8.98), Vector3(14, 0.08, 0.08), Color(0.3, 0.22, 0.17), false)
	box(Vector3(6.98, 2.63, 0), Vector3(0.08, 0.08, 18), Color(0.3, 0.22, 0.17), false)
	box(Vector3(-6.98, 2.63, 0), Vector3(0.08, 0.08, 18), Color(0.3, 0.22, 0.17), false)
	wall_x(-9.05, -7, 7, 2.6, 6, plaster)
	wall_x(9.05, -7, 7, 2.6, 6, plaster)
	wall_z(7.05, -9, 9, 2.6, 6, plaster)
	# west wall with three tall windows
	var z := -9.0
	for wz in [-5.0, 0.0, 5.0]:
		wall_z(-7.05, z, wz - 0.8, 2.6, 6, plaster)
		wall_z(-7.05, wz - 0.8, wz + 0.8, 5.3, 6, plaster)
		box(Vector3(-7.0, 3.95, wz), Vector3(0.06, 0.06, 1.6), Color(0.3, 0.22, 0.17), false)
		box(Vector3(-7.0, 3.95, wz), Vector3(0.06, 2.7, 0.06), Color(0.3, 0.22, 0.17), false)
		spot(Vector3(-13, 9.5, wz - 1.0), Vector3(1.5, 0, wz + 0.5), Color(1.0, 0.93, 0.8), 9.0, 30, 9, true, 3.0)
		z = wz + 0.8
	wall_z(-7.05, z, 9, 2.6, 6, plaster)
	for p in [Vector3(-3, 0, -2), Vector3(3, 0, -2), Vector3(-3, 0, 4.5), Vector3(3, 0, 4.5)]:                    # pendant lamps
		cyl(p + Vector3(0, 5.4, 0), 0.01, 1.2, Color(0.2, 0.2, 0.2))
		ball(p + Vector3(0, 4.7, 0), 0.2, Color(1.0, 0.92, 0.75), 2.2)
		omni(p + Vector3(0, 4.5, 0), Color(1.0, 0.9, 0.72), 3.0, 10.0)
	# the bench
	tbox(Vector3(0, 0.25, -7.6), Vector3(7.5, 0.5, 2.8), wood)
	tbox(Vector3(0, 1.12, -6.45), Vector3(5.2, 1.25, 0.5), panel)
	box(Vector3(0, 1.77, -6.5), Vector3(5.4, 0.06, 0.75), Color(0.3, 0.22, 0.17), false)
	prop("GreenChair_01", Vector3(0, 0.95, -7.75), 0.0, 1.35)
	box(Vector3(0, 0.72, -7.6), Vector3(1.2, 0.45, 1.2), Color(0.3, 0.22, 0.17), false)
	box(Vector3(0.9, 1.83, -6.5), Vector3(0.14, 0.05, 0.1), Color(0.3, 0.2, 0.12), false)                         # gavel block
	cyl(Vector3(0.9, 1.88, -6.45), 0.03, 0.12, Color(0.35, 0.22, 0.12)).rotation.z = PI / 2
	box(Vector3(-0.6, 1.83, -6.3), Vector3(0.5, 0.07, 0.05), Color(0.25, 0.18, 0.1), false)
	note("HON. R. ABRAMS", Vector3(-0.6, 1.83, -6.272), 9, Color(0.85, 0.75, 0.4))
	omni(Vector3(0.3, 2.4, -6.6), Color(1.0, 0.85, 0.6), 0.8, 3.0)                                                 # the bench lamp
	cyl(Vector3(0.45, 1.95, -6.55), 0.012, 0.3, Color(0.6, 0.5, 0.2), 0.3)
	ball(Vector3(0.45, 2.1, -6.55), 0.07, Color(0.2, 0.5, 0.3), 0.6, Vector3(1.6, 0.6, 1))
	# seal and flags
	var seal := cyl(Vector3(0, 4.1, -8.96), 0.75, 0.05, Color(0.55, 0.42, 0.2), 0.4)
	seal.rotation.x = PI / 2
	seal.material_override = mat(Color(0.5, 0.4, 0.22), 0.0, 0.6)
	note("CALDER COUNTY", Vector3(0, 4.42, -8.92), 62, Color(0.2, 0.14, 0.05))
	note("SUPERIOR\nCOURT", Vector3(0, 3.92, -8.92), 80, Color(0.2, 0.14, 0.05))
	for fx in [-2.6, 2.6]:
		cyl(Vector3(fx, 1.9, -8.5), 0.025, 2.8, Color(0.6, 0.5, 0.25), 0.3)
		ball(Vector3(fx, 3.35, -8.5), 0.05, Color(0.75, 0.6, 0.25))
		cyl(Vector3(fx, 0.52, -8.5), 0.2, 0.04, Color(0.6, 0.5, 0.25), 0.3)
		if fx < 0:
			box(Vector3(fx + 0.15, 2.45, -8.45), Vector3(0.22, 1.5, 0.12), Color(0.42, 0.1, 0.12), false).rotation.z = 0.06
		else:
			box(Vector3(fx - 0.15, 2.45, -8.45), Vector3(0.22, 1.5, 0.12), Color(0.1, 0.2, 0.42), false).rotation.z = -0.06
	# witness stand, clerk, court reporter
	tbox(Vector3(-3.3, 0.15, -5.4), Vector3(1.7, 0.3, 1.7), wood)
	tbox(Vector3(-3.3, 0.75, -4.6), Vector3(1.7, 0.9, 0.1), panel, false)
	tbox(Vector3(-2.5, 0.75, -5.4), Vector3(0.1, 0.9, 1.7), panel, false)
	box(Vector3(-3.3, 1.22, -4.6), Vector3(1.8, 0.05, 0.25), Color(0.3, 0.22, 0.17), false)
	_seat(Vector3(-3.3, 0.3, -5.6), 0.0)
	cyl(Vector3(-3.1, 1.36, -4.62), 0.012, 0.22, Color(0.1, 0.1, 0.1)).rotation.x = -0.6
	cup(Vector3(-3.8, 1.245, -4.62))
	table(Vector3(1.2, 0, -5.0), Vector2(1.6, 0.7), 0.74, Color(0.36, 0.26, 0.2), 0.0, Color(0.3, 0.22, 0.17))
	prop("classic_laptop", Vector3(1.2, 0.74, -5.0), 0.0, 0.34)
	stack(Vector3(0.65, 0.74, -5.0), 0.15)
	_seat(Vector3(1.2, 0, -5.7), 0.0, Color(0.15, 0.15, 0.17))
	prop("metal_stool_01", Vector3(-1.2, 0, -4.8), 0.0, 0.55)
	box(Vector3(-1.2, 0.75, -4.4), Vector3(0.3, 0.1, 0.22), Color(0.12, 0.12, 0.13), false)                         # steno machine
	cyl(Vector3(-1.2, 0.35, -4.4), 0.015, 0.7, Color(0.5, 0.5, 0.52))
	# jury box: two tiers along the east wall
	tbox(Vector3(6.2, 0.15, -2.5), Vector3(1.4, 0.3, 6.6), wood)
	tbox(Vector3(4.15, 0.5, -2.5), Vector3(0.1, 1.0, 6.6), panel)
	box(Vector3(4.15, 1.02, -2.5), Vector3(0.25, 0.05, 6.7), Color(0.3, 0.22, 0.17), false)
	tbox(Vector3(5.5, 0.5, 0.85), Vector3(2.8, 1.0, 0.1), panel)
	tbox(Vector3(5.5, 0.5, -5.85), Vector3(2.8, 1.0, 0.1), panel)
	for i in 6:
		_seat(Vector3(4.9, 0, -5.2 + i * 1.08), -PI / 2)
		_seat(Vector3(6.2, 0.3, -5.2 + i * 1.08), -PI / 2)
	# counsel tables, lectern
	for tx in [-2.5, 2.5]:
		table(Vector3(tx, 0, 2.0), Vector2(2.6, 0.95), 0.76, Color(0.36, 0.26, 0.2), 0.0, Color(0.3, 0.22, 0.17))
		for cx in [-0.6, 0.6]:
			_seat(Vector3(tx + cx, 0, 2.9), PI, Color(0.2, 0.14, 0.1))
		cyl(Vector3(tx - 1.0, 0.87, 1.8), 0.05, 0.2, Color(0.75, 0.85, 0.9, 0.5), 0.1)                              # water jug
		cup(Vector3(tx - 0.8, 0.76, 1.95), Color(0.9, 0.9, 0.92))
	stack(Vector3(2.0, 0.76, 1.9), 0.2, 0.1)
	stack(Vector3(3.2, 0.76, 2.1), 0.1, -0.3)
	papers(Vector3(2.6, 0.76, 2.1), 4, 0.25, 3)
	prop("cardboard_box_01", Vector3(3.9, 0, 2.6), 0.3)
	note("PEOPLE'S\nEXHIBITS", Vector3(3.9, 0.2, 2.87), 12, INK)
	papers(Vector3(-2.4, 0.76, 2.0), 3, 0.3, 5)
	paper(Vector3(-3.0, 0.762, 2.2), 0.2, Vector2(0.21, 0.297), Color(0.95, 0.9, 0.45))                            # the defense's legal pad
	tbox(Vector3(0, 0.6, 0.2), Vector3(0.6, 1.2, 0.45), panel)
	box(Vector3(0, 1.22, 0.22), Vector3(0.66, 0.04, 0.5), Color(0.3, 0.22, 0.17), false).rotation.x = 0.25
	# the bar, the gallery, the doors
	for seg in [[-7.0, -0.7], [0.7, 7.0]]:
		tbox(Vector3((seg[0] + seg[1]) / 2, 0.45, 4.2), Vector3(seg[1] - seg[0], 0.9, 0.08), panel)
		box(Vector3((seg[0] + seg[1]) / 2, 0.93, 4.2), Vector3(seg[1] - seg[0], 0.05, 0.16), Color(0.3, 0.22, 0.17), false)
	for row in 3:
		for side in [-1, 1]:
			var pz := 5.4 + row * 1.25
			tbox(Vector3(side * 3.9, 0.42, pz), Vector3(5.6, 0.07, 0.45), wood)
			tbox(Vector3(side * 3.9, 0.65, pz + 0.24), Vector3(5.6, 0.75, 0.06), panel, false)
			for e in [-2.8, 2.8]:
				tbox(Vector3(side * 3.9 + e, 0.45, pz + 0.05), Vector3(0.06, 0.9, 0.5), panel, false)
	for side in [-1, 1]:
		door(Vector3(side * 0.55, 0, 8.98), PI, Color(0.36, 0.26, 0.2), 1.05, 2.3, true)
	plate("PART 31", Vector3(0, 2.9, 8.98), PI, 0.8, 0.22, Color(0.2, 0.15, 0.1), Color(0.85, 0.75, 0.45), 70)
	prop("wall_clock", Vector3(2.2, 3.2, 8.98), PI, 0.5)
	plate("QUIET PLEASE\nCOURT IS IN SESSION", Vector3(-2.4, 2.0, 8.98), PI, 0.7, 0.3, Color(0.9, 0.9, 0.85), INK, 34)
	# people
	var trial := stage != "hearing"
	robe(actor("JUDGE", "joe", Vector3(0, 1.1, -7.5), 0.0, "sit_idle", "sit_talk", JUDGE_LOOK))
	actor("HARLAN", "brian", Vector3(-3.1, -0.03, 2.75), PI, "sit_idle", "sit_idle", {"Shirt": Color(0.55, 0.65, 0.9), "Pants": Color(0.45, 0.45, 0.5)})
	actor("", "alex", Vector3(-5.6, 0, -3.2), PI / 2 + 0.3, "idle", "idle")                              # court officer by the side door
	var cross := stage in ["tessa", "okonkwo", "trial"]
	actor("PRUITT", "martha", Vector3(-1.3, 0, -2.6) if cross else Vector3(-1.9, 0, 1.2), PI + 0.75 if cross else PI, "idle", "talk", PRUITT_LOOK)
	match stage:
		"tessa":
			actor("TESSA", "kate", Vector3(-3.3, 0.27, -5.5), 0.5, "sit_idle", "sit_talk")
			close("TESSA", 1.4, 0.3, 1.1, 36)
		"okonkwo":
			actor("OKONKWO", Kit.OKONKWO_MODEL, Vector3(-3.3, 0.27, -5.5), 0.5, "sit_idle", "sit_talk", OKONKWO_LOOK)
			close("OKONKWO", 1.4, 0.3, 1.1, 36)
		"trial":
			actor("PRIYA", "megan", Vector3(-3.3, 0.27, -5.5), 0.5, "sit_idle", "sit_talk")
			close("PRIYA", 1.4, 0.3, 1.1, 36)
			actor("OKONKWO", Kit.OKONKWO_MODEL, Vector3(3.2, -0.03, 5.45), PI, "sit_idle", "sit_talk", OKONKWO_LOOK)
			shot("OKONKWO", Vector3(2.6, 1.2, 3.6), Vector3(3.2, 1.1, 5.45), 40)
	if trial:
		# Jurors never reuse a model that plays a named character, so nobody's double sits in the box.
		var tints := [{}, {}, {"Shirt": Color(0.5, 0.62, 0.52)}, {},
			{"Suit": Color(0.9, 0.65, 0.45), "Tie": Color(0.2, 0.45, 0.3), "Hair": Color(0.5, 0.35, 0.25)},
			{"Shirt": Color(0.75, 0.45, 0.45), "Hair": Color(2.2, 2.2, 2.2)},
			{"Suit": Color(1.5, 1.3, 1.0), "Shirt": Color(0.9, 0.7, 0.6), "Hair": Color(2.2, 2.0, 1.8)},
			{"Shirt": Color(0.55, 0.6, 1.0), "Pants": Color(0.5, 0.5, 0.5)}]
		var who := ["jody", "josh", "roth", "remy", "joe", "roth", "josh", "jody"]
		for i in 8:
			actor("", who[i], Vector3(4.9 if i < 4 else 6.2, -0.03 if i < 4 else 0.27, -5.2 + [0, 1, 3, 4, 1, 2, 4, 5][i] * 1.08), -PI / 2, "sit_idle", "sit_idle", tints[i])
		# an exhibit on an easel, where the jury can't avoid it
		box(Vector3(1.9, 1.35, -4.2), Vector3(1.3, 1.0, 0.05), Color(0.92, 0.91, 0.86), false, 0.0, PI / 4)
		note("PEOPLE'S 4\n\nSIT BY THE\nWINDOW AGAIN.", Vector3(1.92, 1.35, -4.18), 40, INK, 0.0, PI / 4)
		for lx in [-0.4, 0.4]:
			box(Vector3(1.9 + lx, 0.45, -4.2 + lx), Vector3(0.04, 0.9, 0.04), Color(0.4, 0.3, 0.2), false)
	shot("wide", Vector3(0.5, 2.3, 7.6), Vector3(0, 1.5, -6), 56)
	shot("bench", Vector3(0.9, 1.9, -3.4), Vector3(0, 2.25, -7.5), 30)
	shots["JUDGE"] = shots["bench"]
	shot("jury", Vector3(1.6, 1.5, -1.6), Vector3(5.6, 1.15, -3.0), 50)
	shot("ending", Vector3(-4.5, 1.3, 7.8), Vector3(1, 2.4, -6), 60)
	close("PRUITT", 1.5, 0.4, 1.58, 40)
	close("HARLAN", 1.5, 0.4, 1.12, 38)
	tracks["closing"] = [
		[Vector3(2.5, 1.25, 3.0), Vector3(0, 1.6, -6)], [Vector3(2.5, 1.65, 2.5), Vector3(0, 1.9, -6.5)],
		[Vector3(2.9, 1.65, -0.6), Vector3(5.5, 1.2, -2.6)], [Vector3(3.3, 1.65, -2.3), Vector3(5.6, 1.15, -2.7)],
	]
