class_name Kit
extends Node3D
## Building blocks shared by every location: surfaces, props, lights, people, camera shots.
## A location script extends this and fills in `build()`. The game reads `shots`, `cast`,
## `tracks`, `spots`, `talk` and `spawn` from it.

const AMBER := Color(0.95, 0.71, 0.27)
const INK := Color(0.10, 0.10, 0.12)
# Detective Okonkwo, the player. Her model is used for nobody else, so she always reads as herself.
const OKONKWO_MODEL := "elizabeth"
const OKONKWO_LOOK := {"Shirt!": Color(0.1, 0.11, 0.13), "Pants!": Color(0.12, 0.12, 0.14), "Heels": Color(0.08, 0.08, 0.09)}
const HEIGHT := {"remy": 0.47}             # a file in different units from the others gets its scale here
static var _cache := {}                    # loaded scenes, kept so a location change is quick

var FONT: Font = load("res://assets/fonts/SpecialElite-Regular.ttf")
var stage := ""                            # which arrangement of this location is wanted
var st: RefCounted                         # story state, for arrangements that depend on it
var shots := {}                            # name -> [camera position, look-at point, fov]
var cast := {}                             # NAME -> {node, idle, talk}
var tracks := {}                           # name -> list of [camera position, look-at point] per action step
var spots := {}                            # hotspot name -> {pos, size}
var talk := {}                             # NAME -> Callable(left) -> String, for the walk-around scenes
var spawn := [Vector3.ZERO, 0.0]           # where the player stands in a walk-around scene
var ambience := "room"                     # which background sound the location wants
var flickers: Array = []                   # lights that flicker like fire: [light, base energy, speed]
var _t := 0.0

func build() -> void:
	pass

func on_step(_track: String, _i: int) -> void:
	pass                                   # a location can move people as an action sequence advances

func _process(delta: float) -> void:
	_t += delta
	for f in flickers:
		if not (f[0] as Light3D).has_meta("strobe"):
			(f[0] as Light3D).light_energy = f[1] * (0.72 + 0.28 * sin(_t * f[2]) * sin(_t * f[2] * 0.37 + 1.3) + 0.1 * sin(_t * 23.0))
	_strobes()

# ── materials ────────────────────────────────────────────────────

func mat(color: Color, emission := 0.0, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = Color(color.r, color.g, color.b)
		m.emission_energy_multiplier = emission
	return m

func tex(id: String, scale := 0.5, tint := Color.WHITE) -> StandardMaterial3D:
	# A Poly Haven surface, mapped in world space so it tiles the same on every box.
	var key := "tex:%s:%s:%s" % [id, scale, tint]
	if _cache.has(key):
		return _cache[key]
	var base := "res://assets/textures/%s/%s_" % [id, id]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base + ("diff" if ResourceLoader.exists(base + "diff_1k.jpg") else "diffuse") + "_1k.jpg")
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = load(base + "nor_gl_1k.jpg")
	m.roughness_texture = load(base + "rough_1k.jpg")
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	_cache[key] = m
	return m

# ── shapes ───────────────────────────────────────────────────────

func _solid(mi: MeshInstance3D, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	mi.add_child(body)

func box(pos: Vector3, size: Vector3, color: Color, solid := true, emission := 0.0, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(color, emission)
	mi.position = pos
	mi.rotation.y = rot_y
	if emission > 0.0 or color.a < 1.0:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	if solid:
		_solid(mi, size)
	return mi

func tbox(pos: Vector3, size: Vector3, m: Material, solid := true, rot_y := 0.0) -> MeshInstance3D:
	var mi := box(pos, size, Color.WHITE, solid, 0.0, rot_y)
	mi.material_override = m
	return mi

func cyl(pos: Vector3, radius: float, height: float, color: Color, rough := 0.85) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat(color, 0.0, rough)
	mi.position = pos
	add_child(mi)
	return mi

func ball(pos: Vector3, radius: float, color: Color, emission := 0.0, squash := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.scale = squash
	mi.material_override = mat(color, emission)
	mi.position = pos
	if emission > 0.0:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func shell(x0: float, x1: float, z0: float, z1: float, h: float, wall: Material, floor_m: Material, ceil: Variant = null, y := 0.0) -> void:
	# Four walls, a floor and (optionally) a ceiling. Openings are cut by building walls from `wall_x`/`wall_z` instead.
	var cx := (x0 + x1) / 2.0
	var cz := (z0 + z1) / 2.0
	tbox(Vector3(cx, y - 0.05, cz), Vector3(x1 - x0, 0.1, z1 - z0), floor_m)
	if ceil != null:
		if ceil is Color:
			box(Vector3(cx, y + h + 0.05, cz), Vector3(x1 - x0, 0.1, z1 - z0), ceil)
		else:
			tbox(Vector3(cx, y + h + 0.05, cz), Vector3(x1 - x0, 0.1, z1 - z0), ceil)
	if wall != null:
		wall_x(z0 - 0.05, x0, x1, y, y + h, wall)
		wall_x(z1 + 0.05, x0, x1, y, y + h, wall)
		wall_z(x0 - 0.05, z0, z1, y, y + h, wall)
		wall_z(x1 + 0.05, z0, z1, y, y + h, wall)

func wall_x(z: float, x0: float, x1: float, y0: float, y1: float, m: Material, thick := 0.1) -> MeshInstance3D:
	return tbox(Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, z), Vector3(x1 - x0, y1 - y0, thick), m)

func wall_z(x: float, z0: float, z1: float, y0: float, y1: float, m: Material, thick := 0.1) -> MeshInstance3D:
	return tbox(Vector3(x, (y0 + y1) / 2.0, (z0 + z1) / 2.0), Vector3(thick, y1 - y0, z1 - z0), m)

# ── lights ───────────────────────────────────────────────────────

func omni(pos: Vector3, color: Color, energy: float, rng: float, shadows := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = shadows
	add_child(l)
	return l

func spot(pos: Vector3, target: Vector3, color: Color, energy: float, rng := 12.0, angle := 35.0, shadows := true, fog := 1.0) -> SpotLight3D:
	var s := SpotLight3D.new()
	s.position = pos
	s.light_color = color
	s.light_energy = energy
	s.spot_range = rng
	s.spot_angle = angle
	s.shadow_enabled = shadows
	s.light_volumetric_fog_energy = fog
	add_child(s)
	s.look_at(target, Vector3.FORWARD if absf((target - pos).normalized().y) > 0.98 else Vector3.UP)
	return s

func tube(pos: Vector3, length := 1.2, along_x := true, color := Color(0.92, 0.97, 1.0), energy := 1.2, rng := 6.0, shadows := false) -> OmniLight3D:
	# A fluorescent ceiling fitting: a lit tube in a housing, and the light it gives.
	var size := Vector3(length, 0.035, 0.09) if along_x else Vector3(0.09, 0.035, length)
	box(pos, size, color, false, 3.5)
	box(pos + Vector3(0, 0.03, 0), size + Vector3(0.06, 0.02, 0.1) if along_x else size + Vector3(0.1, 0.02, 0.06), Color(0.75, 0.75, 0.73), false)
	return omni(pos - Vector3(0, 0.25, 0), color, energy, rng, shadows)

func fire(pos: Vector3, energy := 3.0, rng := 9.0, size := 0.5) -> void:
	# Firelight, flames and smoke.
	var l := omni(pos + Vector3(0, 0.5, 0), Color(1.0, 0.5, 0.16), energy, rng, true)
	flickers.append([l, energy, 9.0 + randf() * 4.0])
	var flame := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(size, 0.05, size * 0.6)
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 1.8
	pm.gravity = Vector3(0, 1.2, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.4, 0.9))
	ramp.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = ramp
	pm.color_ramp = gt
	flame.process_material = pm
	flame.amount = 60
	flame.lifetime = 0.9
	var q := QuadMesh.new()
	q.size = Vector2(0.35, 0.5)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.vertex_color_use_as_albedo = true
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fm.albedo_texture = _blob()
	q.material = fm
	flame.draw_pass_1 = q
	flame.position = pos
	add_child(flame)
	smoke(pos + Vector3(0, 0.8, 0), size)

func smoke(pos: Vector3, size := 0.5, amount := 40, rise := 1.0) -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(size, 0.1, size)
	pm.direction = Vector3(0.15, 1, 0)
	pm.spread = 18.0
	pm.initial_velocity_min = 0.4 * rise
	pm.initial_velocity_max = 1.0 * rise
	pm.gravity = Vector3(0.1, 0.35, 0)
	pm.scale_min = 1.2
	pm.scale_max = 3.2
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.16, 0.15, 0.15, 0.0))
	ramp.add_point(0.15, Color(0.14, 0.13, 0.13, 0.5))
	ramp.set_color(2, Color(0.2, 0.2, 0.22, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = ramp
	pm.color_ramp = gt
	p.process_material = pm
	p.amount = amount
	p.lifetime = 5.0
	p.preprocess = 4.0
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9)
	var fm := StandardMaterial3D.new()
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.vertex_color_use_as_albedo = true
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fm.albedo_texture = _blob()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(0.55, 0.5, 0.48)
	q.material = fm
	p.draw_pass_1 = q
	p.position = pos
	p.visibility_aabb = AABB(Vector3(-6, -2, -6), Vector3(12, 14, 12))
	add_child(p)

func _blob() -> Texture2D:
	if not _cache.has("blob"):
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		_cache["blob"] = t
	return _cache["blob"]

func env(hdri: String, sky_energy: float, ambient: Color, ambient_energy: float, fog := 0.012, fog_color := Color(0.75, 0.8, 0.95), sky_turn := 0.0) -> Environment:
	var e := Environment.new()
	var sky := Sky.new()
	var pm := PanoramaSkyMaterial.new()
	pm.panorama = load("res://assets/hdri/%s_2k.hdr" % hdri)
	pm.energy_multiplier = sky_energy
	sky.sky_material = pm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.sky_rotation.y = sky_turn
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = ambient
	e.ambient_light_energy = ambient_energy
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_bloom = 0.15
	e.ssao_enabled = true
	e.volumetric_fog_enabled = fog > 0.0
	e.volumetric_fog_density = fog
	e.volumetric_fog_albedo = fog_color
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	return e

# ── props ────────────────────────────────────────────────────────

func _load(path: String) -> PackedScene:
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]

