extends Kit
## Calder Rail Yard and Signal Tower 6.
## Arrangements: "title", "night", "fire" (outside, tower alight), "inside" (the rescue), "standoff" (Harlan on the walkway),
## "dawn" / "dawn_hurt" (afterwards, at the ambulance) and "aftermath" (the morning nobody was looking for her).

const UP := 3.4                       # height of the tower's upper floor and its walkway
var day := false
var burning := false

func build() -> void:
	day = stage in ["dawn", "dawn_hurt", "aftermath"]
	burning = stage in ["fire", "inside"]
	ambience = "fire" if burning else ("dawn" if day else "rail_yard")
	if day:
		env("freight_station", 0.9, Color(0.62, 0.58, 0.6), 1.0, 0.012, Color(1.0, 0.85, 0.7), 1.2)
		var sun := DirectionalLight3D.new()
		sun.light_color = Color(1.0, 0.78, 0.55)
		sun.light_energy = 1.6
		sun.rotation_degrees = Vector3(-11, -105, 0)
		sun.shadow_enabled = true
		sun.directional_shadow_max_distance = 60
		add_child(sun)
	else:
		env("preller_drive", 0.45, Color(0.2, 0.24, 0.36), 1.5, 0.014, Color(0.65, 0.72, 0.9), 2.0)
		var moon := DirectionalLight3D.new()
		moon.light_color = Color(0.55, 0.65, 1.0)
		moon.light_energy = 0.5
		moon.rotation_degrees = Vector3(-40, 150, 0)
		moon.shadow_enabled = true
		add_child(moon)
	_ground()
	_tower()
	_inside()
	_dressing()
	match stage:
		"title", "night":
			shot("wide", Vector3(9, 1.0, 13), Vector3(0, 4, 0), 50)
			shot("title", Vector3(10, 0.7, 12), Vector3(0, 4.2, 0), 46)
		"fire":
			actor("REYES", "louise", Vector3(2.6, 0, 9.5), PI + 0.3)
			shot("wide", Vector3(6.5, 1.5, 14), Vector3(0, 3.6, 0), 52)
			shot("tower", Vector3(1.6, 1.5, 7.2), Vector3(0, 1.0, 2.5), 50)
			close("REYES", 1.5, 0.5, 1.6, 42)
		"inside":
			_rescue()
		"standoff":
			_standoff()
		_:
			_morning()

# ── the yard ─────────────────────────────────────────────────────

