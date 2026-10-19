extends Node2D
## Draws the Hearth bonfire, which grows with its level and gutters when smothered.

var level := 1
var lit := true
var hp := 40.0
var max_hp := 40.0
var _t := 0.0
var _embers: CPUParticles2D


func _ready() -> void:
	z_index = 9
	_embers = CPUParticles2D.new()
	_embers.amount = 18
	_embers.lifetime = 2.2
	_embers.position = Vector2(0, -6)
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.emission_rect_extents = Vector2(10, 2)
	_embers.direction = Vector2(0, -1)
	_embers.spread = 25.0
	_embers.gravity = Vector2(0, -12)
	_embers.initial_velocity_min = 12.0
	_embers.initial_velocity_max = 28.0
	_embers.scale_amount_min = 1.0
	_embers.scale_amount_max = 2.0
	_embers.color = Color(1.0, 0.65, 0.2)
	_embers.z_index = 13
	add_child(_embers)


func _process(delta: float) -> void:
	_t += delta
	_embers.emitting = lit
	queue_redraw()


func _draw() -> void:
	var stone := Color(0.38, 0.34, 0.32)
	for i in 5:
		draw_circle(Vector2(-16 + i * 8, 4), 4.5, stone.darkened(0.1 * (i % 2)))
	draw_rect(Rect2(-12, 0, 24, 6), Color(0.25, 0.15, 0.1))
	if lit:
		var tongues := 3 + level
		for i in tongues:
			var x := -10.0 + 20.0 * i / maxf(1.0, tongues - 1.0)
			var h := 12.0 + level * 4.0 + sin(_t * 8.0 + i * 1.3) * 3.0 - absf(x) * 0.4
			var sway := sin(_t * 5.0 + i) * 2.5
			draw_colored_polygon(PackedVector2Array([Vector2(x - 5, 2), Vector2(x + 5, 2), Vector2(x + sway, 2 - h)]), Color(1.0, 0.45, 0.1))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 2.5, 2), Vector2(x + 2.5, 2), Vector2(x + sway * 0.6, 2 - h * 0.6)]), Color(1.0, 0.85, 0.35))
	else:
		for i in 4:
			draw_circle(Vector2(-6 + i * 4, 0), 1.5, Color(0.8, 0.2, 0.05, 0.5 + 0.4 * sin(_t * 3.0 + i)))
	if hp < max_hp:
		draw_rect(Rect2(-16, -34 - level * 4, 32, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-16, -34 - level * 4, 32 * hp / max_hp, 4), Color(1.0, 0.6, 0.2))
