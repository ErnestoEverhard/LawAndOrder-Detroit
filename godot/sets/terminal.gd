extends Kit
## Port Calder Bus Terminal, Gate 14, before dawn.
## One arrangement: "gate".

var runner: Node3D
var path := [Vector3(1.5, 0, 3.6), Vector3(4.0, 0, 2.0), Vector3(8.0, 0, 3.0), Vector3(11.0, 0, 5.0), Vector3(13.0, 0, 7.4), Vector3(13.6, 0.3, 9.6), Vector3(13.6, 0.3, 9.6)]

func build() -> void:
	ambience = "bus_station"
	env("preller_drive", 0.35, Color(0.36, 0.38, 0.42), 1.3, 0.006, Color(0.8, 0.85, 0.9))
	var floor_m := tex("terrazzo_tiles", 0.35, Color(0.8, 0.8, 0.78))
	var tile := tex("square_tiles", 0.8, Color(0.75, 0.82, 0.8))
	var paint := tex("beige_wall_001", 0.5, Color(0.8, 0.8, 0.74))
	# the hall: 28 m long, glass along the south side where the buses pull in
	tbox(Vector3(0, -0.05, 0), Vector3(28, 0.1, 16), floor_m)
	tbox(Vector3(0, 5.05, 0), Vector3(28, 0.1, 16), tex("ceiling_interior", 0.8, Color(0.75, 0.75, 0.73)))
	wall_x(-8.05, -14, 14, 0, 5, paint)
	tbox(Vector3(0, 0.7, -7.98), Vector3(28, 1.4, 0.04), tile, false)
	wall_z(-14.05, -8, 8, 0, 5, paint)
	wall_z(14.05, -8, 8, 0, 5, paint)
	wall_x(8.05, -14, 14, 3.4, 5, paint)
	for x in range(-14, 15, 4):                                                                    # glazing bars
		box(Vector3(x, 1.7, 8.0), Vector3(0.12, 3.4, 0.12), Color(0.2, 0.22, 0.25))
	box(Vector3(0, 1.7, 8.02), Vector3(28, 3.4, 0.02), Color(0.5, 0.6, 0.7, 0.12), false)
	blocker(Vector3(0, 1.7, 8.0), Vector3(28, 3.4, 0.2))
	for x in [-9.0, -3.0, 3.0, 9.0]:
		for z in [-4.0, 1.5, 6.0]:
			tube(Vector3(x, 4.96, z), 1.2, true, Color(0.9, 0.95, 0.92), 1.3 if (int(x) + int(z)) % 2 else 0.9, 9.0, x == 3.0 and z == 1.5)
	# ticket windows on the north wall, one open
	tbox(Vector3(-6, 0.55, -7.2), Vector3(9, 1.1, 1.2), tex("wooden_panels", 0.7, Color(0.45, 0.4, 0.36)))
	box(Vector3(-6, 1.13, -7.2), Vector3(9.1, 0.06, 1.3), Color(0.2, 0.2, 0.22))
	for i in 4:
		var x := -9.4 + i * 2.25
		box(Vector3(x, 1.9, -6.7), Vector3(1.9, 1.5, 0.02), Color(0.6, 0.7, 0.75, 0.15), false)
		box(Vector3(x + 1.1, 1.9, -6.7), Vector3(0.08, 1.5, 0.1), Color(0.2, 0.2, 0.22), false)
		plate("TICKETS" if i == 1 else "CLOSED", Vector3(x, 2.85, -6.68), 0.0, 1.2, 0.26, Color(0.1, 0.2, 0.4) if i == 1 else Color(0.25, 0.25, 0.27), Color(0.9, 0.9, 0.85), 64, null, 0.8 if i == 1 else 0.0)
	omni(Vector3(-7.1, 2.3, -7.4), Color(1.0, 0.9, 0.7), 1.2, 4.0)
	# departures board
	box(Vector3(4.5, 3.6, -7.95), Vector3(5.0, 1.8, 0.1), Color(0.03, 0.03, 0.04), false)
	note("DEPARTURES", Vector3(4.5, 4.3, -7.89), 70, AMBER, 0.0, 0.0, true)
	note("05:50   ALDER FALLS — NORTHGATE      14   BOARDING\n06:05   PORT CALDER — AIRPORT        3   ON TIME\n06:20   HOLLIS — ST. BRENNAN           9   ON TIME\n06:45   MERCER ST — DOWNTOWN LOOP      2   DELAYED\n07:10   ALDER FALLS — NORTHGATE      14   ON TIME", Vector3(4.5, 3.5, -7.89), 44, AMBER, 0.0, 0.0, true)
	prop("wall_clock", Vector3(8.2, 3.9, -7.94), 0.0, 0.6)
	# rows of seats bolted to the floor, and what people leave on them
	for row in [[-8.0, -1.5], [-8.0, 1.2], [5.5, -2.5]]:
		prop("modular_street_seating", Vector3(row[0], 0, row[1]), 0.0, 0.0, true)
	prop("modular_street_seating", Vector3(8.5, 0, 4.4), 0.25, 0.0, true)
	prop("vintage_suitcase", Vector3(-9.2, 0, -0.6), 0.3)
	prop("cardboard_box_01", Vector3(-6.0, 0, 2.0), 0.6)
	paper(Vector3(-7.4, 0.47, -1.45), 0.4, Vector2(0.3, 0.4), Color(0.8, 0.8, 0.76))                # yesterday's paper
	cup(Vector3(-8.6, 0.46, 1.25))
	cup(Vector3(5.0, 0.01, -1.9))
	# vending, phone, bins, a mop sign, the luggage cart
	box(Vector3(12.6, 0.95, -7.4), Vector3(1.0, 1.9, 0.8), Color(0.12, 0.14, 0.2))
	box(Vector3(12.6, 1.15, -6.98), Vector3(0.8, 1.2, 0.02), Color(0.6, 0.8, 1.0), false, 1.4)
	omni(Vector3(12.6, 1.2, -6.4), Color(0.6, 0.8, 1.0), 0.8, 4.0)
	box(Vector3(11.3, 0.95, -7.4), Vector3(1.0, 1.9, 0.8), Color(0.3, 0.08, 0.08))
	box(Vector3(11.3, 1.15, -6.98), Vector3(0.8, 1.2, 0.02), Color(1.0, 0.75, 0.6), false, 1.0)
	prop("korean_public_payphone_01", Vector3(-13.6, 1.1, 2.0), PI / 2)
	for p in [Vector3(-12.5, 0, -6.5), Vector3(1.5, 0, -6.8), Vector3(13.2, 0, 6.5)]:
		cyl(p + Vector3(0, 0.4, 0), 0.25, 0.8, Color(0.25, 0.27, 0.3), 0.5)
	prop("WetFloorSign_01", Vector3(-2.5, 0, -3.5), 0.8)
	prop("industrial_storage_cart", Vector3(9.5, 0, 0.8), 0.5, 0.9, true)
	prop("vintage_suitcase", Vector3(9.5, 0.5, 0.8), 0.6)
	prop("korean_fire_extinguisher_01", Vector3(13.8, 0, -2.0), -PI / 2)
	# Gate 14: a rope line to the door, the coach idling outside
	plate("GATE 14", Vector3(13.0, 3.9, 7.9), PI, 1.6, 0.5, Color(0.1, 0.2, 0.4), Color(0.95, 0.95, 0.9), 150, null, 0.6)
	plate("GATE 13", Vector3(5.0, 3.9, 7.9), PI, 1.6, 0.5, Color(0.25, 0.25, 0.27), Color(0.8, 0.8, 0.78), 150)
	for i in 4:
		var px := 11.9 + (i % 2) * 2.2
		var pz := 2.6 + (i / 2) * 3.4
		cyl(Vector3(px, 0.5, pz), 0.03, 1.0, Color(0.7, 0.65, 0.4), 0.3)
		cyl(Vector3(px, 0.02, pz), 0.17, 0.04, Color(0.7, 0.65, 0.4), 0.3)
	for px in [11.9, 14.1]:
		box(Vector3(px, 0.92, 4.3), Vector3(0.04, 0.05, 3.4), Color(0.4, 0.08, 0.1), false)
	door(Vector3(12.55, 0, 7.6), 1.3, Color(0.3, 0.33, 0.36), 1.0, 2.2, true)
	_coach(Vector3(13.5, 0, 11.3))
	spot(Vector3(6, 6, 14), Vector3(12, 0, 10.5), Color(1.0, 0.75, 0.5), 6.0, 20, 50, false, 1.5)
	# people waiting for the first bus out
	actor("", "megan", Vector3(-8.6, -0.02, -1.45), 0.0, "sit_idle", "sit_idle", {"Shirt": Color(0.6, 0.3, 0.3)})
	actor("", "leonard", Vector3(6.3, -0.02, -2.45), 0.0, "sit_idle", "sit_idle", {"Sweater": Color(1.6, 1.2, 0.8)})
	actor("", "kate", Vector3(13.0, 0, 5.9), 0.2, "idle", "talk", {"Shirt": Color(0.9, 0.5, 0.4)})
	actor("", "kate", Vector3(13.0, 0, 4.9), 0.0, "idle", "talk", {"Shirt": Color(0.5, 0.7, 0.5), "Hair": Color(0.4, 0.3, 0.25)})
	actor("", "megan", Vector3(12.9, 0, 4.0), -0.2, "idle", "idle", {"Shirt": Color(0.35, 0.4, 0.5), "Hair": Color(1.6, 1.3, 0.9)})
	runner = actor("HARLAN", "brian", Vector3(13.0, 0, 3.1), 0.0, "idle", "talk", {"Shirt": Color(0.5, 0.52, 0.56), "Pants": Color(0.75, 0.75, 0.8)})
	box(Vector3(13.4, 0.2, 3.0), Vector3(0.7, 0.35, 0.35), Color(0.4, 0.42, 0.45), false, 0.0, 0.3)    # his duffel
	actor("REYES", "louise", Vector3(3.5, 0, -1.0), 1.6)
	shot("wide", Vector3(4.5, 1.7, -3.5), Vector3(12.5, 1.2, 4.5), 52)
	shot("HARLAN", Vector3(11.2, 1.6, 0.6), Vector3(13.0, 1.55, 3.1), 30)
	shot("bus", Vector3(9.5, 1.6, 6.0), Vector3(14.5, 1.6, 11.0), 46)
	shot("ending", Vector3(-10, 1.4, 5.5), Vector3(8, 2.2, -4), 55)
	close("REYES", 1.5, 0.5, 1.6, 42)
	# the chase doubles back through the hall and out to the bus: he runs it the other way round from the rope line
	path = [Vector3(13.0, 0, 3.1), Vector3(10.5, 0, 1.5), Vector3(7.5, 0, 0.5), Vector3(7.0, 0, 3.4), Vector3(10.5, 0, 6.6), Vector3(12.6, 0, 8.6), Vector3(13.4, 0.4, 9.9)]
	tracks["gate"] = [
		[Vector3(5.5, 1.6, -2.0), Vector3(12.5, 1.4, 3.0)], [Vector3(8.5, 1.6, -0.5), Vector3(10.5, 1.3, 1.5)],
		[Vector3(9.5, 1.6, 0.0), Vector3(7.0, 1.3, 1.5)], [Vector3(7.6, 1.7, 1.0), Vector3(8.5, 1.2, 4.6)],
		[Vector3(8.0, 1.0, 4.2), Vector3(10.8, 1.2, 6.8)], [Vector3(11.4, 1.6, 7.0), Vector3(13.2, 1.2, 9.6)],
	]

