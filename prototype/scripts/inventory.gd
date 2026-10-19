class_name Inventory
extends RefCounted
## A fixed row of slots. A slot is {} (empty), {"id", "count"} for stackables,
## or {"id": Data.TOOL, "count": 1, "tool": {"core", "frame", "runes"}} for forged gear.

signal changed

const SIZE := 10
const MAX_STACK := 999

var slots: Array = []


func _init() -> void:
	slots.resize(SIZE)
	for i in SIZE:
		slots[i] = {}


func count(id: int) -> int:
	var n := 0
	for s in slots:
		if not s.is_empty() and s["id"] == id:
			n += s["count"]
	return n


## Adds items, returns how many did not fit.
func add(id: int, n: int) -> int:
	for s in slots:
		if n <= 0:
			break
		if not s.is_empty() and s["id"] == id and s["count"] < MAX_STACK:
			var take := mini(n, MAX_STACK - s["count"])
			s["count"] += take
			n -= take
	for i in SIZE:
		if n <= 0:
			break
		if slots[i].is_empty():
			var take := mini(n, MAX_STACK)
			slots[i] = {"id": id, "count": take}
			n -= take
	changed.emit()
	return n


func add_tool(tool: Dictionary) -> bool:
	for i in SIZE:
		if slots[i].is_empty():
			slots[i] = {"id": Data.TOOL, "count": 1, "tool": tool}
			changed.emit()
			return true
	return false


func remove(id: int, n: int) -> bool:
	if count(id) < n:
		return false
	for i in range(SIZE - 1, -1, -1):
		var s: Dictionary = slots[i]
		if n <= 0:
			break
		if not s.is_empty() and s["id"] == id:
			var take := mini(n, s["count"])
			s["count"] -= take
			n -= take
			if s["count"] <= 0:
				slots[i] = {}
	changed.emit()
	return true


func has_all(cost: Dictionary) -> bool:
	for id in cost:
		if count(id) < cost[id]:
			return false
	return true


func pay(cost: Dictionary) -> bool:
	if not has_all(cost):
		return false
	for id in cost:
		remove(id, cost[id])
	return true


## The best forged tool with this core, judged by frame tier. {} if none.
func best_tool(core: String) -> Dictionary:
	var best := {}
	var best_tier := -1
	for s in slots:
		if not s.is_empty() and s["id"] == Data.TOOL and s["tool"]["core"] == core:
			var t: int = Data.FRAMES[s["tool"]["frame"]]["tier"]
			if t > best_tier:
				best_tier = t
				best = s["tool"]
	return best


func to_save() -> Array:
	return slots.duplicate(true)


func from_save(data: Array) -> void:
	for i in SIZE:
		slots[i] = {}
		if i < data.size() and data[i] is Dictionary and not data[i].is_empty():
			var s: Dictionary = data[i]
			var slot := {"id": int(s["id"]), "count": int(s["count"])}
			if s.has("tool"):
				slot["tool"] = {"core": str(s["tool"]["core"]), "frame": str(s["tool"]["frame"]), "runes": Array(s["tool"].get("runes", []))}
			slots[i] = slot
	changed.emit()
