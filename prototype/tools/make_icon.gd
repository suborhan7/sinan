extends SceneTree
## Generates icon.png (a Hearth flame on Gloom violet). Run: godot --headless -s tools/make_icon.gd


func _init() -> void:
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n, n) / 2.0
	for y in n:
		for x in n:
			var p := Vector2(x, y)
			var d := p.distance_to(c) / (n * 0.5)
			if d > 1.0:
				continue
			var col := Color(0.16, 0.08, 0.26).lerp(Color(0.95, 0.55, 0.2), clampf(1.0 - d * 1.4, 0.0, 1.0) * 0.6)
			# Flame: teardrop from (128, 60) down to a round base at (128, 170)
			var fy := (y - 60.0) / 120.0
			if fy >= 0.0 and fy <= 1.0:
				var w := sin(fy * PI * 0.85) * 52.0 * (0.4 + fy * 0.6)
				var dx := absf(x - 128.0 + sin(fy * 6.0) * 6.0 * (1.0 - fy))
				if dx < w:
					col = Color(1.0, 0.45, 0.1)
					if dx < w * 0.55 and fy > 0.35:
						col = Color(1.0, 0.85, 0.35)
			if y > 182 and y < 204 and absf(x - 128.0) < 70.0 - (y - 182) * 0.5:
				col = Color(0.38, 0.33, 0.3)
			if d > 0.94:
				col = Color(0.78, 0.58, 0.28)
			img.set_pixel(x, y, col)
	img.save_png("res://icon.png")
	quit()