static func bounds(n: Node, xf := Transform3D.IDENTITY) -> AABB:
	var out := AABB()
	var first := true
	var stack := [[n, xf]]
	while not stack.is_empty():
		var it: Array = stack.pop_back()
		var node: Node = it[0]
		var t: Transform3D = it[1]
		if node is Node3D and node != n:
			t = t * (node as Node3D).transform
		if node is MeshInstance3D:
			var a: AABB = t * (node as MeshInstance3D).get_aabb()
			out = a if first else out.merge(a)
			first = false
		for c in node.get_children():
			stack.append([c, t])
	return out

func model(id: String, pos: Vector3, rot_y := 0.0, scale := 1.0, solid := Vector3.ZERO, off_z := 0.0) -> Node3D:
	# A Poly Haven model. Its front faces +Z and its origin is on the floor.
	var n: Node3D = _load("res://assets/models/%s/%s_1k.gltf" % [id, id]).instantiate()
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

func prop(id: String, pos: Vector3, rot_y := 0.0, height := 0.0, solid := false) -> Node3D:
	# A model scaled to a wanted height (0 keeps its own size), with a collision box the size of the model.
	var n := model(id, pos, rot_y)
	var a := bounds(n)
	var k := height / a.size.y if height > 0.0 else 1.0
	n.scale = Vector3.ONE * k
	if solid:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = a.size * k
		cs.shape = shape
		cs.position = a.get_center() * k
		body.add_child(cs)
		body.position = pos
		body.rotation.y = rot_y
		add_child(body)
	return n

func unshadow(n: Node) -> void:
	for m in n.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func clear_glass(n: Node3D) -> Node3D:
	# Poly Haven glass arrives as an opaque dark shell; make it see-through.
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		for i in mesh.get_surface_count():
			var m := mesh.surface_get_material(i)
			if m and m.resource_name.to_lower().contains("glass"):
				(mi as MeshInstance3D).set_surface_override_material(i, mat(Color(1, 1, 1, 0.06), 0.0, 0.05))
	return n

func note(text: String, pos: Vector3, size: int, color := INK, tilt := 0.0, rot_y := 0.0, lit := false) -> Label3D:
	# Writing on a surface: faces +Z unless turned, lit by the room like the paper under it.
	var l := Label3D.new()
	l.text = text
	l.font = FONT
	l.font_size = size * 4
	l.pixel_size = 0.00032
	l.modulate = color
	l.outline_size = 0
	l.shaded = not lit
	l.double_sided = false
	l.line_spacing = -6.0
	l.position = pos
	l.rotation.z = tilt
	l.rotation.y = rot_y
	add_child(l)
	return l

func plate(text: String, pos: Vector3, rot_y: float, width: float, height: float, bg: Color, fg: Color, size := 60, font: Font = null, glow := 0.0) -> void:
	# A printed or painted sign: a plate with lettering on its +Z face.
	var plate := box(pos, Vector3(width, height, 0.02), bg, false, glow, rot_y)
	var l := Label3D.new()
	l.text = text
	l.font = font if font else ThemeDB.fallback_font
	l.font_size = size
	l.pixel_size = 0.0016
	l.modulate = fg
	l.outline_size = 0
	l.shaded = glow <= 0.0
	l.double_sided = false
	l.position = Vector3(0, 0, 0.012)
	l.width = width / 0.0016 * 0.92
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plate.add_child(l)

