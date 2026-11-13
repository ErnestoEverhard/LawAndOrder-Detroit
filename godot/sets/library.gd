extends Kit
## Hollis University Library: the service entrance, the staff vestibule, the stacks, and the fence to the rail yard.
## Arrangements: "dock" (van shut; also the canvass), "van" (van open, Harlan in the doorway),
## "chase" (the pursuit through the building) and "fence" (where it ends).

const LOW := -1.2                      # the ground on the rail-yard side sits lower than the dock
var runner: Node3D
var path := [Vector3(3, 0, -0.3), Vector3(2, 0, -5), Vector3(2, 0, -10.5), Vector3(4.5, 0, -17), Vector3(10.5, LOW, -18),
	Vector3(15.5, LOW, -17.5), Vector3(22, LOW, -11.5), Vector3(24.4, LOW + 0.9, -9.25), Vector3(24.4, LOW + 0.9, -9.25)]

func build() -> void:
	ambience = "night"
	env("hansaplatz", 0.5, Color(0.24, 0.27, 0.38), 1.3, 0.016, Color(0.8, 0.75, 0.7))
	_outside()
	_vestibule()
	_stacks()
	_yard_side()
	_people()

func _outside() -> void:
	var brick := tex("factory_brick", 0.4, Color(0.95, 0.85, 0.8))
	tbox(Vector3(0, -0.05, 12), Vector3(60, 0.1, 30), tex("asphalt_02", 0.3, Color(0.75, 0.75, 0.8)))
	# the library's back wall, with the service doorway cut into it
	wall_x(-0.15, -16, 2.5, 0, 8, brick, 0.3)
	wall_x(-0.15, 3.5, 14, 0, 8, brick, 0.3)
	wall_x(-0.15, 2.5, 3.5, 2.1, 8, brick, 0.3)
	box(Vector3(-1, 8.1, -0.15), Vector3(31, 0.25, 0.6), Color(0.3, 0.3, 0.31), false)             # coping
	for x in [-11.0, -7.5, 8.0, 11.5]:                                                            # dark windows, upper floor
		box(Vector3(x, 5.2, 0.01), Vector3(1.6, 2.0, 0.05), Color(0.04, 0.05, 0.07), false).material_override = mat(Color(0.04, 0.05, 0.07), 0.0, 0.1)
		box(Vector3(x, 4.15, 0.06), Vector3(1.8, 0.1, 0.16), Color(0.5, 0.5, 0.48), false)
	# receiving bay
	prop("rollershutter_door", Vector3(-3.6, 0, 0.0), 0.0, 2.9)
	note("2", Vector3(-2.3, 1.7, 0.42), 150, Color(0.85, 0.85, 0.8))
	plate("HOLLIS UNIVERSITY LIBRARY\nRECEIVING", Vector3(-2.2, 3.55, 0.03), 0.0, 3.2, 0.7, Color(0.1, 0.16, 0.3), Color(0.9, 0.9, 0.85), 130)
	plate("DELIVERIES 7 AM – 3 PM\nNO IDLING · NO OVERNIGHT PARKING", Vector3(0.9, 1.7, 0.03), 0.0, 1.1, 0.5, Color(0.9, 0.9, 0.86), Color(0.6, 0.1, 0.1), 36)
	plate("STAFF ONLY", Vector3(4.2, 1.75, 0.03), 0.0, 0.6, 0.18, Color(0.9, 0.9, 0.86), INK, 44)
	for x in [-4.2, -0.4]:                                                                        # rubber dock bumpers
		box(Vector3(x, 0.5, 0.12), Vector3(0.25, 0.6, 0.14), Color(0.05, 0.05, 0.05), false)
	for x in [-5.2, 0.4, 1.9, 4.6]:
		bollard(Vector3(x, 0, 1.4))
	for i in 7:                                                                                    # fire lane hatching, worn
		box(Vector3(-4.6 + i * 0.75, 0.004, 3.2), Vector3(0.12, 0.004, 2.2), Color(0.7, 0.6, 0.15), false, 0.0, 0.6)
	box(Vector3(6.5, 0.003, 5.0), Vector3(3.0, 0.004, 1.6), Color.WHITE, false).material_override = mat(Color(0.03, 0.03, 0.04), 0.0, 0.03)   # puddle
	# sodium lights over the bay and the door
	for x in [-2.2, 3.0]:
		prop("industrial_wall_lamp", Vector3(x, 3.0 if x < 0 else 2.6, 0.02), 0.0)
		omni(Vector3(x, 2.7 if x < 0 else 2.4, 0.9), Color(1.0, 0.62, 0.28), 3.2, 11.0, true)
	# the door, propped open with a mop bucket
	door(Vector3(3.92, 0, 0.42), PI / 2 - 0.25, Color(0.28, 0.33, 0.36), 0.95, 2.05, true)
	cyl(Vector3(3.55, 0.17, 0.3), 0.17, 0.34, Color(0.8, 0.7, 0.1), 0.6)
	cyl(Vector3(3.6, 0.75, 0.25), 0.015, 1.3, Color(0.6, 0.5, 0.35)).rotation.z = 0.2
	# where the night staff smoke
	prop("plastic_monobloc_chair_01", Vector3(5.6, 0, 0.7), -0.5)
	prop("cigarette_pack", Vector3(5.2, 0.0, 0.45), 1.0)
	cyl(Vector3(5.1, 0.08, 0.7), 0.06, 0.16, Color(0.5, 0.12, 0.1), 0.5)                           # coffee can of butts
	cup(Vector3(5.95, 0, 0.35), Color(0.85, 0.83, 0.75))
	# the dock camera, turned to the brick with tape over the lens
	prop("security_camera_01", Vector3(5.5, 3.0, 0.1), PI + 0.2)
	box(Vector3(5.47, 3.12, 0.02), Vector3(0.14, 0.06, 0.02), Color(0.55, 0.56, 0.58), false)
	# dumpster with flattened boxes; her phone is on top
	var green := Color(0.10, 0.22, 0.16)
	box(Vector3(-8.0, 0.65, 1.3), Vector3(2.2, 1.1, 1.3), green)
	box(Vector3(-8.0, 1.24, 1.3), Vector3(2.3, 0.08, 1.4), Color(0.07, 0.15, 0.11), false)
	box(Vector3(-8.5, 1.5, 0.75), Vector3(1.1, 0.04, 1.0), Color(0.06, 0.06, 0.07), false).rotation.x = 1.1      # one lid thrown back
	for i in 4:
		box(Vector3(-8.3 + i * 0.3, 1.3 + i * 0.012, 1.4), Vector3(0.9, 0.012, 0.7), Color(0.55, 0.43, 0.28), false, 0.0, i * 0.5)
	box(Vector3(-7.7, 1.36, 1.5), Vector3(0.075, 0.012, 0.15), Color(0.2, 0.5, 0.35), false, 0.0, 0.4)           # the phone, green case
	note("HOLLIS\nFACILITIES", Vector3(-8.0, 0.7, 1.96), 40, Color(0.8, 0.8, 0.75))
	prop("trashbag", Vector3(-6.5, 0, 1.0), 0.4)
	prop("trashbag", Vector3(-6.3, 0, 1.6), 2.0)
	# pallets of returned books, a hand truck, crates
	for py in 3:
		for b in 3:
			box(Vector3(-11.0, 0.03 + py * 0.14, 1.0 + b * 0.5), Vector3(1.2, 0.02, 0.1), Color(0.5, 0.4, 0.28), false)
		box(Vector3(-11.0, 0.1 + py * 0.14, 1.5), Vector3(1.2, 0.02, 1.0), Color(0.52, 0.42, 0.3), py == 0)
	for b in [[-11.3, 0.44, 1.3, 0.1], [-10.8, 0.44, 1.7, 0.6], [-11.1, 0.78, 1.5, -0.2]]:
		prop("cardboard_box_01", Vector3(b[0], b[1], b[2]), b[3])
	prop("hand_truck", Vector3(-9.6, 0, 0.6), 0.3)
	prop("plastic_crate_01", Vector3(-5.6, 0, 0.5), 0.2)
	prop("plastic_crate_01", Vector3(-5.6, 0.26, 0.5), -0.3)
	prop("exterior_aircon_unit", Vector3(9.5, 0.3, 0.4), 0.0)
	prop("utility_box_01", Vector3(12.0, 0, 0.3), 0.0)
	prop("street_lamp_01", Vector3(-10, 0, 13), 0.0, 5.5)
	spot(Vector3(-10, 5.3, 12.6), Vector3(-7, 0, 9), Color(0.75, 0.85, 1.0), 5.0, 16, 50, true, 2.0)
	prop("concrete_road_barrier", Vector3(9, 0, 13.5), 0.1)
	prop("concrete_road_barrier", Vector3(10.7, 0, 13.4), -0.05)
	prop("covered_car", Vector3(-13, 0, 9), 0.1)
	# the yard is fenced; the rail yard is beyond the east end
	fence_x(15, -16, 14)
	fence_z(14, 0, 15)
	blocker(Vector3(-16, 1.5, 7.5), Vector3(0.3, 3, 15))
	blocker(Vector3(0, 1.5, 15), Vector3(32, 3, 0.3))
	blocker(Vector3(14, 1.5, 7.5), Vector3(0.3, 3, 15))
	# the van
	var open_van := stage != "dock"
	van(Vector3(1.6, 0, 8.6), 0.12, Color(0.86, 0.86, 0.84), open_van, "HOLLIS UNIVERSITY\nFACILITIES  ·  UNIT 7")
	box(Vector3(0.9, 2.17, 8.7), Vector3(2.6, 0.05, 1.3), Color(0.3, 0.3, 0.32), false, 0.0, 0.12)   # ladder rack
	if open_van:
		box(Vector3(0.4, 0.5, 8.75), Vector3(1.5, 0.1, 1.2), Color(0.25, 0.28, 0.4), false, 0.0, 0.3)   # moving blanket
		cyl(Vector3(-0.2, 0.5, 8.2), 0.06, 0.05, Color(0.5, 0.5, 0.52), 0.4)                           # duct tape
		box(Vector3(-0.35, 0.5, 8.95), Vector3(0.26, 0.09, 0.1), Color(0.95, 0.95, 0.93), false, 0.0, 0.7)   # one white sneaker
		omni(Vector3(-0.4, 1.2, 8.8), Color(0.9, 0.95, 1.0), 0.8, 2.5)                                 # Reyes's flashlight