func _ground() -> void:
	tbox(Vector3(0, -0.05, 0), Vector3(140, 0.1, 100), tex("gravel_floor_02", 0.3, Color(0.72, 0.7, 0.72) if day else Color(0.6, 0.62, 0.7)))
	var rail_c := Color(0.42, 0.36, 0.32)
	var sleepers := MultiMesh.new()
	sleepers.transform_format = MultiMesh.TRANSFORM_3D
	var sm := BoxMesh.new()
	sm.size = Vector3(0.24, 0.12, 2.5)
	sm.material = mat(Color(0.2, 0.15, 0.12), 0.0, 1.0)
	sleepers.mesh = sm
	var lines := [[8.0, -60.0, 60.0], [12.0, -60.0, 60.0], [-9.0, -60.0, 60.0], [-13.0, -60.0, 60.0], [5.0, 4.0, 60.0]]   # the last is the dead-end siding by the tower
	var count := 0
	for l in lines:
		count += int((l[2] - l[1]) / 0.7)
	sleepers.instance_count = count
	var k := 0
	for l in lines:
		for side in [-0.72, 0.72]:
			box(Vector3((l[1] + l[2]) / 2, 0.16, l[0] + side), Vector3(l[2] - l[1], 0.12, 0.07), rail_c, false).material_override = mat(rail_c, 0.0, 0.45, 0.7)
		var x: float = l[1]
		while x < l[2] - 0.01 and k < count:
			sleepers.set_instance_transform(k, Transform3D(Basis(), Vector3(x, 0.06, l[0])))
			k += 1
			x += 0.7
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = sleepers
	add_child(mmi)
	# buffer stop where the siding ends
	box(Vector3(3.6, 0.6, 5.0), Vector3(0.3, 1.0, 2.2), Color(0.5, 0.12, 0.1))
	box(Vector3(3.9, 0.35, 5.0), Vector3(0.5, 0.5, 1.9), Color(0.2, 0.15, 0.12), false)
	# freight cars standing on the through lines
	var cars := [[-22.0, 12.0, Color(0.55, 0.28, 0.22), "CRX 48217"], [-9.5, 12.0, Color(0.3, 0.36, 0.42), "CRX 51090"], [16.0, 12.0, Color(0.5, 0.42, 0.25), "KLR 2206"],
		[9.0, -9.0, Color(0.32, 0.4, 0.34), "CRX 47733"], [21.5, -9.0, Color(0.55, 0.28, 0.22), "CRX 48220"], [-18.0, -13.0, Color(0.36, 0.34, 0.4), "TBX 9031"]]
	for c in cars:
		tbox(Vector3(c[0], 2.35, c[1]), Vector3(12, 2.9, 2.8), tex("corrugated_iron_02", 0.5, c[2]))
		box(Vector3(c[0], 0.75, c[1]), Vector3(11.6, 0.3, 2.4), Color(0.1, 0.1, 0.11), false)
		for bx in [-4.2, 4.2]:
			box(Vector3(c[0] + bx, 0.42, c[1]), Vector3(2.0, 0.5, 2.0), Color(0.07, 0.07, 0.08), false)
		for side in [-1, 1]:
			note(c[3], Vector3(c[0] - 3.5, 3.2, c[1] + side * 1.41), 60, Color(0.85, 0.85, 0.8), 0.0, 0.0 if side == 1 else PI)
		box(Vector3(c[0], 2.35, c[1] + 1.42), Vector3(2.6, 2.6, 0.04), c[2] * 0.8, false)                 # sliding door
	note("NORA\nWAS HERE", Vector3(-8, 2.2, 13.43), 110, Color(0.3, 0.7, 0.75), 0.1)
	# signal mast, yard lights, the far fence
	cyl(Vector3(7, 3.0, 2.5), 0.07, 6.0, Color(0.2, 0.2, 0.22), 0.6)
	box(Vector3(7, 5.6, 2.6), Vector3(0.4, 1.0, 0.2), Color(0.05, 0.05, 0.05), false)
	ball(Vector3(7, 5.85, 2.72), 0.1, Color(1.0, 0.08, 0.05), 0.0 if day else 3.0)
	ball(Vector3(7, 5.4, 2.72), 0.1, Color(0.1, 0.12, 0.1))
	if not day:
		omni(Vector3(7, 5.85, 3.2), Color(1.0, 0.15, 0.1), 1.0, 7.0)
	for p in [Vector3(-16, 0, -4), Vector3(22, 0, 3)]:
		cyl(p + Vector3(0, 5, 0), 0.12, 10, Color(0.3, 0.3, 0.32), 0.6)
		box(p + Vector3(0, 10, 0), Vector3(1.4, 0.3, 0.5), Color(0.2, 0.2, 0.22), false)
		if not day:
			ball(p + Vector3(0, 9.8, 0), 0.18, Color(0.85, 0.92, 1.0), 4.0)
			spot(p + Vector3(0, 9.7, 0), Vector3(p.x * 0.3, 0, p.z + 2), Color(0.75, 0.85, 1.0), 9.0, 34, 42, true, 2.2)
	prop("modular_electricity_poles", Vector3(-10, 0, -22), 0.0)
	fence_x(-30, -50, 50)
	box(Vector3(34, 1.6, 24), Vector3(7, 3.2, 4), Color(0.3, 0.3, 0.32))                                   # yard office, one window lit
	box(Vector3(32, 1.8, 21.98), Vector3(1.2, 0.9, 0.04), Color(1.0, 0.85, 0.6), false, 0.0 if day else 1.5)

