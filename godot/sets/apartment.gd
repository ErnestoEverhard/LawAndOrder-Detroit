extends Kit
## Tessa Brandt's bedroom at 418 Mercer Street, and the hall outside it.
## Arrangements: "search" (walk around the room) and "hall" (Priya on the stairs).

func build() -> void:
	env("cobblestone_street_night", 0.7, Color(0.27, 0.29, 0.38), 1.15)
	_room()
	_furniture()
	_lights()
	_people()
	spawn = [Vector3(0.4, 0.0, 2.3), 0.0]
	spots = {
		"Tablet": {"pos": Vector3(-2.1, 0.8, -2.6), "size": Vector3(0.5, 0.3, 0.5)},
		"Bookshelf": {"pos": Vector3(-3.8, 0.85, 0.4), "size": Vector3(0.5, 0.5, 0.9)},
		"Laptop": {"pos": Vector3(2.3, 0.74, -2.4), "size": Vector3(0.6, 0.45, 0.5)},
		"Window": {"pos": Vector3(3.8, 1.4, 0.8), "size": Vector3(0.4, 1.4, 1.8)},
		"Corkboard": {"pos": Vector3(0.2, 1.55, -2.9), "size": Vector3(1.5, 1.0, 0.3)},
		"Wastebasket": {"pos": Vector3(-0.9, 0.25, -2.5), "size": Vector3(0.5, 0.6, 0.5)},
	}
	talk = {"REYES": _reyes, "PRIYA": _priya}
	if stage == "hall":
		shot("wide", Vector3(-0.9, 1.45, 4.35), Vector3(2.4, 0.95, 3.9), 52)
		close("PRIYA", 1.5, 0.35, 1.02, 40)
		close("REYES", 1.5, -0.4, 1.6, 42)
	else:
		shot("wide", Vector3(-3.3, 1.7, 2.3), Vector3(1.0, 1.0, -1.2), 62)
		shot("door", Vector3(0.1, 1.55, 3.9), Vector3(0.6, 1.2, 0.0), 55)
		close("REYES", 1.6, 0.5, 1.6, 42)

var _talks := 0

func _priya(left: int, _budget: int) -> String:
	if left > 0:
		return "She's holding her phone in both hands in case it rings. \"Did you find anything? Please. Just look. I'll be right here.\""
	return "\"Are they done in there? Did you find something?\""

func _reyes(left: int, budget: int) -> String:
	# What your partner says depends on how far the search has got.
	_talks += 1
	if left == 0:
		return "That's our time, Nadia. Crime scene has the room. Priya's still in the hall, and she's the one who called it in. Let's hear it from her."
	if left == budget:
		return [
			"Roommate's name is Priya Nair. That's her room across the hall. She's out on the stairs. Says Tessa texts when she leaves work, every night, and tonight she didn't.",
			"Crime scene's ten minutes out and they'll seal the room. We get four good looks, not six. Pick the ones that tell us where she was tonight.",
		][(_talks - 1) % 2]
	return [
		"You took her complaint three weeks ago. Whatever's in here, you'll know faster than I will what's new and what isn't.",
		"Don't touch more than you have to. If this turns into a case, some defense lawyer is going to walk a jury through this room.",
		"%d left. I'd want to know who had eyes on this place, and who knew her schedule." % left,
	][(_talks - 1) % 3]

func _people() -> void:
	if stage == "hall":
		actor("REYES", "louise", Vector3(0.9, 0, 3.7), 1.2)
		actor("PRIYA", "megan", Vector3(2.52, -0.08, 3.9), -PI / 2, "sit_idle", "sit_talk")
	else:
		# Det. Sam Reyes, your partner, waiting just inside the door; Priya on the stairs in the hall.
		solid_person(actor("REYES", "louise", Vector3(1.5, 0, 1.2), -2.2), "REYES")
		solid_person(actor("PRIYA", "megan", Vector3(2.52, -0.08, 3.9), -PI / 2, "sit_idle", "sit_talk"), "PRIYA", 1.3)

