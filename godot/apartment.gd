extends Node3D
## Chapter 1 prototype: walk around Tessa Brandt's apartment and examine four of six things.
## The room shell is built in code; furniture, surfaces and sky are Poly Haven assets (see assets/MANIFEST.md).
## Run with `-- --shot <file.png>` to save one frame and quit (used for checking the look).

const AMBER := Color(0.95, 0.71, 0.27)
const BUDGET := 4
var FONT: Font = load("res://assets/fonts/SpecialElite-Regular.ttf")

const CLUES := [
	{"name": "Tablet", "pts": 5, "pos": Vector3(-2.1, 0.8, -2.6), "size": Vector3(0.5, 0.3, 0.5),
		"text": "Her tablet, showing her text messages. 73 unread, all from the unknown number in her complaint. It was a few dozen when she came to you. The most recent, 8:51 PM: \"You looked tired today. I can help with that.\""},
	{"name": "Bookshelf", "pts": 5, "pos": Vector3(-3.8, 0.85, 0.4), "size": Vector3(0.5, 0.5, 0.9),
		"text": "A coffee can of dried flowers. Under it, a stack of index cards in careful block capitals. \"I SAW YOU ON THE THIRD FLOOR.\" \"SIT BY THE WINDOW AGAIN.\" She kept every one, the way you keep things you might need as proof."},
	{"name": "Laptop", "pts": 5, "pos": Vector3(2.3, 0.74, -2.4), "size": Vector3(0.6, 0.45, 0.5),
		"text": "Open to a rideshare receipt. She ordered a ride home at 9:14 PM from the Hollis University Library service entrance. The ride was cancelled at 9:16, two minutes later. She never got home."},
	{"name": "Window", "pts": 5, "pos": Vector3(3.8, 1.4, 0.8), "size": Vector3(0.4, 1.4, 1.8),
		"text": "The fire-escape window. The latch is intact. Outside, behind a dead plant on the fire escape, two cut zip ties hang from the railing around a clean patch in the rust. Something small was strapped there, aimed at her window."},
	{"name": "Corkboard", "pts": 5, "pos": Vector3(0.2, 1.55, -2.9), "size": Vector3(1.5, 1.0, 0.3),
		"text": "Her class schedule and her work calendar. She works the closing shift at the library circulation desk on Tuesdays and Thursdays. Tonight is Tuesday. A sticky note: \"ask Campus Safety AGAIN about my report.\""},
	{"name": "Wastebasket", "pts": 5, "pos": Vector3(-0.9, 0.25, -2.5), "size": Vector3(0.5, 0.6, 0.5),
		"text": "A photo-booth strip, torn in half. Tessa's half is here; whoever sat beside her has been ripped away. On the back, in pen: \"E + T\", with the E scratched out hard enough to tear the paper."},
]

var player: CharacterBody3D
var ray: RayCast3D
var left := BUDGET
var strength := 0
var looking: StaticBody3D = null
var talks := 0
var ui_prompt: Label
var ui_info: Label
var ui_panel: PanelContainer
var ui_status: Label

func _ready() -> void:
	_environment()
	_room()
	_furniture()
	_lights()
	_clues()
	_people()
	_player()
	_ui()
	_say("You are Detective Nadia Okonkwo. This is Tessa Brandt's bedroom, in the apartment she shares with Priya Nair. Six things in this room are worth your attention, and you have time to examine four before the crime scene unit seals it.\n\nClick to look around. WASD to walk. Look at a glowing marker and press E. You can also talk to your partner.")
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--shot":
		if args.size() >= 6:
			player.position = Vector3(float(args[2]), 0.0, float(args[3]))
			player.rotation.y = deg_to_rad(float(args[4]))
			player.cam.rotation.x = deg_to_rad(float(args[5]))
		_screenshot(args[1])

# ── building blocks ──────────────────────────────────────────────

