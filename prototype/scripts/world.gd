class_name World
extends Node2D
## Tile grid, procedural generation, and the Light + Gloom simulation.

const W := 480
const H := 220
const T := Data.TILE
const LIGHT_HALF := Vector2i(52, 34)  # light/overlay region around the player, in tiles

var seed_value := 0
var cells := PackedByteArray()
var walls := PackedByteArray()
var gloom := PackedByteArray()   # 0-100 per tile
var sky := PackedInt32Array()    # first solid tile per column, for skylight
var changes := {}                # tile index -> block id, everything the player changed
var lights := {}                 # Vector2i -> light level
var purgers := {}                # Vector2i -> Gloom purge radius
var light_hp := {}               # Vector2i -> hits left
var hearth_cell := Vector2i.ZERO
var hearth_level := 1
var hearth_lit := true
var sun_level := 15
var player_cell := Vector2i(-1, -1)

var region := Rect2i()
var light := PackedByteArray()
var fg: TileMapLayer
var bg: TileMapLayer
var overlay: Sprite2D
var _overlay_tex: ImageTexture
var _solid := PackedByteArray()


func _ready() -> void:
	_solid.resize(256)
	for id in Data.BLOCKS:
		_solid[id] = 1 if Data.is_solid(id) else 0
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	var src := TileSetAtlasSource.new()
	src.texture = Textures.get_atlas()
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	var h := T / 2.0
	var pts := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	for id in range(1, Data.BLOCK_COUNT):
		src.create_tile(Vector2i(id, 0))
		src.create_tile(Vector2i(id, 1))
		if Data.is_solid(id):
			var td := src.get_tile_data(Vector2i(id, 0), 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, pts)
	bg = TileMapLayer.new()
	bg.tile_set = ts
	bg.collision_enabled = false
	add_child(bg)
	fg = TileMapLayer.new()
	fg.tile_set = ts
	add_child(fg)
	overlay = Sprite2D.new()
	overlay.centered = false
	overlay.scale = Vector2(T, T)
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	overlay.z_index = 10
	add_child(overlay)


# --- Generation -------------------------------------------------------------

func generate(s: int, saved_changes := {}) -> void:
	seed_value = s
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var hn := _noise(s, 0.008, 3)
	var hn2 := _noise(s + 1, 0.05, 1)
	var cave := _noise(s + 2, 0.035, 2)
	var worm := _noise(s + 3, 0.02, 1)
	var ore := _noise(s + 4, 0.16, 1)
	var biome := _noise(s + 5, 0.006, 1)
	cells.resize(W * H)
	cells.fill(Data.AIR)
	walls.resize(W * H)
	walls.fill(0)
	gloom.resize(W * H)
	var hs := PackedInt32Array()
	hs.resize(W)
	var base := int(H * 0.3)
	var mid := W / 2
	var mid_h := base + int(hn.get_noise_1d(mid) * 22.0)
	for x in W:
		var h := base + int(hn.get_noise_1d(x) * 22.0 + hn2.get_noise_1d(x) * 3.0)
		var near := absi(x - mid)
		if near < 16:  # flatten the Hearth's meadow
			h = int(lerpf(mid_h, h, maxf(0.0, (near - 6) / 10.0)))
		hs[x] = h
	for x in W:
		var desert := biome.get_noise_1d(x) > 0.3
		var dirt_depth := 4 + int((hn2.get_noise_1d(x + 500) + 1.0) * 2.0)
		for y in range(hs[x], H):
			var depth := y - hs[x]
			var b := Data.STONE
			if depth == 0:
				b = Data.SAND if desert else Data.GRASS
			elif depth < dirt_depth:
				b = Data.SAND if desert else Data.DIRT
			walls[y * W + x] = 0 if depth == 0 else (Data.SAND if desert and depth < dirt_depth else (Data.DIRT if depth < dirt_depth else Data.STONE))
			if depth > 9 and (cave.get_noise_2d(x, y) > 0.32 or absf(worm.get_noise_2d(x, y)) < 0.05):
				b = Data.AIR
			if b == Data.STONE:
				if ore.get_noise_2d(x, y) > 0.62:
					b = Data.COAL
				elif depth > 6 and ore.get_noise_2d(x + 1000, y) > 0.6:
					b = Data.COPPER
				elif depth > 30 and ore.get_noise_2d(x + 2000, y) > 0.63:
					b = Data.IRON
			cells[y * W + x] = b
	for x in W:
		for y in H:
			if y >= H - 3 or x == 0 or x == W - 1:
				cells[y * W + x] = Data.BEDROCK
	# Trees
	var x := 3
	while x < W - 3:
		var top := hs[x]
		if cells[top * W + x] == Data.GRASS and absi(x - mid) > 5 and rng.randf() < 0.22:
			_plant_tree(x, top, rng)
			x += rng.randi_range(4, 8)
		else:
			x += 1
	hearth_cell = Vector2i(mid, hs[mid] - 1)
	cells[hearth_cell.y * W + hearth_cell.x] = Data.HEARTH
	# Gloom: the Hearth's meadow starts Kindled, everything else is dark.
	for yy in H:
		for xx in W:
			var d := Vector2(xx - hearth_cell.x, yy - hearth_cell.y).length()
			var depth_bonus := maxi(0, yy - hs[xx]) * 2
			gloom[yy * W + xx] = clampi(int((d - 14.0) * 5.0) + depth_bonus, 0, 100)
	changes = {}
	for k in saved_changes:
		var i := int(k)
		cells[i] = int(saved_changes[k])
		changes[i] = cells[i]
	_rebuild()


