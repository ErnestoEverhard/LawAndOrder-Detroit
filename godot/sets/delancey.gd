extends Kit
## 88 Delancey Court: a student rental, and the row of back yards behind it.
## Arrangements: "door" (the porch), "yards" (the chase), "caught" (where it ends).

var runner: Node3D
var path := [Vector3(-2, 0, -9.7), Vector3(3, 0, -12.5), Vector3(8, 0, -13), Vector3(17, 0, -13), Vector3(21, 0, -13.2), Vector3(24, 0, -13.5), Vector3(24, 0, -13.5)]

func build() -> void:
	ambience = "city_night"
	env("preller_drive", 0.7, Color(0.26, 0.30, 0.42), 2.0, 0.008, Color(0.7, 0.75, 0.9))
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 1.0)
	moon.light_energy = 0.9
	moon.rotation_degrees = Vector3(-50, 35, 0)
	moon.shadow_enabled = true
	add_child(moon)
	_street()
	_house()
	_yards()
	_people()

func _house_shell(x0: float, x1: float, depth: float, h: float, tint: Color, lit: Array) -> void:
	var siding := tex("weathered_plank_siding", 0.45, tint)
	var cx := (x0 + x1) / 2
	tbox(Vector3(cx, h / 2, -depth / 2), Vector3(x1 - x0, h, depth), siding)
	# a pitched roof: two slabs leaning together
	for side in [-1, 1]:
		var r := box(Vector3(cx + side * (x1 - x0) * 0.26, h + 0.95, -depth / 2), Vector3((x1 - x0) * 0.62, 0.14, depth + 0.6), Color(0.13, 0.13, 0.15), false)
		r.rotation.z = -side * 0.55
	box(Vector3(cx, h + 0.6, 0.02), Vector3((x1 - x0) * 0.6, 1.1, 0.1), tint * 0.5, false)
	# windows: upstairs and down, most of them dark
	var k := 0
	for wy in [1.7, 4.2]:
		for wx in [x0 + 1.4, x1 - 1.4]:
			var on: bool = k in lit
			box(Vector3(wx, wy, 0.03), Vector3(1.2, 1.5, 0.06), Color(0.85, 0.85, 0.8), false)
			var g := box(Vector3(wx, wy, 0.07), Vector3(1.0, 1.3, 0.02), Color(1.0, 0.8, 0.5) if on else Color(0.04, 0.05, 0.07), false, 1.6 if on else 0.0)
			if not on:
				g.material_override = mat(Color(0.04, 0.05, 0.07), 0.0, 0.1)
			box(Vector3(wx, wy, 0.085), Vector3(1.0, 0.04, 0.02), Color(0.85, 0.85, 0.8), false)
			k += 1

func _street() -> void:
	tbox(Vector3(4, -0.06, 13), Vector3(70, 0.1, 9), tex("asphalt_02", 0.3, Color(0.7, 0.7, 0.75)))
	tbox(Vector3(4, -0.03, 7.9), Vector3(70, 0.14, 1.5), tex("concrete_pavement", 0.5))
	tbox(Vector3(4, -0.05, -5), Vector3(70, 0.1, 24.5), tex("leafy_grass", 0.4, Color(0.5, 0.58, 0.5)))
	tbox(Vector3(0.5, -0.02, 5.0), Vector3(1.2, 0.1, 4.4), tex("concrete_pavement", 0.5), false)        # front path
	prop("street_lamp_01", Vector3(-7, 0, 8.3), 0.0, 5.0)
	spot(Vector3(-7, 4.8, 8.6), Vector3(-6, 0, 9.5), Color(1.0, 0.75, 0.45), 6.0, 14, 55, true, 1.5)
	prop("covered_car", Vector3(-9.5, 0, 11), PI / 2 + 0.03)
	prop("fire_hydrant", Vector3(6.5, 0, 8.2), 0.4)
	# recycling that has been at the curb more than one week
	for i in 3:
		prop("plastic_crate_01", Vector3(2.6 + i * 0.5, 0.04, 8.0 + (i % 2) * 0.2), i * 0.4, 0.3)
	for i in 9:
		cyl(Vector3(2.5 + (i % 5) * 0.28, 0.42 + (i % 2) * 0.05, 7.95 + (i % 3) * 0.1), 0.03, 0.22, Color(0.2, 0.4, 0.25) if i % 2 else Color(0.45, 0.3, 0.12), 0.2)
	prop("trashbag", Vector3(4.3, 0.04, 8.1), 1.0)
	box(Vector3(1.6, 0.55, 7.6), Vector3(0.1, 1.1, 0.1), Color(0.3, 0.25, 0.2), false)                # mailbox
	box(Vector3(1.6, 1.15, 7.6), Vector3(0.22, 0.22, 0.5), Color(0.15, 0.15, 0.17), false)
	note("88", Vector3(1.715, 1.15, 7.6), 30, Color(0.9, 0.9, 0.85), 0.0, PI / 2)
	# neighbours either side
	_house_shell_at(-16.5, [1])
	_house_shell_at(11.0, [])
	_house_shell_at(22.0, [2])