func _mat(color: Color, emission := 0.0, rough := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func _box(pos: Vector3, size: Vector3, color: Color, solid := true, emission := 0.0, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color, emission)
	mi.position = pos
	mi.rotation.y = rot_y
	if emission > 0.0:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		mi.add_child(body)
	return mi

func _omni(pos: Vector3, color: Color, energy: float, rng: float, shadows := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = shadows
	add_child(l)
	return l

# ── scene ────────────────────────────────────────────────────────

func _tex(id: String, diff := "diff", scale := 0.5, tint := Color.WHITE) -> StandardMaterial3D:
	# A Poly Haven surface, mapped in world space so it tiles the same on every box.
	var base := "res://assets/textures/%s/%s_" % [id, id]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base + diff + "_1k.jpg")
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = load(base + "nor_gl_1k.jpg")
	m.roughness_texture = load(base + "rough_1k.jpg")
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	return m

func _model(id: String, pos: Vector3, rot_y := 0.0, scale := 1.0, solid := Vector3.ZERO, off_z := 0.0) -> Node3D:
	# A Poly Haven model. Its front faces +Z and its origin is on the floor.
	var n: Node3D = (load("res://assets/models/%s/%s_1k.gltf" % [id, id]) as PackedScene).instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * scale
	add_child(n)
	if solid != Vector3.ZERO:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = solid
		cs.shape = shape
		cs.position = Vector3(0, solid.y / 2.0, off_z)   # models are not centred on their origin
		body.add_child(cs)
		body.position = pos
		body.rotation.y = rot_y
		add_child(body)
	return n

func _person(who: String, anim: String, pos: Vector3, rot_y := 0.0) -> Node3D:
	# A Mixamo character playing one looping Mixamo animation. Each character's bones carry
	# their own prefix (mixamorig_, mixamorig9_, ...), so the animation's tracks are renamed to match.
	var n: Node3D = (load("res://assets/mixamo/characters/%s.fbx" % who) as PackedScene).instantiate()
	n.position = pos
	n.rotation.y = rot_y
	add_child(n)
	var skel: Skeleton3D = n.find_child("Skeleton3D", true, false)
	var prefix := ""
	for i in skel.get_bone_count():
		if skel.get_bone_name(i).ends_with("Hips"):
			prefix = skel.get_bone_name(i).trim_suffix("Hips")
	var src: Node = (load("res://assets/mixamo/animations/%s.fbx" % anim) as PackedScene).instantiate()
	var a: Animation = (src.find_child("AnimationPlayer", true, false) as AnimationPlayer).get_animation("mixamo_com").duplicate()
	src.free()
	for t in a.get_track_count():
		var path := str(a.track_get_path(t))
		var bone := path.get_slice(":", 1)
		a.track_set_path(t, NodePath("Skeleton3D:" + prefix + bone.substr(bone.find("_") + 1)))
	a.loop_mode = Animation.LOOP_LINEAR
	var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
	var lib := AnimationLibrary.new()
	lib.add_animation(anim, a)
	ap.add_animation_library("mx", lib)
	ap.play("mx/" + anim)
	return n

func _cyl(pos: Vector3, radius: float, height: float, color: Color, rough := 0.85) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = _mat(color, 0.0, rough)
	mi.position = pos
	add_child(mi)
	return mi

func _note(text: String, pos: Vector3, size: int, color: Color, tilt := 0.0) -> Label3D:
	# Writing on a sheet of paper: faces +Z, lit by the room like the paper under it.
	var l := Label3D.new()
	l.text = text
	l.font = FONT
	l.font_size = size * 4
	l.pixel_size = 0.00032
	l.modulate = color
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	l.line_spacing = -6.0
	l.position = pos
	l.rotation.z = tilt
	add_child(l)
	return l

func _photo(pos: Vector3, hdri: String, crop: Vector3, tilt := 0.0) -> void:
	# An instant-film snapshot: white card with a cropped piece of a real photograph.
	var card := _box(pos, Vector3(0.13, 0.155, 0.004), Color(0.93, 0.92, 0.88), false)
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

func _clear_glass(n: Node3D) -> void:
	# Poly Haven glass arrives as an opaque dark shell; make it see-through.
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i)
			if mat and mat.resource_name.to_lower().contains("glass"):
				var g := StandardMaterial3D.new()
				g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				g.albedo_color = Color(1, 1, 1, 0.06)
				g.roughness = 0.05
				(mi as MeshInstance3D).set_surface_override_material(i, g)