func _noise(s: int, f: float, octaves: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = s
	n.frequency = f
	n.fractal_octaves = octaves
	return n


func _plant_tree(x: int, top: int, rng: RandomNumberGenerator) -> void:
	var h := rng.randi_range(4, 7)
	for i in range(1, h + 1):
		_set_raw(x, top - i, Data.WOOD)
	var cy := top - h
	for dy in range(-3, 2):
		for dx in range(-2, 3):
			if absi(dx) + absi(dy) <= 3 and get_block(Vector2i(x + dx, cy + dy)) == Data.AIR:
				_set_raw(x + dx, cy + dy, Data.LEAVES)


func _set_raw(x: int, y: int, id: int) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		cells[y * W + x] = id


func _rebuild() -> void:
	fg.clear()
	bg.clear()
	lights.clear()
	purgers.clear()
	light_hp.clear()
	sky.resize(W)
	for y in H:
		for x in W:
			var i := y * W + x
			var b := cells[i]
			var c := Vector2i(x, y)
			if b != Data.AIR:
				fg.set_cell(c, 0, Vector2i(b, 0))
				_register(c, b)
			if walls[i] != 0:
				bg.set_cell(c, 0, Vector2i(walls[i], 1))
	for x in W:
		_update_sky(x)


func _register(c: Vector2i, id: int) -> void:
	var d: Dictionary = Data.BLOCKS.get(id, {})
	if d.has("light"):
		lights[c] = d["light"]
	if d.has("purge"):
		purgers[c] = d["purge"]
	if d.has("hp"):
		light_hp[c] = d["hp"]


func _update_sky(x: int) -> void:
	sky[x] = H
	for y in H:
		if _solid[cells[y * W + x]] == 1:
			sky[x] = y
			return


# --- Queries and edits ------------------------------------------------------

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H


func get_block(c: Vector2i) -> int:
	return cells[c.y * W + c.x] if in_bounds(c) else Data.BEDROCK


func set_block(c: Vector2i, id: int) -> void:
	if not in_bounds(c):
		return
	var i := c.y * W + c.x
	cells[i] = id
	changes[i] = id
	if id == Data.AIR:
		fg.erase_cell(c)
	else:
		fg.set_cell(c, 0, Vector2i(id, 0))
	lights.erase(c)
	purgers.erase(c)
	light_hp.erase(c)
	_register(c, id)
	_update_sky(c.x)


func has_support(c: Vector2i) -> bool:
	if in_bounds(c) and walls[c.y * W + c.x] != 0:
		return true
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var n := get_block(c + d)
		if n != Data.AIR:
			return true
	return false


func gloom_at(c: Vector2i) -> int:
	return gloom[c.y * W + c.x] if in_bounds(c) else 100


func light_at(c: Vector2i) -> int:
	if not region.has_point(c):
		return 0
	return light[(c.y - region.position.y) * region.size.x + (c.x - region.position.x)]


func to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))


func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c * T) + Vector2(T, T) * 0.5


func hearth_radius() -> int:
	return Data.HEARTH_BASE_RADIUS + Data.HEARTH_RADIUS_PER_LEVEL * hearth_level


# --- Light ------------------------------------------------------------------

func update_light(center: Vector2i) -> void:
	region = Rect2i(center - LIGHT_HALF, LIGHT_HALF * 2).intersection(Rect2i(0, 0, W, H))
	var rw := region.size.x
	var rh := region.size.y
	var ox := region.position.x
	var oy := region.position.y
	light.resize(rw * rh)
	light.fill(0)
	var buckets := []
	for k in 16:
		buckets.append([])
	for lx in rw:
		var top := sky[ox + lx]
		for ly in rh:
			if oy + ly >= top:
				break
			var li := ly * rw + lx
			light[li] = sun_level
			buckets[sun_level].append(li)
	for c in lights:
		if region.has_point(c):
			var lv: int = lights[c]
			if c == hearth_cell and not hearth_lit:
				lv = 5
			_seed_light(c, lv, buckets)
	if region.has_point(player_cell):
		_seed_light(player_cell, 8, buckets)
	for lv in range(15, 1, -1):
		var b: Array = buckets[lv]
		for li in b:
			if light[li] != lv:
				continue
			var lx: int = li % rw
			var ly: int = li / rw
			var gi: int = (oy + ly) * W + ox + lx
			if lx > 0:
				_spread(li - 1, gi - 1, lv, buckets)
			if lx < rw - 1:
				_spread(li + 1, gi + 1, lv, buckets)
			if ly > 0:
				_spread(li - rw, gi - W, lv, buckets)
			if ly < rh - 1:
				_spread(li + rw, gi + W, lv, buckets)


