extends Node2D
## Game controller: input, mining/placing/combat, day and night, Gloom Tides, Hearth, forge, saving.

const T := Data.TILE
const REACH := 6.0 * T
const SAVE_PATH := "user://emberdeep_save.json"
const DAY_LEN := 200.0      # seconds per full day
const NIGHT_START := 0.62   # fraction of the day when night falls
const HEARTH_HP_BASE := 40.0

const PlayerScript := preload("res://scripts/player.gd")
const WispScript := preload("res://scripts/wisp.gd")
const HearthFx := preload("res://scripts/hearth_fx.gd")
const CursorScript := preload("res://scripts/cursor.gd")
const HudScript := preload("res://scripts/hud.gd")

var world: World
var player: CharacterBody2D
var hud: CanvasLayer
var cam: Camera2D
var cursor: Node2D
var hearth_fx: Node2D
var inv := Inventory.new()
var wisp_layer: Node2D

var time_of_day := 0.08
var day := 1
var is_night := false
var tide_active := false
var tide_to_spawn := 0
var hearth_hp := HEARTH_HP_BASE
var hearth_out := 0.0

var _mine_cell := Vector2i(-1, -1)
var _mine_progress := 0.0
var _place_cd := 0.0
var _attack_cd := 0.0
var _light_t := 0.0
var _gloom_t := 0.0
var _spawn_t := 0.0
var _tide_t := 0.0
var _save_t := 0.0
var _toast_cd := 0.0
var _lmb := false
var _rmb := false
var _touch_index := -1
var _touch_pos := Vector2.ZERO
var _touch_mode := ""
var _autotest := false


func _ready() -> void:
	_setup_input()
	_autotest = "--autotest" in OS.get_cmdline_user_args()
	world = World.new()
	add_child(world)
	hearth_fx = HearthFx.new()
	world.add_child(hearth_fx)
	wisp_layer = Node2D.new()
	world.add_child(wisp_layer)
	player = PlayerScript.new()
	world.add_child(player)
	cursor = CursorScript.new()
	world.add_child(cursor)
	cam = Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = World.W * T
	cam.limit_bottom = World.H * T
	player.add_child(cam)
	hud = HudScript.new()
	hud.main = self
	add_child(hud)
	if _autotest or not _load_game():
		_start_world(randi() if not _autotest else 12345)
	hud.touch_root.visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	hud.banner("Day %d" % day)
	if _autotest:
		var t: Node = load("res://tests/autotest.gd").new()
		add_child(t)


func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP], "attack": [KEY_F],
		"interact": [KEY_E], "craft": [KEY_C], "close": [KEY_ESCAPE],
		"toggle_touch": [KEY_F1], "new_world": [KEY_F9],
	}
	for i in 10:
		keys["slot_%d" % i] = [KEY_1 + i if i < 9 else KEY_0]
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	# Controller: left stick / d-pad to move, A to jump, X to attack, Y for the Hearth.
	var pad := [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0]]
	for p in pad:
		var m := InputEventJoypadMotion.new()
		m.axis = p[1]
		m.axis_value = p[2]
		InputMap.action_add_event(p[0], m)
	for p in [["jump", JOY_BUTTON_A], ["attack", JOY_BUTTON_X], ["interact", JOY_BUTTON_Y], ["move_left", JOY_BUTTON_DPAD_LEFT], ["move_right", JOY_BUTTON_DPAD_RIGHT]]:
		var b := InputEventJoypadButton.new()
		b.button_index = p[1]
		InputMap.action_add_event(p[0], b)


func _start_world(s: int) -> void:
	world.generate(s)
	world.hearth_level = 1
	inv.from_save([])
	inv.add_tool({"core": "pick", "frame": "worn", "runes": []})
	inv.add(Data.TORCH, 6)
	time_of_day = 0.08
	day = 1
	is_night = false
	tide_active = false
	tide_to_spawn = 0
	hearth_hp = _hearth_max_hp()
	hearth_out = 0.0
	for w in wisp_layer.get_children():
		w.queue_free()
	_respawn()
	_after_world_loaded()


func _after_world_loaded() -> void:
	hearth_fx.position = world.cell_center(world.hearth_cell) + Vector2(0, T * 0.5 - 6)
	_sync_hearth()
	world.player_cell = world.to_cell(player.global_position)
	world.update_light(world.player_cell)
	world.update_overlay(0.0)
	cam.reset_smoothing()