func _tower() -> void:
	var brick := tex("factory_brick", 0.42, Color(0.9, 0.78, 0.72) if not stage == "aftermath" else Color(0.5, 0.42, 0.4))
	var conc := tex("concrete_floor_worn_001", 0.5)
	# ground floor walls; the door is in the south face
	wall_x(-2.38, -2.5, 2.5, 0, 6.6, brick, 0.25)
	wall_z(-2.38, -2.5, 2.5, 0, 6.6, brick, 0.25)
	wall_z(2.38, -2.5, 2.5, 0, UP, brick, 0.25)
	wall_x(2.38, -2.5, -0.5, 0, UP, brick, 0.25)
	wall_x(2.38, 0.5, 2.5, 0, UP, brick, 0.25)
	wall_x(2.38, -0.5, 0.5, 2.1, UP, brick, 0.25)
	# upper floor: the old operating room, windows on the south and east, boarded
	wall_x(2.38, -2.5, 2.5, UP, UP + 0.9, brick, 0.25)
	wall_x(2.38, -2.5, 2.5, UP + 2.5, 6.6, brick, 0.25)
	for x in [-2.3, 0.0, 2.3]:
		wall_x(2.38, x - 0.2, x + 0.2, UP + 0.9, UP + 2.5, brick, 0.25)
	wall_z(2.38, -2.5, 2.5, UP, UP + 0.9, brick, 0.25)
	wall_z(2.38, -2.5, 2.5, UP + 2.5, 6.6, brick, 0.25)
	for z in [-2.3, 0.0, 2.3]:
		wall_z(2.38, z - 0.2, z + 0.2, UP + 0.9, UP + 2.5, brick, 0.25)
	tbox(Vector3(0, 6.75, 0), Vector3(6.2, 0.3, 6.2), conc)                                               # roof slab, overhanging
	box(Vector3(0, UP + 0.86, 2.56), Vector3(5.2, 0.1, 0.2), Color(0.55, 0.55, 0.53), false)               # sill
	# boards over the windows, with gaps; in the "inside" arrangement the south-east window is the way out
	var board := tex("wood_planks_grey", 0.8, Color(0.65, 0.58, 0.5))
	for w in [[-1.15, 2.52, 0.0], [1.15, 2.52, 0.0], [2.52, -1.15, PI / 2], [2.52, 1.15, PI / 2]]:
		if burning or stage == "aftermath":
			var glow := box(Vector3(w[0], UP + 1.7, w[1]) * Vector3(0.96, 1, 0.96), Vector3(1.8, 1.5, 0.02), Color(1.0, 0.45, 0.12), false, 2.5 if burning else 0.0, w[2])
			if not burning:
				glow.material_override = mat(Color(0.03, 0.03, 0.03))
		for i in 6:
			if stage == "inside" and w[0] == 1.15 and i in [2, 3, 4]:
				continue
			var b := tbox(Vector3(w[0], UP + 1.0 + i * 0.28, w[1]), Vector3(1.95, 0.22, 0.03), board, false, w[2])
			b.rotation.z = sin(i * 2.3 + w[0]) * 0.04
	# the walkway round the south and east sides, its rail, and the ladder
	var steel := Color(0.16, 0.17, 0.19)
	tbox(Vector3(0.55, UP - 0.04, 3.05), Vector3(6.1, 0.08, 1.1), tex("metal_plate", 0.8, Color(0.5, 0.5, 0.52)))
	tbox(Vector3(3.05, UP - 0.04, -0.3), Vector3(1.1, 0.08, 5.6), tex("metal_plate", 0.8, Color(0.5, 0.5, 0.52)))
	for y in [0.55, 1.05]:
		box(Vector3(1.05, UP + y, 3.57), Vector3(5.1, 0.05, 0.05), steel, false)
		box(Vector3(3.57, UP + y, 0.25), Vector3(0.05, 0.05, 6.6), steel, false)
	for x in [-1.5, -0.5, 0.6, 1.7, 2.7, 3.57]:
		box(Vector3(x, UP + 0.52, 3.57), Vector3(0.05, 1.05, 0.05), steel, false)
	for z in [-3.0, -1.8, -0.6, 0.6, 1.8]:
		box(Vector3(3.57, UP + 0.52, z), Vector3(0.05, 1.05, 0.05), steel, false)
	for b in [[-2.3, 3.3], [3.3, 3.3], [3.3, -2.8]]:                                                       # brackets down to the wall
		box(Vector3(b[0], UP - 0.5, b[1]), Vector3(0.08, 0.9, 0.08), steel, false).rotation.x = 0.5
	for side in [-0.25, 0.25]:
		box(Vector3(-2.05 + side, 2.1, 3.68), Vector3(0.05, 4.4, 0.05), steel, false)
	for i in 13:
		box(Vector3(-2.05, 0.3 + i * 0.3, 3.68), Vector3(0.5, 0.035, 0.035), steel, false)
	# the door: steel, padlocked; open for the rescue
	if stage == "inside" or stage == "aftermath":
		door(Vector3(-0.5, 0, 2.9), -1.4, Color(0.25, 0.28, 0.3), 1.0, 2.1)
	else:
		door(Vector3(0, 0, 2.52), 0.0, Color(0.25, 0.28, 0.3), 1.0, 2.1)
		box(Vector3(0.38, 1.05, 2.57), Vector3(0.06, 0.09, 0.04), Color(0.72, 0.6, 0.25), false)
	plate("6", Vector3(1.5, 2.5, 2.52), 0.0, 0.6, 0.7, Color(0.9, 0.9, 0.85), INK, 330)
	plate("CALDER RAIL\nNO TRESPASSING\nSTRUCTURE UNSAFE", Vector3(-1.5, 1.6, 2.52), 0.0, 0.8, 0.5, Color(0.8, 0.7, 0.15), INK, 44)
	note("SEEN", Vector3(1.4, 1.1, 2.52), 90, Color(0.75, 0.75, 0.8), -0.08)
	if burning:
		fire(Vector3(1.4, UP + 0.1, 1.2), 4.0, 12.0, 0.6)
		smoke(Vector3(0, 0.2, 2.7), 0.5, 30 if st == null or st.late < 2 else 90, 0.6)
		smoke(Vector3(1.2, 6.9, 1.0), 1.0, 60, 1.6)
		omni(Vector3(1.2, UP + 1.7, 3.6), Color(1.0, 0.5, 0.16), 2.5, 9.0)
		omni(Vector3(3.6, UP + 1.7, 1.0), Color(1.0, 0.5, 0.16), 2.0, 9.0)
		flickers.append([get_child(get_child_count() - 1), 2.0, 11.0])
		flickers.append([get_child(get_child_count() - 2), 2.5, 8.0])
	elif stage == "aftermath":
		smoke(Vector3(0.5, 6.9, 0.5), 1.4, 70, 1.2)
		for w in [[1.15, 2.53], [-1.15, 2.53]]:
			box(Vector3(w[0], UP + 3.0, w[1]), Vector3(2.0, 1.4, 0.02), Color(0.02, 0.02, 0.02, 0.8), false)   # soot above the windows
	elif not day:
		omni(Vector3(1.2, UP + 1.5, 1.0), Color(1.0, 0.6, 0.3), 0.8, 4.0)                                  # the heater, behind the boards
		box(Vector3(1.15, UP + 1.7, 2.4), Vector3(1.8, 1.5, 0.02), Color(1.0, 0.55, 0.25), false, 0.2)