func _photo(pos: Vector3, hdri: String, crop: Vector3, tilt := 0.0) -> void:
	# An instant-film snapshot: white card with a cropped piece of a real photograph.
	var card := box(pos, Vector3(0.13, 0.155, 0.004), Color(0.93, 0.92, 0.88), false)
	card.rotation.z = tilt
	var pic := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.11, 0.105)
	pic.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/hdri/%s.hdr" % hdri)
	m.albedo_color = Color(0.9, 0.9, 0.9)
	m.uv1_scale = Vector3(0.16, 0.2, 1)
	m.uv1_offset = crop
	m.roughness = 0.4
	pic.material_override = m
	pic.position = Vector3(0, 0.014, 0.003)
	card.add_child(pic)

func _room() -> void:
	var plaster := tex("beige_wall_001", 0.5, Color(0.62, 0.60, 0.70))
	var brick := tex("brick_wall_001", 0.5, Color(0.75, 0.68, 0.68))
	var boards := tex("old_wooden_floor_01", 0.5, Color(0.80, 0.72, 0.66))
	box(Vector3(0, -0.05, 0), Vector3(8, 0.1, 6), Color.WHITE).material_override = boards       # floor
	box(Vector3(0, 2.85, 0), Vector3(8, 0.1, 6), Color(0.30, 0.29, 0.33))                        # ceiling
	box(Vector3(0, 1.4, -3.05), Vector3(8, 2.8, 0.1), Color.WHITE).material_override = brick    # north, bare brick
	for w in [
		[Vector3(-4.05, 1.4, 0), Vector3(0.1, 2.8, 6)],          # west
		[Vector3(-2.25, 1.4, 3.05), Vector3(3.5, 2.8, 0.1)],     # south, left of door
		[Vector3(2.25, 1.4, 3.05), Vector3(3.5, 2.8, 0.1)],      # south, right of door
		[Vector3(0, 2.45, 3.05), Vector3(1.0, 0.7, 0.1)],        # above door
		# east wall with a window opening (z 0..1.6, y 0.9..2.2)
		[Vector3(4.05, 1.4, -1.5), Vector3(0.1, 2.8, 3.0)],
		[Vector3(4.05, 1.4, 2.3), Vector3(0.1, 2.8, 1.4)],
		[Vector3(4.05, 0.45, 0.8), Vector3(0.1, 0.9, 1.6)],
		[Vector3(4.05, 2.5, 0.8), Vector3(0.1, 0.6, 1.6)],
	]:
		box(w[0], w[1], Color.WHITE).material_override = plaster
	box(Vector3(-0.35, 1.05, 3.4), Vector3(0.9, 2.1, 0.06), Color(0.30, 0.22, 0.16), false, 0.0, 1.0)  # door, ajar
	# the apartment's hall beyond the bedroom door: Priya's room opposite, stairs down to the street at the east end
	for h in [
		[Vector3(0, 1.4, 4.85), Vector3(6.2, 2.8, 0.1)],
		[Vector3(-3.1, 1.4, 3.95), Vector3(0.1, 2.8, 1.9)],
		[Vector3(3.1, 1.4, 3.95), Vector3(0.1, 2.8, 1.9)],
		[Vector3(0, 2.85, 3.95), Vector3(6.2, 0.1, 1.9)],
	]:
		box(h[0], h[1], Color.WHITE).material_override = plaster
	box(Vector3(0, -0.05, 3.95), Vector3(6.2, 0.1, 1.9), Color.WHITE).material_override = tex("concrete_floor_worn_001", 0.5)
	for i in 3:                                                                                    # stairs
		box(Vector3(2.3 + i * 0.3, 0.1 + i * 0.1, 3.95), Vector3(0.3, 0.2 + i * 0.2, 1.7), Color(0.20, 0.19, 0.20))
	# Priya's bedroom door, shut, across the hall
	box(Vector3(0.15, 1.05, 4.79), Vector3(0.9, 2.1, 0.04), Color(0.30, 0.22, 0.16), false)
	box(Vector3(0.5, 1.0, 4.76), Vector3(0.04, 0.04, 0.06), Color(0.65, 0.6, 0.45), false)
	# the hall is lived in: coats, shoes by the door, yesterday's mail, a runner that has seen better years
	box(Vector3(-1.6, 1.7, 4.76), Vector3(1.2, 0.08, 0.04), Color(0.3, 0.22, 0.16), false)
	for i in 3:
		box(Vector3(-2.0 + i * 0.4, 1.25, 4.7), Vector3(0.34, 0.85, 0.12), [Color(0.2, 0.3, 0.25), Color(0.5, 0.2, 0.2), Color(0.15, 0.15, 0.2)][i], false, 0.0, (i - 1) * 0.1)
	for i in 4:
		box(Vector3(-2.2 + i * 0.28, 0.05, 4.6 - (i % 2) * 0.05), Vector3(0.1, 0.09, 0.27), [Color(0.9, 0.9, 0.88), Color(0.9, 0.9, 0.88), Color(0.2, 0.15, 0.1), Color(0.2, 0.15, 0.1)][i], false, 0.0, (i % 2) * 0.3 - 0.1)
	box(Vector3(1.4, 0.4, 4.7), Vector3(0.7, 0.8, 0.25), Color(0.32, 0.24, 0.18))
	box(Vector3(1.3, 0.81, 4.7), Vector3(0.24, 0.012, 0.16), Color(0.92, 0.9, 0.85), false, 0.0, 0.3)
	box(Vector3(1.55, 0.815, 4.68), Vector3(0.22, 0.01, 0.11), Color(0.85, 0.8, 0.65), false, 0.0, -0.2)
	cyl(Vector3(1.62, 0.84, 4.75), 0.05, 0.07, Color(0.3, 0.45, 0.5), 0.4)
	box(Vector3(-0.4, 0.006, 3.95), Vector3(4.2, 0.012, 0.9), Color.WHITE, false).material_override = tex("dirty_carpet", 0.7, Color(0.45, 0.5, 0.6))
	box(Vector3(1.4, 1.6, 4.79), Vector3(0.5, 0.65, 0.02), Color(0.2, 0.2, 0.22), false)
	box(Vector3(1.4, 1.6, 4.778), Vector3(0.42, 0.57, 0.01), Color.WHITE, false).material_override = mat(Color(0.3, 0.33, 0.36), 0.0, 0.1)
	cyl(Vector3(0.3, 2.74, 3.95), 0.14, 0.08, Color(0.95, 0.9, 0.8), 0.4)
	box(Vector3(0, 0.05, -2.98), Vector3(8, 0.1, 0.03), Color(0.16, 0.14, 0.15), false)          # skirting
	box(Vector3(-3.98, 0.05, 0), Vector3(0.03, 0.1, 6), Color(0.16, 0.14, 0.15), false)
	for i in 9:                                                                                    # blinds
		box(Vector3(4.0, 0.98 + i * 0.145, 0.8), Vector3(0.03, 0.075, 1.6), Color(0.78, 0.76, 0.70), false)
	box(Vector3(0, 0.006, 0.4), Vector3(2.6, 0.012, 1.8), Color.WHITE, false).material_override = tex("dirty_carpet", 0.7, Color(0.75, 0.42, 0.38))  # rug
	# fire escape outside the window
	var iron := Color(0.07, 0.07, 0.08)
	box(Vector3(4.6, 0.82, 0.8), Vector3(1.0, 0.04, 2.4), iron, false)
	box(Vector3(5.08, 1.75, 0.8), Vector3(0.04, 0.04, 2.4), iron, false)
	for i in 9:
		box(Vector3(5.08, 1.3, -0.4 + i * 0.3), Vector3(0.025, 0.9, 0.025), iron, false)
	model("potted_plant_02", Vector3(4.75, 0.94, 0.2), 0.6, 0.8)