func _vestibule() -> void:
	var paint := tex("beige_wall_001", 0.5, Color(0.78, 0.84, 0.76))
	var floor_m := tex("concrete_floor_worn_001", 0.5)
	tbox(Vector3(3.5, -0.05, -1.5), Vector3(5, 0.1, 3), floor_m)
	box(Vector3(3.5, 2.85, -1.5), Vector3(5, 0.1, 3), Color(0.7, 0.7, 0.68))
	wall_z(0.95, -3, 0, 0, 2.8, paint)
	wall_z(6.05, -3, 0, 0, 2.8, paint)
	wall_x(-3.05, 2.5, 6, 0, 2.8, paint)
	wall_x(-3.05, 1, 1.5, 0, 2.8, paint)
	wall_x(-3.05, 1.5, 2.5, 2.1, 2.8, paint)
	tube(Vector3(3.5, 2.76, -1.5), 1.2, true, Color(0.85, 0.95, 0.9), 2.4, 7.0, true)
	# time clock and card rack, facing the door
	box(Vector3(3.3, 1.45, -2.96), Vector3(0.3, 0.36, 0.14), Color(0.25, 0.27, 0.3), false)
	box(Vector3(3.3, 1.52, -2.885), Vector3(0.2, 0.1, 0.01), Color(0.5, 0.9, 0.6), false, 1.2)
	box(Vector3(3.95, 1.4, -2.98), Vector3(0.6, 0.8, 0.04), Color(0.4, 0.4, 0.42), false)
	for i in 10:
		box(Vector3(3.74 + (i % 2) * 0.32, 1.1 + (i / 2) * 0.15, -2.95), Vector3(0.24, 0.11, 0.02), Color(0.92, 0.88, 0.7), false)
	box(Vector3(3.5, 1.3, -2.9), Vector3(0.24, 0.11, 0.02), Color(0.95, 0.9, 0.72), false, 0.0, 0.0).rotation.z = 0.35   # his card, left out
	note("HARLAN, W.\nOUT  9:02 PM", Vector3(3.5, 1.3, -2.888), 9, INK, 0.35)
	plate("PUNCH IN · PUNCH OUT\nNO BUDDY PUNCHING", Vector3(3.6, 1.95, -2.99), 0.0, 0.8, 0.2, Color(0.92, 0.9, 0.82), INK, 30)
	# lockers along the east wall
	for i in 6:
		var z := -2.7 + i * 0.4
		box(Vector3(5.78, 0.95, z), Vector3(0.45, 1.9, 0.38), Color(0.36, 0.44, 0.5) if i != 3 else Color(0.33, 0.41, 0.47))
		for v in 3:
			box(Vector3(5.55, 1.6 + v * 0.05, z), Vector3(0.01, 0.012, 0.22), Color(0.1, 0.12, 0.14), false)
		box(Vector3(5.55, 1.05, z + 0.12), Vector3(0.015, 0.08, 0.03), Color(0.7, 0.7, 0.72), false)
		note(str(11 + i), Vector3(5.548, 1.42, z), 40, Color(0.9, 0.9, 0.85), 0.0, -PI / 2)
	note("HARLAN", Vector3(5.548, 1.3, -1.5), 22, Color(0.9, 0.9, 0.85), 0.0, -PI / 2)
	prop("WetFloorSign_01", Vector3(1.6, 0, -0.8), 0.5)
	box(Vector3(1.25, 0.5, -2.2), Vector3(0.4, 1.0, 0.9), Color(0.5, 0.5, 0.5))                       # grey supply cabinet
	prop("metal_toolbox", Vector3(1.3, 1.0, -2.2), PI / 2)
	plate("LOST PROPERTY GOES TO CIRCULATION, NOT YOUR LOCKER  — MGMT", Vector3(4.8, 2.1, -2.99), 0.0, 0.9, 0.16, Color(0.95, 0.9, 0.5), INK, 26)