func _house_shell_at(x: float, lit: Array) -> void:
	var n := Node3D.new()
	add_child(n)
	_house_shell(x - 4.5, x + 4.5, 9.0, 5.6, Color(0.6, 0.62, 0.7) if int(x) % 2 else Color(0.75, 0.7, 0.62), lit)
	box(Vector3(x, 0.25, 1.0), Vector3(4.0, 0.5, 2.0), Color(0.3, 0.3, 0.32))
	door(Vector3(x, 0.5, 0.03), 0.0, Color(0.2, 0.25, 0.3))

func _house() -> void:
	_house_shell(-5, 5, 9.0, 5.6, Color(0.78, 0.76, 0.66), [3])
	# porch: deck, steps, posts, a roof, a rail with a gap
	var deck := tex("wood_planks_grey", 0.6, Color(0.75, 0.7, 0.65))
	tbox(Vector3(0, 0.225, 1.0), Vector3(7, 0.45, 2.0), deck)
	for i in 2:
		tbox(Vector3(0.5, 0.11 + i * 0.0, 2.2 + i * 0.3), Vector3(1.6, 0.22 if i == 0 else 0.11, 0.3), deck)
	box(Vector3(0, 3.0, 1.1), Vector3(7.4, 0.14, 2.4), Color(0.2, 0.2, 0.22), false)
	for x in [-3.4, -0.6, 1.6, 3.4]:
		box(Vector3(x, 1.7, 1.9), Vector3(0.12, 2.6, 0.12), Color(0.85, 0.84, 0.8), false)
	for seg in [[-3.4, -0.6], [1.6, 3.4]]:
		box(Vector3((seg[0] + seg[1]) / 2, 1.3, 1.9), Vector3(seg[1] - seg[0], 0.06, 0.06), Color(0.85, 0.84, 0.8), false)
		var x: float = seg[0] + 0.2
		while x < seg[1]:
			box(Vector3(x, 0.87, 1.9), Vector3(0.04, 0.85, 0.04), Color(0.85, 0.84, 0.8), false)
			x += 0.2
	# the couch on the porch, and what collects around it
	prop("Sofa_01", Vector3(-2.2, 0.45, 0.6), 0.0)
	prop("plastic_monobloc_chair_01", Vector3(2.6, 0.45, 0.9), -0.7)
	prop("plastic_crate_01", Vector3(1.9, 0.45, 0.6), 0.3)
	for i in 4:
		cyl(Vector3(1.85 + (i % 2) * 0.12, 0.78, 0.55 + (i / 2) * 0.12), 0.033, 0.12, Color(0.75, 0.75, 0.78), 0.3)   # cans
	prop("planter_pot_clay", Vector3(-0.5, 0.45, 1.6), 0.0)
	prop("dirty_football", Vector3(-3.5, 0, 4.0), 0.0)
	plate("88", Vector3(1.35, 2.0, 0.04), 0.0, 0.3, 0.2, Color(0.1, 0.1, 0.1), Color(0.9, 0.9, 0.85), 80)
	prop("industrial_wall_lamp", Vector3(-0.35, 2.3, 0.03), 0.0)
	omni(Vector3(-0.3, 2.3, 0.7), Color(1.0, 0.78, 0.5), 2.4, 8.0, true)
	omni(Vector3(3.6, 4.2, 1.0), Color(1.0, 0.8, 0.5), 0.6, 4.0)
	# front door: open with him in it for the knock, slammed after
	box(Vector3(0.5, 1.5, 0.01), Vector3(1.1, 2.15, 0.05), Color(0.06, 0.05, 0.05), false)
	if stage == "door":
		omni(Vector3(0.5, 1.9, -0.6), Color(1.0, 0.85, 0.65), 1.2, 3.5)
	else:
		door(Vector3(0.5, 0.45, 0.04), 0.0, Color(0.25, 0.14, 0.1))
	# side passage and the back of the house
	prop("exterior_aircon_unit", Vector3(-5.4, 0.2, -4), PI / 2)
	door(Vector3(-2, 0, -9.04), PI, Color(0.8, 0.8, 0.76))
	prop("industrial_wall_lamp", Vector3(-1.2, 2.2, -9.03), PI)
	omni(Vector3(-1.2, 2.1, -9.8), Color(1.0, 0.8, 0.55), 2.0, 8.0, true)

