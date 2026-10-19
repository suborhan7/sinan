extends Node2D
## Gloomling: a fog creature that drifts through rock toward the nearest light and snuffs it out.
## Spawns only in Gloomed tiles and is burned by Kindled light.

var main: Node
var world: World
var tide := false
var hp := 8.0
var speed := 38.0
var _t := 0.0
var _target := Vector2i(-1, -1)
var _retarget := 0.0
var _attack_cd := 0.0
var _burn := 0.0
var _echo_t := -1.0
var _echo_dmg := 0.0
var _flash := 0.0


func _ready() -> void:
	add_to_group("wisps")
	z_index = 12
	_t = randf() * 10.0
	if tide:
		hp = 10.0
		speed = 46.0


func _process(delta: float) -> void:
	_t += delta
	_retarget -= delta
	_attack_cd -= delta
	_flash = maxf(0.0, _flash - delta)
	if _retarget <= 0.0 or not world.lights.has(_target):
		_pick_target()
	var player: Node2D = main.player
	var goal := player.global_position
	var chasing_player := true
	if world.lights.has(_target) and not (_target == world.hearth_cell and not world.hearth_lit):
		goal = world.cell_center(_target)
		chasing_player = false
	var to := goal - global_position
	var bob := Vector2(0, sin(_t * 3.0) * 10.0)
	if to.length() > 8.0:
		global_position += (to.normalized() * speed + bob) * delta
	elif not chasing_player and _attack_cd <= 0.0:
		_attack_cd = 0.8
		main.damage_light(_target, 1)
	if global_position.distance_to(player.global_position) < 15.0:
		main.hurt_player(8.0, global_position)
	# Kindled light burns Gloomlings.
	var c := world.to_cell(global_position)
	if world.gloom_at(c) < 10 and world.light_at(c) >= 8:
		hp -= 1.5 * delta
	if _burn > 0.0:
		_burn -= delta
		hp -= 1.0 * delta
	if _echo_t >= 0.0:
		_echo_t -= delta
		if _echo_t < 0.0:
			_damage(_echo_dmg)
	if hp <= 0.0:
		main.on_wisp_killed(self)
		queue_free()
	queue_redraw()


func _pick_target() -> void:
	_retarget = 1.5
	_target = Vector2i(-1, -1)
	var best := (70.0 if tide else 40.0) * World.T
	if not tide and global_position.distance_to(main.player.global_position) < 7.0 * World.T:
		return
	for c in world.lights:
		if c == world.hearth_cell and not world.hearth_lit:
			continue
		var d := global_position.distance_to(world.cell_center(c))
		if d < best:
			best = d
			_target = c


func take_hit(dmg: float, runes: Array, from: Vector2) -> void:
	_damage(dmg)
	global_position += (global_position - from).normalized() * 14.0
	if "ignite" in runes:
		_burn = 3.0
	if "echo" in runes:
		_echo_t = 0.25
		_echo_dmg = dmg * 0.5


func _damage(d: float) -> void:
	hp -= d
	_flash = 0.12


func _draw() -> void:
	var body := Color(0.16, 0.08, 0.26, 0.92)
	if _flash > 0.0:
		body = Color(1, 1, 1, 0.9)
	elif _burn > 0.0:
		body = Color(0.5, 0.2, 0.1, 0.92)
	var r := 9.0 if tide else 7.5
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		var rr := r + sin(_t * 5.0 + i * 1.7) * 1.6
		if a > 0.3 and a < PI - 0.3:
			rr += 3.0 + sin(_t * 7.0 + i) * 2.0  # trailing wisps underneath
		pts.append(Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, body)
	var eye := Color(1.0, 0.35, 0.3) if tide else Color(0.75, 0.95, 1.0)
	draw_circle(Vector2(-3, -2), 1.6, eye)
	draw_circle(Vector2(3, -2), 1.6, eye)