func _environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var pm := PanoramaSkyMaterial.new()
	pm.panorama = load("res://assets/hdri/cobblestone_street_night_2k.hdr")
	pm.energy_multiplier = 0.7
	sky.sky_material = pm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.27, 0.29, 0.38)
	env.ambient_light_energy = 1.15
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	env.ssao_enabled = true
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(0.75, 0.8, 0.95)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _room() -> void:
	var plaster := _tex("beige_wall_001", "diff", 0.5, Color(0.62, 0.60, 0.70))
	var brick := _tex("brick_wall_001", "diffuse", 0.5, Color(0.75, 0.68, 0.68))
	var boards := _tex("old_wooden_floor_01", "diff", 0.5, Color(0.80, 0.72, 0.66))
	_box(Vector3(0, -0.05, 0), Vector3(8, 0.1, 6), Color.WHITE).material_override = boards       # floor
	_box(Vector3(0, 2.85, 0), Vector3(8, 0.1, 6), Color(0.30, 0.29, 0.33))                        # ceiling
	_box(Vector3(0, 1.4, -3.05), Vector3(8, 2.8, 0.1), Color.WHITE).material_override = brick    # north, bare brick
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
		_box(w[0], w[1], Color.WHITE).material_override = plaster
	_box(Vector3(-0.35, 1.05, 3.4), Vector3(0.9, 2.1, 0.06), Color(0.30, 0.22, 0.16), false, 0.0, 1.0)  # door, ajar
	# the apartment's hall beyond the bedroom door: Priya's room opposite, stairs down to the street at the east end
	for h in [
		[Vector3(0, 1.4, 4.85), Vector3(6.2, 2.8, 0.1)],
		[Vector3(-3.1, 1.4, 3.95), Vector3(0.1, 2.8, 1.9)],
		[Vector3(3.1, 1.4, 3.95), Vector3(0.1, 2.8, 1.9)],
		[Vector3(0, 2.85, 3.95), Vector3(6.2, 0.1, 1.9)],
	]:
		_box(h[0], h[1], Color.WHITE).material_override = plaster
	_box(Vector3(0, -0.05, 3.95), Vector3(6.2, 0.1, 1.9), Color.WHITE).material_override = _tex("concrete_floor_worn_001", "diff", 0.5)
	for i in 3:                                                                                    # stairs
		_box(Vector3(2.3 + i * 0.3, 0.1 + i * 0.1, 3.95), Vector3(0.3, 0.2 + i * 0.2, 1.7), Color(0.20, 0.19, 0.20))
	# Priya's bedroom door, shut, across the hall
	_box(Vector3(0.15, 1.05, 4.79), Vector3(0.9, 2.1, 0.04), Color(0.30, 0.22, 0.16), false)
	_box(Vector3(0.5, 1.0, 4.76), Vector3(0.04, 0.04, 0.06), Color(0.65, 0.6, 0.45), false)
	_box(Vector3(0, 0.05, -2.98), Vector3(8, 0.1, 0.03), Color(0.16, 0.14, 0.15), false)          # skirting
	_box(Vector3(-3.98, 0.05, 0), Vector3(0.03, 0.1, 6), Color(0.16, 0.14, 0.15), false)
	for i in 9:                                                                                    # blinds
		_box(Vector3(4.0, 0.98 + i * 0.145, 0.8), Vector3(0.03, 0.075, 1.6), Color(0.78, 0.76, 0.70), false)
	_box(Vector3(0, 0.006, 0.4), Vector3(2.6, 0.012, 1.8), Color.WHITE, false).material_override = _tex("dirty_carpet", "diff", 0.7, Color(0.75, 0.42, 0.38))  # rug
	# fire escape outside the window
	var iron := Color(0.07, 0.07, 0.08)
	_box(Vector3(4.6, 0.82, 0.8), Vector3(1.0, 0.04, 2.4), iron, false)
	_box(Vector3(5.08, 1.75, 0.8), Vector3(0.04, 0.04, 2.4), iron, false)
	for i in 9:
		_box(Vector3(5.08, 1.3, -0.4 + i * 0.3), Vector3(0.025, 0.9, 0.025), iron, false)
	_model("potted_plant_02", Vector3(4.75, 0.94, 0.2), 0.6, 0.8)