func new_world() -> void:
	hud.close_panels()
	_start_world(randi())
	hud.banner("A new world. Day 1")
	save_game()


func _respawn() -> void:
	player.global_position = world.cell_center(world.hearth_cell) + Vector2(3 * T, -T)
	player.velocity = Vector2.ZERO
	player.hp = player.max_hp


# --- Input ------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and not hud.is_over_ui(event.position):
			_touch_index = event.index
			_touch_pos = event.position
			_touch_mode = _context_mode(_screen_to_world(event.position))
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_touch_pos = event.position
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		var over: bool = hud.is_over_ui(event.position)
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_lmb = event.pressed and not over
				if _lmb and _is_hearth_cell(world.to_cell(_screen_to_world(event.position))):
					_lmb = false
					hud.toggle_hearth()
			MOUSE_BUTTON_RIGHT:
				_rmb = event.pressed and not over
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					hud.select(posmod(hud.selected - 1, Inventory.SIZE))
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					hud.select(posmod(hud.selected + 1, Inventory.SIZE))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("craft"):
		hud.toggle_craft()
	elif event.is_action_pressed("interact"):
		hud.toggle_hearth()
	elif event.is_action_pressed("close"):
		hud.close_panels()
	elif event.is_action_pressed("toggle_touch"):
		hud.touch_root.visible = not hud.touch_root.visible
	elif event.is_action_pressed("new_world"):
		hud.request_new_world()
	else:
		for i in 10:
			if event.is_action_pressed("slot_%d" % i):
				hud.select(i)


