extends CharacterBody2D
## The Lightbearer. Runs, jumps, steps up single tiles, and swings at Gloom creatures.

const SPEED := 140.0
const ACCEL := 1500.0
const GRAVITY := 980.0
const JUMP := 345.0
const MAX_FALL := 620.0
const COYOTE := 0.1
const JUMP_BUFFER := 0.12

var facing := 1
var hp := 100.0
var max_hp := 100.0
var invuln := 0.0
var _coyote := 0.0
var _buffer := 0.0
var _swing := 0.0
var _swing_dir := Vector2.RIGHT


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 28)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	z_index = 11
	floor_snap_length = 4.0


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	_coyote = COYOTE if is_on_floor() else _coyote - delta
	_buffer = JUMP_BUFFER if Input.is_action_just_pressed("jump") else _buffer - delta
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = -JUMP
		_buffer = 0.0
		_coyote = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5
	# Step up one-tile ledges so walking over bumpy ground feels smooth.
	if is_on_floor() and dir != 0.0:
		var push := Vector2(signf(dir) * 2.0, 0)
		var up := Vector2(0, -17)
		if test_move(global_transform, push) and not test_move(global_transform, up) \
				and not test_move(global_transform.translated(up), push):
			position.y -= 17.0
	move_and_slide()
	invuln = maxf(0.0, invuln - delta)
	_swing = maxf(0.0, _swing - delta)
	queue_redraw()


func knockback(from: Vector2) -> void:
	var d := (global_position - from).normalized()
	velocity = Vector2(d.x * 260.0, -180.0)


func swing(dir: Vector2) -> void:
	_swing = 0.18
	_swing_dir = dir
	if absf(dir.x) > 0.2:
		facing = 1 if dir.x > 0.0 else -1


func _draw() -> void:
	if invuln > 0.0 and int(invuln * 20.0) % 2 == 0:
		return
	var cloak := Color(0.55, 0.22, 0.12)
	draw_rect(Rect2(-6, -6, 12, 20), cloak)
	draw_rect(Rect2(-5, 10, 4, 4), Color(0.25, 0.18, 0.12))
	draw_rect(Rect2(1, 10, 4, 4), Color(0.25, 0.18, 0.12))
	draw_rect(Rect2(-5, -14, 10, 9), Color(0.95, 0.78, 0.6))
	draw_rect(Rect2(-6, -15, 12, 3), Color(0.35, 0.2, 0.1))
	draw_rect(Rect2(1 if facing > 0 else -3, -11, 2, 2), Color(0.1, 0.1, 0.15))
	# A small lantern on the belt, the player's personal light.
	draw_rect(Rect2(facing * 5 - 2, 0, 4, 5), Color(1.0, 0.8, 0.35))
	if _swing > 0.0:
		var a := _swing_dir.angle()
		var t := 1.0 - _swing / 0.18
		draw_arc(Vector2.ZERO, 22.0, a - 1.2 + t * 0.8, a + 0.4 + t * 0.8, 10, Color(1, 0.9, 0.7, 0.8), 3.0)
