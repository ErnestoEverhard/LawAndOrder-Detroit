extends Node
## DEAD SIGNAL — the game: plays the story graph over 3D locations.
## Dialogue with camera cuts, timed choices, action prompts, walk-around searches, flowcharts, endings.
##
## Testing switches (after `--`):
##   --at <node>            start at a story node instead of the title screen
##   --set k=v,k=v          preset story flags / clues (clue.<id>=1, strength=40, late=2, trust=2, f flags otherwise)
##   --auto [skill 0-1]     play by itself with random choices, fast; quits at the ending
##   --robot               play through the real input paths: keys are injected, and in searches the player is aimed at things
##   --shots <dir>          save a picture of every camera shot the run reaches
##   --stage <set:stage>    build one location, save all of its shots to --shots dir, and quit

const AMBER := Kit.AMBER
const PAPER := Color(0.91, 0.9, 0.87)
const DIM := Color(0.62, 0.61, 0.58)
const WHO_COLOR := {"OKONKWO": Color(0.95, 0.71, 0.27), "COLE": Color(0.95, 0.71, 0.27), "REYES": Color(0.55, 0.75, 0.95),
	"HARLAN": Color(0.85, 0.42, 0.38), "PRUITT": Color(0.85, 0.42, 0.38), "JUDGE": Color(0.8, 0.78, 0.9)}
const NAMES := {"OKONKWO": "DET. NADIA OKONKWO", "REYES": "DET. SAM REYES", "PRIYA": "PRIYA NAIR", "EVAN": "EVAN KESSLER",
	"DIAZ": "CAPT. DIAZ", "HARLAN": "WADE HARLAN", "TESSA": "TESSA BRANDT", "COLE": "ADA IMANI COLE", "JUDGE": "JUDGE ABRAMS", "PRUITT": "DANA PRUITT, FOR THE DEFENSE"}
const KEYS := {KEY_SPACE: "SPACE", KEY_ENTER: "ENTER", KEY_KP_ENTER: "ENTER", KEY_ESCAPE: "ESC", KEY_W: "W", KEY_A: "A", KEY_S: "S", KEY_D: "D", KEY_E: "E",
	KEY_1: "1", KEY_2: "2", KEY_3: "3", KEY_KP_1: "1", KEY_KP_2: "2", KEY_KP_3: "3", KEY_F: "F"}
const QKEYS := ["W", "A", "S", "D", "E", "SPACE"]

var FONT: Font = load("res://assets/fonts/SpecialElite-Regular.ttf")
var story: Story
var s: CaseState
var loc: Kit                       # the current location
var cur_bg := ""
var cam: Camera3D
var drift := Vector3.ZERO          # slow push-in on the current shot
var drifted := 0.0
var clock := 0.0                   # game time; stops while paused
var events: Array[String] = []     # key presses waiting to be read
var auto := false
var robot := false
var robot_t := 0.0
var robot_i := 0
var robot_exit := ""
var skill := 0.7
var shots_dir := ""
var shot_seen := {}
var player: CharacterBody3D
var ray: RayCast3D
var running := false

