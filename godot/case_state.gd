class_name CaseState
extends RefCounted
## Everything the story remembers about one playthrough.

signal notice(text: String)

const PRE_VAN := ["tablet", "notes", "receipt", "window", "report", "name", "witness"]

var clues := {}      # id -> label
var f := {}          # story flags
var seen := {}       # node ids and flowchart marks reached
var strength := 0    # how well the case will hold up in court, 0-100
var trust := 0       # Reyes's opinion of how you work
var late := 0        # delays; each one pushes the night's clock back 40 minutes
var chapter := 1

func on(k: String) -> bool:
	return bool(f.get(k, false))

func num(k: String) -> int:
	return int(f.get(k, 0))

func has(k: String) -> bool:
	return clues.has(k)

func mark(k: String) -> void:
	seen[k] = 1

func say(msg: String) -> void:
	notice.emit(msg)

func add(n: int) -> void:
	strength = clampi(strength + n, 0, 100)

func clue(id: String, label: String, pts := 5) -> void:
	if clues.has(id):
		return
	clues[id] = label
	seen["clue_" + id] = 1
	add(pts)
	say("EVIDENCE LOGGED — " + label)

func partner(d: int, msg: String) -> void:
	trust += d
	say(("▲ REYES — " if d > 0 else "▼ REYES — ") + msg)

func lost(n: int, why: String) -> void:
	late += n
	say("TIME LOST — " + why)

func clock(h: int, m: int) -> String:
	var t := h * 60 + m + late * 40
	var hr := (t / 60) % 12
	return "%d:%02d AM" % [12 if hr == 0 else hr, t % 60]

func pre_van() -> int:
	var n := 0
	for k in PRE_VAN:
		if clues.has(k):
			n += 1
	return n

func can_lib() -> bool:
	return has("name") or has("notes") or has("receipt") or has("report")

func can_ex() -> bool:
	return has("tablet") or has("ex") or on("evanName")

func bad_facts() -> int:
	# things the defense can use against the investigation at trial
	return int(on("wrong")) + int(not on("warrant")) + int(on("pushed"))
