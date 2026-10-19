class_name Data
extends RefCounted
## All game content lives here as plain data. Later this becomes JSON data packs,
## so updates (new blocks, frames, runes, recipes) add data rather than code.

const TILE := 16

enum {AIR, GRASS, DIRT, STONE, SAND, WOOD, LEAVES, PLANK, BRICK, COAL, COPPER, IRON, BEDROCK, TORCH, LANTERN, HEARTH, BLOCK_COUNT}

# Non-block items.
const SHARD := 50
const TOOL := 100

# hard: seconds to mine at speed 1.0. tier: pick tier needed. drop: item given.
# light: light level emitted (0-15). purge: radius in tiles that a source clears Gloom.
# hp: how many hits a light source survives from Gloom creatures.
const BLOCKS := {
	GRASS: {"name": "Grass", "color": Color(0.33, 0.62, 0.25), "hard": 0.4, "tier": 0, "drop": DIRT, "solid": true},
	DIRT: {"name": "Dirt", "color": Color(0.47, 0.33, 0.22), "hard": 0.35, "tier": 0, "drop": DIRT, "solid": true},
	STONE: {"name": "Stone", "color": Color(0.46, 0.46, 0.5), "hard": 0.9, "tier": 1, "drop": STONE, "solid": true},
	SAND: {"name": "Sand", "color": Color(0.86, 0.78, 0.52), "hard": 0.3, "tier": 0, "drop": SAND, "solid": true},
	WOOD: {"name": "Wood", "color": Color(0.5, 0.34, 0.18), "hard": 0.8, "tier": 0, "drop": WOOD, "solid": false},
	LEAVES: {"name": "Leaves", "color": Color(0.22, 0.52, 0.22), "hard": 0.15, "tier": 0, "drop": AIR, "solid": false},
	PLANK: {"name": "Planks", "color": Color(0.72, 0.53, 0.3), "hard": 0.6, "tier": 0, "drop": PLANK, "solid": true},
	BRICK: {"name": "Stone Brick", "color": Color(0.56, 0.54, 0.56), "hard": 1.1, "tier": 1, "drop": BRICK, "solid": true},
	COAL: {"name": "Coal", "color": Color(0.13, 0.13, 0.15), "hard": 1.0, "tier": 1, "drop": COAL, "solid": true},
	COPPER: {"name": "Copperleaf Ore", "color": Color(0.9, 0.52, 0.24), "hard": 1.2, "tier": 1, "drop": COPPER, "solid": true},
	IRON: {"name": "Iron Ore", "color": Color(0.82, 0.72, 0.66), "hard": 1.6, "tier": 2, "drop": IRON, "solid": true},
	BEDROCK: {"name": "Bedrock", "color": Color(0.12, 0.1, 0.14), "hard": 9999.0, "tier": 99, "drop": AIR, "solid": true},
	TORCH: {"name": "Torch", "color": Color(1.0, 0.75, 0.3), "hard": 0.1, "tier": 0, "drop": TORCH, "solid": false, "light": 12, "hp": 3},
	LANTERN: {"name": "Lantern", "color": Color(1.0, 0.85, 0.45), "hard": 0.3, "tier": 0, "drop": LANTERN, "solid": false, "light": 13, "purge": 7, "hp": 8},
	HEARTH: {"name": "Hearth", "color": Color(1.0, 0.5, 0.15), "hard": 9999.0, "tier": 99, "drop": AIR, "solid": false, "light": 15},
}

const RECIPES := [
	{"out": PLANK, "n": 4, "in": {WOOD: 1}},
	{"out": TORCH, "n": 3, "in": {WOOD: 1, COAL: 1}},
	{"out": BRICK, "n": 2, "in": {STONE: 2}},
	{"out": LANTERN, "n": 1, "in": {COPPER: 2, COAL: 1, PLANK: 2}},
]

# Cost to go from level i+1 to i+2. Each level asks for three material types.
const HEARTH_LEVELS := [
	{WOOD: 10, STONE: 15, COAL: 5},
	{COPPER: 10, IRON: 5, SHARD: 3},
	{IRON: 15, BRICK: 20, SHARD: 8},
]
const HEARTH_BASE_RADIUS := 8
const HEARTH_RADIUS_PER_LEVEL := 5

# Modular forging stub: Core x Frame x Runes.
const CORES := {
	"pick": {"name": "Pick"},
	"blade": {"name": "Blade"},
}
const FRAMES := {
	"worn": {"name": "Worn", "tier": 1, "speed": 1.0, "dmg": 2.0, "slots": 0, "color": Color(0.55, 0.5, 0.45), "cost": {}},
	"copper": {"name": "Copperleaf", "tier": 2, "speed": 1.6, "dmg": 4.0, "slots": 1, "color": Color(0.9, 0.52, 0.24), "cost": {COPPER: 5, PLANK: 2}},
	"iron": {"name": "Iron", "tier": 3, "speed": 2.4, "dmg": 7.0, "slots": 2, "color": Color(0.8, 0.8, 0.85), "cost": {IRON: 5, PLANK: 2}},
}
const FORGE_FRAMES := ["copper", "iron"]
const RUNES := {
	"ignite": {"name": "Ignite", "desc": "Blade: sets foes ablaze. Pick: digs 50% faster.", "cost": {COAL: 3}},
	"echo": {"name": "Echo", "desc": "Blade: repeats each hit. Pick: mines a 2-tile strip.", "cost": {SHARD: 2}},
}

const HAND := {"tier": 0, "speed": 0.8, "dmg": 1.5}


static func is_block(id: int) -> bool:
	return id > AIR and id < BLOCK_COUNT


static func is_solid(id: int) -> bool:
	return BLOCKS.has(id) and BLOCKS[id]["solid"]


static func item_name(id: int) -> String:
	if BLOCKS.has(id):
		return BLOCKS[id]["name"]
	if id == SHARD:
		return "Gloom Shard"
	return "?"


static func tool_name(tool: Dictionary) -> String:
	var s: String = FRAMES[tool["frame"]]["name"] + " " + CORES[tool["core"]]["name"]
	for r in tool.get("runes", []):
		s += " +" + RUNES[r]["name"]
	return s


static func tool_stats(tool: Dictionary) -> Dictionary:
	if tool.is_empty():
		return HAND
	var f: Dictionary = FRAMES[tool["frame"]]
	var speed: float = f["speed"]
	if tool["core"] == "pick" and "ignite" in tool.get("runes", []):
		speed *= 1.5
	return {"tier": f["tier"], "speed": speed, "dmg": f["dmg"]}


static func merge_costs(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for k in b:
		out[k] = out.get(k, 0) + b[k]
	return out


static func cost_text(cost: Dictionary, inv: Inventory = null) -> String:
	var parts := []
	for id in cost:
		if inv:
			parts.append("%s %d/%d" % [item_name(id), mini(inv.count(id), cost[id]), cost[id]])
		else:
			parts.append("%d %s" % [cost[id], item_name(id)])
	return ", ".join(parts)