func paper(pos: Vector3, rot_y := 0.0, size := Vector2(0.21, 0.297), color := Color(0.9, 0.89, 0.85)) -> MeshInstance3D:
	# A sheet lying flat on a surface.
	return box(pos, Vector3(size.x, 0.002, size.y), color, false, 0.0, rot_y)

func door(pos: Vector3, rot_y := 0.0, color := Color(0.30, 0.22, 0.16), w := 0.9, h := 2.05, window := false) -> MeshInstance3D:
	var d := box(pos + Vector3(0, h / 2.0, 0), Vector3(w, h, 0.045), color, false, 0.0, rot_y)
	var knob := ball(Vector3(w * 0.4, -0.05, 0.04), 0.03, Color(0.7, 0.66, 0.5))
	remove_child(knob)
	d.add_child(knob)
	if window:
		var g := box(Vector3.ZERO, Vector3(w * 0.45, h * 0.3, 0.05), Color(0.55, 0.62, 0.66, 0.35), false)
		remove_child(g)
		g.position = Vector3(0, h * 0.22, 0)
		d.add_child(g)
	return d

# ── people ───────────────────────────────────────────────────────

func _anim(skel_prefix: String, anim: String, k := 1.0) -> Animation:
	var key := "anim:" + anim
	if not _cache.has(key):
		var src: Node = _load("res://assets/mixamo/animations/%s.fbx" % anim).instantiate()
		_cache[key] = (src.find_child("AnimationPlayer", true, false) as AnimationPlayer).get_animation("mixamo_com")
		src.free()
	var a: Animation = (_cache[key] as Animation).duplicate()
	for t in a.get_track_count():
		var bone := str(a.track_get_path(t)).get_slice(":", 1)
		a.track_set_path(t, NodePath("Skeleton3D:" + skel_prefix + bone.substr(bone.find("_") + 1)))
		if k != 1.0 and a.track_get_type(t) == Animation.TYPE_POSITION_3D:
			for i in a.track_get_key_count(t):       # the hips travel in the units of the skeleton the clip was made on
				a.track_set_key_value(t, i, a.track_get_key_value(t, i) / k)
	# A clip that carries the body forward (a jump, a vault, a slide) is kept on the spot: the game moves the
	# person itself, and a clip that also travelled would snap back when it ended.
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_POSITION_3D or not str(a.track_get_path(t)).ends_with("Hips"):
			continue
		var n := a.track_get_key_count(t)
		if n < 2:
			continue
		var first: Vector3 = a.track_get_key_value(t, 0)
		var last: Vector3 = a.track_get_key_value(t, n - 1)
		if Vector2(last.x - first.x, last.z - first.z).length() > absf(first.y) * 0.3:
			for i in n:
				var p: Vector3 = a.track_get_key_value(t, i)
				a.track_set_key_value(t, i, Vector3(first.x, p.y, first.z))
	a.loop_mode = Animation.LOOP_LINEAR
	return a

static func clip(want: String, fallback: String) -> String:
	# An animation that may not be installed, with the one to use instead.
	return want if ResourceLoader.exists("res://assets/mixamo/animations/%s.fbx" % want) else fallback

static func have_people() -> bool:
	return ResourceLoader.exists("res://assets/mixamo/characters/leonard.fbx")

func actor(who: String, model_id: String, pos: Vector3, rot_y := 0.0, idle := "idle", talk_anim := "talk", look: Dictionary = {}) -> Node3D:
	# A Mixamo character in the cast. Each character's bones carry their own prefix
	# (mixamorig_, mixamorig9_, ...), so animations are renamed to match as they are added.
	# `look` recolours parts of the model, e.g. {"Hair": Color, "Suit": Color}, to tell reused models apart.
	if not have_people():
		return null
	var n: Node3D = _load("res://assets/mixamo/characters/%s.fbx" % model_id).instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * HEIGHT.get(model_id, 1.0)
	add_child(n)
	# Some files mark skin and clothes as see-through, which lets the eye sockets show through the
	# lids and makes the eyes bulge. Only hair and lashes need transparency.
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		for i in mesh.get_surface_count():
			var sm := mesh.surface_get_material(i) as StandardMaterial3D
			if sm == null or sm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
				continue
			var soft := sm.resource_name.to_lower().contains("hair") or sm.resource_name.to_lower().contains("lash")
			if soft and sm.albedo_texture != null and sm.albedo_texture.resource_path.get_file() == model_id + "_0.png":
				(mi as MeshInstance3D).visible = false        # lashes pointing at the skin texture: drop them
			elif not soft:
				sm.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			elif sm.resource_name.to_lower().contains("hair"):
				# Hair is painted on thin cards. Drawn one-sided with a hard cut-off it looks sparse and the
				# scalp shows; drawing both sides and keeping the faint strands fills it out.
				sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				sm.alpha_scissor_threshold = 0.12
				sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	for key in look:
		var part: String = (key as String).trim_suffix("!")       # "Shirt!" also drops the printed pattern: a plain garment
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			if str(mi.name).contains(part):
				var m := (mi as MeshInstance3D).mesh
				for i in m.get_surface_count():
					var d: StandardMaterial3D = m.surface_get_material(i).duplicate()
					d.albedo_color = look[key]
					if (key as String).ends_with("!"):
						d.albedo_texture = null
					(mi as MeshInstance3D).set_surface_override_material(i, d)
	var skel: Skeleton3D = n.find_child("Skeleton3D", true, false)
	var prefix := ""
	for i in skel.get_bone_count():
		if skel.get_bone_name(i).ends_with("Hips"):
			prefix = skel.get_bone_name(i).trim_suffix("Hips")
	var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
	var lib := AnimationLibrary.new()
	ap.add_animation_library("mx", lib)
	n.set_meta("prefix", prefix)
	n.set_meta("lib", lib)
	n.set_meta("ap", ap)
	if who != "":
		cast[who] = {"node": n, "idle": idle, "talk": talk_anim}
	pose(n, idle)
	ap.seek(randf() * 2.0)
	if who in ["REYES", "OKONKWO"]:
		badge(n)
	return n