func _furniture() -> void:
	# desk: two school desks pushed together, chair pulled out
	_model("SchoolDesk_01", Vector3(-2.61, 0, -2.68), 0.0, 0.85, Vector3(0.62, 0.75, 0.48))
	_model("SchoolDesk_01", Vector3(-1.99, 0, -2.68), 0.0, 0.85, Vector3(0.62, 0.75, 0.48))
	_model("SchoolChair_01", Vector3(-2.2, 0, -1.9), 2.75, 0.9, Vector3(0.5, 0.5, 0.5))
	_model("desk_lamp_arm_01", Vector3(-2.75, 0.75, -2.72), 1.2)
	# tablet
	_box(Vector3(-2.1, 0.76, -2.6), Vector3(0.28, 0.015, 0.2), Color(0.55, 0.75, 1.0), false, 2.0, 0.2)
	# wastebasket
	_box(Vector3(-0.9, 0.2, -2.6), Vector3(0.3, 0.4, 0.3), Color(0.22, 0.24, 0.27))
	# bed against the brick wall, laptop left open on it
	# single bed along the brick wall, unmade, head toward the window wall
	var linen := _mat(Color(0.40, 0.46, 0.60), 0.0, 1.0)
	_box(Vector3(2.7, 0.16, -2.45), Vector3(2.05, 0.32, 1.0), Color(0.24, 0.17, 0.12))                       # frame
	_box(Vector3(3.76, 0.5, -2.45), Vector3(0.06, 1.0, 1.0), Color(0.24, 0.17, 0.12), false)                 # headboard
	_box(Vector3(2.7, 0.41, -2.45), Vector3(1.96, 0.18, 0.94), Color(0.80, 0.79, 0.76), false)               # mattress
	_box(Vector3(2.35, 0.515, -2.43), Vector3(1.35, 0.05, 1.0), Color.WHITE, false, 0.0, 0.03).material_override = linen   # duvet
	_box(Vector3(3.0, 0.545, -2.38), Vector3(0.28, 0.07, 0.98), Color.WHITE, false, 0.0, -0.06).material_override = linen  # folded back
	var pillow := MeshInstance3D.new()
	pillow.mesh = SphereMesh.new()
	pillow.scale = Vector3(0.42, 0.13, 0.62)
	pillow.position = Vector3(3.42, 0.56, -2.45)
	pillow.material_override = _mat(Color(0.84, 0.83, 0.80))
	add_child(pillow)
	_model("classic_laptop", Vector3(2.3, 0.54, -2.4), 0.35, 0.8)
	_model("side_table_01", Vector3(1.35, 0, -2.72), 0.0, 1.0, Vector3(0.56, 0.55, 0.46))
	# bookshelf on the west wall
	var shelf := _model("Shelf_01", Vector3(-3.98, 0, 0.2), PI / 2, 1.0, Vector3(1.0, 2.08, 0.3), 0.13)
	for y in [0.38, 0.94, 1.51]:
		var books: Node3D = (load("res://assets/models/book_encyclopedia_set_01/book_encyclopedia_set_01_1k.gltf") as PackedScene).instantiate()
		books.position = Vector3(-0.42 if y != 0.94 else -0.1, y + 0.01, 0.1)
		shelf.add_child(books)
	# coffee can of dried flowers on the shelf at 0.66, sitting on the stack of index cards
	_box(Vector3(-3.82, 0.668, 0.5), Vector3(0.13, 0.012, 0.08), Color(0.90, 0.88, 0.80), false, 0.0, 0.25)
	_cyl(Vector3(-3.82, 0.734, 0.5), 0.045, 0.12, Color(0.55, 0.20, 0.16), 0.5)
	_cyl(Vector3(-3.82, 0.796, 0.5), 0.047, 0.006, Color(0.62, 0.63, 0.65), 0.35)
	for f in [[-0.02, 0.0, 0.10, 0.2], [0.015, 0.02, 0.085, -0.25], [0.0, -0.025, 0.07, 0.1], [0.02, -0.01, 0.105, -0.1]]:
		var stem := _cyl(Vector3(-3.82 + f[0], 0.79 + f[2] / 2.0, 0.5 + f[1]), 0.003, f[2], Color(0.42, 0.36, 0.22))
		stem.rotation.z = f[3]
		var head := MeshInstance3D.new()
		var hm := SphereMesh.new()
		hm.radius = 0.014
		hm.height = 0.024
		head.mesh = hm
		head.material_override = _mat(Color(0.55, 0.38, 0.30), 0.0, 1.0)
		head.position = Vector3(-3.82 + f[0] - sin(f[3]) * f[2] * 0.5, 0.79 + f[2], 0.5 + f[1])
		add_child(head)
	# seating and the ceiling light
	_model("modern_arm_chair_01", Vector3(3.3, 0, -0.75), -1.9, 1.0, Vector3(0.8, 0.6, 0.9), -0.08)
	_model("sofa_02", Vector3(2.5, 0, 2.5), PI, 1.0, Vector3(1.8, 0.5, 0.85), -0.1)
	# chest of drawers on the west wall, with a framed picture above it
	_model("drawer_cabinet", Vector3(-3.78, 0, -1.3), PI / 2, 0.7, Vector3(0.8, 1.32, 0.36))
	_model("hanging_picture_frame_01", Vector3(-3.99, 1.95, -1.3), PI / 2, 0.8)
	_clear_glass(_model("alarm_clock_01", Vector3(1.3, 0.55, -2.68), 0.25, 1.1))
	_model("wall_clock", Vector3(2.5, 2.05, 2.99), PI)
	_model("wicker_basket_02", Vector3(-0.75, 0, 1.95), 0.4, 1.7)
	_model("rubber_boots", Vector3(1.05, 0, 2.78), 2.9, 0.75)
	_model("potted_plant_01", Vector3(3.68, 0, 2.6), 1.0, 0.9)
	_closet()
	var lamp := _model("modern_ceiling_lamp_01", Vector3(0, 2.1, 0.3), 0.0, 0.6)
	for m in lamp.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # or it would shade its own bulb
	var bulb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.035
	bm.height = 0.07
	bulb.mesh = bm
	bulb.material_override = _mat(Color(1.0, 0.86, 0.62), 4.0)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bulb.position = Vector3(0, 2.3, 0.3)
	add_child(bulb)
	# corkboard
	_box(Vector3(0.2, 1.55, -2.97), Vector3(1.3, 0.85, 0.04), Color(0.50, 0.35, 0.22), false)
	var ink := Color(0.10, 0.10, 0.12)
	# class schedule
	_box(Vector3(-0.2, 1.62, -2.945), Vector3(0.34, 0.46, 0.004), Color(0.92, 0.9, 0.86), false)
	_note("HOLLIS UNIVERSITY\nFALL SCHEDULE\nT. BRANDT", Vector3(-0.2, 1.79, -2.942), 17, ink)
	_note("MON WED   9:00   PSYC 210\nMON WED  13:00   STAT 201\nTUE THU  10:30   ENGL 245\nFRI      11:00   BIOL 110 LAB\n\nTUE THU  17:00   WORK", Vector3(-0.2, 1.62, -2.942), 16, ink)
	_note("advisor mtg Oct 20!!", Vector3(-0.2, 1.44, -2.942), 16, Color(0.75, 0.12, 0.12), 0.06)
	# work calendar
	_box(Vector3(0.3, 1.74, -2.945), Vector3(0.44, 0.3, 0.004), Color(0.86, 0.80, 0.62), false)
	_note("LIBRARY — CIRCULATION DESK\nOCTOBER SHIFTS", Vector3(0.3, 1.845, -2.942), 18, ink)
	_note("THU  9   CLOSE  5–9\nTUE 14   CLOSE  5–9\nTHU 16   CLOSE  5–9\nTUE 21   CLOSE  5–9", Vector3(0.3, 1.72, -2.942), 18, ink)
	_note("swap w/ Dana?", Vector3(0.38, 1.635, -2.942), 16, Color(0.75, 0.12, 0.12), 0.05)
	# sticky note
	_box(Vector3(0.66, 1.36, -2.945), Vector3(0.17, 0.17, 0.004), Color(0.96, 0.9, 0.4), false, 0.0)
	_note("ask Campus\nSafety AGAIN\nabout my\nreport", Vector3(0.66, 1.36, -2.942), 20, Color(0.1, 0.15, 0.45), -0.05)
	# campus safety card
	_box(Vector3(0.28, 1.38, -2.945), Vector3(0.3, 0.16, 0.004), Color(0.80, 0.86, 0.90), false, 0.0)
	_note("HOLLIS CAMPUS SAFETY\nNight escort: 555-0142\nReport no. CS-2291  (Sept 22)", Vector3(0.28, 1.38, -2.942), 15, ink)
	# two snapshots
	_photo(Vector3(0.68, 1.77, -2.945), "cobblestone_street_night_2k", Vector3(0.18, 0.35, 0), 0.07)
	_photo(Vector3(-0.31, 1.27, -2.945), "hansaplatz_2k", Vector3(0.55, 0.38, 0), -0.05)
	for pin in [Vector3(-0.2, 1.84, 0), Vector3(0.3, 1.875, 0), Vector3(0.66, 1.43, 0), Vector3(0.28, 1.45, 0), Vector3(0.68, 1.85, 0), Vector3(-0.31, 1.35, 0)]:
		var pm := MeshInstance3D.new()
		var ps := SphereMesh.new()
		ps.radius = 0.008
		ps.height = 0.016
		pm.mesh = ps
		pm.material_override = _mat(Color(0.7, 0.1, 0.1), 0.0, 0.3)
		pm.position = Vector3(pin.x, pin.y, -2.936)
		add_child(pm)