# interface
var ui: Control
var hud: Control
var hud_chapter: Label
var hud_strength: Label
var hud_bar: ProgressBar
var toasts: VBoxContainer
var dialog: PanelContainer
var who_label: Label
var text_label: Label
var adv_label: Label
var choices: HBoxContainer
var timer_bar: ProgressBar
var prompt_label: Label
var crosshair: Label
var roam_status: Label
var card: Control
var card_box: VBoxContainer
var qte: Control
var qte_title: Label
var qte_text: Label
var qte_key: Label
var qte_act: Label
var qte_how: Label
var qte_time: ProgressBar
var qte_fill: ProgressBar
var qte_marks: Label
var overlay: Control
var overlay_box: VBoxContainer
var fade: ColorRect
var pause_menu: Control
var sfx: AudioStreamPlayer
var amb: AudioStreamPlayer
var tense: AudioStreamPlayer
var tense_fade: Tween
const AMB_DB := {"room": -14.0, "city_night": -12.0, "rail_yard": -12.0, "fire": -8.0, "office": -16.0, "courtroom": -18.0, "bus_station": -14.0, "dawn": -16.0}
const CUES := {       # words in narration → [sound, volume]
	"knocks": ["door_knock", -6.0], "slams the door": ["thud", -6.0], "handcuffs": ["handcuffs", -6.0], "sirens": ["siren", -12.0],
	"gavel": ["gavel", -6.0], "hit the g": ["thud", -5.0], "glass": ["glass", -8.0], "radio": ["radio", -10.0], "phone rings": ["phone_ring", -8.0],
	"fence": ["fence", -8.0], "van door": ["van_door", -6.0], "rear doors": ["van_door", -6.0], "gallery": ["crowd_gasp", -12.0],
	"photograph": ["camera", -8.0], "door opens": ["door_open", -8.0],
}
const CHASE_TRACKS := ["yards", "chase", "gate"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	story = Story.new()
	cam = Camera3D.new()
	cam.fov = 50
	add_child(cam)
	_build_ui()
	_audio()
	var args := OS.get_cmdline_user_args()
	var at := ""
	var preset := ""
	var stage := ""
	var i := 0
	while i < args.size():
		match args[i]:
			"--at":
				at = args[i + 1]
				i += 1
			"--set":
				preset = args[i + 1]
				i += 1
			"--shots":
				shots_dir = args[i + 1]
				DirAccess.make_dir_recursive_absolute(shots_dir)
				i += 1
			"--stage":
				stage = args[i + 1]
				i += 1
			"--robot":
				robot = true
			"--auto":
				auto = true
				if i + 1 < args.size() and args[i + 1].is_valid_float():
					skill = float(args[i + 1])
					i += 1
		i += 1
	if auto or robot:
		Engine.time_scale = 6.0
	if stage != "":
		_stage_shots(stage, preset)
	elif at != "" or auto:
		_new_state(preset)
		_run(at if at != "" else Story.START)
	else:
		_title()

func _new_state(preset := "") -> void:
	s = CaseState.new()
	s.notice.connect(_toast)
	for kv in preset.split(",", false):
		var k := kv.get_slice("=", 0)
		var v := kv.get_slice("=", 1)
		if k.begins_with("clue."):
			s.clues[k.substr(5)] = k.substr(5)
		elif k in ["strength", "late", "trust", "chapter"]:
			s.set(k, int(v))
		elif v.is_valid_int():
			s.f[k] = int(v)
		elif v in ["true", "false"]:
			s.f[k] = v == "true"
		else:
			s.f[k] = v

func _process(delta: float) -> void:
	clock += delta
	if robot:
		robot_t += delta
		if robot_t > 0.35:
			robot_t = 0.0
			robot_i += 1
			if player != null:
				_robot_aim()
			elif qte.visible and qte_key.get_parent().visible:
				for i in 4:
					events.append(qte_key.text)
			else:
				events.append(["SPACE", "1", "SPACE", "2", "SPACE", "3"][robot_i % 6])
	if drift != Vector3.ZERO and drifted < 0.3 and cam.current:
		cam.position += drift * delta * 0.018
		drifted += delta * 0.018

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and KEYS.has(e.physical_keycode):
		var k: String = KEYS[e.physical_keycode]
		if k == "ESC" and running:
			_pause(true)
		else:
			events.append(k)
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and player == null:
		events.append("CLICK")

func _robot_aim() -> void:
	# stands the player in front of the next thing worth pressing E on, looking at it
	var target: Node3D = null
	var spots_left := 0
	for c in loc.get_children():
		if c is StaticBody3D and c.has_meta("spot") and not c.has_meta("used"):
			spots_left += 1
			if target == null:
				target = c
	if target == null or roam_status.text.count("●") == 0:
		for c in loc.get_children():
			if c is StaticBody3D and c.has_meta("talk") and c.get_meta("talk") == robot_exit:
				target = c
	if target == null:
		return
	var at: Vector3 = target.global_position
	var eye := Vector3(at.x, 1.62, at.z) + (Vector3(loc.spawn[0].x, 0, loc.spawn[0].z) - Vector3(at.x, 0, at.z)).normalized() * 1.4
	var aim := at + Vector3(0, 0.9 if target.has_meta("talk") else 0.0, 0)
	if target.has_meta("talk") and loc.cast.has(target.get_meta("talk")):      # people are approached from the front
		var r: float = loc.cast[target.get_meta("talk")].node.rotation.y
		eye = Vector3(at.x, 1.62, at.z) + Vector3(sin(r), 0, cos(r)) * 1.3
	for k in 8:                                # try standing on different sides until nothing is in the way
		var q := PhysicsRayQueryParameters3D.create(eye, aim, 3, [player.get_rid()])
		var hit := loc.get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty() or hit.collider == target:
			break
		eye = Vector3(at.x, 1.62, at.z) + Vector3(sin(k * PI / 4), 0, cos(k * PI / 4)) * 1.4
	player.global_position = Vector3(eye.x, 0, eye.z)
	player.rotation.y = atan2(eye.x - at.x, eye.z - at.z)
	player.cam.rotation.x = atan2(at.y + (0.9 if target.has_meta("talk") else 0.0) - 1.62, 1.4)
	if robot_i % 3 == 0:
		events.append("E")
		if OS.has_environment("ROBOT_DEBUG"):
			print("robot aims at ", target.get_meta("spot").name if target.has_meta("spot") else target.get_meta("talk"), " ray hits ", ray.get_collider(), " left ", roam_status.text)

func wait(sec: float) -> void:
	var until := clock + sec
	while clock < until:
		await get_tree().process_frame

func _key(accept: Array) -> String:
	# waits for one of the given keys
	events.clear()
	while true:
		await get_tree().process_frame
		while not events.is_empty():
			var k: String = events.pop_front()
			if k in accept:
				return k
	return ""

# ── locations and camera ─────────────────────────────────────────

func _go(bg: String, quick := false) -> void:
	if bg == cur_bg or bg == "":
		return
	if cur_bg != "" and not quick:
		await _fade(1.0, 0.35)
	if loc:
		loc.queue_free()
		loc = null
		await get_tree().process_frame
	cur_bg = bg
	loc = (load("res://sets/%s.gd" % bg.get_slice(":", 0)) as GDScript).new()
	loc.stage = bg.get_slice(":", 1)
	loc.st = s
	add_child(loc)
	loc.build()
	_ambience(loc.ambience)
	cam.current = true
	_shot("wide")
	await get_tree().process_frame
	await get_tree().process_frame
	if not quick:
		await _fade(0.0, 0.5)

func _shot(name: String) -> bool:
	if loc == null or not loc.shots.has(name):
		return false
	var sh: Array = loc.shots[name]
	cam.position = sh[0]
	cam.look_at(sh[1])
	cam.fov = sh[2]
	drift = -cam.global_transform.basis.z
	drifted = 0.0
	if shots_dir != "" and not shot_seen.has(cur_bg + name):
		shot_seen[cur_bg + name] = 1
		_snap("%s_%s" % [cur_bg.replace(":", "-"), name])
	return true

func _snap(label: String) -> void:
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots_dir.path_join(label + ".png"))

