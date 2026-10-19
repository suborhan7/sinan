extends CanvasLayer
## All on-screen UI, built in code: status, hotbar, crafting, Hearth (feed + forge), touch controls.

const PARCHMENT := Color(0.93, 0.85, 0.68)
const BRASS := Color(0.78, 0.58, 0.28)
const INK := Color(0.22, 0.14, 0.08)

var main: Node
var selected := 0
var touch_root: Control

var _root: Control
var _slots: Array[Button] = []
var _slot_icons: Array[TextureRect] = []
var _slot_counts: Array[Label] = []
var _hp_bar: ProgressBar
var _status: Label
var _goal: Label
var _banner: Label
var _banner_t := 0.0
var _toast: Label
var _toast_t := 0.0
var _item_name: Label
var _craft_panel: PanelContainer
var _craft_list: VBoxContainer
var _hearth_panel: PanelContainer
var _hearth_title: Label
var _feed_cost: Label
var _feed_btn: Button
var _forge_cost: Label
var _forge_btn: Button
var _core := "pick"
var _frame := "copper"
var _runes := []
var _rune_btns := {}
var _ui_rects: Array[Control] = []
var _touch_help: Label
var _new_world_btn: Button
var _new_world_armed := 0.0
var _style_slot: StyleBoxFlat
var _style_selected: StyleBoxFlat


func _ready() -> void:
	layer = 5
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
	_build_status()
	_build_hotbar()
	_build_top_buttons()
	_build_craft_panel()
	_build_hearth_panel()
	_build_touch()
	main.inv.changed.connect(refresh_inventory)
	refresh_inventory()


func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 18
	var panel := StyleBoxFlat.new()
	panel.bg_color = PARCHMENT
	panel.border_color = BRASS
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(6)
	panel.set_content_margin_all(14)
	th.set_stylebox("panel", "PanelContainer", panel)
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(0.36, 0.24, 0.14, 0.92)
	btn.border_color = BRASS
	btn.set_border_width_all(2)
	btn.set_corner_radius_all(5)
	btn.set_content_margin_all(8)
	var hover := btn.duplicate()
	hover.bg_color = Color(0.48, 0.32, 0.18, 0.95)
	var pressed := btn.duplicate()
	pressed.bg_color = Color(0.7, 0.45, 0.2, 1.0)
	pressed.border_color = Color(1.0, 0.85, 0.5)
	var disabled := btn.duplicate()
	disabled.bg_color = Color(0.3, 0.26, 0.22, 0.6)
	th.set_stylebox("normal", "Button", btn)
	th.set_stylebox("hover", "Button", hover)
	th.set_stylebox("pressed", "Button", pressed)
	th.set_stylebox("hover_pressed", "Button", pressed)
	th.set_stylebox("disabled", "Button", disabled)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", Color(1.0, 0.92, 0.75))
	th.set_color("font_hover_color", "Button", Color(1, 1, 0.9))
	th.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	th.set_color("font_disabled_color", "Button", Color(0.75, 0.68, 0.6))
	th.set_color("font_color", "Label", Color(1.0, 0.95, 0.85))
	th.set_color("font_outline_color", "Label", Color(0.1, 0.06, 0.04))
	th.set_constant("outline_size", "Label", 4)
	_style_slot = btn.duplicate()
	_style_slot.set_content_margin_all(4)
	_style_selected = pressed.duplicate()
	_style_selected.set_border_width_all(3)
	_style_selected.set_content_margin_all(4)
	return th


func _ink(l: Label) -> Label:
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	return l


func _build_status() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(16, 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(240, 18)
	_hp_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.3, 0.2)
	fill.set_corner_radius_all(4)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.06, 0.05, 0.7)
	back.border_color = BRASS
	back.set_border_width_all(2)
	back.set_corner_radius_all(4)
	_hp_bar.add_theme_stylebox_override("fill", fill)
	_hp_bar.add_theme_stylebox_override("background", back)
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_hp_bar)
	_status = Label.new()
	box.add_child(_status)
	_goal = Label.new()
	_goal.add_theme_font_size_override("font_size", 16)
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD
	_goal.custom_minimum_size = Vector2(460, 0)
	box.add_child(_goal)
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position.y = 90
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 34)
	_banner.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	_banner.add_theme_constant_override("outline_size", 8)
	_root.add_child(_banner)