func _talkable(n: Node3D, who: String, height := 1.8) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 3          # blocks the player (1) and is seen by the look ray (2)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = height
	cs.shape = cap
	cs.position.y = height / 2.0
	body.add_child(cs)
	body.set_meta("talk", who)
	n.add_child(body)

func _people() -> void:
	if not ResourceLoader.exists("res://assets/mixamo/characters/leonard.fbx"):
		return
	# Det. Sam Reyes, your partner, waiting just inside the door.
	_talkable(_person("leonard", "idle", Vector3(1.5, 0, 1.2), -2.2), "Reyes")
	# Priya Nair, the roommate, sitting on the stairs in the hall.
	_talkable(_person("megan", "sit_idle", Vector3(2.52, -0.08, 3.9), -PI / 2), "Priya", 1.3)

func _closet() -> void:
	# built-in closet on the door wall, left of the door: one sliding door shut, the other pushed back
	var white := Color(0.62, 0.60, 0.57)
	var x0 := -3.95
	var x1 := -0.9
	_box(Vector3((x0 + x1) / 2.0, 2.5, 2.7), Vector3(x1 - x0, 0.6, 0.6), white, false)        # soffit
	_box(Vector3(x1 + 0.04, 1.1, 2.7), Vector3(0.08, 2.2, 0.6), white, false)                 # end panel
	_box(Vector3(-3.2, 1.1, 2.42), Vector3(1.5, 2.2, 0.035), white, false)                    # shut door
	_box(Vector3(-2.45, 1.1, 2.47), Vector3(1.5, 2.2, 0.035), white, false)                   # open door, slid across
	for x in [-3.93, -2.47, -3.18, -1.72]:                                                    # door edges
		_box(Vector3(x, 1.1, 2.40 if x < -3.0 or x == -2.47 else 2.45), Vector3(0.03, 2.2, 0.02), Color(0.2, 0.2, 0.2), false)
	_box(Vector3(-1.3, 1.1, 2.97), Vector3(0.82, 2.2, 0.02), Color(0.05, 0.05, 0.06), false)  # dark interior
	_box(Vector3(-1.3, 1.85, 2.72), Vector3(0.8, 0.025, 0.025), Color(0.5, 0.5, 0.52), false) # rail
	_box(Vector3(-1.3, 2.0, 2.72), Vector3(0.8, 0.03, 0.5), white, false)                     # shelf
	_box(Vector3(-1.42, 2.1, 2.75), Vector3(0.4, 0.18, 0.3), Color(0.42, 0.33, 0.24), false)  # storage box
	var cloth := [Color(0.16, 0.20, 0.30), Color(0.45, 0.14, 0.15), Color(0.55, 0.53, 0.48), Color(0.12, 0.12, 0.13),
		Color(0.25, 0.33, 0.27), Color(0.50, 0.40, 0.22), Color(0.30, 0.30, 0.36)]
	for i in 7:                                                                               # hanging clothes
		var h := 0.75 + (i * 37 % 5) * 0.09
		_box(Vector3(-1.64 + i * 0.105, 1.83 - h / 2.0, 2.72), Vector3(0.06, h, 0.42), cloth[i], false, 0.0, (i % 3 - 1) * 0.12).material_override = _mat(cloth[i], 0.0, 1.0)
	_box(Vector3(-1.2, 0.09, 2.72), Vector3(0.3, 0.18, 0.34), Color(0.36, 0.28, 0.2), false, 0.0, 0.2)   # shoe box
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(x1 - x0 + 0.1, 2.8, 0.62)
	cs.shape = shape
	body.add_child(cs)
	body.position = Vector3((x0 + x1) / 2.0, 1.4, 2.7)
	add_child(body)