func _furniture() -> void:
	# desk: two school desks pushed together, chair pulled out
	model("SchoolDesk_01", Vector3(-2.61, 0, -2.68), 0.0, 0.85, Vector3(0.62, 0.75, 0.48))
	model("SchoolDesk_01", Vector3(-1.99, 0, -2.68), 0.0, 0.85, Vector3(0.62, 0.75, 0.48))
	model("SchoolChair_01", Vector3(-2.2, 0, -1.9), 2.75, 0.9, Vector3(0.5, 0.5, 0.5))
	model("desk_lamp_arm_01", Vector3(-2.75, 0.75, -2.72), 1.2)
	# tablet
	box(Vector3(-2.1, 0.76, -2.6), Vector3(0.28, 0.015, 0.2), Color(0.55, 0.75, 1.0), false, 2.0, 0.2)
	# wastebasket
	box(Vector3(-0.9, 0.2, -2.6), Vector3(0.3, 0.4, 0.3), Color(0.22, 0.24, 0.27))
	# bed against the brick wall, laptop left open on it
	# single bed along the brick wall, unmade, head toward the window wall
	var linen := mat(Color(0.40, 0.46, 0.60), 0.0, 1.0)
	box(Vector3(2.7, 0.16, -2.45), Vector3(2.05, 0.32, 1.0), Color(0.24, 0.17, 0.12))                       # frame
	box(Vector3(3.76, 0.5, -2.45), Vector3(0.06, 1.0, 1.0), Color(0.24, 0.17, 0.12), false)                 # headboard
	box(Vector3(2.7, 0.41, -2.45), Vector3(1.96, 0.18, 0.94), Color(0.80, 0.79, 0.76), false)               # mattress
	box(Vector3(2.35, 0.515, -2.43), Vector3(1.35, 0.05, 1.0), Color.WHITE, false, 0.0, 0.03).material_override = linen   # duvet
	box(Vector3(3.0, 0.545, -2.38), Vector3(0.28, 0.07, 0.98), Color.WHITE, false, 0.0, -0.06).material_override = linen  # folded back
	var pillow := MeshInstance3D.new()
	pillow.mesh = SphereMesh.new()
	pillow.scale = Vector3(0.42, 0.13, 0.62)
	pillow.position = Vector3(3.42, 0.56, -2.45)
	pillow.material_override = mat(Color(0.84, 0.83, 0.80))
	add_child(pillow)
	model("classic_laptop", Vector3(2.3, 0.54, -2.4), 0.35, 0.8)
	model("side_table_01", Vector3(1.35, 0, -2.72), 0.0, 1.0, Vector3(0.56, 0.55, 0.46))
	# bookshelf on the west wall
	var shelf := model("Shelf_01", Vector3(-3.98, 0, 0.2), PI / 2, 1.0, Vector3(1.0, 2.08, 0.3), 0.13)
	for y in [0.38, 0.94, 1.51]:
		var books: Node3D = (load("res://assets/models/book_encyclopedia_set_01/book_encyclopedia_set_01_1k.gltf") as PackedScene).instantiate()
		books.position = Vector3(-0.42 if y != 0.94 else -0.1, y + 0.01, 0.1)
		shelf.add_child(books)
	# coffee can of dried flowers on the shelf at 0.66, sitting on the stack of index cards
	box(Vector3(-3.82, 0.668, 0.5), Vector3(0.13, 0.012, 0.08), Color(0.90, 0.88, 0.80), false, 0.0, 0.25)
	cyl(Vector3(-3.82, 0.734, 0.5), 0.045, 0.12, Color(0.55, 0.20, 0.16), 0.5)
	cyl(Vector3(-3.82, 0.796, 0.5), 0.047, 0.006, Color(0.62, 0.63, 0.65), 0.35)
	for f in [[-0.02, 0.0, 0.10, 0.2], [0.015, 0.02, 0.085, -0.25], [0.0, -0.025, 0.07, 0.1], [0.02, -0.01, 0.105, -0.1]]:
		var stem := cyl(Vector3(-3.82 + f[0], 0.79 + f[2] / 2.0, 0.5 + f[1]), 0.003, f[2], Color(0.42, 0.36, 0.22))
		stem.rotation.z = f[3]
		var head := MeshInstance3D.new()
		var hm := SphereMesh.new()
		hm.radius = 0.014
		hm.height = 0.024
		head.mesh = hm
		head.material_override = mat(Color(0.55, 0.38, 0.30), 0.0, 1.0)
		head.position = Vector3(-3.82 + f[0] - sin(f[3]) * f[2] * 0.5, 0.79 + f[2], 0.5 + f[1])
		add_child(head)
	# seating and the ceiling light
	model("modern_arm_chair_01", Vector3(3.3, 0, -0.75), -1.9, 1.0, Vector3(0.8, 0.6, 0.9), -0.08)
	model("sofa_02", Vector3(2.5, 0, 2.5), PI, 1.0, Vector3(1.8, 0.5, 0.85), -0.1)
	# chest of drawers on the west wall, with a framed picture above it
	model("drawer_cabinet", Vector3(-3.78, 0, -1.3), PI / 2, 0.7, Vector3(0.8, 1.32, 0.36))
	model("hanging_picture_frame_01", Vector3(-3.99, 1.95, -1.3), PI / 2, 0.8)
	clear_glass(model("alarm_clock_01", Vector3(1.3, 0.55, -2.68), 0.25, 1.1))
	model("wall_clock", Vector3(2.5, 2.05, 2.99), PI)
	model("wicker_basket_02", Vector3(-0.75, 0, 1.95), 0.4, 1.7)
	model("rubber_boots", Vector3(1.05, 0, 2.78), 2.9, 0.75)
	model("potted_plant_01", Vector3(3.68, 0, 2.6), 1.0, 0.9)
	_closet()
	var lamp := model("modern_ceiling_lamp_01", Vector3(0, 2.1, 0.3), 0.0, 0.6)
	for m in lamp.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # or it would shade its own bulb
	var bulb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.035
	bm.height = 0.07
	bulb.mesh = bm
	bulb.material_override = mat(Color(1.0, 0.86, 0.62), 4.0)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bulb.position = Vector3(0, 2.3, 0.3)
	add_child(bulb)
	# corkboard
	box(Vector3(0.2, 1.55, -2.97), Vector3(1.3, 0.85, 0.04), Color(0.50, 0.35, 0.22), false)
	var ink := Color(0.10, 0.10, 0.12)
	# class schedule
	box(Vector3(-0.2, 1.62, -2.945), Vector3(0.34, 0.46, 0.004), Color(0.92, 0.9, 0.86), false)
	note("HOLLIS UNIVERSITY\nFALL SCHEDULE\nT. BRANDT", Vector3(-0.2, 1.79, -2.942), 17, ink)
	note("MON WED   9:00   PSYC 210\nMON WED  13:00   STAT 201\nTUE THU  10:30   ENGL 245\nFRI      11:00   BIOL 110 LAB\n\nTUE THU  17:00   WORK", Vector3(-0.2, 1.62, -2.942), 16, ink)
	note("advisor mtg Oct 20!!", Vector3(-0.2, 1.44, -2.942), 16, Color(0.75, 0.12, 0.12), 0.06)
	# work calendar
	box(Vector3(0.3, 1.74, -2.945), Vector3(0.44, 0.3, 0.004), Color(0.86, 0.80, 0.62), false)
	note("LIBRARY — CIRCULATION DESK\nOCTOBER SHIFTS", Vector3(0.3, 1.845, -2.942), 18, ink)
	note("THU  9   CLOSE  5–9\nTUE 14   CLOSE  5–9\nTHU 16   CLOSE  5–9\nTUE 21   CLOSE  5–9", Vector3(0.3, 1.72, -2.942), 18, ink)
	note("swap w/ Dana?", Vector3(0.38, 1.635, -2.942), 16, Color(0.75, 0.12, 0.12), 0.05)
	# sticky note
	box(Vector3(0.66, 1.36, -2.945), Vector3(0.17, 0.17, 0.004), Color(0.96, 0.9, 0.4), false, 0.0)
	note("ask Campus\nSafety AGAIN\nabout my\nreport", Vector3(0.66, 1.36, -2.942), 20, Color(0.1, 0.15, 0.45), -0.05)
	# campus safety card
	box(Vector3(0.28, 1.38, -2.945), Vector3(0.3, 0.16, 0.004), Color(0.80, 0.86, 0.90), false, 0.0)
	note("HOLLIS CAMPUS SAFETY\nNight escort: 555-0142\nReport no. CS-2291  (Sept 22)", Vector3(0.28, 1.38, -2.942), 15, ink)
	# two snapshots
	_photo(Vector3(0.68, 1.77, -2.945), "cobblestone_street_night_2k", Vector3(0.18, 0.35, 0), 0.07)
	_photo(Vector3(-0.31, 1.27, -2.945), "hansaplatz_2k", Vector3(0.55, 0.38, 0), -0.05)
	for pin in [Vector3(-0.2, 1.84, 0), Vector3(0.3, 1.875, 0), Vector3(0.66, 1.43, 0), Vector3(0.28, 1.45, 0), Vector3(0.68, 1.85, 0), Vector3(-0.31, 1.35, 0)]:
		var pm := MeshInstance3D.new()
		var ps := SphereMesh.new()
		ps.radius = 0.008
		ps.height = 0.016
		pm.mesh = ps
		pm.material_override = mat(Color(0.7, 0.1, 0.1), 0.0, 0.3)
		pm.position = Vector3(pin.x, pin.y, -2.936)
		add_child(pm)