func _seed_light(c: Vector2i, lv: int, buckets: Array) -> void:
	var li := (c.y - region.position.y) * region.size.x + (c.x - region.position.x)
	if lv > light[li]:
		light[li] = lv
		buckets[lv].append(li)


func _spread(li: int, gi: int, lv: int, buckets: Array) -> void:
	var nl := lv - (3 if _solid[cells[gi]] == 1 else 1)
	if nl > light[li]:
		light[li] = nl
		buckets[nl].append(li)


# --- Gloom ------------------------------------------------------------------

## Unlit tiles next to Gloom slowly fill back in; lanterns and the Hearth purge it.
func tick_gloom() -> void:
	var rw := region.size.x
	var rh := region.size.y
	var ox := region.position.x
	var oy := region.position.y
	for ly in range(1, rh - 1):
		for lx in range(1, rw - 1):
			var gi := (oy + ly) * W + ox + lx
			var g := gloom[gi]
			if g >= 100 or light[ly * rw + lx] >= 5:
				continue
			var m := maxi(maxi(gloom[gi - 1], gloom[gi + 1]), maxi(gloom[gi - W], gloom[gi + W]))
			if m >= 40:
				gloom[gi] = mini(100, g + 4)
	for c in purgers:
		_purge(c, purgers[c], 30)
	if hearth_lit:
		_purge(hearth_cell, hearth_radius(), 30)


func _purge(c: Vector2i, r: int, amount: int) -> void:
	for dy in range(-r, r + 1):
		var y := c.y + dy
		if y < 0 or y >= H:
			continue
		for dx in range(-r, r + 1):
			var x := c.x + dx
			if x < 0 or x >= W or dx * dx + dy * dy > r * r:
				continue
			var i := y * W + x
			gloom[i] = maxi(0, gloom[i] - amount)


## Paints darkness, violet Gloom fog, and warm Kindled light into one overlay texture.
func update_overlay(time: float) -> void:
	var rw := region.size.x
	var rh := region.size.y
	var ox := region.position.x
	var oy := region.position.y
	var data := PackedByteArray()
	data.resize(rw * rh * 4)
	for ly in rh:
		for lx in rw:
			var li := ly * rw + lx
			var l := light[li] / 15.0
			var g := gloom[(oy + ly) * W + ox + lx] / 100.0
			var r := 0.02
			var gg := 0.01
			var b := 0.05
			var a := (1.0 - l) * 0.95
			if g > 0.0:
				var f := g * 0.85 * (0.3 + 0.7 * l)
				r = lerpf(r, 0.30, f)
				gg = lerpf(gg, 0.10, f)
				b = lerpf(b, 0.46, f)
				var shimmer := sin(time * 1.3 + (ox + lx) * 0.35 + (oy + ly) * 0.22) * 0.05
				a = maxf(a, g * (0.42 + shimmer))
			elif l > 0.3:
				var k := (l - 0.3) * 0.6
				r = lerpf(r, 1.0, k)
				gg = lerpf(gg, 0.7, k)
				b = lerpf(b, 0.3, k)
				a = maxf(a, 0.08 * l)
			data[li * 4] = int(r * 255.0)
			data[li * 4 + 1] = int(gg * 255.0)
			data[li * 4 + 2] = int(b * 255.0)
			data[li * 4 + 3] = int(clampf(a, 0.0, 1.0) * 255.0)
	var img := Image.create_from_data(rw, rh, false, Image.FORMAT_RGBA8, data)
	if _overlay_tex and Vector2i(_overlay_tex.get_size()) == Vector2i(rw, rh):
		_overlay_tex.update(img)
	else:
		_overlay_tex = ImageTexture.create_from_image(img)
		overlay.texture = _overlay_tex
	overlay.position = Vector2(region.position * T)


# --- Save -------------------------------------------------------------------

func to_save() -> Dictionary:
	var hp := {}
	for c in light_hp:
		hp["%d,%d" % [c.x, c.y]] = light_hp[c]
	return {
		"seed": seed_value,
		"changes": changes,
		"gloom": Marshalls.raw_to_base64(gloom.compress(FileAccess.COMPRESSION_DEFLATE)),
		"light_hp": hp,
		"hearth_level": hearth_level,
	}


func from_save(d: Dictionary) -> void:
	generate(int(d["seed"]), d.get("changes", {}))
	hearth_level = int(d.get("hearth_level", 1))
	var raw := Marshalls.base64_to_raw(d.get("gloom", ""))
	if raw.size() > 0:
		var g := raw.decompress(W * H, FileAccess.COMPRESSION_DEFLATE)
		if g.size() == W * H:
			gloom = g
	var hp: Dictionary = d.get("light_hp", {})
	for k in hp:
		var p: PackedStringArray = k.split(",")
		var c := Vector2i(int(p[0]), int(p[1]))
		if light_hp.has(c):
			light_hp[c] = int(hp[k])
