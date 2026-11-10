extends Node3D
## Chapter 1 prototype: walk around Tessa Brandt's apartment and examine four of six things.
## The room is built in code from simple shapes; lighting does most of the work.
## Run with `-- --shot <file.png>` to save one frame and quit (used for checking the look).

const AMBER := Color(0.95, 0.71, 0.27)
const BUDGET := 4

const CLUES := [
	{"name": "Tablet", "pts": 5, "pos": Vector3(-2.2, 0.82, -2.45), "size": Vector3(0.5, 0.3, 0.5),
		"text": "Her tablet, showing her text messages. 73 unread, all from the unknown number in her complaint. It was a few dozen when she came to you. The most recent, 8:51 PM: \"You looked tired today. I can help with that.\""},
	{"name": "Bookshelf", "pts": 5, "pos": Vector3(-3.7, 1.15, 0.2), "size": Vector3(0.5, 0.5, 0.9),
		"text": "A coffee can of dried flowers. Under it, a stack of index cards in careful block capitals. \"I SAW YOU ON THE THIRD FLOOR.\" \"SIT BY THE WINDOW AGAIN.\" She kept every one, the way you keep things you might need as proof."},
	{"name": "Laptop", "pts": 5, "pos": Vector3(2.3, 0.7, -1.9), "size": Vector3(0.6, 0.4, 0.5),
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
var ui_prompt: Label
var ui_info: Label
var ui_panel: PanelContainer
var ui_status: Label

func _ready() -> void:
	_environment()
	_room()
	_furniture()
	_lights()
	_city()
	_clues()
	_player()
	_ui()
	_say("You are Detective Nadia Okonkwo. Six things in this room are worth your attention, and you have time to examine four before the crime scene unit seals it.\n\nClick to look around. WASD to walk. Look at a glowing marker and press E.")
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--shot":
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

func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.20, 0.24, 0.38)
	env.ambient_light_energy = 0.6
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
	var wall := Color(0.36, 0.33, 0.40)
	_box(Vector3(0, -0.05, 0), Vector3(8, 0.1, 6), Color(0.23, 0.17, 0.13))            # floor
	_box(Vector3(0, 2.85, 0), Vector3(8, 0.1, 6), Color(0.30, 0.29, 0.33))             # ceiling
	_box(Vector3(0, 1.4, -3.05), Vector3(8, 2.8, 0.1), wall)                            # north
	_box(Vector3(-4.05, 1.4, 0), Vector3(0.1, 2.8, 6), wall)                            # west
	_box(Vector3(-2.25, 1.4, 3.05), Vector3(3.5, 2.8, 0.1), wall)                       # south, left of door
	_box(Vector3(2.25, 1.4, 3.05), Vector3(3.5, 2.8, 0.1), wall)                        # south, right of door
	_box(Vector3(0, 2.45, 3.05), Vector3(1.0, 0.7, 0.1), wall)                          # above door
	_box(Vector3(-0.35, 1.05, 3.4), Vector3(0.9, 2.1, 0.06), Color(0.30, 0.22, 0.16), false, 0.0, 1.0)  # door, ajar
	# east wall with a window opening (z 0..1.6, y 0.9..2.2)
	_box(Vector3(4.05, 1.4, -1.5), Vector3(0.1, 2.8, 3.0), wall)
	_box(Vector3(4.05, 1.4, 2.3), Vector3(0.1, 2.8, 1.4), wall)
	_box(Vector3(4.05, 0.45, 0.8), Vector3(0.1, 0.9, 1.6), wall)
	_box(Vector3(4.05, 2.5, 0.8), Vector3(0.1, 0.6, 1.6), wall)
	for i in 9:                                                                          # blinds
		_box(Vector3(4.0, 0.98 + i * 0.145, 0.8), Vector3(0.03, 0.075, 1.6), Color(0.78, 0.76, 0.70), false)
	_box(Vector3(0, 0.005, 0.4), Vector3(2.6, 0.01, 1.8), Color(0.33, 0.16, 0.14), false)  # rug

func _furniture() -> void:
	var wood := Color(0.33, 0.23, 0.16)
	# desk + chair
	_box(Vector3(-2.3, 0.74, -2.55), Vector3(1.7, 0.06, 0.75), wood)
	for x in [-3.05, -1.55]:
		_box(Vector3(x, 0.36, -2.55), Vector3(0.06, 0.72, 0.65), wood, false)
	_box(Vector3(-2.3, 0.45, -1.8), Vector3(0.45, 0.06, 0.45), Color(0.15, 0.15, 0.17))
	_box(Vector3(-2.3, 0.75, -1.6), Vector3(0.45, 0.6, 0.05), Color(0.15, 0.15, 0.17), false)
	# desk lamp
	_box(Vector3(-2.9, 0.79, -2.7), Vector3(0.16, 0.03, 0.16), Color(0.1, 0.1, 0.1), false)
	_box(Vector3(-2.9, 1.0, -2.7), Vector3(0.03, 0.42, 0.03), Color(0.1, 0.1, 0.1), false)
	_box(Vector3(-2.8, 1.22, -2.65), Vector3(0.26, 0.1, 0.18), AMBER, false, 2.5)
	# tablet
	_box(Vector3(-2.2, 0.785, -2.45), Vector3(0.28, 0.015, 0.2), Color(0.55, 0.75, 1.0), false, 2.0)
	# wastebasket
	_box(Vector3(-0.9, 0.2, -2.6), Vector3(0.3, 0.4, 0.3), Color(0.22, 0.24, 0.27))
	# bed
	_box(Vector3(2.5, 0.25, -1.9), Vector3(2.8, 0.5, 2.0), Color(0.27, 0.23, 0.36))
	_box(Vector3(2.5, 0.53, -1.9), Vector3(2.8, 0.08, 2.0), Color(0.42, 0.37, 0.52), false)
	_box(Vector3(3.4, 0.64, -2.5), Vector3(0.8, 0.14, 0.5), Color(0.85, 0.84, 0.88), false)
	_box(Vector3(2.5, 0.9, -2.95), Vector3(2.8, 1.0, 0.1), Color(0.22, 0.18, 0.28), false)
	# laptop on the bed
	_box(Vector3(2.3, 0.585, -1.9), Vector3(0.36, 0.02, 0.26), Color(0.12, 0.12, 0.13), false)
	_box(Vector3(2.3, 0.72, -2.04), Vector3(0.36, 0.25, 0.015), Color(0.65, 0.8, 1.0), false, 0.9)
	# bookshelf
	_box(Vector3(-3.8, 1.0, 0.2), Vector3(0.35, 2.0, 1.2), Color(0.20, 0.16, 0.22))
	var spines := [Color(0.45, 0.25, 0.25), Color(0.25, 0.32, 0.42), Color(0.42, 0.38, 0.24), Color(0.24, 0.36, 0.30)]
	for row in 3:
		for i in 8:
			_box(Vector3(-3.6, 0.42 + row * 0.6, -0.3 + i * 0.1), Vector3(0.05, 0.28 + (i % 3) * 0.04, 0.07), spines[(i + row) % 4], false)
	_box(Vector3(-3.6, 1.12, 0.6), Vector3(0.12, 0.14, 0.12), Color(0.6, 0.62, 0.65), false)   # coffee can
	_box(Vector3(-3.6, 1.26, 0.6), Vector3(0.02, 0.18, 0.02), Color(0.7, 0.5, 0.4), false)
	_box(Vector3(-3.6, 1.36, 0.6), Vector3(0.06, 0.05, 0.06), Color(0.8, 0.45, 0.45), false)
	# corkboard
	_box(Vector3(0.2, 1.55, -2.97), Vector3(1.3, 0.85, 0.04), Color(0.50, 0.35, 0.22), false)
	_box(Vector3(-0.15, 1.65, -2.94), Vector3(0.3, 0.42, 0.01), Color(0.92, 0.9, 0.86), false)
	_box(Vector3(0.3, 1.72, -2.94), Vector3(0.42, 0.28, 0.01), Color(0.86, 0.80, 0.62), false)
	_box(Vector3(0.65, 1.38, -2.94), Vector3(0.16, 0.16, 0.01), Color(0.96, 0.9, 0.4), false, 0.3)

func _lights() -> void:
	_omni(Vector3(-2.7, 1.1, -2.4), Color(1.0, 0.72, 0.38), 1.6, 4.5, true)     # desk lamp
	_omni(Vector3(-2.2, 0.95, -2.4), Color(0.55, 0.75, 1.0), 0.25, 1.2)         # tablet glow
	_omni(Vector3(2.3, 0.9, -1.6), Color(0.6, 0.78, 1.0), 0.3, 2.0)            # laptop glow
	_omni(Vector3(0.3, 2.1, 3.9), Color(1.0, 0.9, 0.72), 1.4, 5.0, true)        # hallway, through the door
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

func _city() -> void:
	# a few dark buildings with lit windows, seen through the blinds
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for b in 5:
		var z := -4.0 + b * 2.6
		var h := 5.0 + rng.randf() * 5.0
		_box(Vector3(14.0 + rng.randf() * 3.0, h / 2.0 - 3.0, z), Vector3(2.0, h, 2.2), Color(0.03, 0.04, 0.07), false)
		for w in 9:
			if rng.randf() < 0.5:
				_box(Vector3(12.9, -2.0 + rng.randf() * (h - 1.0), z - 0.8 + rng.randf() * 1.6), Vector3(0.05, 0.22, 0.16), Color(1.0, 0.82, 0.5), false, 3.0)

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
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	return l

func _ui() -> void:
	var layer := CanvasLayer.new()
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
	if left > 0 and ray.is_colliding():
		var hit := ray.get_collider() as StaticBody3D
		if hit and hit.has_meta("clue") and not hit.has_meta("used"):
			looking = hit
	ui_prompt.text = "[ E ]  Examine the %s" % looking.get_meta("clue").name.to_lower() if looking else ""

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_E and looking:
		var c: Dictionary = looking.get_meta("clue")
		looking.set_meta("used", true)
		(looking.get_meta("mark") as MeshInstance3D).visible = false
		left -= 1
		strength += c.pts
		var text: String = c.name.to_upper() + "\n" + c.text
		if left == 0:
			text += "\n\nThe crime scene unit is at the door. Time to step out.  (End of prototype.)"
		_say(text)
		_status()

func _screenshot(path: String) -> void:
	for i in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