func _inside() -> void:
	var conc := tex("concrete_floor_worn_001", 0.5)
	tbox(Vector3(0, 0.01, 0), Vector3(4.6, 0.04, 4.6), conc, false)
	# upper floor slab with the stair opening on the west side
	tbox(Vector3(0.55, UP - 0.06, 0), Vector3(3.6, 0.12, 4.6), tex("wood_planks_grey", 0.6, Color(0.6, 0.52, 0.45)), false)
	tbox(Vector3(-1.75, UP - 0.06, 1.9), Vector3(1.0, 0.12, 0.8), tex("wood_planks_grey", 0.6, Color(0.6, 0.52, 0.45)), false)
	for i in 12:
		tbox(Vector3(-1.75, 0.14 + i * 0.28, -1.9 + i * 0.3), Vector3(1.0, 0.06, 0.3), tex("wood_planks_grey", 0.6, Color(0.5, 0.42, 0.36)), false)
	# ground floor: what a signal tower collects in twenty years shut
	prop("wooden_crate_02", Vector3(1.5, 0, -1.6), 0.3)
	prop("cement_bag", Vector3(1.4, 0, 0.6), 0.5)
	prop("cement_bag", Vector3(1.45, 0.18, 0.65), 0.9)
	prop("Barrel_01", Vector3(0.4, 0, -1.8), 0.0)
	prop("old_tyre", Vector3(1.9, 0.3, 1.6), 1.0)
	# upstairs: he had been getting it ready for a while
	prop("old_bed_frame", Vector3(1.55, UP, -1.1), 0.0)
	box(Vector3(1.55, UP + 0.42, -1.1), Vector3(0.85, 0.12, 1.9), Color(0.5, 0.5, 0.46), false)            # mattress
	box(Vector3(1.55, UP + 0.5, -0.8), Vector3(0.9, 0.05, 1.2), Color(0.3, 0.35, 0.5), false, 0.0, 0.05)   # blanket
	prop("barrel_stove", Vector3(1.4, UP, 1.3), 0.0, 0.7)
	cyl(Vector3(0.9, UP + 0.2, 1.6), 0.15, 0.4, Color(0.75, 0.75, 0.72), 0.5)                               # the gas bottle
	cyl(Vector3(0, UP + 1.0, -2.2), 0.04, 4.4, Color(0.3, 0.2, 0.15), 0.5).rotation.z = PI / 2              # the pipe
	prop("plastic_crate_01", Vector3(-0.6, UP, 1.7), 0.2)
	for i in 3:
		cyl(Vector3(-0.7 + i * 0.12, UP + 0.37, 1.7), 0.035, 0.22, Color(0.7, 0.8, 0.9, 0.6), 0.2)          # water bottles
	prop("book_encyclopedia_set_01", Vector3(-0.2, UP, -1.9), 0.3)
	# photographs of her on the wall, a neat grid
	for i in 12:
		box(Vector3(2.24, UP + 1.1 + (i / 4) * 0.2, -2.0 + (i % 4) * 0.18), Vector3(0.004, 0.15, 0.11), Color(0.85, 0.84, 0.8) if i % 5 else Color(0.5, 0.55, 0.65), false)
	note("TUE  THU\n5 — 9", Vector3(2.235, UP + 1.85, -1.75), 22, INK, 0.0, -PI / 2)
	if not burning:
		omni(Vector3(0.5, UP + 1.6, 0), Color(1.0, 0.7, 0.4), 0.6, 5.0)