func _closet() -> void:
	# built-in closet on the door wall, left of the door: one sliding door shut, the other pushed back
	var white := Color(0.62, 0.60, 0.57)
	var x0 := -3.95
	var x1 := -0.9
	box(Vector3((x0 + x1) / 2.0, 2.5, 2.7), Vector3(x1 - x0, 0.6, 0.6), white, false)        # soffit
	box(Vector3(x1 + 0.04, 1.1, 2.7), Vector3(0.08, 2.2, 0.6), white, false)                 # end panel
	box(Vector3(-3.2, 1.1, 2.42), Vector3(1.5, 2.2, 0.035), white, false)                    # shut door
	box(Vector3(-2.45, 1.1, 2.47), Vector3(1.5, 2.2, 0.035), white, false)                   # open door, slid across
	for x in [-3.93, -2.47, -3.18, -1.72]:                                                    # door edges
		box(Vector3(x, 1.1, 2.40 if x < -3.0 or x == -2.47 else 2.45), Vector3(0.03, 2.2, 0.02), Color(0.2, 0.2, 0.2), false)
	box(Vector3(-1.3, 1.1, 2.97), Vector3(0.82, 2.2, 0.02), Color(0.05, 0.05, 0.06), false)  # dark interior
	box(Vector3(-1.3, 1.85, 2.72), Vector3(0.8, 0.025, 0.025), Color(0.5, 0.5, 0.52), false) # rail
	box(Vector3(-1.3, 2.0, 2.72), Vector3(0.8, 0.03, 0.5), white, false)                     # shelf
	box(Vector3(-1.42, 2.1, 2.75), Vector3(0.4, 0.18, 0.3), Color(0.42, 0.33, 0.24), false)  # storage box
	var cloth := [Color(0.16, 0.20, 0.30), Color(0.45, 0.14, 0.15), Color(0.55, 0.53, 0.48), Color(0.12, 0.12, 0.13),
		Color(0.25, 0.33, 0.27), Color(0.50, 0.40, 0.22), Color(0.30, 0.30, 0.36)]
	for i in 7:                                                                               # hanging clothes
		var h := 0.75 + (i * 37 % 5) * 0.09
		box(Vector3(-1.64 + i * 0.105, 1.83 - h / 2.0, 2.72), Vector3(0.06, h, 0.42), cloth[i], false, 0.0, (i % 3 - 1) * 0.12).material_override = mat(cloth[i], 0.0, 1.0)
	box(Vector3(-1.2, 0.09, 2.72), Vector3(0.3, 0.18, 0.34), Color(0.36, 0.28, 0.2), false, 0.0, 0.2)   # shoe box
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(x1 - x0 + 0.1, 2.8, 0.62)
	cs.shape = shape
	body.add_child(cs)
	body.position = Vector3((x0 + x1) / 2.0, 1.4, 2.7)
	add_child(body)