func _plank_fence_z(x: float, z0: float, z1: float) -> void:
	tbox(Vector3(x, 0.9, (z0 + z1) / 2), Vector3(0.06, 1.8, z1 - z0), tex("wood_planks_grey", 0.7, Color(0.7, 0.66, 0.6)))

func _yards() -> void:
	tbox(Vector3(8, 0.9, -17.5), Vector3(40, 1.8, 0.06), tex("wood_planks_grey", 0.7, Color(0.62, 0.6, 0.56)))
	for x in [-6.5, 6.5, 13.0, 19.5, 26.0]:
		_plank_fence_z(x, -17.5, -9.0 if x > -6 and x < 26 else 2.0)
	# behind 88: a party that nobody cleaned up after
	table(Vector3(1.5, 0, -14.5), Vector2(2.2, 0.75), 0.74, Color(0.8, 0.8, 0.78), 0.3)
	for i in 10:
		cup(Vector3(0.9 + (i % 5) * 0.3, 0.74, -14.6 + (i / 5) * 0.25 + (i % 5) * 0.09), Color(0.75, 0.12, 0.1))
	prop("plastic_monobloc_chair_01", Vector3(-1.5, 0, -15.5), 2.2)
	var fallen := prop("plastic_monobloc_chair_01", Vector3(-3.0, 0.3, -12.5), 0.4)
	fallen.rotation.x = 1.5
	prop("Barrel_01", Vector3(-5.5, 0, -15.5), 0.0)
	prop("trashbag", Vector3(-4.6, 0, -10.0), 0.3)
	prop("trashbag", Vector3(-5.2, 0, -10.6), 1.5)
	box(Vector3(0, 2.0, -11.5), Vector3(11.5, 0.012, 0.012), Color(0.8, 0.8, 0.8), false)             # washing line
	for i in 4:
		box(Vector3(-3.0 + i * 1.1, 1.6, -11.5), Vector3(0.6, 0.8, 0.01), [Color(0.3, 0.35, 0.5), Color(0.8, 0.8, 0.78), Color(0.5, 0.2, 0.2), Color(0.2, 0.2, 0.22)][i], false).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# next door: someone gardens
	prop("painted_wooden_bench", Vector3(10, 0, -16.6), 0.0)
	for i in 3:
		prop("planter_pot_clay", Vector3(7.4 + i * 0.5, 0, -10.2), i * 1.0, 0.3 + i * 0.08)
	tbox(Vector3(11.5, 0.15, -11.0), Vector3(2.0, 0.3, 1.0), tex("wood_planks_grey", 0.7, Color(0.5, 0.4, 0.32)))    # raised bed
	prop("potted_plant_01", Vector3(11.2, 0.25, -11.0), 0.0, 0.8)
	prop("security_light", Vector3(11, 3.0, -9.03), PI)
	spot(Vector3(11, 2.9, -9.3), Vector3(11, 0, -13.5), Color(0.9, 0.95, 1.0), 9.0, 12, 50, true, 2.0)   # motion light, tripped
	# third yard: kids
	box(Vector3(15.0, 1.0, -16.0), Vector3(2.4, 2.0, 1.8), Color(0.3, 0.2, 0.15))                      # shed
	box(Vector3(15.0, 2.1, -16.0), Vector3(2.7, 0.1, 2.1), Color(0.15, 0.15, 0.16), false).rotation.x = 0.12
	prop("old_tyre", Vector3(17.5, 0.9, -11.5), 0.3)
	box(Vector3(17.5, 1.9, -11.5), Vector3(0.015, 1.6, 0.015), Color(0.6, 0.55, 0.4), false)
	prop("dirty_football", Vector3(16.2, 0, -12.2), 0.0)
	# fourth: the bins he kicks over, and where he falls
	prop("metal_trash_can", Vector3(21.5, 0, -11.6), 0.4)
	prop("trashbag", Vector3(22.6, 0, -12.2), 0.8)
	prop("old_tyre", Vector3(25.0, 0.1, -16.0), 0.0).rotation.x = PI / 2
	prop("weed_plant_02", Vector3(23.5, 0, -15.5), 1.0, 0.4)
	omni(Vector3(22, 2.5, -9.6), Color(1.0, 0.8, 0.55), 2.4, 10.0, true)
	omni(Vector3(16, 2.6, -9.6), Color(1.0, 0.8, 0.55), 1.6, 9.0)
	omni(Vector3(4, 2.4, -9.6), Color(1.0, 0.8, 0.55), 1.4, 9.0)

