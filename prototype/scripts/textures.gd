class_name Textures
extends RefCounted
## Procedural placeholder pixel art, so the prototype needs no asset files.
## Row 0 of the atlas holds block tiles, row 1 darker background-wall versions.

static var atlas: ImageTexture
static var _icon_cache := {}


static func get_atlas() -> ImageTexture:
	if atlas == null:
		atlas = ImageTexture.create_from_image(_make_atlas())
	return atlas


static func _hash(x: int, y: int, s: int) -> float:
	var h := (x * 374761393 + y * 668265263 + s * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 1000) / 1000.0


static func _shade(c: Color, amount: float) -> Color:
	return c.lightened(amount) if amount > 0.0 else c.darkened(-amount)


static func _make_atlas() -> Image:
	var img := Image.create(Data.BLOCK_COUNT * 16, 32, false, Image.FORMAT_RGBA8)
	for id in range(1, Data.BLOCK_COUNT):
		for y in 16:
			for x in 16:
				var c := _pixel(id, x, y)
				img.set_pixel(id * 16 + x, y, c)
				if c.a > 0.0:
					var w := c.darkened(0.6)
					w.a = 1.0
					img.set_pixel(id * 16 + x, 16 + y, w)
	return img


static func _pixel(id: int, x: int, y: int) -> Color:
	var base: Color = Data.BLOCKS[id]["color"]
	var n := (_hash(x, y, id) - 0.5) * 0.14
	var c := _shade(base, n)
	var stone: Color = Data.BLOCKS[Data.STONE]["color"]
	match id:
		Data.GRASS:
			var depth := 3 + int(_hash(x, 0, 7) * 3.0)
			if y >= depth:
				c = _shade(Data.BLOCKS[Data.DIRT]["color"], n)
		Data.STONE, Data.BEDROCK:
			if (x * 3 + y * 5) % 11 == 0:
				c = c.darkened(0.18)
		Data.COAL, Data.COPPER, Data.IRON:
			c = _shade(stone, n)
			var hx := x / 4
			var hy := y / 4
			if _hash(hx, hy, id * 31) > 0.45 and _hash(x, y, id + 9) > 0.25 and x > 0 and y > 0 and x < 15 and y < 15:
				c = _shade(base, n * 2.0)
		Data.WOOD:
			if x < 3 or x > 12:
				return Color(0, 0, 0, 0)
			if x % 3 == 0:
				c = c.darkened(0.2)
		Data.LEAVES:
			if _hash(x, y, 77) < 0.12:
				return Color(0, 0, 0, 0)
			if _hash(x / 2, y / 2, 5) > 0.7:
				c = c.lightened(0.15)
		Data.PLANK:
			if y % 4 == 3:
				c = c.darkened(0.25)
			elif (x + (y / 4) * 5) % 8 == 0:
				c = c.darkened(0.15)
		Data.BRICK:
			var row := y / 4
			if y % 4 == 3 or (x + row * 4) % 8 == 7:
				c = Color(0.72, 0.7, 0.66)
		Data.TORCH:
			if x >= 7 and x <= 8 and y >= 7:
				return Color(0.45, 0.3, 0.15)
			var d := Vector2(x - 7.5, y - 5.0).length()
			if d < 2.0:
				return Color(1.0, 0.95, 0.6)
			if d < 3.2 and y <= 7:
				return Color(1.0, 0.55, 0.15)
			return Color(0, 0, 0, 0)
		Data.LANTERN:
			if y < 3:
				return Color(0.3, 0.27, 0.25) if x >= 7 and x <= 8 else Color(0, 0, 0, 0)
			if x < 4 or x > 11 or y > 14:
				return Color(0, 0, 0, 0)
			if x == 4 or x == 11 or y == 3 or y == 14 or y == 4:
				return Color(0.35, 0.3, 0.25)
			return Color(1.0, 0.9, 0.5).lerp(Color(1.0, 0.6, 0.2), float(y - 5) / 9.0)
		Data.HEARTH:
			return Color(0, 0, 0, 0)
	if Data.is_solid(id):
		if x == 0 or y == 0:
			c = c.lightened(0.08)
		elif x == 15 or y == 15:
			c = c.darkened(0.15)
	return c


static func icon(slot: Dictionary) -> Texture2D:
	if slot.is_empty():
		return null
	var id: int = slot["id"]
	if Data.is_block(id):
		var a := AtlasTexture.new()
		a.atlas = get_atlas()
		a.region = Rect2(id * 16, 0, 16, 16)
		return a
	var key := str(id)
	if id == Data.TOOL:
		key = slot["tool"]["core"] + slot["tool"]["frame"] + str(slot["tool"].get("runes", []).size())
	if _icon_cache.has(key):
		return _icon_cache[key]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	if id == Data.SHARD:
		for y in 16:
			for x in 16:
				var d := absf(x - 7.5) * 1.6 + absf(y - 7.5)
				if d < 7.0:
					img.set_pixel(x, y, Color(0.55, 0.3, 0.8).lightened(0.4 - d * 0.06))
	elif id == Data.TOOL:
		var tool: Dictionary = slot["tool"]
		var head: Color = Data.FRAMES[tool["frame"]]["color"]
		var handle := Color(0.5, 0.33, 0.18)
		for i in 10:
			img.set_pixel(3 + i, 12 - i, handle if tool["core"] == "pick" else head)
			if tool["core"] == "blade":
				img.set_pixel(4 + i, 12 - i, head.darkened(0.2))
		if tool["core"] == "pick":
			for i in 9:
				img.set_pixel(5 + i, 2 + absi(i - 4) / 2, head)
				img.set_pixel(5 + i, 3 + absi(i - 4) / 2, head.darkened(0.25))
		else:
			for i in 4:
				img.set_pixel(1 + i, 14 - i, handle)
			img.set_pixel(3, 10, Color(0.8, 0.7, 0.3))
			img.set_pixel(6, 13, Color(0.8, 0.7, 0.3))
		if tool.get("runes", []).size() > 0:
			img.set_pixel(13, 13, Color(1, 0.8, 0.3))
			img.set_pixel(14, 13, Color(1, 0.8, 0.3))
	var tex := ImageTexture.create_from_image(img)
	_icon_cache[key] = tex
	return tex
