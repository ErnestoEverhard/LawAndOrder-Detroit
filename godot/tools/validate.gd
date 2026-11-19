extends SceneTree
## Walks the story graph without the 3D game: checks every link resolves, then plays thousands of
## random runs to confirm there are no dead ends and every node, ending and flowchart mark is reachable.
##   godot --headless --path godot -s tools/validate.gd
const RUNS := 20000
var errors := 0

func err(m: String) -> void:
	errors += 1
	printerr("ERROR: " + m)

func res(v: Variant, s: CaseState) -> Variant:
	return v.call(s) if v is Callable else v

func _init() -> void:
	var story := Story.new()
	var N: Dictionary = story.N
	for id in N:
		var n: Dictionary = N[id]
		var targets := []
		if n.get("next") is String:
			targets.append(n.next)
		for o in n.get("options", []):
			targets.append(o.next)
		if n.has("timeout"):
			targets.append(n.timeout.next)
		for t in targets:
			if not N.has(t):
				err("%s -> missing node \"%s\"" % [id, t])
		if n.type != "ending" and n.get("next") == null and not n.has("options"):
			err("%s has no exit" % id)
		if n.has("bg") and not (n.bg as String).contains(":"):
			err("%s has a bg without an arrangement" % id)
	var endings := {}
	var seen_all := {}
	var strengths := {}
	for i in RUNS:
		if errors:
			break
		var s := CaseState.new()
		var skill := randf()
		var careful := randf()
		var id := Story.START
		var steps := 0
		while id != "":
			if not N.has(id):
				err("run reached missing node \"%s\"" % id)
				break
			var n: Dictionary = N[id]
			steps += 1
			if steps > 500:
				err("loop detected at " + id)
				break
			s.seen[id] = 1
			if n.has("chapter"):
				s.chapter = n.chapter
			match n.type:
				"ending":
					n.text.call(s)
					endings[id] = endings.get(id, 0) + 1
					if id in ["end_guilty", "end_lesser", "end_acquit"]:
						strengths[id] = strengths.get(id, []) + [s.strength]
					id = ""
				"card":
					res(n.lines, s)
					id = n.next
				"scene":
					if n.do != null:
						n.do.call(s)
					for b in res(n.beats, s):
						if b != null and (not b is Array or b.size() < 2 or not b[0] is String or not b[1] is String):
							err("bad beat in " + id)
					id = res(n.next, s)
				"choice":
					var ok := []
					for o in n.options:
						if o.req == null or o.req.call(s):
							ok.append(o)
					var pick: Dictionary = n.timeout if (randf() < 0.1 or ok.is_empty()) else ok[randi() % ok.size()]
					if pick.get("do") != null:
						pick.do.call(s)
					id = pick.next
				"roam":
					var pool: Array = n.hotspots.duplicate()
					pool.shuffle()
					var take: int = n.budget if careful > 0.3 else randi() % (n.budget + 1)
					for h in pool.slice(0, take):
						h.do.call(s)
					id = n.next
				"qte":
					if n.has("scale"):
						n.scale.call(s)
					var fails := 0
					for st in n.steps:
						if randf() > skill:
							fails += 1
					var r := {"fails": fails}
					if n.has("do"):
						n.do.call(s, r)
					id = n.next.call(s, r) if n.next is Callable else n.next
				"branch":
					id = n.next.call(s)
				"chapterEnd":
					id = n.next
				_:
					err("unknown node type \"%s\" at %s" % [n.type, id])
					id = ""
		seen_all.merge(s.seen)
	for id in N:
		if N[id].type == "ending" and not endings.has(id):
			err("ending \"%s\" never reached" % id)
		if not seen_all.has(id):
			err("node \"%s\" never reached" % id)
	for ch in story.FLOW:
		for row in story.FLOW[ch].rows:
			for cell in row:
				if not seen_all.has(cell[0]):
					err("flowchart id \"%s\" never marked" % cell[0])
	print("%d nodes, %d random runs" % [N.size(), RUNS])
	for id in N:
		if N[id].type == "ending":
			print("  %-13s %5.1f%%" % [id, endings.get(id, 0) * 100.0 / RUNS])
	for id in strengths:
		var v: Array = strengths[id]
		v.sort()
		print("  strength at %s: min %d, median %d, max %d" % [id, v[0], v[v.size() / 2], v[-1]])
	print("FAILED with %d error(s)" % errors if errors else "OK")
	quit(1 if errors else 0)
