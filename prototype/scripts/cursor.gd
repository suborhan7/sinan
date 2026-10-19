extends Node2D
## Highlights the targeted tile and shows mining progress.

var cell := Vector2i.ZERO
var ok := true
var progress := 0.0


func _ready() -> void:
	z_index = 14


func show_at(c: Vector2i, in_reach: bool, p: float) -> void:
	cell = c
	ok = in_reach
	progress = p
	visible = true
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2(cell * World.T), Vector2(World.T, World.T))
	draw_rect(r, Color(1, 1, 1, 0.8) if ok else Color(1, 0.3, 0.3, 0.6), false, 1.0)
	if progress > 0.0:
		draw_rect(r.grow(-1), Color(0, 0, 0, 0.45 * progress))
		var c := r.get_center()
		var n := int(progress * 4.0) + 1
		for i in n:
			var a := i * 1.9 + 0.4
			draw_line(c, c + Vector2(cos(a), sin(a)) * 7.0, Color(0, 0, 0, 0.8), 1.0)
