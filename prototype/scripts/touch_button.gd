class_name TouchButton
extends Control
## Multitouch on-screen button that presses an input action while a finger is on it.
## Reads touches in _input so several buttons can be held at once.

var action := ""
var label := ""
var _touch := -2  # -2 = up, -1 = held by mouse, >=0 = touch index


func _init(p_action := "", p_label := "", diameter := 110.0) -> void:
	action = p_action
	label = p_label
	custom_minimum_size = Vector2(diameter, diameter)
	size = custom_minimum_size
	mouse_filter = MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -2 and _hit(event.position):
			_press(event.index)
		elif not event.pressed and event.index == _touch:
			_release()
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _touch == -2 and _hit(event.position):
			_press(-1)
		elif not event.pressed and _touch == -1:
			_release()


func _hit(p: Vector2) -> bool:
	return get_global_rect().grow(8).has_point(p)


func _press(idx: int) -> void:
	_touch = idx
	Input.action_press(action)
	queue_redraw()


func _release() -> void:
	_touch = -2
	Input.action_release(action)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and _touch != -2:
		_release()


func _draw() -> void:
	var held := _touch != -2
	var c := size / 2.0
	draw_circle(c, size.x / 2.0, Color(0.2, 0.13, 0.08, 0.55 if held else 0.35))
	draw_arc(c, size.x / 2.0 - 2.0, 0, TAU, 32, Color(0.95, 0.75, 0.4, 0.9 if held else 0.6), 3.0)
	var font := get_theme_default_font()
	var fs := 26
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, c + Vector2(-w / 2.0, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.92, 0.75))