func _coach(pos: Vector3) -> void:
	# A long-distance coach, door side toward the terminal, lit inside.
	var c := Node3D.new()
	c.position = pos
	add_child(c)
	var parts := [
		[Vector3(0, 1.75, 0), Vector3(11.5, 2.7, 2.5), Color(0.82, 0.84, 0.86)],
		[Vector3(0, 0.95, -1.26), Vector3(11.5, 0.5, 0.02), Color(0.15, 0.3, 0.55)],
		[Vector3(-0.6, 2.2, -1.26), Vector3(9.6, 0.9, 0.02), Color(0.9, 0.85, 0.6)],
		[Vector3(5.76, 2.0, 0), Vector3(0.02, 1.3, 2.2), Color(0.05, 0.06, 0.08)],
		[Vector3(0, 0.3, 0), Vector3(11.0, 0.2, 2.2), Color(0.08, 0.08, 0.09)],
		[Vector3(0.4, 1.2, -1.27), Vector3(0.9, 1.9, 0.03), Color(0.03, 0.03, 0.04)],     # the open door
		[Vector3(0.4, 0.42, -1.5), Vector3(0.9, 0.12, 0.4), Color(0.2, 0.2, 0.22)],      # its step
	]
	for i in parts.size():
		var b := _into(c, box(parts[i][0], parts[i][1], parts[i][2], i == 0, 1.2 if i == 2 else 0.0))
	for wx in [-4.0, 3.8]:
		_into(c, cyl(Vector3(wx, 0.5, -1.15), 0.5, 0.3, Color(0.05, 0.05, 0.05), 0.9)).rotation.x = PI / 2
	plate("14  ALDER FALLS — NORTHGATE", Vector3(pos.x + 3.6, 2.85, pos.z - 1.28), PI, 2.6, 0.28, Color(0.03, 0.03, 0.04), AMBER, 60, null, 1.0)
	omni(pos + Vector3(0.4, 1.8, -1.8), Color(1.0, 0.9, 0.7), 1.2, 4.0)
	for hz in [-0.8, 0.8]:
		_into(c, box(Vector3(5.77, 0.8, hz), Vector3(0.02, 0.18, 0.35), Color(1.0, 0.95, 0.8), false, 3.0))

func on_step(track: String, i: int) -> void:
	if track != "gate" or runner == null:
		return
	var to: Vector3 = path[mini(i, path.size() - 1)]
	var from := runner.position
	if to.distance_to(from) > 0.1:
		pose(runner, "run")
		runner.rotation.y = atan2(to.x - from.x, to.z - from.z)
		create_tween().tween_property(runner, "position", to, 1.5)