func _screen_to_world(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * p


func _is_hearth_cell(c: Vector2i) -> bool:
	var d := c - world.hearth_cell
	return absi(d.x) <= 1 and d.y >= -2 and d.y <= 0


## On touch, one tap does the sensible thing: hit a foe, mine a block, open the Hearth, or place.
func _context_mode(wpos: Vector2) -> String:
	var c := world.to_cell(wpos)
	if _enemy_near(wpos, 28.0):
		return "attack"
	if _is_hearth_cell(c):
		hud.toggle_hearth()
		return ""
	var b := world.get_block(c)
	if b != Data.AIR:
		return "mine"
	return "place"


func _enemy_near(wpos: Vector2, r: float) -> bool:
	for w in wisp_layer.get_children():
		if w.global_position.distance_to(wpos) < r:
			return true
	return false


# --- Frame ------------------------------------------------------------------

func _process(delta: float) -> void:
	_update_time(delta)
	_place_cd -= delta
	_attack_cd -= delta
	_toast_cd -= delta
	var act := ""
	var wpos: Vector2
	if _touch_index != -1:
		wpos = _screen_to_world(_touch_pos)
		act = _touch_mode
	else:
		wpos = _screen_to_world(get_viewport().get_mouse_position())
		if _lmb:
			act = "attack" if _enemy_near(wpos, 24.0) else "mine"
		elif _rmb:
			act = "place"
	if hud.any_panel_open() and _touch_index == -1:
		act = ""
	var cell := world.to_cell(wpos)
	match act:
		"mine":
			_do_mine(cell, delta)
		"place":
			_do_place(cell)
		"attack":
			_do_attack(wpos)
	if act != "mine":
		_mine_progress = 0.0
	if Input.is_action_just_pressed("attack"):
		_do_attack(_auto_aim())
	var touch_ui: bool = hud.touch_root.visible
	cursor.visible = not touch_ui or _touch_index != -1
	if cursor.visible:
		var hard := 1.0
		if world.get_block(cell) != Data.AIR and Data.BLOCKS.has(world.get_block(cell)):
			hard = Data.BLOCKS[world.get_block(cell)]["hard"]
		cursor.show_at(cell, _in_reach(cell), _mine_progress / hard if cell == _mine_cell else 0.0)
	_tick_sim(delta)
	_update_player(delta)
	_update_hud()
	_save_t += delta
	if _save_t > 30.0 and not _autotest:
		_save_t = 0.0
		save_game()


func _auto_aim() -> Vector2:
	var best := player.global_position + Vector2(player.facing * 24, 0)
	var bd := 70.0
	for w in wisp_layer.get_children():
		var d := player.global_position.distance_to(w.global_position)
		if d < bd:
			bd = d
			best = w.global_position
	return best


func _in_reach(c: Vector2i) -> bool:
	return player.global_position.distance_to(world.cell_center(c)) <= REACH


func _do_mine(c: Vector2i, delta: float) -> void:
	var b := world.get_block(c)
	if b == Data.AIR or b == Data.HEARTH or not world.in_bounds(c) or not _in_reach(c):
		_mine_progress = 0.0
		return
	var pick := inv.best_tool("pick")
	var st := Data.tool_stats(pick)
	var d: Dictionary = Data.BLOCKS[b]
	if st["tier"] < d["tier"]:
		if _toast_cd <= 0.0:
			hud.toast("Too hard. You need a stronger pick (forge one at the Hearth)." if d["tier"] < 90 else "Nothing can break this.")
			_toast_cd = 1.5
		return
	if c != _mine_cell:
		_mine_cell = c
		_mine_progress = 0.0
	_mine_progress += delta * st["speed"]
	if _mine_progress >= d["hard"]:
		_mine_progress = 0.0
		_break(c)
		if "echo" in pick.get("runes", []):
			var dir := c - world.to_cell(player.global_position)
			var step := Vector2i(signi(dir.x), 0) if absi(dir.x) >= absi(dir.y) else Vector2i(0, signi(dir.y))
			var nxt := c + step
			var nb := world.get_block(nxt)
			if nb != Data.AIR and nb != Data.HEARTH and Data.BLOCKS[nb]["tier"] <= st["tier"]:
				_break(nxt)


func _break(c: Vector2i) -> void:
	var b := world.get_block(c)
	var drop: int = Data.BLOCKS[b]["drop"]
	world.set_block(c, Data.AIR)
	if drop != Data.AIR:
		if inv.add(drop, 1) > 0:
			hud.toast("Inventory full")
	_light_t = 0.0


func _do_place(c: Vector2i) -> void:
	if _place_cd > 0.0:
		return
	var slot: Dictionary = inv.slots[hud.selected]
	if slot.is_empty() or not Data.is_block(slot["id"]):
		return
	var id: int = slot["id"]
	if world.get_block(c) != Data.AIR or not _in_reach(c) or not world.has_support(c):
		return
	var tile := Rect2(Vector2(c * T), Vector2(T, T))
	var body := Rect2(player.global_position - Vector2(6, 14), Vector2(12, 28))
	if Data.is_solid(id) and tile.intersects(body):
		return
	world.set_block(c, id)
	inv.remove(id, 1)
	_place_cd = 0.12
	_light_t = 0.0


func _do_attack(wpos: Vector2) -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = 0.38
	var blade := inv.best_tool("blade")
	var dmg: float = Data.tool_stats(blade)["dmg"]
	var dir := wpos - player.global_position
	dir = dir.normalized() if dir.length() > 1.0 else Vector2(player.facing, 0)
	player.swing(dir)
	var center := player.global_position + dir * 22.0
	for w in wisp_layer.get_children():
		if w.global_position.distance_to(center) < 30.0:
			w.take_hit(dmg, blade.get("runes", []), player.global_position)


# --- Simulation -------------------------------------------------------------

func _tick_sim(delta: float) -> void:
	_light_t -= delta
	if _light_t <= 0.0:
		_light_t = 0.12
		world.player_cell = world.to_cell(player.global_position)
		world.update_light(world.player_cell)
		world.update_overlay(Time.get_ticks_msec() / 1000.0)
	_gloom_t -= delta
	if _gloom_t <= 0.0:
		_gloom_t = 0.5
		world.tick_gloom()
	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = 2.5
		var normal := 0
		for w in wisp_layer.get_children():
			if not w.tide:
				normal += 1
		if normal < (7 if is_night else 4):
			_try_spawn(world.to_cell(player.global_position), 20, 34, false)
	if tide_active:
		_tide_t -= delta
		if tide_to_spawn > 0 and _tide_t <= 0.0:
			_tide_t = 1.4
			if _try_spawn(world.hearth_cell, 28, 40, true):
				tide_to_spawn -= 1
		elif tide_to_spawn <= 0:
			var left := 0
			for w in wisp_layer.get_children():
				if w.tide:
					left += 1
			if left == 0:
				tide_active = false
				inv.add(Data.SHARD, 3)
				hud.banner("The Tide breaks! The light holds.")
				hud.toast("+3 Gloom Shards")
	if hearth_out > 0.0:
		hearth_out -= delta
		if hearth_out <= 0.0:
			world.hearth_lit = true
			hearth_hp = _hearth_max_hp() * 0.5
			hud.banner("The Hearth rekindles.")
	elif hearth_hp < _hearth_max_hp():
		hearth_hp = minf(_hearth_max_hp(), hearth_hp + delta * 0.5)
	_sync_hearth()


func _try_spawn(around: Vector2i, rmin: int, rmax: int, tide: bool) -> bool:
	for attempt in 12:
		var a := randf() * TAU
		var r := randf_range(rmin, rmax)
		var c := around + Vector2i(int(cos(a) * r), int(sin(a) * r * 0.7))
		if not world.in_bounds(c) or world.gloom_at(c) < 50:
			continue
		var w: Node2D = WispScript.new()
		w.main = self
		w.world = world
		w.tide = tide
		w.global_position = world.cell_center(c)
		wisp_layer.add_child(w)
		return true
	return false


func _update_time(delta: float) -> void:
	time_of_day += delta / DAY_LEN
	if time_of_day >= 1.0:
		time_of_day -= 1.0
		day += 1
		hud.banner("Day %d" % day)
	var night_now := time_of_day >= NIGHT_START
	if night_now and not is_night:
		is_night = true
		_on_night()
	elif not night_now and is_night:
		is_night = false
	var s := 1.0
	if time_of_day > NIGHT_START - 0.06 and time_of_day < NIGHT_START + 0.02:
		s = 1.0 - (time_of_day - (NIGHT_START - 0.06)) / 0.08
	elif time_of_day >= NIGHT_START + 0.02 and time_of_day < 0.96:
		s = 0.0
	elif time_of_day >= 0.96:
		s = (time_of_day - 0.96) / 0.04
	world.sun_level = int(lerpf(3.0, 15.0, s))
	var sky := Color(0.45, 0.68, 0.92).lerp(Color(0.03, 0.03, 0.09), 1.0 - s)
	var g := world.gloom_at(world.to_cell(player.global_position)) / 100.0
	RenderingServer.set_default_clear_color(sky.lerp(Color(0.25, 0.16, 0.35), g * 0.6))


func _on_night() -> void:
	if day >= 2 and day % 2 == 0:
		tide_active = true
		tide_to_spawn = 6 + day * 2
		_tide_t = 3.0
		hud.banner("Night %d. A Gloom Tide is rising!" % day)
		hud.toast("Gloomlings will hunt your lights. Defend the Hearth.")
	else:
		hud.banner("Night %d. The Gloom creeps closer." % day)


func _update_player(delta: float) -> void:
	var g := world.gloom_at(world.to_cell(player.global_position))
	if g == 0:
		player.hp = minf(player.max_hp, player.hp + 4.0 * delta)
	elif g < 50:
		player.hp = minf(player.max_hp, player.hp + 0.5 * delta)
	if player.global_position.y > World.H * T:
		player.hp = 0
	if player.hp <= 0.0:
		_respawn()
		player.invuln = 2.0
		hud.banner("The Hearth pulls you back from the dark.")


func hurt_player(dmg: float, from: Vector2) -> void:
	if player.invuln > 0.0:
		return
	player.hp -= dmg
	player.invuln = 0.7
	player.knockback(from)


func damage_light(c: Vector2i, amount: int) -> void:
	if c == world.hearth_cell:
		if not world.hearth_lit:
			return
		hearth_hp -= amount
		if hearth_hp <= 0.0:
			hearth_hp = 0.0
			world.hearth_lit = false
			hearth_out = 25.0
			hud.banner("The Hearth is smothered!")
			hud.toast("Its light returns in a moment. Clear the Gloomlings.")
		return
	if not world.light_hp.has(c):
		return
	world.light_hp[c] -= amount
	if world.light_hp[c] <= 0:
		var bname: String = Data.BLOCKS[world.get_block(c)]["name"]
		world.set_block(c, Data.AIR)
		hud.toast("A %s was snuffed out!" % bname.to_lower())
		_light_t = 0.0


func on_wisp_killed(w: Node2D) -> void:
	if randf() < (0.8 if w.tide else 0.5):
		inv.add(Data.SHARD, 1)
		hud.toast("+1 Gloom Shard")


# --- Hearth, crafting, forge -------------------------------------------------

func _hearth_max_hp() -> float:
	return HEARTH_HP_BASE + 20.0 * (world.hearth_level - 1)


func _sync_hearth() -> void:
	hearth_fx.level = world.hearth_level
	hearth_fx.lit = world.hearth_lit
	hearth_fx.hp = hearth_hp
	hearth_fx.max_hp = _hearth_max_hp()


func near_hearth() -> bool:
	return player.global_position.distance_to(world.cell_center(world.hearth_cell)) < 9.0 * T


func feed_hearth() -> void:
	var lvl := world.hearth_level
	if lvl - 1 >= Data.HEARTH_LEVELS.size() or not inv.pay(Data.HEARTH_LEVELS[lvl - 1]):
		return
	world.hearth_level += 1
	hearth_hp = _hearth_max_hp()
	world.hearth_lit = true
	hearth_out = 0.0
	hud.banner("Hearth Level %d! Its light reaches further." % world.hearth_level)
	hud.refresh_panels()


func craft(i: int) -> void:
	var r: Dictionary = Data.RECIPES[i]
	if inv.pay(r["in"]):
		inv.add(r["out"], r["n"])
		hud.toast("Crafted %d %s" % [r["n"], Data.item_name(r["out"])])


func forge_cost(frame: String, runes: Array) -> Dictionary:
	var cost: Dictionary = Data.FRAMES[frame]["cost"]
	for r in runes:
		cost = Data.merge_costs(cost, Data.RUNES[r]["cost"])
	return cost


func forge(core: String, frame: String, runes: Array) -> void:
	if runes.size() > Data.FRAMES[frame]["slots"]:
		return
	var cost := forge_cost(frame, runes)
	if not inv.has_all(cost):
		return
	var tool := {"core": core, "frame": frame, "runes": runes}
	inv.pay(cost)
	if not inv.add_tool(tool):
		for id in cost:
			inv.add(id, cost[id])
		hud.toast("No room for it. Free a slot first.")
		return
	hud.toast("Forged: %s" % Data.tool_name(tool))


# --- HUD text ---------------------------------------------------------------

func _update_hud() -> void:
	var g := world.gloom_at(world.to_cell(player.global_position))
	var zone := "Kindled" if g == 0 else ("Dim" if g < 50 else "Gloomed")
	var phase := "Night" if is_night else "Day"
	var status := "%s %d   |   %s   |   Hearth Lv %d%s" % [phase, day, zone, world.hearth_level, "" if world.hearth_lit else " (smothered)"]
	if tide_active:
		status += "   |   TIDE"
	hud.update_status(player.hp, player.max_hp, status, _goal_text())


func _goal_text() -> String:
	var lvl := world.hearth_level
	if inv.count(Data.LANTERN) == 0 and world.purgers.is_empty() and lvl == 1 and inv.count(Data.COPPER) < 2:
		return "Goal: dig for coal and copperleaf ore. Craft a Lantern and carry it into the dark: lanterns burn the Gloom away."
	if lvl - 1 < Data.HEARTH_LEVELS.size():
		return "Goal: feed the Hearth.  " + Data.cost_text(Data.HEARTH_LEVELS[lvl - 1], inv)
	return "Goal: claim the world. Push lanterns deep into the Gloom and hold them."


# --- Save / load ------------------------------------------------------------

func save_game() -> void:
	var d := world.to_save()
	d["version"] = 1
	d["inv"] = inv.to_save()
	d["player"] = [player.global_position.x, player.global_position.y]
	d["time"] = time_of_day
	d["day"] = day
	d["hearth_hp"] = hearth_hp
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func _load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not d is Dictionary or int(d.get("version", 0)) != 1:
		return false
	world.from_save(d)
	inv.from_save(d.get("inv", []))
	var p: Array = d.get("player", [])
	_respawn()
	if p.size() == 2:
		player.global_position = Vector2(p[0], p[1])
	time_of_day = float(d.get("time", 0.08))
	day = int(d.get("day", 1))
	is_night = time_of_day >= NIGHT_START
	hearth_hp = float(d.get("hearth_hp", _hearth_max_hp()))
	_after_world_loaded()
	return true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if world and not _autotest:
			save_game()