func robe(n: Node3D, color := Color(0.03, 0.03, 0.035), sleeves := true, metal := 0.0, rough := 0.92, body := 1.0) -> void:
	# `body` under 1 shortens it to a wrap round the shoulders (a blanket).
	# A judge's robe worn over a suit: a loose black body, a yoke over the shoulders and bell sleeves,
	# each piece fixed to a bone so it moves with the person.
	if n == null:
		return
	var skel: Skeleton3D = n.find_child("Skeleton3D", true, false)
	var k := 1.0 / skel.global_transform.basis.get_scale().x
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = color
	cloth.roughness = rough
	cloth.metallic = metal
	# [bone, top radius, bottom radius, length, offset along the bone, squash]
	for part in [["Spine1", 0.2, 0.36, 0.8, -0.12, Vector3(1.0, 1.0, 0.74)], ["Spine2", 0.13, 0.27, 0.2, 0.17, Vector3(1.0, 1.0, 0.72)],
			["LeftArm", 0.1, 0.095, 0.3, 0.14, Vector3.ONE], ["RightArm", 0.1, 0.095, 0.3, 0.14, Vector3.ONE],
			["LeftForeArm", 0.095, 0.15, 0.25, 0.11, Vector3.ONE], ["RightForeArm", 0.095, 0.15, 0.25, 0.11, Vector3.ONE]]:
		if not sleeves and (part[0] as String).contains("Arm"):
			continue
		if part[0] == "Spine1" and body < 1.0:
			part = ["Spine1", 0.24, lerpf(0.24, 0.36, body), 0.8 * body, -0.12 + (1.0 - body) * 0.42, Vector3(1.05, 1.0, 0.8)]
		var at := BoneAttachment3D.new()
		skel.add_child(at)
		at.bone_name = str(n.get_meta("prefix")) + part[0]
		var mi := MeshInstance3D.new()
		var m := CylinderMesh.new()
		m.top_radius = part[1]
		m.bottom_radius = part[2]
		m.height = part[3]
		if (part[0] as String).contains("Arm"):         # arm bones run shoulder to hand, so the wide end goes last
			m.top_radius = part[2]
			m.bottom_radius = part[1]
		mi.mesh = m
		mi.material_override = cloth
		mi.position = Vector3(0, part[4], 0.015 if (part[0] as String).begins_with("Spine") else 0.0) * k
		mi.scale = (part[5] as Vector3) * k
		at.add_child(mi)