func _dressing() -> void:
	for p in [[-3.2, 3.5, 0.0], [3.0, 4.6, 1.0], [-1.0, -3.2, 2.0], [-3.4, -1.0, 4.0], [4.4, -2.0, 0.5], [6.0, 6.8, 3.0], [-6, 7.2, 5.0]]:
		prop("weed_plant_02", Vector3(p[0], 0, p[1]), p[2], 0.5)
	prop("grass_medium_01", Vector3(-2.6, 0, 2.9), 0.0)
	prop("grass_medium_01", Vector3(-2.9, 0, -1.0), PI / 2)
	prop("old_tyre", Vector3(-3.4, 0.1, 2.2), 0.0).rotation.x = PI / 2
	prop("Barrel_01", Vector3(-3.3, 0, 0.6), 0.0)
	prop("wooden_crate_01", Vector3(3.2, 0, 3.3), 0.4)
	prop("concrete_road_barrier", Vector3(-6, 0, 4.5), 0.3)
	prop("cement_bag", Vector3(2.9, 0, 1.2), 1.2)
	for i in 5:                                                                                            # a stack of old sleepers
		box(Vector3(-6.5, 0.07 + (i / 3) * 0.13, 1.0 + (i % 3) * 0.3), Vector3(2.5, 0.12, 0.24), Color(0.2, 0.15, 0.12), false)

# ── arrangements ─────────────────────────────────────────────────