func _people() -> void:
	match stage:
		"door":
			actor("EVAN", "leonard", Vector3(0.5, 0.45, 0.25), 0.0, "idle", "talk")
			actor("REYES", "louise", Vector3(-0.2, 0.45, 1.25), PI - 0.35)
			shot("wide", Vector3(4.0, 1.5, 8.5), Vector3(0.3, 1.9, 0), 50)
			shot("EVAN", Vector3(1.0, 2.05, 1.75), Vector3(0.5, 2.0, 0.25), 40)
			close("REYES", 1.4, -0.5, 1.6, 42)
		"yards":
			runner = actor("EVAN", "leonard", path[0], 2.0, "run", "run")
			tracks["yards"] = [
				[Vector3(-5.8, 1.6, 3.0), Vector3(-5.8, 1.4, -8)], [Vector3(-5.6, 1.6, -9.6), Vector3(2, 1.2, -12.3)],
				[Vector3(4.2, 1.6, -12.6), Vector3(8, 1.7, -13)], [Vector3(15.5, 1.6, -13), Vector3(20, 1.3, -13.1)],
				[Vector3(19.0, 1.6, -12.8), Vector3(22.5, 1.0, -13.3)], [Vector3(22.6, 1.5, -12.6), Vector3(24, 0.5, -13.5)],
			]
			shot("wide", Vector3(-5.8, 1.6, 3.0), Vector3(-5.8, 1.4, -8), 60)
		"caught":
			actor("EVAN", "leonard", Vector3(24, 0, -13.5), -1.9, clip("hands_up", "look_around"), clip("hands_up", "talk"))
			actor("REYES", "louise", Vector3(22.7, 0, -14.2), 1.2)
			strobe(Vector3(22, 2.5, -8.0))
			shot("wide", Vector3(20.5, 1.7, -11.2), Vector3(23.6, 1.2, -13.8), 52)
			close("EVAN", 1.7, 0.5, 1.35, 46)
			close("REYES", 1.4, -0.4, 1.6, 42)

func on_step(track: String, i: int) -> void:
	if track != "yards" or runner == null:
		return
	var to: Vector3 = path[mini(i + 1, path.size() - 1)]
	var from := runner.position
	if to.distance_to(from) > 0.1:
		runner.rotation.y = atan2(to.x - from.x, to.z - from.z)
		create_tween().tween_property(runner, "position", to, 1.6)
	else:
		pose(runner, "terrified")