func _stacks() -> void:
	var paint := tex("beige_wall_001", 0.5, Color(0.86, 0.84, 0.74))
	var lino := tex("old_linoleum_flooring_01", 0.6, Color(0.5, 0.52, 0.5))
	# corridor north from the vestibule
	tbox(Vector3(2, -0.05, -6), Vector3(2, 0.1, 6), lino)
	box(Vector3(2, 2.85, -6), Vector3(2, 0.1, 6), Color(0.7, 0.7, 0.68))
	wall_z(0.95, -9, -3, 0, 2.8, paint)
	wall_z(3.05, -9, -3, 0, 2.8, paint)
	tube(Vector3(2, 2.76, -6), 1.2, false, Color(0.85, 0.95, 0.9), 1.4, 6.0)
	prop("industrial_storage_cart", Vector3(2.3, 0, -8.0), 0.3, 1.1)
	prop("book_encyclopedia_set_01", Vector3(2.0, 0.5, -8.0), 0.4)
	prop("korean_fire_extinguisher_01", Vector3(1.1, 0, -4.2), PI / 2)
	# the stacks
	tbox(Vector3(2, -0.05, -15), Vector3(12, 0.1, 12), lino)
	box(Vector3(5, 2.95, -15), Vector3(18, 0.1, 12), Color(0.66, 0.66, 0.64))
	wall_x(-9.05, -4, 1, 0, 2.9, paint)
	wall_x(-9.05, 3, 14, 0, 2.9, paint)
	wall_x(-21.05, -4, 14, LOW, 2.9, paint)
	wall_z(-4.05, -21, -9, 0, 2.9, paint)
	wall_z(14.05, -21, -18.5, LOW, 2.9, paint)
	wall_z(14.05, -17.5, -9, LOW, 2.9, paint)
	wall_z(14.05, -18.5, -17.5, LOW + 2.1, 2.9, paint)
	for x in [-2.6, -0.2, 4.2, 6.6]:
		for i in 4:
			var tilt := 0.0
			var sh := prop("wooden_bookshelf_worn", Vector3(x, 0, -11.0 - i * 1.5), PI / 2 if x < 2 else -PI / 2)
			if stage == "chase" and x == 4.2 and i > 0:                    # the ones he pulls down behind him
				sh.rotation.z = 0.5 + i * 0.12
				sh.position += Vector3(-0.3, 0, 0)
			for y in [0.1, 0.52, 0.94, 1.36]:
				if (i + int(y * 10)) % 3 != 0:
					var b: Node3D = _load("res://assets/models/book_encyclopedia_set_01/book_encyclopedia_set_01_1k.gltf").instantiate()
					b.position = Vector3(-0.5, y, 0.1)
					b.scale = Vector3(1.6, 1.15, 1.2)
					sh.add_child(b)
	for z in [-11.5, -15.0, -18.5]:
		tube(Vector3(2, 2.86, z), 1.2, true, Color(0.9, 0.95, 0.88), 1.2 if z != -15.0 else 0.4, 7.0, z == -11.5)
	plate("QUIET FLOOR", Vector3(2, 2.3, -20.98), 0.0, 1.2, 0.25, Color(0.15, 0.25, 0.2), Color(0.9, 0.9, 0.85), 70)
	plate("EXIT →", Vector3(8.5, 2.5, -20.98), 0.0, 0.7, 0.22, Color(0.1, 0.5, 0.2), Color(1, 1, 1), 70, null, 1.5)
	# stairs down to the fire door
	for i in 6:
		tbox(Vector3(8.25 + i * 0.5, -0.1 - i * 0.2, -18), Vector3(0.5, 0.2, 3.0), tex("concrete_floor_worn_001", 0.5))
	tbox(Vector3(12.5, LOW - 0.05, -18), Vector3(3, 0.1, 6), tex("concrete_floor_worn_001", 0.5))
	box(Vector3(9.5, 0.3, -16.45), Vector3(3.2, 0.05, 0.05), Color(0.5, 0.5, 0.52), false).rotation.z = -0.38   # hand rail
	door(Vector3(14.3, LOW, -18.6), -1.0, Color(0.5, 0.12, 0.1), 1.0, 2.05)
	plate("FIRE DOOR\nKEEP CLOSED", Vector3(13.98, LOW + 2.35, -18), -PI / 2, 0.7, 0.24, Color(0.75, 0.1, 0.1), Color(1, 1, 1), 40)
	omni(Vector3(12.5, LOW + 2.2, -18), Color(1.0, 0.3, 0.2), 0.8, 5.0)
	tube(Vector3(9.5, 2.86, -18), 1.2, true, Color(0.9, 0.95, 0.88), 1.0, 7.0)