func _fade(to: float, sec: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", to, sec)
	await wait(sec)

func _stage_shots(bg: String, preset: String) -> void:
	_new_state(preset)
	hud.visible = false
	await _go(bg, true)
	for i in 30:
		await get_tree().process_frame
	for name in loc.shots:
		_shot(name)
		for i in 8:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shots_dir.path_join("%s_%s.png" % [bg.replace(":", "-"), name]))
	for tr in loc.tracks:
		for j in loc.tracks[tr].size():
			cam.position = loc.tracks[tr][j][0]
			cam.look_at(loc.tracks[tr][j][1])
			cam.fov = 62
			loc.on_step(tr, j)
			for i in 8:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(shots_dir.path_join("%s_track-%s-%d.png" % [bg.replace(":", "-"), tr, j]))
	get_tree().quit()

# ── the story loop ───────────────────────────────────────────────

func _res(v: Variant) -> Variant:
	return v.call(s) if v is Callable else v

func _run(id: String) -> void:
	running = true
	hud.visible = true
	while id != "":
		var n: Dictionary = story.N[id]
		s.mark(id)
		if n.has("chapter"):
			s.chapter = n.chapter
		_hud()
		match n.type:
			"card":
				await _card(_res(n.lines), n.bg)
				id = n.next
			"scene":
				await _go(n.bg)
				if n.do != null:
					n.do.call(s)
					_hud()
				for b in _res(n.beats):
					if b != null:
						await _say(b[0], b[1], b[2] if b.size() > 2 else "")
				id = _res(n.next)
			"choice":
				var pick: Dictionary = await _choose(n)
				if pick.get("do") != null:
					pick.do.call(s)
				id = pick.next
			"roam":
				await _go(n.bg)
				await _roam(n)
				id = n.next
			"qte":
				await _go(n.bg)
				var r: Dictionary = await _qte(n)
				if n.has("do"):
					n.do.call(s, r)
				id = n.next.call(s, r) if n.next is Callable else n.next
			"branch":
				id = n.next.call(s)
			"chapterEnd":
				await _flowchart(n.chapter, true)
				id = n.next
			"ending":
				await _go(n.bg)
				await _ending(n)
				id = ""
	running = false
	if auto or robot:
		print("AUTO RUN FINISHED strength=%d clues=%d late=%d" % [s.strength, s.clues.size(), s.late])
		await wait(0.5)
		get_tree().quit()
	else:
		_restart()

func _restart() -> void:
	cur_bg = ""
	if loc:
		loc.queue_free()
		loc = null
	_title()

# ── title, cards ─────────────────────────────────────────────────

func _title() -> void:
	_new_state()
	hud.visible = false
	fade.color.a = 1.0
	await _go("yard:title", true)
	_shot("title")
	_fade(0.0, 1.5)
	_overlay_open(0.35)
	_olabel("AN INTERACTIVE PROCEDURAL", 16, DIM)
	_olabel("DEAD SIGNAL", 84, PAPER)
	_olabel("A student doesn't come home. You have one night to find her, and three months to make it stick.\nEvery choice is timed. Every shortcut has a price in court.", 20, PAPER)
	_olabel("", 10, DIM)
	_olabel("[ SPACE ]  OPEN THE CASE FILE", 24, AMBER)
	_olabel("", 10, DIM)
	_olabel("SPACE advance    1–3 choose    W A S D E SPACE action prompts    mouse + WASD to walk    ESC pause", 15, DIM)
	_olabel("Contains themes of stalking and abduction. Nothing graphic is depicted.", 14, DIM)
	await _key(["SPACE", "ENTER", "CLICK"])
	_blip(520)
	await _fade(1.0, 0.5)
	overlay.visible = false
	_run(Story.START)

func _card(lines: Array, bg: String) -> void:
	_hide_all()
	await _fade(1.0, 0.4)
	card.visible = true
	for c in card_box.get_children():
		c.queue_free()
	for i in lines.size():
		var l := _label(lines[i], 30 if i == 0 else 20, PAPER if i == 0 else (AMBER if lines[i].begins_with("—") else DIM))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		card_box.add_child(l)
		create_tween().tween_property(l, "modulate:a", 1.0, 0.5)
		_blip(300 + i * 40, 0.05)
		await wait(0.55)
	await _go_behind(bg)
	if not auto:
		await _key_or(4.0)
	card.visible = false
	hud.visible = true
	await _fade(0.0, 0.6)