func badge(n: Node3D) -> void:
	# A detective's shield clipped to the belt, left of the buckle.
	if n == null:
		return
	var skel: Skeleton3D = n.find_child("Skeleton3D", true, false)
	var k := 1.0 / skel.global_transform.basis.get_scale().x
	var at := BoneAttachment3D.new()
	skel.add_child(at)
	at.bone_name = str(n.get_meta("prefix")) + "Hips"
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.85, 0.68, 0.25)
	gold.metallic = 0.9
	gold.roughness = 0.3
	for piece in [[Vector3(0.09, 0.045, 0.118), Vector3(0.05, 0.065, 0.012), Color(0.05, 0.05, 0.05)], [Vector3(0.09, 0.045, 0.126), Vector3(0.036, 0.046, 0.008), Color.WHITE]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = piece[1]
		mi.mesh = bm
		mi.material_override = gold if piece[2] == Color.WHITE else mat(piece[2])
		mi.position = (piece[0] as Vector3) * k
		mi.scale = Vector3.ONE * k
		at.add_child(mi)

func pose(n: Node3D, anim: String, blend := 0.3) -> void:
	if n == null:
		return
	var lib: AnimationLibrary = n.get_meta("lib")
	if not lib.has_animation(anim):
		lib.add_animation(anim, _anim(n.get_meta("prefix"), anim, n.scale.x))
	(n.get_meta("ap") as AnimationPlayer).play("mx/" + anim, blend)

func speaking(who: String, on: bool) -> void:
	if cast.has(who):
		var c: Dictionary = cast[who]
		pose(c.node, c.talk if on else c.idle)

func solid_person(n: Node3D, who := "", height := 1.8) -> void:
	# Lets the player bump into (and, with a name, talk to) someone in a walk-around scene.
	if n == null:
		return
	var body := StaticBody3D.new()
	body.collision_layer = 3          # blocks the player (1) and is seen by the look ray (2)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = height
	cs.shape = cap
	cs.position.y = height / 2.0
	body.add_child(cs)
	if who != "":
		body.set_meta("talk", who)
	body.position = n.position
	body.scale = Vector3.ONE
	add_child(body)

# ── camera shots ─────────────────────────────────────────────────

func shot(name: String, pos: Vector3, target: Vector3, fov := 50.0) -> void:
	shots[name] = [pos, target, fov]

func close(who: String, dist := 1.5, side := 0.45, head := 1.58, fov := 42.0, lift := 0.0) -> void:
	# A shot on a cast member's face from in front and slightly to one side.
	if not cast.has(who):
		return
	var n: Node3D = cast[who].node
	var fwd := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
	var right := Vector3(fwd.z, 0, -fwd.x)
	var face := n.position + Vector3(0, head, 0)
	shots[who] = [face + fwd * dist + right * side + Vector3(0, lift, 0), face, fov]

# ── set dressing ─────────────────────────────────────────────────

func table(pos: Vector3, top: Vector2, h := 0.74, color := Color(0.42, 0.43, 0.45), rot_y := 0.0, leg := Color(0.2, 0.2, 0.22)) -> Node3D:
	# A plain table: `pos` is the floor point under its centre.
	var t := Node3D.new()
	t.position = pos
	t.rotation.y = rot_y
	add_child(t)
	var parts := [[Vector3(0, h - 0.02, 0), Vector3(top.x, 0.04, top.y), color]]
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			parts.append([Vector3(sx * (top.x / 2 - 0.06), (h - 0.04) / 2, sz * (top.y / 2 - 0.06)), Vector3(0.04, h - 0.04, 0.04), leg])
	for p in parts:
		var b := box(p[0], p[1], p[2], false)
		remove_child(b)
		t.add_child(b)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(top.x, h, top.y)
	cs.shape = shape
	cs.position.y = h / 2
	body.add_child(cs)
	t.add_child(body)
	return t

func papers(pos: Vector3, n := 4, spread := 0.25, seed_v := 1) -> void:
	# Loose sheets and a folder or two, scattered on a surface at `pos`.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in n:
		var folder := rng.randf() < 0.3
		var c := Color(0.78, 0.66, 0.42) if folder else Color(0.9, 0.89, 0.85)
		var p := paper(pos + Vector3(rng.randf_range(-spread, spread), i * 0.0025, rng.randf_range(-spread, spread) * 0.6), rng.randf_range(-0.6, 0.6), Vector2(0.24, 0.31) if folder else Vector2(0.21, 0.297), c)
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func stack(pos: Vector3, height := 0.12, rot_y := 0.0, color := Color(0.88, 0.87, 0.83)) -> void:
	# A pile of files.
	var layers := int(height / 0.03)
	for i in layers:
		box(pos + Vector3(sin(i * 2.1) * 0.012, 0.015 + i * 0.03, cos(i * 1.7) * 0.012), Vector3(0.24, 0.028, 0.31), color if i % 3 else Color(0.78, 0.66, 0.42), false, 0.0, rot_y + sin(i * 1.3) * 0.08)

func cup(pos: Vector3, color := Color(0.92, 0.9, 0.86)) -> void:
	cyl(pos + Vector3(0, 0.05, 0), 0.036, 0.1, color, 0.6)
	cyl(pos + Vector3(0, 0.098, 0), 0.031, 0.004, Color(0.16, 0.1, 0.06), 0.3)

func bollard(pos: Vector3, h := 1.0) -> void:
	cyl(pos + Vector3(0, h / 2, 0), 0.07, h, Color(0.75, 0.6, 0.1), 0.6)
	cyl(pos + Vector3(0, h * 0.8, 0), 0.072, 0.12, Color(0.08, 0.08, 0.08), 0.6)
	blocker(pos + Vector3(0, h / 2, 0), Vector3(0.16, h, 0.16))

func blocker(pos: Vector3, size: Vector3) -> void:
	# An invisible wall that keeps the player inside the part of a location that is built.
	box(pos, size, Color.WHITE, true).visible = false

func fence_x(z: float, x0: float, x1: float, h := 2.4, y := 0.0) -> void:
	# Chain-link fence running along X: posts, rails and a see-through mesh.
	_mesh_panel(Vector3((x0 + x1) / 2, y + h / 2, z), Vector2(x1 - x0, h), 0.0)
	var x := x0
	while x <= x1 + 0.01:
		cyl(Vector3(x, y + h / 2, z), 0.035, h, Color(0.45, 0.47, 0.5), 0.5)
		x += 2.5
	for yy in [0.08, h - 0.04]:
		box(Vector3((x0 + x1) / 2, y + yy, z), Vector3(x1 - x0, 0.04, 0.04), Color(0.45, 0.47, 0.5), false)

func fence_z(x: float, z0: float, z1: float, h := 2.4, y := 0.0) -> void:
	_mesh_panel(Vector3(x, y + h / 2, (z0 + z1) / 2), Vector2(z1 - z0, h), PI / 2)
	var z := z0
	while z <= z1 + 0.01:
		cyl(Vector3(x, y + h / 2, z), 0.035, h, Color(0.45, 0.47, 0.5), 0.5)
		z += 2.5
	box(Vector3(x, y + h - 0.04, (z0 + z1) / 2), Vector3(0.04, 0.04, z1 - z0), Color(0.45, 0.47, 0.5), false)

func _into(parent: Node3D, n: Node3D) -> Node3D:
	remove_child(n)
	parent.add_child(n)
	return n

# ── vehicles ─────────────────────────────────────────────────────
# Each vehicle is a side outline pulled across its width, with wheel arches cut in, glass, lamps, bumpers,
# mirrors and door lines added. Nose toward +X before turning, rear at -X.
#   top: the outline from the rear bumper over the roof to the front bumper     arches: wheel positions along X
#   glass: which outline edges are windows      windows: side-window shapes     seams: door lines along X
const VEHICLES := {
	"van": {"w": 1.95, "wheel": 0.36, "arches": [-1.45, 1.85], "glass": [5], "seams": [-0.9, 0.95, 1.9], "shoulder": 1.25,
		"top": [Vector2(-2.4, 0.42), Vector2(-2.42, 0.62), Vector2(-2.4, 2.0), Vector2(-2.28, 2.1), Vector2(1.0, 2.1), Vector2(1.4, 2.04),
			Vector2(2.1, 1.3), Vector2(2.72, 1.1), Vector2(2.9, 0.86), Vector2(2.92, 0.46)],
		"windows": [[Vector2(1.08, 1.34), Vector2(1.12, 1.92), Vector2(1.42, 1.9), Vector2(1.95, 1.34)]]},
	"car": {"w": 1.84, "wheel": 0.33, "arches": [-1.42, 1.45], "glass": [3, 5], "seams": [-0.62, 0.42], "shoulder": 0.98,
		"top": [Vector2(-2.38, 0.42), Vector2(-2.42, 0.72), Vector2(-2.32, 0.95), Vector2(-1.55, 1.02), Vector2(-0.95, 1.43), Vector2(0.4, 1.45),
			Vector2(1.12, 1.02), Vector2(2.18, 0.9), Vector2(2.4, 0.72), Vector2(2.42, 0.42)],
		"windows": [[Vector2(-1.4, 1.03), Vector2(-0.92, 1.37), Vector2(-0.66, 1.37), Vector2(-0.66, 1.03)],
			[Vector2(-0.58, 1.03), Vector2(-0.58, 1.37), Vector2(0.36, 1.39), Vector2(0.95, 1.03)]]},
	"truck": {"w": 2.4, "wheel": 0.5, "arches": [-2.2, 2.35], "glass": [5], "seams": [0.6, 1.25, 2.2], "shoulder": 1.7,
		"top": [Vector2(-3.6, 0.6), Vector2(-3.62, 0.8), Vector2(-3.6, 2.55), Vector2(1.2, 2.55), Vector2(1.25, 2.8), Vector2(3.0, 2.8),
			Vector2(3.4, 1.75), Vector2(3.46, 1.5), Vector2(3.48, 0.62)],
		"windows": [[Vector2(1.4, 1.8), Vector2(1.4, 2.6), Vector2(2.95, 2.6), Vector2(3.2, 1.8)]]},
	"coach": {"w": 2.5, "wheel": 0.5, "arches": [-3.9, 3.9], "glass": [4], "seams": [], "shoulder": 1.6,
		"top": [Vector2(-5.75, 0.6), Vector2(-5.77, 0.85), Vector2(-5.72, 3.0), Vector2(-5.5, 3.12), Vector2(5.2, 3.12), Vector2(5.72, 1.6), Vector2(5.76, 0.66)],
		"windows": [[Vector2(-5.20, 1.75), Vector2(-5.20, 2.72), Vector2(-3.98, 2.72), Vector2(-3.98, 1.75)], [Vector2(-3.84, 1.75), Vector2(-3.84, 2.72), Vector2(-2.62, 2.72), Vector2(-2.62, 1.75)], [Vector2(-2.48, 1.75), Vector2(-2.48, 2.72), Vector2(-1.26, 2.72), Vector2(-1.26, 1.75)], [Vector2(-1.12, 1.75), Vector2(-1.12, 2.72), Vector2(0.10, 2.72), Vector2(0.10, 1.75)], [Vector2(0.24, 1.75), Vector2(0.24, 2.72), Vector2(1.46, 2.72), Vector2(1.46, 1.75)], [Vector2(1.60, 1.75), Vector2(1.60, 2.72), Vector2(2.82, 2.72), Vector2(2.82, 1.75)], [Vector2(2.96, 1.75), Vector2(2.96, 2.72), Vector2(4.18, 2.72), Vector2(4.18, 1.75)]]},
}

func van(pos: Vector3, rot_y: float, body_c := Color(0.86, 0.86, 0.84), open := false, side_text := "", stripe: Variant = null, lightbar := false, kind := "van") -> Node3D:
	var spec: Dictionary = VEHICLES[kind]
	var hw: float = spec.w / 2.0
	var wr: float = spec.wheel
	var top: Array = spec.top
	var rear_x: float = top[0].x
	var nose_x: float = top[-1].x
	var roof_y := 0.0
	for p in top:
		roof_y = maxf(roof_y, p.y)
	var v := Node3D.new()
	v.position = pos
	v.rotation.y = rot_y
	add_child(v)
	# the outline: the top as given, then the sill running back from the nose with an arch over each wheel
	var outline := PackedVector2Array(top)
	var first_top := top.size()
	var sill: float = top[-1].y - 0.06
	outline.append(Vector2(nose_x - 0.08, sill))
	var arches: Array = spec.arches.duplicate()
	arches.sort()
	arches.reverse()
	for ax in arches:
		var ar := wr + 0.07
		for i in 9:
			var ang := PI * i / 8.0
			outline.append(Vector2(ax + ar * cos(ang), maxf(sill, wr + ar * sin(ang))))
	outline.append(Vector2(rear_x + 0.08, sill))
	var paint := StandardMaterial3D.new()
	paint.albedo_color = body_c
	paint.metallic = 0.12
	paint.roughness = 0.5
	paint.clearcoat_enabled = true
	paint.clearcoat = 0.2
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.04, 0.055, 0.07)
	glass.metallic = 0.7
	glass.roughness = 0.08
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	if kind == "coach":                           # cabin lights on
		glass.albedo_color = Color(0.5, 0.46, 0.34)
		glass.emission_enabled = true
		glass.emission = Color(1.0, 0.88, 0.6)
		glass.emission_energy_multiplier = 0.9
	var half := func(y: float) -> float:          # the body leans in above the shoulder line
		return hw - 0.09 * smoothstep(spec.shoulder, roof_y, y)
	var body := SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	var panes := SurfaceTool.new()
	panes.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tri := func(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
		if (b - a).cross(c - a).dot(n) > 0.0:       # Godot's front face winds clockwise
			var t := b
			b = c
			c = t
		for p in [a, b, c]:
			st.set_normal(n)
			st.add_vertex(p)
	var idx := Geometry2D.triangulate_polygon(outline)
	for side in [-1.0, 1.0]:
		for i in range(0, idx.size(), 3):
			var q := [outline[idx[i]], outline[idx[i + 1]], outline[idx[i + 2]]]
			tri.call(body, Vector3(q[0].x, q[0].y, side * half.call(q[0].y)), Vector3(q[1].x, q[1].y, side * half.call(q[1].y)),
				Vector3(q[2].x, q[2].y, side * half.call(q[2].y)), Vector3(0, 0, side))
		for win in spec.windows:                    # side windows, a hair proud of the paint
			var w2 := PackedVector2Array(win)
			var wi := Geometry2D.triangulate_polygon(w2)
			for i in range(0, wi.size(), 3):
				var pts := []
				for j in 3:
					var p2: Vector2 = w2[wi[i + j]]
					pts.append(Vector3(p2.x, p2.y, side * (half.call(p2.y) + 0.006)))
				tri.call(panes, pts[0], pts[1], pts[2], Vector3(0, 0, side))
	var clockwise := Geometry2D.is_polygon_clockwise(outline)
	for i in outline.size():
		var p: Vector2 = outline[i]
		var q: Vector2 = outline[(i + 1) % outline.size()]
		var is_rear := i < first_top - 1 and p.x < rear_x + 0.2 and q.x < rear_x + 0.2
		if open and is_rear:
			continue                                # the rear is the doors, built below
		var along := (q - p).normalized()
		var n2 := Vector2(along.y, -along.x) * (-1.0 if clockwise else 1.0)
		var n := Vector3(n2.x, n2.y, 0)
		var a := Vector3(p.x, p.y, half.call(p.y))
		var b := Vector3(q.x, q.y, half.call(q.y))
		var c := Vector3(q.x, q.y, -half.call(q.y))
		var d := Vector3(p.x, p.y, -half.call(p.y))
		if i >= first_top and p.y > sill + 0.001 or (i >= first_top and q.y > sill + 0.001):
			# a wheel arch: only a well at each side, so the load floor runs flat between them
			for side in [-1.0, 1.0]:
				var inner := Vector3(0, 0, side * 0.34)
				var a2 := Vector3(a.x, a.y, side * a.z)
				var b2 := Vector3(b.x, b.y, side * b.z)
				tri.call(body, a2, b2, b2 - inner, n)
				tri.call(body, a2, b2 - inner, a2 - inner, n)
			continue
		tri.call(body, a, b, c, n)
		tri.call(body, a, c, d, n)
		if i in spec.glass:                         # windscreen or rear window: inset from the pillars
			var g := []
			for corner in [[0.1, 1.0], [0.92, 1.0], [0.92, -1.0], [0.1, -1.0]]:
				var e := p.lerp(q, corner[0])
				g.append(Vector3(e.x, e.y, corner[1] * (half.call(e.y) - 0.1)) + n * 0.012)
			tri.call(panes, g[0], g[1], g[2], n)
			tri.call(panes, g[0], g[2], g[3], n)
	var shell := MeshInstance3D.new()
	shell.mesh = body.commit()
	shell.material_override = paint
	v.add_child(shell)
	var win_mesh := MeshInstance3D.new()
	win_mesh.mesh = panes.commit()
	win_mesh.material_override = glass
	v.add_child(win_mesh)
	var dark := Color(0.05, 0.055, 0.06)
	var trim := Color(0.13, 0.13, 0.14)
	# wheels, with a dark well behind each pair so the arches do not show daylight
	for ax in arches:
		for side in [-1.0, 1.0]:
			_into(v, box(Vector3(ax, (sill + wr * 2.0 + 0.07) / 2.0, side * (hw - 0.34)), Vector3(wr * 2.0 + 0.16, wr * 2.0 + 0.07 - sill, 0.02), dark, false))
			_into(v, cyl(Vector3(ax, wr, side * (hw - 0.13)), wr, 0.24, Color(0.045, 0.045, 0.05), 0.95)).rotation.x = PI / 2
			_into(v, cyl(Vector3(ax, wr, side * (hw - 0.005)), wr * 0.6, 0.02, Color(0.55, 0.56, 0.58), 0.35)).rotation.x = PI / 2
			_into(v, cyl(Vector3(ax, wr, side * (hw + 0.006)), wr * 0.2, 0.02, Color(0.2, 0.2, 0.21), 0.5)).rotation.x = PI / 2
	_into(v, box(Vector3((rear_x + nose_x) / 2.0, sill - 0.06, 0), Vector3(nose_x - rear_x - 0.3, 0.1, spec.w - 0.3), dark, false))   # underside
	# bumpers, grille, plates and lamps
	var by: float = top[-1].y + 0.04
	_into(v, box(Vector3(nose_x + 0.03, by, 0), Vector3(0.14, 0.2, spec.w + 0.02), trim, false))
	_into(v, box(Vector3(rear_x - 0.03, by, 0), Vector3(0.14, 0.2, spec.w + 0.02), trim, false))
	_into(v, box(Vector3(nose_x + 0.005, by + 0.3, 0), Vector3(0.03, 0.22, spec.w * 0.5), dark, false))
	_into(v, box(Vector3(nose_x + 0.105, by, 0), Vector3(0.01, 0.12, 0.34), Color(0.9, 0.9, 0.86), false))
	_into(v, box(Vector3(rear_x - 0.105, by + 0.02, 0), Vector3(0.01, 0.12, 0.34), Color(0.9, 0.9, 0.86), false))
	for side in [-1.0, 1.0]:
		_into(v, box(Vector3(nose_x - 0.01, by + 0.32, side * (hw - 0.28)), Vector3(0.05, 0.16, 0.36), Color(0.95, 0.94, 0.85), false, 0.6))
		_into(v, box(Vector3(nose_x - 0.01, by + 0.32, side * (hw - 0.07)), Vector3(0.05, 0.1, 0.1), Color(0.95, 0.55, 0.1), false, 0.3))
		var tail_y: float = by + (0.75 if kind != "car" else 0.38)
		_into(v, box(Vector3(rear_x + 0.0, tail_y, side * (hw - 0.07)), Vector3(0.05, 0.42 if kind != "car" else 0.14, 0.12 if kind != "car" else 0.4), Color(0.55, 0.04, 0.04), false, 0.4))
		# mirror on a stalk, door handles, door lines, dirt along the sill
		var mx: float = top[spec.glass[-1]].x - 0.12
		var my: float = spec.shoulder + 0.14
		_into(v, box(Vector3(mx, my, side * (hw + 0.1)), Vector3(0.05, 0.2 if kind != "car" else 0.1, 0.16), trim, false))
		_into(v, box(Vector3(mx, my - 0.04, side * (hw + 0.02)), Vector3(0.03, 0.03, 0.1), trim, false))
		for sx in spec.seams:
			_into(v, box(Vector3(sx, (spec.shoulder + sill) / 2.0 + 0.1, side * (hw + 0.002)), Vector3(0.012, spec.shoulder - sill - 0.1, 0.004), Color(0.0, 0.0, 0.0, 0.55), false))
			_into(v, box(Vector3(sx - 0.14, spec.shoulder - 0.16, side * (hw + 0.012)), Vector3(0.13, 0.03, 0.02), trim, false))
		_into(v, box(Vector3((rear_x + nose_x) / 2.0, sill + 0.09, side * (hw + 0.003)), Vector3(nose_x - rear_x - 0.2, 0.2, 0.004), Color(0.2, 0.17, 0.13, 0.35), false))
		if stripe != null:
			_into(v, box(Vector3((rear_x + top[spec.glass[-1]].x) / 2.0 - 0.1, spec.shoulder - 0.3, side * (hw + 0.004)), Vector3(top[spec.glass[-1]].x - rear_x - 0.4, 0.2, 0.004), stripe, false))
	# rear doors on vans and trucks
	if kind in ["van", "truck"]:
		var door_h: float = roof_y - sill - 0.16
		for side in [-1.0, 1.0]:
			var hinge := Node3D.new()
			hinge.position = Vector3(rear_x, sill + 0.06 + door_h / 2.0, side * (hw - 0.03))
			v.add_child(hinge)
			if open or kind == "van":
				var leaf := _into(hinge, box(Vector3(0, 0, -side * (hw - 0.04) / 2.0), Vector3(0.05, door_h, hw - 0.05), body_c, false))
				_into(leaf, box(Vector3(-0.03, door_h * 0.22, 0), Vector3(0.012, door_h * 0.3, (hw - 0.05) * 0.7), dark, false))
				_into(leaf, box(Vector3(-0.035, -door_h * 0.1, side * (hw - 0.05) * 0.38), Vector3(0.03, 0.14, 0.03), trim, false))
			if open:
				hinge.rotation.y = side * 1.9
		if open:                                    # load floor, wall lining and the bulkhead behind the seats
			var cab_x: float = top[spec.glass[-1]].x - 0.25
			_into(v, box(Vector3((rear_x + cab_x) / 2.0, sill + 0.05, 0), Vector3(cab_x - rear_x, 0.05, spec.w - 0.08), Color(0.2, 0.2, 0.21), false))
			_into(v, box(Vector3(cab_x, (sill + roof_y) / 2.0, 0), Vector3(0.05, roof_y - sill - 0.1, spec.w - 0.12), Color(0.3, 0.3, 0.31), false))
			for side in [-1.0, 1.0]:
				_into(v, box(Vector3((rear_x + cab_x) / 2.0, sill + 0.5, side * (hw - 0.05)), Vector3(cab_x - rear_x - 0.1, 0.85, 0.02), Color(0.42, 0.36, 0.28), false))
				for rib in 4:
					_into(v, box(Vector3(rear_x + 0.4 + rib * (cab_x - rear_x - 0.6) / 3.0, sill + 1.3, side * (hw - 0.06)), Vector3(0.05, 0.75, 0.03), Color(0.6, 0.6, 0.6), false))
	if side_text != "":
		for side in [-1, 1]:
			var l := Label3D.new()
			l.text = side_text
			l.font_size = 40
			l.pixel_size = 0.004 if kind != "car" else 0.003
			l.modulate = Color(0.12, 0.2, 0.4) if body_c.get_luminance() > 0.4 else Color(0.92, 0.92, 0.9)
			l.outline_size = 0
			l.shaded = true
			l.position = Vector3((rear_x + top[spec.glass[-1]].x) / 2.0 - 0.1, spec.shoulder + (0.3 if kind != "car" else -0.42), side * (half.call(spec.shoulder + 0.3) + 0.012))
			l.rotation.y = 0.0 if side == 1 else PI
			v.add_child(l)
	if lightbar:
		var lx: float = top[spec.glass[-1]].x - 0.5
		_into(v, box(Vector3(lx, roof_y + 0.03, 0), Vector3(0.3, 0.05, 1.2), trim, false))
		for i in 2:
			_into(v, box(Vector3(lx, roof_y + 0.1, -0.3 + i * 0.6), Vector3(0.26, 0.11, 0.56), Color(1.0, 0.1, 0.1) if i == 0 else Color(0.15, 0.3, 1.0), false, 2.5))
	var solid := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(nose_x - rear_x, roof_y, spec.w)
	cs.shape = shape
	cs.position = Vector3((nose_x + rear_x) / 2.0, roof_y / 2.0, 0)
	solid.add_child(cs)
	v.add_child(solid)
	return v

func blanket(pos: Vector3, size: Vector2, color: Color, rot_y := 0.0, lump := 0.1, seed_n := 7) -> MeshInstance3D:
	# A quilted moving blanket thrown down in a heap: a cloth sheet with folds, flat at its edges.
	var noise := FastNoiseLite.new()
	noise.seed = seed_n
	noise.frequency = 2.2
	var nx := 28
	var nz := 20
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := func(i: int, j: int) -> float:
		var edge := minf(minf(i, nx - i), minf(j, nz - j)) / 4.0
		return lump * clampf(edge, 0.0, 1.0) * (0.55 + 0.45 * noise.get_noise_2d(i * 0.09, j * 0.09)) + 0.012
	for i in nx:
		for j in nz:
			for c in [[0, 0], [0, 1], [1, 0], [1, 0], [0, 1], [1, 1]]:
				var a: int = i + c[0]
				var b: int = j + c[1]
				st.set_uv(Vector2(a, b) / 4.0)
				st.add_vertex(Vector3((float(a) / nx - 0.5) * size.x, h.call(a, b), (float(b) / nz - 0.5) * size.y))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var img := Image.create(32, 32, true, Image.FORMAT_RGB8)      # quilting: a grid of stitch lines
	img.fill(Color.WHITE)
	for i in 32:
		img.set_pixel(i, 0, Color(0.55, 0.55, 0.55))
		img.set_pixel(0, i, Color(0.55, 0.55, 0.55))
		img.set_pixel(i, i, Color(0.8, 0.8, 0.8))
	img.generate_mipmaps()
	m.albedo_texture = ImageTexture.create_from_image(img)
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = rot_y
	add_child(mi)
	return mi

func foil_wrap(pos: Vector3, rot_y: float, neck_y := 1.0) -> MeshInstance3D:
	# An emergency blanket round a seated or standing person's shoulders: open at the front, crinkled,
	# falling from the neck over the shoulders to the elbows. `pos` and `rot_y` are the person's.
	var noise := FastNoiseLite.new()
	noise.frequency = 9.0
	var rings := [[0.0, 0.1, 0.15], [-0.05, 0.16, 0.23], [-0.13, 0.2, 0.3], [-0.3, 0.22, 0.31], [-0.5, 0.25, 0.33]]   # drop, depth, width
	var seg := 22
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var at := func(r: int, i: int) -> Vector3:
		var ang := deg_to_rad(52.0 + 256.0 * i / seg)
		var ring: Array = rings[r]
		var crinkle := 1.0 + 0.07 * noise.get_noise_2d(i * 0.13, r * 0.31)
		return Vector3(ring[2] * sin(ang) * crinkle, neck_y + ring[0] + 0.02 * noise.get_noise_2d(i * 0.2, r * 0.9), ring[1] * cos(ang) * crinkle - 0.02)
	for r in rings.size() - 1:
		for i in seg:
			for c in [[0, 0], [1, 0], [0, 1], [0, 1], [1, 0], [1, 1]]:
				st.add_vertex(at.call(r + c[0], i + c[1]))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.74, 0.62)
	m.metallic = 0.85
	m.roughness = 0.38
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = rot_y
	add_child(mi)
	return mi

