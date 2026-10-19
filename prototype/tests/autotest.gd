extends Node
## Scripted smoke test: `godot --path . -- --autotest`. Prints PASS/FAIL lines and saves screenshots to build/shots.

var main: Node
var fails := 0


func _ready() -> void:
	main = get_parent()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/shots"))
	_run()


func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(name: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://build/shots/%s.png" % name)


func _run() -> void:
	var w: World = main.world
	var p: CharacterBody2D = main.player
	await frames(60)
	var counts := {}
	for b in w.cells:
		counts[b] = counts.get(b, 0) + 1
	for id in counts:
		print("  block %s: %d" % [Data.BLOCKS[id]["name"] if Data.BLOCKS.has(id) else "Air", counts[id]])
	check(counts.get(Data.COAL, 0) > 50 and counts.get(Data.COPPER, 0) > 50 and counts.get(Data.IRON, 0) > 20, "ores generated")
	check(counts.get(Data.WOOD, 0) > 50, "trees generated")
	check(p.is_on_floor(), "player lands on the ground")
	await shot("01_spawn")

	# Movement
	var x0 := p.global_position.x
	Input.action_press("move_right")
	await frames(45)
	Input.action_release("move_right")
	check(p.global_position.x > x0 + 40, "player walks right (%.0f px)" % (p.global_position.x - x0))
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	await frames(8)
	check(p.velocity.y < 0 or not p.is_on_floor(), "player jumps")
	await frames(60)

	# Mining: dirt below the player
	var pc := w.to_cell(p.global_position)
	var below := pc + Vector2i(0, 1)
	while w.get_block(below) == Data.AIR:
		below.y += 1
	var b0 := w.get_block(below)
	for i in 30:
		main._do_mine(below, 0.1)
	check(w.get_block(below) == Data.AIR, "mined %s below player" % Data.item_name(b0))
	check(main.inv.count(Data.BLOCKS[b0]["drop"]) >= 1, "mined block went to inventory")
	# Placing it back
	for i in Inventory.SIZE:
		if not main.inv.slots[i].is_empty() and main.inv.slots[i]["id"] == Data.BLOCKS[b0]["drop"]:
			main.hud.select(i)
	main._place_cd = 0
	var side := w.to_cell(p.global_position) + Vector2i(2, 0)
	while w.get_block(side) != Data.AIR:
		side.y -= 1
	main._do_place(side)
	check(w.get_block(side) == Data.BLOCKS[b0]["drop"], "placed a block")

	# Hearth feeding
	main.inv.add(Data.WOOD, 10); main.inv.add(Data.STONE, 15); main.inv.add(Data.COAL, 5)
	main.feed_hearth()
	check(w.hearth_level == 2, "Hearth levels up after feeding 3 materials")
	check(w.hearth_radius() == 18, "Hearth radius grew")

	# Crafting a lantern
	main.inv.add(Data.WOOD, 1); main.inv.add(Data.COPPER, 2); main.inv.add(Data.COAL, 1)
	main.craft(0)
	main.craft(3)
	check(main.inv.count(Data.LANTERN) == 1, "crafted a lantern")

	# Forge
	main.inv.add(Data.COPPER, 5); main.inv.add(Data.PLANK, 2); main.inv.add(Data.COAL, 3)
	main.forge("blade", "copper", ["ignite"])
	var blade: Dictionary = main.inv.best_tool("blade")
	check(not blade.is_empty() and blade["runes"] == ["ignite"], "forged Copperleaf Blade +Ignite")
	main.inv.add(Data.IRON, 5); main.inv.add(Data.PLANK, 2); main.inv.add(Data.SHARD, 2); main.inv.add(Data.COAL, 3)
	main.forge("pick", "iron", ["echo", "ignite"])
	check(main.inv.best_tool("pick").get("frame", "") == "iron", "forged Iron Pick with 2 runes")
	main.forge("pick", "copper", ["echo", "ignite"])
	check(main.inv.best_tool("pick").get("frame", "") == "iron", "copper frame rejects 2 runes")

	# Lantern purges Gloom out in the dark
	var far := Vector2i(w.hearth_cell.x + 40, 0)
	while w.get_block(far + Vector2i(0, 1)) == Data.AIR or w.get_block(far + Vector2i(0, 1)) == Data.LEAVES or w.get_block(far + Vector2i(0, 1)) == Data.WOOD:
		far.y += 1
	while w.get_block(far) != Data.AIR:
		far.y -= 1
	p.global_position = w.cell_center(far) + Vector2(-2 * World.T, 0)
	await frames(10)
	var g_before := w.gloom_at(far)
	for i in Inventory.SIZE:
		if not main.inv.slots[i].is_empty() and main.inv.slots[i]["id"] == Data.LANTERN:
			main.hud.select(i)
	main._place_cd = 0
	main._do_place(far)
	check(w.get_block(far) == Data.LANTERN, "placed lantern in the Gloom")
	await shot("02_lantern_before")
	for i in 6:
		w.update_light(w.to_cell(p.global_position))
		w.tick_gloom()
	check(g_before >= 50 and w.gloom_at(far) == 0, "lantern purged Gloom (%d -> %d)" % [g_before, w.gloom_at(far)])
	await frames(10)
	await shot("03_lantern_after")

	# Gloomlings spawn only in Gloom and hunt lights
	var spawned := 0
	for wisp in main.wisp_layer.get_children():
		wisp.free()
	for i in 20:
		if main._try_spawn(w.to_cell(p.global_position), 20, 34, false):
			spawned += 1
	var all_gloomy := true
	for wisp in main.wisp_layer.get_children():
		if w.gloom_at(w.to_cell(wisp.global_position)) < 50:
			all_gloomy = false
	check(spawned > 0 and all_gloomy, "Gloomlings spawn only in Gloom (%d)" % spawned)
	var lantern_hp: int = w.light_hp.get(far, 0)
	await frames(900)
	check(w.get_block(far) != Data.LANTERN or w.light_hp.get(far, 99) < lantern_hp or main.wisp_layer.get_child_count() < spawned, "Gloomlings attacked the lantern or burned in its light")
	# Combat
	for wisp in main.wisp_layer.get_children():
		wisp.queue_free()
	await frames(2)
	main._try_spawn(w.to_cell(p.global_position), 2, 3, false)
	if main.wisp_layer.get_child_count() == 0:
		var wisp: Node2D = main.WispScript.new()
		wisp.main = main
		wisp.world = w
		main.wisp_layer.add_child(wisp)
	var target: Node2D = main.wisp_layer.get_child(0)
	target.global_position = p.global_position + Vector2(20, 0)
	var hp0: float = target.hp
	main._attack_cd = 0
	main._do_attack(target.global_position)
	check(target.hp < hp0, "blade hits a Gloomling")
	for wisp in main.wisp_layer.get_children():
		wisp.queue_free()

	# Night 2 brings a Gloom Tide
	p.global_position = w.cell_center(w.hearth_cell) + Vector2(3 * World.T, -World.T)
	main.day = 2
	main.time_of_day = main.NIGHT_START - 0.0002
	await frames(10)
	check(main.tide_active, "Gloom Tide starts on night 2")
	await frames(600)
	var tide_count := 0
	for wisp in main.wisp_layer.get_children():
		if wisp.tide:
			tide_count += 1
	check(tide_count > 0, "Tide Gloomlings spawned (%d)" % tide_count)
	await shot("04_tide_night")

	# Underground
	var cave := Vector2i(w.hearth_cell.x - 20, w.hearth_cell.y + 40)
	p.global_position = w.cell_center(cave)
	await frames(30)
	await shot("05_underground")

	# Perf
	p.global_position = w.cell_center(w.hearth_cell) + Vector2(3 * World.T, -World.T)
	var t0 := Time.get_ticks_usec()
	for i in 20:
		w.update_light(w.to_cell(p.global_position))
	var light_ms := (Time.get_ticks_usec() - t0) / 20000.0
	t0 = Time.get_ticks_usec()
	for i in 20:
		w.update_overlay(0.0)
	var ov_ms := (Time.get_ticks_usec() - t0) / 20000.0
	t0 = Time.get_ticks_usec()
	for i in 20:
		w.tick_gloom()
	var gl_ms := (Time.get_ticks_usec() - t0) / 20000.0
	print("  perf: light %.2f ms, overlay %.2f ms, gloom %.2f ms per update" % [light_ms, ov_ms, gl_ms])

	# Touch layout and Hearth panel
	main.hud.touch_root.visible = true
	main.time_of_day = 0.2
	await frames(30)
	await shot("06_touch_ui")
	main.hud.toggle_hearth()
	await shot("07_hearth_panel")
	main.hud.close_panels()
	main.hud.toggle_craft()
	await shot("08_craft_panel")
	main.hud.close_panels()

	# Save / load round trip
	main.save_game()
	var lvl: int = w.hearth_level
	var changed := w.changes.size()
	w.hearth_level = 1
	main._load_game()
	check(main.world.hearth_level == lvl and main.world.changes.size() == changed, "save/load keeps Hearth level and %d edits" % changed)
	check(main.inv.best_tool("pick").get("frame", "") == "iron", "save/load keeps forged gear")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.SAVE_PATH))

	print("RESULT: %s (%d failures)" % ["OK" if fails == 0 else "FAILED", fails])
	get_tree().quit(1 if fails else 0)