func _lights() -> void:
	_omni(Vector3(-2.6, 1.15, -2.45), Color(1.0, 0.72, 0.38), 1.6, 4.5, true)   # desk lamp
	_omni(Vector3(-2.1, 0.95, -2.5), Color(0.55, 0.75, 1.0), 0.25, 1.2)         # tablet glow
	_omni(Vector3(2.3, 0.9, -2.2), Color(0.6, 0.78, 1.0), 0.5, 2.2)            # laptop glow
	_omni(Vector3(0.3, 2.3, 3.9), Color(1.0, 0.9, 0.72), 1.6, 6.0, true)        # hallway, through the door
	_omni(Vector3(2.6, 2.0, 0.6), Color(0.50, 0.58, 0.9), 1.0, 6.0)            # cool fill, window side
	_omni(Vector3(-1.6, 2.1, 1.9), Color(1.0, 0.85, 0.68), 0.55, 5.5)          # hallway spill on the door wall
	_omni(Vector3(2.4, 2.1, 2.0), Color(0.75, 0.75, 0.85), 0.45, 4.5)          # lifts the corner by the sofa
	_omni(Vector3(0, 2.14, 0.3), Color(1.0, 0.84, 0.62), 1.1, 7.5, true)       # the ceiling light, on
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

func _clues() -> void:
	for c in CLUES:
		var body := StaticBody3D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		body.position = c.pos
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = c.size
		cs.shape = shape
		body.add_child(cs)
		body.set_meta("clue", c)
		# pulsing marker
		var mark := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.045
		sm.height = 0.09
		mark.mesh = sm
		mark.material_override = _mat(AMBER, 1.6)
		mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mark.position = Vector3(0, c.size.y / 2.0 + 0.12, 0)
		body.add_child(mark)
		body.set_meta("mark", mark)
		add_child(body)
		var tw := create_tween().set_loops()
		tw.tween_property(mark, "scale", Vector3.ONE * 1.6, 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(mark, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_SINE)

func _player() -> void:
	player = CharacterBody3D.new()
	player.set_script(load("res://player.gd"))
	player.position = Vector3(0.4, 0.0, 2.3)
	add_child(player)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -2.8)
	ray.collision_mask = 3
	player.cam.add_child(ray)