func _go_behind(bg: String) -> void:
	# builds the next location while the card is on screen
	if bg != cur_bg:
		await get_tree().process_frame
		if loc:
			loc.queue_free()
			loc = null
		cur_bg = ""
		await get_tree().process_frame
		fade.color.a = 1.0
		await _go(bg, true)

func _key_or(sec: float) -> void:
	# resumes on SPACE / click, or after `sec` seconds
	var until := clock + sec
	events.clear()
	while clock < until:
		await get_tree().process_frame
		for k in events:
			if k in ["SPACE", "ENTER", "CLICK"]:
				events.clear()
				return
		events.clear()

# ── dialogue ─────────────────────────────────────────────────────

func _say(who: String, text: String, shot := "") -> void:
	_hide_all()
	if shot != "":
		_shot(shot)
	elif who != "" and loc.shots.has(who):
		_shot(who)
	if who == "":
		_cue(text)
	loc.speaking(who, true)
	dialog.visible = true
	who_label.text = NAMES.get(who, who)
	who_label.visible = who != ""
	who_label.add_theme_color_override("font_color", WHO_COLOR.get(who, Color(0.8, 0.85, 0.8)))
	text_label.add_theme_color_override("font_color", PAPER if who != "" else Color(0.78, 0.8, 0.86))
	text_label.text = text
	text_label.visible_characters = 0
	adv_label.visible = false
	events.clear()
	var shown := 0.0
	var done := false
	if auto:
		text_label.visible_characters = -1
		await wait(0.25)
		loc.speaking(who, false)
		return
	while true:
		await get_tree().process_frame
		if not done:
			shown += get_process_delta_time() * 75.0
			text_label.visible_characters = int(shown)
			if int(shown) >= text.length():
				done = true
				text_label.visible_characters = -1
				adv_label.visible = true
		var hit := false
		for k in events:
			if k in ["SPACE", "ENTER", "CLICK"]:
				hit = true
		events.clear()
		if hit:
			if done:
				break
			done = true
			text_label.visible_characters = -1
			adv_label.visible = true
	loc.speaking(who, false)
	_blip(440, 0.03, 0.02)

func _hide_all() -> void:
	dialog.visible = false
	choices.visible = false
	timer_bar.visible = false
	qte.visible = false
	prompt_label.text = ""
	crosshair.visible = false
	roam_status.visible = false

# ── timed choices: the clock only starts after you have had time to read ─────

func _choose(n: Dictionary) -> Dictionary:
	_hide_all()
	dialog.visible = true
	who_label.visible = false
	text_label.add_theme_color_override("font_color", Color(0.78, 0.8, 0.86))
	text_label.text = n.prompt
	text_label.visible_characters = -1
	adv_label.visible = false
	for c in choices.get_children():
		c.queue_free()
	choices.visible = true
	var ok: Array = []
	var chars: int = n.prompt.length()
	for i in n.options.size():
		var o: Dictionary = n.options[i]
		var can: bool = o.req == null or o.req.call(s)
		ok.append(can)
		var sub: String = o.sub if can else o.lock
		chars += o.label.length() + sub.length()
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", _panel(Color(0.05, 0.06, 0.09, 0.92), AMBER if can else Color(0.3, 0.3, 0.32), 14))
		var v := VBoxContainer.new()
		p.add_child(v)
		v.add_child(_label("[%d]  %s%s" % [i + 1, "" if can else "LOCKED — ", o.label], 20, AMBER if can else DIM))
		var sl := _label(sub, 15, PAPER if can else DIM)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sl.custom_minimum_size.x = 200
		v.add_child(sl)
		choices.add_child(p)
	if auto:
		await wait(0.3)
		choices.visible = false
		var live := []
		for i in ok.size():
			if ok[i]:
				live.append(n.options[i])
		return n.timeout if (randf() < 0.08 or live.is_empty()) else live[randi() % live.size()]
	var read_until := clock + minf(9.0, 2.0 + chars * 0.045)
	var deadline := -1.0
	timer_bar.visible = n.timer > 0
	timer_bar.value = 100
	events.clear()
	var pick: Dictionary = {}
	while pick.is_empty():
		await get_tree().process_frame
		if n.timer > 0 and deadline < 0 and clock >= read_until:
			deadline = clock + n.timer
			_tension(true)
		if deadline > 0:
			timer_bar.value = maxf(0.0, (deadline - clock) / n.timer * 100.0)
			if clock >= deadline:
				_blip(120, 0.3)
				pick = n.timeout
		for k in events:
			if k in ["1", "2", "3"] and int(k) <= ok.size() and ok[int(k) - 1]:
				pick = n.options[int(k) - 1]
		events.clear()
	_blip(600, 0.06)
	_tension(false)
	choices.visible = false
	timer_bar.visible = false
	return pick

# ── walk-around search ───────────────────────────────────────────

