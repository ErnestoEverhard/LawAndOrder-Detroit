extends CharacterBody3D
## First-person walker: WASD to move, mouse to look. Click captures the mouse, Esc releases it.

const SPEED := 2.6
const SENS := 0.0025
var cam: Camera3D
var frozen := false

func _ready() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	col.shape = cap
	col.position.y = 0.85
	add_child(col)
	cam = Camera3D.new()
	cam.position.y = 1.62
	cam.fov = 70.0
	add_child(cam)
	cam.current = true

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-e.relative.x * SENS)
		cam.rotation.x = clampf(cam.rotation.x - e.relative.y * SENS, -1.3, 1.3)
	elif e is InputEventMouseButton and e.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(_delta: float) -> void:
	var d := Vector3.ZERO
	if not frozen:
		if Input.is_physical_key_pressed(KEY_W): d.z -= 1.0
		if Input.is_physical_key_pressed(KEY_S): d.z += 1.0
		if Input.is_physical_key_pressed(KEY_A): d.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D): d.x += 1.0
	d = transform.basis * d
	d.y = 0.0
	velocity = d.normalized() * SPEED
	move_and_slide()
