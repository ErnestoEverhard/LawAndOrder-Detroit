extends SceneTree
# Debug: the principal cast in costume, side by side.   godot --path . -s tools/costumes.gd -- out.png
func _init() -> void:
	var k: Node3D = load("res://kit.gd").new()
	get_root().add_child(k)
	k.env("hansaplatz", 0.0, Color(0.9, 0.9, 0.92), 1.1, 0.0, Color.WHITE)
	k.box(Vector3(0, -0.05, 0), Vector3(30, 0.1, 10), Color(0.45, 0.45, 0.47))
	k.box(Vector3(0, 1.5, -1.2), Vector3(30, 3.2, 0.1), Color(0.5, 0.5, 0.55))
	var gray := {"Shirt": Color(0.5, 0.52, 0.56), "Pants": Color(0.75, 0.75, 0.8)}
	var court := load("res://sets/courthouse.gd")
	var who := [["OKONKWO", Kit.OKONKWO_MODEL, Kit.OKONKWO_LOOK], ["REYES", "louise", {}], ["PRUITT", "martha", court.PRUITT_LOOK],
		["JUDGE", "joe", court.JUDGE_LOOK], ["HARLAN", "brian", gray], ["EVAN", "leonard", {}], ["PRIYA", "megan", {}], ["TESSA", "kate", {}],
		["officer", "alex", {}], ["medic", "chad", {}]]
	for i in who.size():
		var n: Node3D = k.actor(who[i][0], who[i][1], Vector3((i - (who.size() - 1) / 2.0) * 0.8, 0, 0), 0.0, "idle", "idle", who[i][2])
		if who[i][0] == "JUDGE":
			k.robe(n)

		var l := Label3D.new()
		l.text = who[i][0]
		l.pixel_size = 0.003
		l.modulate = Color.BLACK
		l.outline_size = 0
		l.position = n.position + Vector3(0, 2.0, 0)
		get_root().add_child(l)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-25, 15, 0)
	get_root().add_child(sun)
	var cam := Camera3D.new()
	get_root().add_child(cam)
	cam.fov = 30
	cam.look_at_from_position(Vector3(0, 1.15, 9.2), Vector3(0, 1.0, 0))
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	quit()