func _build_hotbar() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.position.y -= 10
	bar.add_theme_constant_override("separation", 4)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)
	for i in Inventory.SIZE:
		var b := Button.new()
		b.custom_minimum_size = Vector2(58, 58)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(select.bind(i))
		var icon := TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 9
		icon.offset_top = 9
		icon.offset_right = -9
		icon.offset_bottom = -9
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(icon)
		var key := Label.new()
		key.text = str((i + 1) % 10)
		key.position = Vector2(4, 0)
		key.add_theme_font_size_override("font_size", 12)
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(key)
		var cnt := Label.new()
		cnt.set_anchors_preset(Control.PRESET_FULL_RECT)
		cnt.offset_right = -5
		cnt.offset_bottom = -1
		cnt.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cnt.add_theme_font_size_override("font_size", 14)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.add_child(cnt)
		bar.add_child(b)
		_slots.append(b)
		_slot_icons.append(icon)
		_slot_counts.append(cnt)
		_ui_rects.append(b)
	_item_name = Label.new()
	_item_name.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_item_name.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_item_name.position.y = -98
	_item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_item_name)
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.position.y = -130
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	_root.add_child(_toast)


func _build_top_buttons() -> void:
	var box := HBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.position = Vector2(-16, 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	for spec in [["Craft (C)", toggle_craft], ["Hearth (E)", toggle_hearth]]:
		var b := Button.new()
		b.text = spec[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(130, 48)
		b.pressed.connect(spec[1])
		box.add_child(b)
		_ui_rects.append(b)


func _panel(title: String) -> Array:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.custom_minimum_size = Vector2(520, 0)
	p.visible = false
	_root.add_child(p)
	_ui_rects.append(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := _ink(Label.new())
	t.text = title
	t.add_theme_font_size_override("font_size", 24)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): p.visible = false)
	head.add_child(close)
	return [p, v, t]


func _build_craft_panel() -> void:
	var r := _panel("Crafting")
	_craft_panel = r[0]
	_craft_list = VBoxContainer.new()
	r[1].add_child(_craft_list)
	var hint := _ink(Label.new())
	hint.text = "Torches hold back the Gloom. Lanterns burn it away."
	hint.add_theme_font_size_override("font_size", 15)
	r[1].add_child(hint)
	_new_world_btn = Button.new()
	_new_world_btn.text = "Start a new world (F9)"
	_new_world_btn.focus_mode = Control.FOCUS_NONE
	_new_world_btn.pressed.connect(request_new_world)
	r[1].add_child(_new_world_btn)


func _build_hearth_panel() -> void:
	var r := _panel("The Hearth")
	_hearth_panel = r[0]
	_hearth_title = r[2]
	var v: VBoxContainer = r[1]
	_feed_cost = _ink(Label.new())
	_feed_cost.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(_feed_cost)
	_feed_btn = Button.new()
	_feed_btn.text = "Feed the Hearth"
	_feed_btn.focus_mode = Control.FOCUS_NONE
	_feed_btn.pressed.connect(func(): main.feed_hearth())
	v.add_child(_feed_btn)
	v.add_child(HSeparator.new())
	var ft := _ink(Label.new())
	ft.text = "Forge: Core + Frame + Runes"
	ft.add_theme_font_size_override("font_size", 20)
	v.add_child(ft)
	v.add_child(_choice_row("Core", Data.CORES, func(k): _core = k))
	var frames := {}
	for k in Data.FORGE_FRAMES:
		frames[k] = Data.FRAMES[k]
	v.add_child(_choice_row("Frame", frames, func(k): _frame = k))
	var runes := HBoxContainer.new()
	var rl := _ink(Label.new())
	rl.text = "Runes"
	rl.custom_minimum_size.x = 70
	runes.add_child(rl)
	for k in Data.RUNES:
		var b := Button.new()
		b.text = Data.RUNES[k]["name"]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = Data.RUNES[k]["desc"]
		b.toggled.connect(_on_rune.bind(k))
		runes.add_child(b)
		_rune_btns[k] = b
	v.add_child(runes)
	var desc := _ink(Label.new())
	desc.text = "Ignite: burns foes, or digs 50% faster.  Echo: repeats hits, or mines a 2-tile strip.\nCopperleaf holds 1 rune, Iron holds 2."
	desc.add_theme_font_size_override("font_size", 14)
	v.add_child(desc)
	_forge_cost = _ink(Label.new())
	v.add_child(_forge_cost)
	_forge_btn = Button.new()
	_forge_btn.text = "Forge"
	_forge_btn.focus_mode = Control.FOCUS_NONE
	_forge_btn.pressed.connect(func(): main.forge(_core, _frame, _runes.duplicate()))
	v.add_child(_forge_btn)


func _choice_row(title: String, options: Dictionary, on_pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := _ink(Label.new())
	l.text = title
	l.custom_minimum_size.x = 70
	row.add_child(l)
	var group := ButtonGroup.new()
	var first := true
	for k in options:
		var b := Button.new()
		b.text = options[k]["name"]
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.button_pressed = first
		first = false
		b.pressed.connect(func():
			on_pick.call(k)
			refresh_panels())
		row.add_child(b)
	return row


func _on_rune(on: bool, k: String) -> void:
	if on and not k in _runes:
		_runes.append(k)
	elif not on:
		_runes.erase(k)
	refresh_panels()


func _build_touch() -> void:
	touch_root = Control.new()
	touch_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(touch_root)
	var specs := [
		["move_left", "<", Control.PRESET_BOTTOM_LEFT, Vector2(24, -134)],
		["move_right", ">", Control.PRESET_BOTTOM_LEFT, Vector2(148, -134)],
		["jump", "Jump", Control.PRESET_BOTTOM_RIGHT, Vector2(-134, -134)],
		["attack", "Hit", Control.PRESET_BOTTOM_RIGHT, Vector2(-250, -96)],
	]
	for s in specs:
		var b := TouchButton.new(s[0], s[1], 110.0 if s[0] != "attack" else 90.0)
		b.set_anchors_preset(s[2])
		b.position += s[3]
		touch_root.add_child(b)
		_ui_rects.append(b)
	var help := Label.new()
	_touch_help = help
	help.text = "Tap a block to mine it, tap empty space to place, tap a Gloomling to hit it."
	help.add_theme_font_size_override("font_size", 14)
	help.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help.grow_horizontal = Control.GROW_DIRECTION_BOTH
	help.position.y = -160
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	touch_root.add_child(help)


# --- Public -----------------------------------------------------------------

func _input(event: InputEvent) -> void:
	# Hotbar taps from any finger, so you can switch items while holding a move button.
	if event is InputEventScreenTouch and event.pressed:
		for i in _slots.size():
			if _slots[i].get_global_rect().has_point(event.position):
				select(i)


func is_over_ui(p: Vector2) -> bool:
	for c in _ui_rects:
		if c.is_visible_in_tree() and c.get_global_rect().grow(4).has_point(p):
			return true
	return false


func any_panel_open() -> bool:
	return _craft_panel.visible or _hearth_panel.visible


func close_panels() -> void:
	_craft_panel.visible = false
	_hearth_panel.visible = false


func select(i: int) -> void:
	selected = clampi(i, 0, Inventory.SIZE - 1)
	refresh_inventory()


func toggle_craft() -> void:
	_hearth_panel.visible = false
	_craft_panel.visible = not _craft_panel.visible
	refresh_panels()


func toggle_hearth() -> void:
	_craft_panel.visible = false
	if not _hearth_panel.visible and not main.near_hearth():
		toast("Return to the Hearth to feed it or forge.")
		return
	_hearth_panel.visible = not _hearth_panel.visible
	refresh_panels()


func refresh_inventory() -> void:
	for i in _slots.size():
		var s: Dictionary = main.inv.slots[i]
		_slot_icons[i].texture = Textures.icon(s)
		_slot_counts[i].text = "" if s.is_empty() or s["id"] == Data.TOOL else str(s["count"])
		_slots[i].add_theme_stylebox_override("normal", _style_selected if i == selected else _style_slot)
		_slots[i].add_theme_stylebox_override("hover", _style_selected if i == selected else _style_slot)
	var cur: Dictionary = main.inv.slots[selected]
	if cur.is_empty():
		_item_name.text = ""
	elif cur["id"] == Data.TOOL:
		_item_name.text = Data.tool_name(cur["tool"])
	else:
		_item_name.text = Data.item_name(cur["id"])
	refresh_panels()


func refresh_panels() -> void:
	if _craft_panel == null:
		return
	if _craft_panel.visible:
		for c in _craft_list.get_children():
			c.queue_free()
		for i in Data.RECIPES.size():
			var r: Dictionary = Data.RECIPES[i]
			var b := Button.new()
			b.text = "%d %s   <-   %s" % [r["n"], Data.item_name(r["out"]), Data.cost_text(r["in"], main.inv)]
			b.focus_mode = Control.FOCUS_NONE
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.disabled = not main.inv.has_all(r["in"])
			b.icon = Textures.icon({"id": r["out"], "count": 1})
			b.expand_icon = false
			b.pressed.connect(func(): main.craft(i))
			_craft_list.add_child(b)
	if _hearth_panel.visible:
		var lvl: int = main.world.hearth_level
		_hearth_title.text = "The Hearth - Level %d" % lvl
		if lvl - 1 < Data.HEARTH_LEVELS.size():
			var cost: Dictionary = Data.HEARTH_LEVELS[lvl - 1]
			_feed_cost.text = "Feed it to reach Level %d (light reaches %d tiles):\n%s" % [lvl + 1, Data.HEARTH_BASE_RADIUS + Data.HEARTH_RADIUS_PER_LEVEL * (lvl + 1), Data.cost_text(cost, main.inv)]
			_feed_btn.disabled = not main.inv.has_all(cost)
			_feed_btn.visible = true
		else:
			_feed_cost.text = "The Hearth burns at full strength in this prototype."
			_feed_btn.visible = false
		var slots: int = Data.FRAMES[_frame]["slots"]
		for k in _rune_btns:
			var b: Button = _rune_btns[k]
			b.disabled = not b.button_pressed and _runes.size() >= slots
		while _runes.size() > slots:
			var k: String = _runes.pop_back()
			_rune_btns[k].set_pressed_no_signal(false)
		var cost: Dictionary = main.forge_cost(_frame, _runes)
		var tool := {"core": _core, "frame": _frame, "runes": _runes}
		_forge_cost.text = "%s   costs: %s" % [Data.tool_name(tool), Data.cost_text(cost, main.inv)]
		_forge_btn.disabled = not main.inv.has_all(cost)


func update_status(hp: float, max_hp: float, status: String, goal: String) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_status.text = status
	_goal.text = goal


## New world wipes progress, so it needs a second press to confirm.
func request_new_world() -> void:
	if _new_world_armed > 0.0:
		_new_world_armed = 0.0
		_new_world_btn.text = "Start a new world (F9)"
		main.new_world()
	else:
		_new_world_armed = 3.0
		_new_world_btn.text = "Press again to erase this world"
		toast("Press again to start over. This world will be erased.")


func banner(text: String) -> void:
	_banner.text = text
	_banner_t = 4.0
	_banner.modulate.a = 1.0


func toast(text: String) -> void:
	_toast.text = text
	_toast_t = 2.2
	_toast.modulate.a = 1.0


func _process(delta: float) -> void:
	_banner_t -= delta
	_banner.modulate.a = clampf(_banner_t, 0.0, 1.0)
	_toast_t -= delta
	_toast.modulate.a = clampf(_toast_t * 2.0, 0.0, 1.0)
	_touch_help.visible = not any_panel_open()
	if _new_world_armed > 0.0:
		_new_world_armed -= delta
		if _new_world_armed <= 0.0:
			_new_world_btn.text = "Start a new world (F9)"