func _roam(n: Dictionary) -> void:
	_hide_all()
	var left: int = n.budget
	var marks := {}
	if auto:
		var pool: Array = n.hotspots.duplicate()
		pool.shuffle()
		for h in pool.slice(0, n.budget if randf() < 0.8 else randi() % (n.budget + 1)):
			if not loc.spots.has(h.name):
				push_error("no spot for hotspot " + h.name)
			h.do.call(s)
		await wait(0.3)
		return
	player = CharacterBody3D.new()
	player.set_script(load("res://player.gd"))
	player.position = loc.spawn[0]
	player.rotation.y = loc.spawn[1]
	loc.add_child(player)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -2.8)
	ray.collision_mask = 3
	player.cam.add_child(ray)
	for h in n.hotspots:
		var sp: Dictionary = loc.spots[h.name]
		var body := StaticBody3D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		body.position = sp.pos
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = sp.size
		cs.shape = shape
		body.add_child(cs)
		body.set_meta("spot", h)
		var mark := loc.ball(Vector3.ZERO, 0.045, AMBER, 1.6)
		loc.remove_child(mark)
		mark.position = Vector3(0, sp.size.y / 2.0 + 0.12, 0)
		body.add_child(mark)
		loc.add_child(body)
		marks[h.name] = body
		var tw := mark.create_tween().set_loops()
		tw.tween_property(mark, "scale", Vector3.ONE * 1.6, 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(mark, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	crosshair.visible = true
	roam_status.visible = true
	_info(n.title, n.intro)
	var exit_who: String = n.exit.talk
	robot_exit = exit_who
	var asked_leave := false
	events.clear()
	while true:
		await get_tree().process_frame
		roam_status.text = "TIME LEFT  %s%s" % ["●".repeat(left), "○".repeat(n.budget - left)]
		var hit: StaticBody3D = ray.get_collider() as StaticBody3D if ray.is_colliding() else null
		var target := ""
		if hit and hit.has_meta("talk"):
			target = "talk"
			var w: String = hit.get_meta("talk")
			prompt_label.text = "[ E ]  %s %s" % ["Leave with" if (w == exit_who and (asked_leave or left == 0)) else "Talk to", w.capitalize()]
		elif hit and hit.has_meta("spot") and left > 0 and not hit.has_meta("used"):
			target = "spot"
			prompt_label.text = "[ E ]  Examine the %s" % hit.get_meta("spot").name.to_lower()
		else:
			prompt_label.text = ""
		var pressed := false
		for k in events:
			if k == "E":
				pressed = true
		events.clear()
		if not pressed:
			continue
		if target == "spot":
			var h: Dictionary = hit.get_meta("spot")
			hit.set_meta("used", true)
			hit.get_child(1).visible = false
			left -= 1
			asked_leave = false
			h.do.call(s)
			_hud()
			_blip(520, 0.08)
			_info(h.name.to_upper(), h.text + ("\n\n" + n.spent if left == 0 else ""))
		elif target == "talk":
			var w: String = hit.get_meta("talk")
			if w == exit_who and (left == 0 or asked_leave):
				break
			var line: String = loc.talk[w].call(left, n.budget) if loc.talk.has(w) else "..."
			if w == exit_who:
				asked_leave = true
				line += "\n\n" + n.exit.early + " Press E again to leave."
			_info(NAMES.get(w, w), line)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _fade(1.0, 0.3)
	for b in marks.values():
		b.queue_free()
	player.queue_free()
	player = null
	_hide_all()
	cam.current = true
	_shot("wide")
	await _fade(0.0, 0.3)

func _info(title: String, text: String) -> void:
	dialog.visible = true
	who_label.visible = true
	who_label.text = title
	who_label.add_theme_color_override("font_color", AMBER)
	text_label.add_theme_color_override("font_color", PAPER)
	text_label.text = text
	text_label.visible_characters = -1
	adv_label.visible = false

# ── action prompts ───────────────────────────────────────────────
# press: hit the key once.  mash: tap it n times.  hold: keep it down until the bar fills.

func _qte(n: Dictionary) -> Dictionary:
	_hide_all()
	var scale: float = n.scale.call(s) if n.has("scale") else 1.0
	var track: Array = loc.tracks.get(n.get("track", ""), [])
	var fails := 0
	qte.visible = true
	qte_title.text = n.title
	qte_marks.text = ""
	qte_key.get_parent().visible = false
	qte_text.text = "GET READY"
	var chase: bool = n.get("track", "") in CHASE_TRACKS
	_tension(true, "footsteps_run" if chase else "heartbeat", -6.0 if chase else -8.0)
	if not track.is_empty():
		cam.position = track[0][0]
		cam.look_at(track[0][1])
		cam.fov = 62
		drift = Vector3.ZERO
	loc.on_step(n.get("track", ""), 0)
	await wait(0.4 if auto else 1.4)
	for i in n.steps.size():
		var st: Dictionary = n.steps[i]
		qte_text.text = st.text
		var total: float = (st.ms * scale + (st.hold if st.type == "hold" else 0)) / 1000.0
		var move: Tween = null
		if track.size() > i + 1:
			loc.on_step(n.get("track", ""), i + 1)
			move = create_tween().set_parallel()
			move.tween_property(cam, "position", track[i + 1][0], total).set_trans(Tween.TRANS_SINE)
			move.tween_method(func(t: float): cam.look_at((track[i][1] as Vector3).lerp(track[i + 1][1], t)), 0.0, 1.0, total)
		await wait(0.15 if auto else 0.6)
		var ok: bool = await _qte_step(st, scale)
		if move and move.is_running():
			move.set_speed_scale(6.0)          # finish the move quickly once the step is decided
		if not ok:
			fails += 1
			_shake()
		qte_marks.text += "✓ " if ok else "✗ "
		_blip(660 if ok else 140, 0.14 if ok else 0.3)
		qte_key.get_parent().visible = false
		await wait(0.2 if auto else 0.5)
		if move and move.is_running():
			await wait(0.3)
	if shots_dir != "":
		await _snap("%s_qte-%s" % [cur_bg.replace(":", "-"), n.get("track", "x")])
	await wait(0.2 if auto else 0.7)
	_tension(false)
	qte.visible = false
	return {"fails": fails}

func _qte_step(st: Dictionary, scale: float) -> bool:
	if auto:
		await wait(0.1)
		return randf() <= skill
	var key: String = st.key
	var total: float = (st.ms * scale + (st.hold if st.type == "hold" else 0)) / 1000.0
	qte_key.get_parent().visible = true
	qte_key.text = key
	qte_act.text = st.act
	qte_how.text = "TAP REPEATEDLY" if st.type == "mash" else ("HOLD THE KEY DOWN" if st.type == "hold" else "PRESS ONCE")
	qte_fill.visible = st.type != "press"
	qte_fill.value = 0
	var t0 := clock
	var count := 0
	var held := 0.0
	var keycode: int = KEYS.find_key(key)
	events.clear()
	while clock - t0 < total:
		await get_tree().process_frame
		qte_time.value = (1.0 - (clock - t0) / total) * 100.0
		for k in events:
			if k == key:
				if st.type == "press":
					return true
				if st.type == "mash":
					count += 1
					qte_fill.value = count * 100.0 / st.n
					_blip(280 + count * 25, 0.04, 0.03)
					if count >= st.n:
						return true
			elif st.type == "press" and k in QKEYS:
				return false                       # wrong key
		events.clear()
		if st.type == "hold":
			if Input.is_physical_key_pressed(keycode):
				held += get_process_delta_time()
			else:
				held = maxf(0.0, held - get_process_delta_time() * 3.0)   # letting go drains the bar; press again while time remains
			qte_fill.value = held * 1000.0 / st.hold * 100.0
			if held * 1000.0 >= st.hold:
				return true
	return false

func _shake() -> void:
	var tw := create_tween()
	for i in 5:
		tw.tween_property(cam, "h_offset", randf_range(-0.08, 0.08), 0.04)
	tw.tween_property(cam, "h_offset", 0.0, 0.04)
	var flash := create_tween()
	fade.color = Color(0.5, 0.05, 0.03, 0.35)
	flash.tween_property(fade, "color", Color(0, 0, 0, 0), 0.4)

# ── flowcharts and endings ───────────────────────────────────────

func _overlay_open(dark := 0.9) -> void:
	_hide_all()
	overlay.visible = true
	(overlay.get_child(0) as ColorRect).color = Color(0.02, 0.025, 0.04, dark)
	for c in overlay_box.get_children():
		overlay_box.remove_child(c)
		c.queue_free()

func _olabel(text: String, size: int, color: Color) -> Label:
	var l := _label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 1000
	overlay_box.add_child(l)
	return l

func _flow_rows(ch: int) -> void:
	var fl: Dictionary = story.FLOW[ch]
	_olabel(fl.title, 24, PAPER)
	var found := 0
	var total := 0
	for row in fl.rows:
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 8)
		for cell in row:
			var seen: bool = s.seen.has(cell[0])
			total += 1
			found += int(seen)
			var p := PanelContainer.new()
			p.add_theme_stylebox_override("panel", _panel(Color(0.16, 0.12, 0.05, 0.95) if seen else Color(0.06, 0.07, 0.09, 0.9), AMBER if seen else Color(0.22, 0.23, 0.26), 8))
			var l := _label(cell[1] if seen else "?  ?  ?", 14, PAPER if seen else Color(0.35, 0.36, 0.4))
			l.custom_minimum_size.x = 150
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p.add_child(l)
			h.add_child(p)
		overlay_box.add_child(h)
	_olabel("%d of %d outcomes seen on this path" % [found, total], 14, DIM)

func _flowchart(ch: int, chapter_end := false) -> void:
	await _fade(1.0, 0.4)
	_overlay_open(1.0)
	fade.color.a = 0.0
	if chapter_end:
		_olabel("CHAPTER COMPLETE", 15, AMBER)
	_flow_rows(ch)
	_olabel("CASE STRENGTH  %d%%        EVIDENCE  %d" % [s.strength, s.clues.size()], 16, AMBER)
	_olabel("[ SPACE ]  CONTINUE", 18, PAPER)
	if shots_dir != "":
		await _snap("flow_%d" % ch)
	if auto:
		await wait(0.3)
	else:
		await _key(["SPACE", "ENTER", "CLICK"])
	fade.color.a = 1.0
	overlay.visible = false

func _ending(n: Dictionary) -> void:
	_hide_all()
	if not _shot("ending"):
		_shot("wide")
	await wait(1.0)
	_overlay_open(0.72)
	_olabel("— CASE FILE CLOSED —" if n.title.find("OPEN CASE") < 0 else "— CASE FILE —", 15, DIM)
	_olabel(n.title, 40, AMBER)
	_olabel(n.text.call(s), 20, PAPER)
	_olabel("", 8, DIM)
	_olabel("FINAL CASE STRENGTH  %d%%        EVIDENCE LOGGED  %d" % [s.strength, s.clues.size()], 16, AMBER)
	_olabel("[ SPACE ]  REVIEW THE CASE", 18, PAPER)
	if shots_dir != "":
		await _snap("ending")
	if auto or robot:
		await wait(0.3)
		return
	await _key(["SPACE", "ENTER", "CLICK"])
	for ch in story.FLOW:
		if ch <= s.chapter:
			await _flowchart(ch)
			fade.color.a = 0.0
	_overlay_open(1.0)
	_olabel("DEAD SIGNAL", 48, PAPER)
	_olabel("There are %d endings. The marks you did not see are on other paths." % 7, 18, DIM)
	_olabel("[ SPACE ]  BACK TO THE TITLE", 18, AMBER)
	await _key(["SPACE", "ENTER", "CLICK"])
	overlay.visible = false
	fade.color.a = 1.0

# ── heads-up display ─────────────────────────────────────────────

func _hud() -> void:
	hud_chapter.text = story.FLOW[s.chapter].title
	hud_strength.text = "CASE STRENGTH  %d%%     EVIDENCE  %d" % [s.strength, s.clues.size()]
	hud_bar.value = s.strength

func _toast(msg: String) -> void:
	_hud()
	var l := _label(msg, 15, AMBER)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel(Color(0.05, 0.06, 0.09, 0.9), AMBER, 8))
	p.add_child(l)
	toasts.add_child(p)
	_blip(660, 0.08)
	if msg.begins_with("EVIDENCE"):
		_sound("camera", -10.0)
	var tw := p.create_tween()
	tw.tween_interval(3.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)