func _lights() -> void:
	omni(Vector3(-2.6, 1.15, -2.45), Color(1.0, 0.72, 0.38), 1.6, 4.5, true)   # desk lamp
	omni(Vector3(-2.1, 0.95, -2.5), Color(0.55, 0.75, 1.0), 0.25, 1.2)         # tablet glow
	omni(Vector3(2.3, 0.9, -2.2), Color(0.6, 0.78, 1.0), 0.5, 2.2)            # laptop glow
	omni(Vector3(0.3, 2.3, 3.9), Color(1.0, 0.9, 0.72), 1.6, 6.0, true)        # hallway, through the door
	omni(Vector3(2.6, 2.0, 0.6), Color(0.50, 0.58, 0.9), 1.0, 6.0)            # cool fill, window side
	omni(Vector3(-1.6, 2.1, 1.9), Color(1.0, 0.85, 0.68), 0.55, 5.5)          # hallway spill on the door wall
	omni(Vector3(2.4, 2.1, 2.0), Color(0.75, 0.75, 0.85), 0.45, 4.5)          # lifts the corner by the sofa
	omni(Vector3(0, 2.14, 0.3), Color(1.0, 0.84, 0.62), 1.1, 7.5, true)       # the ceiling light, on
	# streetlight through the blinds
	var s := SpotLight3D.new()
	s.position = Vector3(6.4, 3.0, 1.1)
	s.light_color = Color(0.62, 0.74, 1.0)
	s.light_energy = 6.0
	s.spot_range = 14.0
	s.spot_angle = 28.0
	s.shadow_enabled = true
	s.light_volumetric_fog_energy = 2.5
	add_child(s)
	s.look_at(Vector3(0.0, 0.2, 0.3))