func tape_roll(pos: Vector3, color := Color(0.56, 0.57, 0.6), flat := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.038
	t.outer_radius = 0.062
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = 0.5
	m.roughness = 0.35
	mi.material_override = m
	mi.scale = Vector3(1, 2.0, 1)                 # a roll is taller than a ring
	mi.position = pos + Vector3(0, 0.025, 0)
	if not flat:
		mi.rotation.x = PI / 2
	add_child(mi)
	return mi

func sneaker(pos: Vector3, rot_y := 0.0, color := Color(0.93, 0.93, 0.9), on_side := false) -> Node3D:
	# A low canvas sneaker, about a women's size seven: sole, toe cap, upper, collar, laces.
	var s := Node3D.new()
	s.position = pos
	s.rotation.y = rot_y
	if on_side:
		s.rotation.x = PI / 2 - 0.15
		s.position.y += 0.045
	add_child(s)
	var rubber := Color(0.82, 0.82, 0.8)
	_into(s, ball(Vector3(0, 0.014, 0), 0.5, rubber, 0.0, Vector3(0.25, 0.028, 0.092)))          # sole
	_into(s, ball(Vector3(0.012, 0.045, 0), 0.5, color, 0.0, Vector3(0.215, 0.075, 0.082)))      # upper
	_into(s, ball(Vector3(0.085, 0.034, 0), 0.5, rubber, 0.0, Vector3(0.075, 0.05, 0.086)))      # toe cap
	_into(s, cyl(Vector3(-0.065, 0.07, 0), 0.036, 0.05, color))                                   # ankle collar
	_into(s, cyl(Vector3(-0.065, 0.097, 0), 0.03, 0.006, Color(0.12, 0.12, 0.13)))                # the dark inside
	for i in 4:
		_into(s, box(Vector3(0.0 + i * 0.022, 0.078 - i * 0.006, 0), Vector3(0.006, 0.004, 0.05), Color(0.98, 0.98, 0.96), false))
	_into(s, box(Vector3(0.0, 0.03, 0.0), Vector3(0.2, 0.006, 0.094), Color(0.75, 0.1, 0.1), false))   # a red stripe round the sole
	return s

func strobe(pos: Vector3, a := Color(1.0, 0.15, 0.1), b := Color(0.15, 0.3, 1.0), energy := 2.5, rng := 14.0) -> void:
	# Emergency lights: two colours taking turns.
	var la := omni(pos, a, energy, rng)
	var lb := omni(pos, b, 0.0, rng)
	flickers.append([la, 0.0, 0.0])
	la.set_meta("strobe", [lb, energy])

func _strobes() -> void:
	for f in flickers:
		var l: Light3D = f[0]
		if l.has_meta("strobe"):
			var on := fmod(_t, 0.84) < 0.42
			l.light_energy = l.get_meta("strobe")[1] if on else 0.0
			(l.get_meta("strobe")[0] as Light3D).light_energy = 0.0 if on else l.get_meta("strobe")[1]

func _mesh_panel(pos: Vector3, size: Vector2, rot_y: float) -> void:
	# Chain link: a diamond wire pattern cut out of a flat panel.
	if not _cache.has("wire"):
		var img := Image.create(32, 32, true, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for i in 32:
			for w in 2:
				img.set_pixel(i, (i + w) % 32, Color(0.6, 0.62, 0.65, 1))
				img.set_pixel(i, (31 - i + w) % 32, Color(0.6, 0.62, 0.65, 1))
		img.generate_mipmaps()
		_cache["wire"] = ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _cache["wire"]
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.3
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.metallic = 0.5
	m.roughness = 0.5
	m.uv1_scale = Vector3(size.x * 9.0, size.y * 9.0, 1)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	blocker(pos, Vector3(size.x, size.y, 0.1) if rot_y == 0.0 else Vector3(0.1, size.y, size.x))