func _to_title() -> void:
	_pause(false)
	get_tree().reload_current_scene()

func _pause(on: bool) -> void:
	if auto:
		return
	get_tree().paused = on
	pause_menu.visible = on
	if on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# ── interface construction ───────────────────────────────────────

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	return l

func _panel(bg: Color, border: Color, margin := 18) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_top = 2
	sb.set_content_margin_all(margin)
	return sb

func _bar(fill: Color, height := 6) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size.y = height
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b

func _full(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _build_ui() -> void:
	# film grade over the 3D view, under the interface
	var film := CanvasLayer.new()
	film.layer = 0
	add_child(film)
	var grade := ColorRect.new()
	_full(grade)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://grade.gdshader")
	grade.material = sm
	film.add_child(grade)
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	ui = _full(Control.new())
	layer.add_child(ui)

	# top bar
	hud = _full(Control.new())
	ui.add_child(hud)
	hud_chapter = _label("", 14, Color(0.7, 0.69, 0.66))
	hud_chapter.position = Vector2(20, 14)
	hud.add_child(hud_chapter)
	var right := VBoxContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.position = Vector2(-20, 14)
	right.custom_minimum_size.x = 330
	hud.add_child(right)
	hud_strength = _label("", 14, AMBER)
	hud_strength.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(hud_strength)
	hud_bar = _bar(AMBER, 4)
	right.add_child(hud_bar)
	roam_status = _label("", 14, AMBER)
	roam_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(roam_status)
	toasts = VBoxContainer.new()
	toasts.position = Vector2(20, 44)
	toasts.add_theme_constant_override("separation", 6)
	ui.add_child(toasts)

	crosshair = _label("•", 18, Color(1, 1, 1, 0.7))
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ui.add_child(crosshair)

	# bottom column: prompt, timer, choices, dialogue
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BEGIN
	col.position.y = -22
	col.custom_minimum_size.x = 940
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 8)
	ui.add_child(col)
	prompt_label = _label("", 18, AMBER)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(prompt_label)
	choices = HBoxContainer.new()
	choices.add_theme_constant_override("separation", 10)
	col.add_child(choices)
	timer_bar = _bar(Color(0.85, 0.3, 0.2), 5)
	col.add_child(timer_bar)
	dialog = PanelContainer.new()
	dialog.add_theme_stylebox_override("panel", _panel(Color(0.05, 0.06, 0.09, 0.88), AMBER))
	col.add_child(dialog)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	dialog.add_child(dv)
	who_label = _label("", 15, AMBER)
	dv.add_child(who_label)
	text_label = _label("", 19, PAPER)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(900, 56)
	dv.add_child(text_label)
	adv_label = _label("SPACE ▸", 12, DIM)
	adv_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dv.add_child(adv_label)

	# action prompt
	qte = _full(Control.new())
	ui.add_child(qte)
	var qv := VBoxContainer.new()
	qv.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	qv.grow_horizontal = Control.GROW_DIRECTION_BOTH
	qv.grow_vertical = Control.GROW_DIRECTION_BOTH
	qv.custom_minimum_size.x = 620
	qv.add_theme_constant_override("separation", 10)
	qte.add_child(qv)
	qte_title = _label("", 16, DIM)
	qte_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qv.add_child(qte_title)
	qte_text = _label("", 26, PAPER)
	qte_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qte_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qv.add_child(qte_text)
	var kp := PanelContainer.new()
	kp.add_theme_stylebox_override("panel", _panel(Color(0.05, 0.06, 0.09, 0.9), AMBER, 16))
	kp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kp.custom_minimum_size.x = 420
	qv.add_child(kp)
	var kv := VBoxContainer.new()
	kv.add_theme_constant_override("separation", 6)
	kp.add_child(kv)
	qte_key = _label("", 64, AMBER)
	qte_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kv.add_child(qte_key)
	qte_act = _label("", 24, PAPER)
	qte_act.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kv.add_child(qte_act)
	qte_how = _label("", 14, DIM)
	qte_how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kv.add_child(qte_how)
	qte_fill = _bar(AMBER, 10)
	kv.add_child(qte_fill)
	qte_time = _bar(Color(0.85, 0.3, 0.2), 5)
	kv.add_child(qte_time)
	qte_marks = _label("", 22, PAPER)
	qte_marks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qv.add_child(qte_marks)

	# location card
	card = _full(Control.new())
	ui.add_child(card)
	card_box = VBoxContainer.new()
	card_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	card_box.add_theme_constant_override("separation", 12)
	card.add_child(card_box)

	# fade: over the scene and the dialogue, under the cards and overlays
	fade = ColorRect.new()
	_full(fade)
	fade.color = Color(0, 0, 0, 0)
	ui.add_child(fade)
	ui.move_child(card, -1)

	# title / flowchart / ending overlay
	overlay = _full(Control.new())
	ui.add_child(overlay)
	overlay.add_child(_full(ColorRect.new()))
	var center := CenterContainer.new()
	_full(center)
	overlay.add_child(center)
	overlay_box = VBoxContainer.new()
	overlay_box.add_theme_constant_override("separation", 12)
	center.add_child(overlay_box)

	# pause
	pause_menu = _full(Control.new())
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	var pbg := ColorRect.new()
	_full(pbg)
	pbg.color = Color(0, 0, 0, 0.7)
	pause_menu.add_child(pbg)
	var pc := CenterContainer.new()
	_full(pc)
	pause_menu.add_child(pc)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 14)
	pc.add_child(pv)
	pv.add_child(_label("PAUSED", 40, PAPER))
	for item in [["RESUME", _pause.bind(false)], ["QUIT TO TITLE", _to_title], ["QUIT GAME", get_tree().quit]]:
		var b := Button.new()
		b.text = item[0]
		b.add_theme_font_override("font", FONT)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(item[1])
		pv.add_child(b)
	ui.add_child(pause_menu)
	pause_menu.visible = false
	overlay.visible = false
	card.visible = false
	_hide_all()