func _standoff() -> void:
	actor("HARLAN", "brian", Vector3(0.6, UP, 2.95), 0.1, "argue", "argue", {"Shirt": Color(0.5, 0.52, 0.56), "Pants": Color(0.75, 0.75, 0.8)})
	actor("TESSA", "kate", Vector3(0.75, UP, 3.3), 0.0, "terrified", "terrified")
	actor("REYES", "louise", Vector3(-2.2, 0, 9.5), PI + 0.2)
	box(Vector3(0.95, UP + 1.25, 3.25), Vector3(0.02, 0.1, 0.03), Color(0.9, 0.75, 0.1), false)             # box cutter, roughly at his hand
	spot(Vector3(-4, 1.2, 12), Vector3(0.6, UP + 1.2, 3.1), Color(0.9, 0.95, 1.0), 5.0, 16, 22, true, 2.5)   # Reyes's flashlight
	shot("wide", Vector3(3.5, 1.4, 11.5), Vector3(0.4, 3.6, 3), 52)
	shot("HARLAN", Vector3(1.9, 3.0, 8.0), Vector3(0.65, UP + 1.5, 3.1), 26)
	shot("TESSA", Vector3(-0.4, 3.2, 7.5), Vector3(0.75, UP + 1.45, 3.3), 26)
	close("REYES", 1.5, 0.5, 1.6, 42)
	tracks["walkway"] = [
		[Vector3(-2.05, 1.6, 6.0), Vector3(-2.05, 3.0, 3.7)], [Vector3(-2.05, UP + 1.5, 4.1), Vector3(0.6, UP + 1.4, 3.1)],
		[Vector3(-1.2, UP + 1.6, 3.1), Vector3(0.6, UP + 1.4, 3.1)], [Vector3(-0.5, UP + 1.6, 3.05), Vector3(0.6, UP + 1.2, 3.15)],
		[Vector3(-0.2, UP + 1.6, 3.0), Vector3(0.8, UP + 1.3, 3.35)], [Vector3(-0.1, UP + 1.6, 3.0), Vector3(0.7, UP + 0.4, 3.0)],
	]

func _rescue() -> void:
	actor("TESSA", "kate", Vector3(0.0, UP - 0.25, -1.75), 0.0, "sit_idle", "sit_idle")
	actor("REYES", "louise", Vector3(1.6, 0, 5.6), PI)
	fire(Vector3(-0.6, 0.05, -0.2), 2.5, 7.0, 0.5)
	fire(Vector3(0.2, UP + 0.05, 1.7), 3.0, 8.0, 0.7)
	fire(Vector3(-1.75, 1.8, -0.2), 2.0, 6.0, 0.3)
	shot("wide", Vector3(0, 1.6, 6.5), Vector3(0, 1.2, 2.5), 60)
	tracks["rescue"] = [
		[Vector3(0, 1.6, 6.5), Vector3(0, 1.2, 2.5)], [Vector3(0, 1.5, 3.4), Vector3(0, 1.0, 0)],
		[Vector3(0.4, 0.8, 1.3), Vector3(-1.6, 1.0, -1.5)], [Vector3(-1.75, UP + 1.5, 1.3), Vector3(0.6, UP + 1.2, 0.2)],
		[Vector3(-0.8, UP + 1.5, 0.6), Vector3(0.0, UP + 0.9, -1.75)], [Vector3(-0.2, UP + 1.1, -0.7), Vector3(0.0, UP + 0.7, -1.75)],
		[Vector3(0.3, UP + 1.5, 0.8), Vector3(1.15, UP + 1.6, 2.4)], [Vector3(1.15, UP + 1.5, 2.0), Vector3(1.6, 0.6, 5.6)],
		[Vector3(1.4, 1.5, 6.5), Vector3(0.5, 4.6, 2.5)],
	]

