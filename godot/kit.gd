class_name Kit
extends Node3D
## Building blocks shared by every location: surfaces, props, lights, people, camera shots.
## A location script extends this and fills in `build()`. The game reads `shots`, `cast`,
## `tracks`, `spots`, `talk` and `spawn` from it.

const AMBER := Color(0.95, 0.71, 0.27)
const INK := Color(0.10, 0.10, 0.12)
# Detective Okonkwo, the player. Her model is used for nobody else, so she always reads as herself.
const OKONKWO_MODEL := "elizabeth"
const OKONKWO_LOOK := {"Shirt": Color(0.25, 0.25, 0.3), "Pants": Color(0.3, 0.3, 0.33)}
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
	for part in look:
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			if str(mi.name).contains(part):
				var m := (mi as MeshInstance3D).mesh
				for i in m.get_surface_count():
					var d: StandardMaterial3D = m.surface_get_material(i).duplicate()
					d.albedo_color = look[part]
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
	return n

func robe(n: Node3D, color := Color(0.03, 0.03, 0.035)) -> void:
	# A judge's robe worn over a suit: a loose black body, a yoke over the shoulders and bell sleeves,
	# each piece fixed to a bone so it moves with the person.
	if n == null:
		return
	var skel: Skeleton3D = n.find_child("Skeleton3D", true, false)
	var k := 1.0 / skel.global_transform.basis.get_scale().x
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = color
	cloth.roughness = 0.92
	# [bone, top radius, bottom radius, length, offset along the bone, squash]
	for part in [["Spine1", 0.2, 0.36, 0.8, -0.12, Vector3(1.0, 1.0, 0.74)], ["Spine2", 0.13, 0.27, 0.2, 0.17, Vector3(1.0, 1.0, 0.72)],
			["LeftArm", 0.1, 0.095, 0.3, 0.14, Vector3.ONE], ["RightArm", 0.1, 0.095, 0.3, 0.14, Vector3.ONE],
			["LeftForeArm", 0.095, 0.15, 0.25, 0.11, Vector3.ONE], ["RightForeArm", 0.095, 0.15, 0.25, 0.11, Vector3.ONE]]:
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

func van(pos: Vector3, rot_y: float, body_c := Color(0.86, 0.86, 0.84), open := false, side_text := "", stripe: Variant = null, lightbar := false) -> Node3D:
	# A panel van built from boxes: nose toward +X before turning, rear doors at -X. `open` swings the rear doors.
	var v := Node3D.new()
	v.position = pos
	v.rotation.y = rot_y
	add_child(v)
	var dark := Color(0.05, 0.06, 0.07)
	var parts := [
		[Vector3(-0.55, 1.22, 0), Vector3(3.5, 1.75, 1.9), body_c],             # cargo box
		[Vector3(1.75, 1.0, 0), Vector3(1.1, 1.3, 1.9), body_c],                # cab
		[Vector3(2.55, 0.72, 0), Vector3(0.6, 0.72, 1.86), body_c],             # hood
		[Vector3(2.32, 1.38, 0), Vector3(0.06, 0.55, 1.7), dark],               # windshield
		[Vector3(1.8, 1.32, 0.955), Vector3(0.8, 0.5, 0.02), dark],             # side windows
		[Vector3(1.8, 1.32, -0.955), Vector3(0.8, 0.5, 0.02), dark],
		[Vector3(2.88, 0.42, 0), Vector3(0.08, 0.2, 1.9), Color(0.2, 0.2, 0.21)],   # bumpers
		[Vector3(-2.33, 0.42, 0), Vector3(0.08, 0.2, 1.9), Color(0.2, 0.2, 0.21)],
		[Vector3(0, 0.3, 0), Vector3(5.0, 0.12, 1.7), Color(0.1, 0.1, 0.1)],    # underside
	]
	if stripe != null:
		parts.append([Vector3(-0.55, 1.1, 0.96), Vector3(3.5, 0.22, 0.01), stripe])
		parts.append([Vector3(-0.55, 1.1, -0.96), Vector3(3.5, 0.22, 0.01), stripe])
	if open:
		parts[0] = [Vector3(-0.55, 2.07, 0), Vector3(3.5, 0.06, 1.9), body_c]   # roof, sides and floor instead of a solid block
		parts.append([Vector3(-0.55, 1.22, 0.93), Vector3(3.5, 1.75, 0.05), body_c])
		parts.append([Vector3(-0.55, 1.22, -0.93), Vector3(3.5, 1.75, 0.05), body_c])
		parts.append([Vector3(-0.55, 0.4, 0), Vector3(3.5, 0.08, 1.9), Color(0.25, 0.25, 0.26)])
		parts.append([Vector3(1.18, 1.22, 0), Vector3(0.05, 1.75, 1.9), Color(0.3, 0.3, 0.31)])
	for p in parts:
		_into(v, box(p[0], p[1], p[2], false))
	for wx in [-1.5, 1.9]:
		for wz in [-0.9, 0.9]:
			_into(v, cyl(Vector3(wx, 0.36, wz), 0.36, 0.24, Color(0.06, 0.06, 0.06), 0.9)).rotation.x = PI / 2
			_into(v, cyl(Vector3(wx, 0.36, wz * 1.14), 0.17, 0.02, Color(0.6, 0.6, 0.62), 0.4)).rotation.x = PI / 2
	for hz in [-0.7, 0.7]:
		_into(v, box(Vector3(2.86, 0.82, hz), Vector3(0.03, 0.14, 0.26), Color(0.9, 0.9, 0.8), false))
		_into(v, box(Vector3(-2.31, 1.0, hz * 1.25), Vector3(0.02, 0.3, 0.1), Color(0.5, 0.05, 0.05), false))
	for side in [-1, 1]:                                                        # rear doors
		var hinge := Node3D.new()
		hinge.position = Vector3(-2.32, 1.22, side * 0.95)
		v.add_child(hinge)
		var d := _into(hinge, box(Vector3(0, 0, -side * 0.465), Vector3(0.05, 1.6, 0.93), body_c, false))
		_into(d, box(Vector3(-0.03, 0.4, 0), Vector3(0.02, 0.4, 0.6), dark, false))
		if open:
			hinge.rotation.y = side * 1.9
	if side_text != "":
		for side in [-1, 1]:
			var l := Label3D.new()
			l.text = side_text
			l.font_size = 40
			l.pixel_size = 0.004
			l.modulate = Color(0.12, 0.2, 0.4)
			l.outline_size = 0
			l.shaded = true
			l.position = Vector3(-0.55, 1.55, side * 0.957)
			l.rotation.y = 0.0 if side == 1 else PI
			v.add_child(l)
	if lightbar:
		for i in 2:
			_into(v, box(Vector3(1.6, 1.72, -0.4 + i * 0.8), Vector3(0.25, 0.12, 0.5), Color(1.0, 0.1, 0.1) if i == 0 else Color(0.15, 0.3, 1.0), false, 2.5))
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.3, 2.1, 2.0)
	cs.shape = shape
	cs.position = Vector3(0.25, 1.05, 0)
	body.add_child(cs)
	v.add_child(body)
	return v

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