# ── sound: small synthesized cues, and a looping room tone where one is installed ─────

func _audio() -> void:
	sfx = AudioStreamPlayer.new()
	sfx.max_polyphony = 6
	add_child(sfx)
	amb = AudioStreamPlayer.new()
	amb.volume_db = -14
	add_child(amb)
	tense = AudioStreamPlayer.new()
	add_child(tense)

func _blip(freq: float, dur := 0.1, vol := 0.05) -> void:
	if auto:
		return
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var env := 1.0 - float(i) / n
		data.encode_s16(i * 2, int(sin(TAU * freq * i / rate) * env * env * 32767.0 * vol * 4.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	sfx.stream = w
	sfx.play()

func _ambience(kind: String) -> void:
	var path := "res://assets/audio/%s.ogg" % kind
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/room.ogg"
	if not ResourceLoader.exists(path) or auto:
		return
	var st: AudioStream = load(path)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	if amb.stream == st:
		return
	if amb.playing:                       # dip the old bed out before the new one comes in
		var out := create_tween()
		out.tween_property(amb, "volume_db", -50.0, 0.4)
		await out.finished
	amb.stream = st
	amb.volume_db = -50.0
	amb.play()
	create_tween().tween_property(amb, "volume_db", AMB_DB.get(kind, -14.0), 0.8)

func _sound(name: String, db := -8.0) -> void:
	# A recorded one-shot, if that file is installed.
	var path := "res://assets/audio/%s.ogg" % name
	if auto or not ResourceLoader.exists(path):
		return
	var st: AudioStream = load(path)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = false
	var p := AudioStreamPlayer.new()
	p.stream = st
	p.volume_db = db
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func _tension(on: bool, kind := "heartbeat", db := -10.0) -> void:
	# A looping layer over the room sound while a timer or an action sequence is running.
	if on:
		var path := "res://assets/audio/%s.ogg" % kind
		if auto or not ResourceLoader.exists(path):
			return
		var st: AudioStream = load(path)
		if st is AudioStreamOggVorbis:
			(st as AudioStreamOggVorbis).loop = true
		if tense_fade:
			tense_fade.kill()
		tense.stream = st
		tense.volume_db = db
		tense.play()
	elif tense.playing:
		tense_fade = create_tween()
		tense_fade.tween_property(tense, "volume_db", -50.0, 0.5)
		tense_fade.tween_callback(tense.stop)

func _cue(text: String) -> void:
	# Narration that describes a sound gets that sound.
	var low := text.to_lower()
	for word in CUES:
		if low.contains(word):
			_sound(CUES[word][0], CUES[word][1])
			return