func _yard_side() -> void:
	tbox(Vector3(27, LOW - 0.05, -14), Vector3(26, 0.1, 30), tex("gravel_floor_02", 0.35, Color(0.7, 0.7, 0.75)))
	wall_z(14.2, -9, 0, LOW, 8, tex("factory_brick", 0.4, Color(0.95, 0.85, 0.8)), 0.3)
	fence_x(-9.2, 16, 36, 2.4, LOW)
	# the rail yard beyond the fence
	var car := tex("corrugated_iron_02", 0.5, Color(0.55, 0.3, 0.25))
	tbox(Vector3(22, LOW + 2.0, -4.5), Vector3(12, 2.8, 2.8), car, false)
	tbox(Vector3(35, LOW + 2.0, -4.5), Vector3(12, 2.8, 2.8), tex("corrugated_iron_02", 0.5, Color(0.3, 0.38, 0.45)), false)
	for x in [17.5, 26.5, 30.5, 39.5]:
		box(Vector3(x, LOW + 0.35, -4.5), Vector3(1.6, 0.7, 2.2), Color(0.08, 0.08, 0.09), false)
	box(Vector3(27, LOW + 0.06, -3.8), Vector3(40, 0.12, 0.08), Color(0.4, 0.38, 0.36), false)
	box(Vector3(27, LOW + 0.06, -5.2), Vector3(40, 0.12, 0.08), Color(0.4, 0.38, 0.36), false)
	prop("old_tyre", Vector3(19, LOW + 0.3, -9.6), 0.2)
	prop("weed_plant_02", Vector3(21, LOW, -9.7), 0.0, 0.5)
	prop("weed_plant_02", Vector3(26, LOW, -9.9), 2.0, 0.6)
	prop("Barrel_01", Vector3(17, LOW, -10.2), 0.0)
	spot(Vector3(30, LOW + 9, -2), Vector3(24, LOW, -10), Color(0.75, 0.85, 1.0), 6.0, 22, 40, true, 2.5)
	omni(Vector3(16, LOW + 2.6, -17), Color(1.0, 0.62, 0.28), 2.2, 9.0, true)
	if stage == "fence" and st != null and st.on("fled"):
		box(Vector3(24.4, LOW + 2.36, -9.2), Vector3(0.05, 0.1, 0.03), Color(0.45, 0.45, 0.45), false)                 # torn belt loop
		box(Vector3(24.4, LOW + 2.27, -9.18), Vector3(0.014, 0.08, 0.005), Color.WHITE, false).material_override = mat(Color(0.75, 0.58, 0.2), 0.3, 0.3, 0.8)