# ── interface ────────────────────────────────────────────────────

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	return l

func _ui() -> void:
	# film grade over the 3D view, under the interface
	var film := CanvasLayer.new()
	film.layer = 0
	add_child(film)
	var grade := ColorRect.new()
	grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = load("res://grade.gdshader")
	grade.material = sm
	film.add_child(grade)
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var title := _label("CHAPTER 1 — THE EMPTY APARTMENT", 14, Color(0.7, 0.69, 0.66))
	title.position = Vector2(20, 14)
	root.add_child(title)

	ui_status = _label("", 14, AMBER)
	ui_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	ui_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_status.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ui_status.position = Vector2(-20, 14)
	root.add_child(ui_status)

	var dot := _label("•", 18, Color(1, 1, 1, 0.7))
	dot.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root.add_child(dot)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BEGIN
	col.position.y = -24
	col.custom_minimum_size.x = 860
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 10)
	root.add_child(col)

	ui_prompt = _label("", 18, AMBER)
	ui_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(ui_prompt)

	ui_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.09, 0.88)
	sb.border_color = AMBER
	sb.border_width_top = 2
	sb.set_content_margin_all(18)
	ui_panel.add_theme_stylebox_override("panel", sb)
	col.add_child(ui_panel)
	ui_info = Label.new()
	ui_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui_info.add_theme_font_override("font", FONT)
	ui_info.add_theme_font_size_override("font_size", 18)
	ui_info.add_theme_color_override("font_color", Color(0.91, 0.9, 0.87))
	ui_panel.add_child(ui_info)
	_status()

