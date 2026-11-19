extends SceneTree
# Debug: print each Poly Haven model's bounding box (size, then centre) so sets can place them.
func _box(n: Node, xf: Transform3D, acc: Array) -> void:
	if n is Node3D:
		xf = xf * (n as Node3D).transform
	if n is MeshInstance3D:
		var a: AABB = xf * (n as MeshInstance3D).get_aabb()
		acc[0] = a if acc[0] == null else (acc[0] as AABB).merge(a)
	for c in n.get_children():
		_box(c, xf, acc)

func _init() -> void:
	var d := DirAccess.open("res://assets/models")
	var ids := d.get_directories()
	ids.sort()
	for id in ids:
		var p := "res://assets/models/%s/%s_1k.gltf" % [id, id]
		if not ResourceLoader.exists(p):
			continue
		var n: Node = (load(p) as PackedScene).instantiate()
		var acc := [null]
		_box(n, Transform3D.IDENTITY, acc)
		var a: AABB = acc[0]
		print("%-30s size %5.2f %5.2f %5.2f  ctr %5.2f %5.2f %5.2f" % [id, a.size.x, a.size.y, a.size.z, a.get_center().x, a.get_center().y, a.get_center().z])
		n.free()
	quit()