func _people() -> void:
	var gray := {"Tops": Color(1.6, 1.6, 1.6)}
	match stage:
		"dock":
			solid_person(actor("REYES", "leonard", Vector3(-1.6, 0, 7.4), 2.6), "REYES")
			talk = {"REYES": _reyes}
			spawn = [Vector3(-2.5, 0, 10.5), 0.0]
			spots = {
				"Dumpster": {"pos": Vector3(-7.9, 1.0, 1.5), "size": Vector3(2.2, 1.6, 1.4)},
				"Time clock": {"pos": Vector3(3.5, 1.4, -2.85), "size": Vector3(1.4, 0.9, 0.3)},
				"Dock camera": {"pos": Vector3(5.5, 2.7, 0.35), "size": Vector3(0.8, 1.0, 0.7)},
			}
			blocker(Vector3(2, 1.4, -3.0), Vector3(1.0, 2.8, 0.2))
			shot("wide", Vector3(-7.5, 2.3, 13.5), Vector3(0.5, 1.4, 3), 55)
			close("REYES", 1.5, 0.5, 1.6, 42)
			shot("locker", Vector3(4.3, 1.5, -1.0), Vector3(5.8, 1.25, -1.55), 45)
		"van":
			actor("REYES", "leonard", Vector3(-1.9, 0, 7.6), 1.9)
			actor("HARLAN", "remy", Vector3(3, 0, -0.35), 0.15, "idle", "talk", gray)
			shot("wide", Vector3(-6.0, 1.9, 11.5), Vector3(1.5, 1.3, 3.5), 55)
			shot("van", Vector3(-3.6, 1.5, 9.4), Vector3(0, 0.9, 8.7), 45)
			shot("HARLAN", Vector3(1.9, 1.55, 4.2), Vector3(3, 1.5, -0.35), 30)
			close("REYES", 1.5, 0.5, 1.6, 42)
		"chase":
			runner = actor("HARLAN", "remy", path[0], PI, "run", "run", gray)
			tracks["chase"] = [
				[Vector3(3, 1.6, 4.0), Vector3(3, 1.4, -2)], [Vector3(3, 1.6, -1.2), Vector3(2, 1.3, -6)],
				[Vector3(2, 1.6, -6.2), Vector3(2, 1.2, -12)], [Vector3(2, 1.6, -12.5), Vector3(5, 1.2, -17)],
				[Vector3(6.4, 1.6, -17.6), Vector3(11, LOW + 1.2, -18)], [Vector3(11.5, LOW + 1.6, -18), Vector3(15, LOW + 1.4, -18)],
				[Vector3(17, LOW + 1.6, -16.5), Vector3(23, LOW + 1.2, -10.5)], [Vector3(23.2, LOW + 1.6, -11.0), Vector3(24.4, LOW + 1.9, -9.3)],
			]
			shot("wide", Vector3(3, 1.6, 4.0), Vector3(3, 1.4, -2), 60)
		"fence":
			var fled: bool = st != null and st.on("fled")
			actor("REYES", "leonard", Vector3(23.0, LOW, -11.2), 0.6)
			if not fled:
				actor("HARLAN", "remy", Vector3(24.2, LOW, -10.4), 2.6, "idle", "talk", gray)
			shot("wide", Vector3(20.0, LOW + 1.7, -13.5), Vector3(24.2, LOW + 1.3, -9.8), 52)
			close("HARLAN", 1.4, 0.4, 1.58, 40)
			close("REYES", 1.4, -0.4, 1.6, 42)
			shot("key", Vector3(24.0, LOW + 2.0, -10.2), Vector3(24.4, LOW + 2.3, -9.2), 40)

func _reyes(left: int, _budget: int) -> String:
	if left == 0:
		return "That's the phone buzzing. Tell me that's Diaz."
	return [
		"Trash is fair game. So's anything we can see from where a delivery driver could stand. We just can't open anything that's shut.",
		"That door's propped. I can see a time clock and a row of lockers from here. Looking is free. Touching his locker isn't, not yet.",
	][left % 2]

func on_step(track: String, i: int) -> void:
	if track != "chase" or runner == null:
		return
	var to: Vector3 = path[mini(i + 1, path.size() - 1)]
	var from := runner.position
	if to.distance_to(from) > 0.1:
		runner.rotation.y = atan2(to.x - from.x, to.z - from.z)
		create_tween().tween_property(runner, "position", to, 1.6)