func _status() -> void:
	ui_status.text = "TIME LEFT  %s%s\nCASE STRENGTH  %d%%" % ["●".repeat(left), "○".repeat(BUDGET - left), strength]

func _say(text: String) -> void:
	ui_info.text = text
	ui_panel.visible = text != ""

func _process(_delta: float) -> void:
	looking = null
	if ray.is_colliding():
		var hit := ray.get_collider() as StaticBody3D
		if hit and hit.has_meta("talk"):
			looking = hit
		elif hit and left > 0 and hit.has_meta("clue") and not hit.has_meta("used"):
			looking = hit
	if looking and looking.has_meta("talk"):
		ui_prompt.text = "[ E ]  Talk to %s" % looking.get_meta("talk")
	else:
		ui_prompt.text = "[ E ]  Examine the %s" % looking.get_meta("clue").name.to_lower() if looking else ""

func _priya() -> String:
	if left > 0:
		return "She's holding her phone in both hands in case it rings. \"Did you find anything? Please. Just look. I'll be right here.\""
	return "\"She texts me when she leaves work. Every time. Just one word: 'Leaving.' Tonight there was nothing.\"\n\n(Her interview is the next scene. End of prototype.)"

func _reyes() -> String:
	# What your partner says depends on how far the search has got.
	talks += 1
	if left == 0:
		return "That's our time, Nadia. Crime scene has the room. Priya's still in the hall, and she's the one who called it in. Let's hear it from her."
	if left == BUDGET:
		return [
			"Roommate's name is Priya Nair. That's her room across the hall. She's out on the stairs with a uniform. Says Tessa texts when she leaves work, every night, and tonight she didn't.",
			"Crime scene's ten minutes out and they'll seal the room. We get four good looks, not six. Pick the ones that tell us where she was tonight.",
		][(talks - 1) % 2]
	return [
		"You took her complaint three weeks ago. Whatever's in here, you'll know faster than I will what's new and what isn't.",
		"Don't touch more than you have to. If this turns into a case, some defense lawyer is going to walk a jury through this room.",
		"%d left. I'd want to know who had eyes on this place, and who knew her schedule." % left,
	][(talks - 1) % 3]

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_E and looking and looking.has_meta("talk"):
		if looking.get_meta("talk") == "Priya":
			_say("PRIYA NAIR\n" + _priya())
		else:
			_say("DET. SAM REYES\n" + _reyes())
	elif e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_E and looking:
		var c: Dictionary = looking.get_meta("clue")
		looking.set_meta("used", true)
		(looking.get_meta("mark") as MeshInstance3D).visible = false
		left -= 1
		strength += c.pts
		var text: String = c.name.to_upper() + "\n" + c.text
		if left == 0:
			text += "\n\nThe crime scene unit is at the door. Time to step out and talk to Priya, on the stairs in the hall."
		_say(text)
		_status()

func _screenshot(path: String) -> void:
	for i in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