func _morning() -> void:
	# ambulance backed up toward the tower, rear doors open
	van(Vector3(9.0, 0, 8.2), 0.06, Color(0.9, 0.9, 0.88), true, "CALDER COUNTY EMS", Color(0.85, 0.3, 0.1), true)
	box(Vector3(6.35, 0.35, 8.05), Vector3(0.5, 0.1, 1.5), Color(0.3, 0.3, 0.32), false)                    # the back step
	strobe(Vector3(10.5, 2.3, 8.2), Color(1.0, 0.15, 0.1), Color(1.0, 0.9, 0.8), 1.5, 9.0)
	van(Vector3(-9.5, 0, 9.5), -0.3, Color(0.1, 0.13, 0.25), false, "POLICE", Color(0.9, 0.9, 0.9), true, "car")
	# tape between stakes
	for seg in [[Vector3(-5, 1.0, 6.5), Vector3(5, 1.0, 6.2)], [Vector3(5, 1.0, 6.2), Vector3(5.5, 1.0, -3)]]:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var tape := box((a + b) / 2, Vector3(a.distance_to(b), 0.07, 0.004), Color(0.95, 0.8, 0.1), false)
		tape.rotation.y = atan2(a.z - b.z, b.x - a.x)
		tape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for p in seg:
			cyl(Vector3(p.x, 0.55, p.z), 0.02, 1.1, Color(0.4, 0.3, 0.2))
	prop("medical_box", Vector3(5.6, 0, 7.0), 0.5)
	actor("REYES", "louise", Vector3(4.2, 0, 9.6), 1.9)
	if stage == "dawn":
		# foil blanket wrapped round her shoulders
		actor("TESSA", "kate", Vector3(6.3, -0.08, 8.05), -PI / 2, "sit_idle", "sit_talk")
		foil_wrap(Vector3(6.1, -0.08, 8.05), -PI / 2, 1.14)
		actor("", "chad", Vector3(6.0, 0, 6.6), 0.4, "idle", "talk")
		close("TESSA", 1.5, 0.35, 1.06, 38)
	else:
		box(Vector3(7.6, 0.75, 8.2), Vector3(1.9, 0.08, 0.6), Color(0.85, 0.85, 0.82), false)               # stretcher
		box(Vector3(7.6, 0.87, 8.2), Vector3(1.7, 0.16, 0.5), Color(0.75, 0.3, 0.1), false)
		actor("", "chad", Vector3(6.5, 0, 9.35), 2.9, "idle", "talk")
		if stage == "dawn_hurt":
			actor("TESSA", "kate", Vector3(7.6, 0.0, 8.2), PI / 2, clip("lie", "sit_idle"), clip("lie", "sit_idle"))
		actor("", "alex", Vector3(4.4, 0, 6.0), 0.5, "idle", "idle")
		if stage == "aftermath":
			van(Vector3(-6.5, 0, 12.5), PI - 0.15, Color(0.6, 0.08, 0.06), false, "CALDER FIRE  ·  ENGINE 9", Color(0.9, 0.85, 0.3), true, "truck")
			box(Vector3(0, 0.04, 6.5), Vector3(0.09, 0.07, 7.0), Color(0.6, 0.55, 0.3), false, 0.0, 0.25)     # hose
			actor("", "leonard", Vector3(1.0, 0, 5.2), PI + 0.4, "idle", "talk", {"Sweater": Color(2.4, 2.0, 0.6), "Pants": Color(2.0, 1.7, 0.5)})
	if st != null and st.on("harlanDead"):
		box(Vector3(2.0, 0.12, 5.0), Vector3(1.9, 0.22, 0.8), Color(0.15, 0.25, 0.5), false, 0.0, 0.5)       # tarp
	shot("wide", Vector3(1.0, 1.5, 12.5), Vector3(6.0, 1.1, 8.0), 50)
	shot("ambulance", Vector3(3.6, 1.5, 9.4), Vector3(6.8, 1.0, 8.1), 42)
	shot("tower", Vector3(5.5, 1.4, 10.0), Vector3(0.5, 3.2, 2.0), 50)
	shot("sunrise", Vector3(-2, 1.4, 10), Vector3(-40, 5.0, 4), 40)
	shot("ending", Vector3(8, 1.0, 14), Vector3(0, 4, 0), 46)
	close("REYES", 1.5, -0.5, 1.6, 42)
