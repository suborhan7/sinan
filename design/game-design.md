# Emberdeep — Game Design Document (v0.1)

*Working title. A 2D sandbox survival/crafting game for PC (Steam) and mobile (Google Play).*

## 1. The pitch

The world has gone dark. A living fog called **the Gloom** covers everything, and only light holds it back. You start beside a dying **Hearth**, a fire that is the last source of true light. Feed it, carry its flame outward with lanterns and beacons, and you reclaim the world tile by tile. The Gloom pushes back.

Where Terraria is "dig, build, beat bosses", Emberdeep is **"dig, build, and hold the light."** Exploration, building and combat all serve one visible goal: how much of the world is yours.

## 2. What makes it different (and better)

| Terraria-style norm | Emberdeep's twist | Why it's better |
|---|---|---|
| Static world; safety comes from walls and housing | **Light is territory.** Lit areas are *Kindled* (safe, buffed, farmable); dark areas are *Gloomed* (hostile, mutating, richer loot) | Progress is visible on the map; base building has a purpose beyond decoration |
| Fixed recipes, hundreds of single-purpose items | **Modular forging.** Every tool and weapon is built from a Core + Frame + up to 3 Runes | Fewer items to learn, far more combinations; each new part in an update multiplies existing builds |
| Bosses are the only real pressure | **Gloom Tides.** Every few in-game nights the Gloom surges and tries to retake land you hold | The world pushes back, so defense and logistics matter mid-game too |
| Wiki-dependent progression | **The Ember Journal.** The Hearth "remembers" materials you bring it and hints at what they can make | Discoverability without a browser tab, essential on mobile |
| Touch controls bolted on | **Designed for both from day one.** Auto-aim option, contextual mine/place, radial forge menu | One game that feels native on Steam and Play Store |

### The core hook in one sentence
> Every light you place is a claim on the world, and the darkness will try to take it back.

## 3. Core systems

### 3.1 Light & the Gloom
- The world is a grid of tiles. Each tile has a **Light value** (0–15) and a **Gloom value** (0–100).
- **Light sources** (torches, lanterns, beacons, the Hearth) push Gloom down within their radius. Torches only light; **Lanterns** and **Beacons** actively purge Gloom.
- **Kindled zone** (Gloom 0): no natural enemy spawns, crops grow, NPC settlers can move in, health regen.
- **Dim zone** (1–49): normal spawns, normal resources.
- **Gloomed zone** (50–100): stronger mutated enemies, rare *Gloom-touched* ore variants, blocks slowly corrupt. Risk vs. reward: the best materials are in the dark.
- Beacons need **fuel** (Ember shards, coal, oil). This creates a light logistics layer: supply lines, fuel farms, and later automated feeders.

### 3.2 The Hearth (your progression anchor)
- Feeding the Hearth new materials raises its **Hearth Level** (1–10).
- Each level: larger base light radius, new forge tiers, new beacon types, and new settlers arriving.
- The Hearth is the player's "home" in a way a bed never was. It can be relocated once per tier (big event: a convoy of light across the map).

### 3.3 Gloom Tides (the world pushes back)
- Every 3–5 nights (configurable), a Tide rolls in from Gloomed regions toward your Kindled territory.
- Waves of enemies target **light sources first**. Lost beacons let the Gloom flow back in.
- Defenses: walls, traps, turrets powered by light, and settlers who man posts.
- Tides scale with territory size, not just time, so expanding faster means harder defense. The player chooses their own difficulty curve.

### 3.4 Modular forging
- **Core** decides the item type: Blade, Pick, Bow, Staff, Hook, Drill, Hammer.
- **Frame** (material) decides base stats: Copperleaf, Iron, Glimmersteel, Voidglass…
- **Runes** (up to 3 slots, unlocked by frame tier) add behaviour: *Ignite*, *Chain*, *Pierce*, *Echo* (repeats the last hit), *Lightborne* (stronger in Kindled zones), *Hungering* (stronger in the Gloom).
- Rune synergies create emergent builds (Chain + Ignite spreads fire between enemies; Echo + Pick mines a 2-tile strip).
- Items are never obsolete: you can **reforge** a beloved weapon onto a better frame and keep its runes.
- Implementation note: items are data (JSON) composed at runtime, so content updates are mostly new data, not new code.

### 3.5 Settlers
- NPCs arrive when Hearth level and Kindled area thresholds are met.
- Each settler has a role (Smith, Lamplighter, Farmer, Scout, Warden) and needs a lit room.
- Lamplighters auto-refuel nearby beacons; Scouts reveal map regions; Wardens defend during Tides. Settlers turn the base into a living town that does real work.

## 4. Core loop

**Moment to moment (seconds):** mine, place, fight, light a torch.
**Session loop (10–30 min):** venture into the dark → gather materials → return → feed the Hearth / forge gear → push a beacon line deeper.
**Long loop (hours):** raise Hearth level → unlock new biome access → defeat a Gloom Warden boss → survive larger Tides → claim the world.

```
Explore the dark ──▶ Gather rare materials ──▶ Forge & feed the Hearth
      ▲                                                  │
      │                                                  ▼
Defend against Tides ◀── Expand light territory ◀── Unlock beacons & settlers
```

Short sessions must feel complete on mobile: a single beacon push or a single Tide defense is a natural stopping point.

## 5. Progression

| Act | Hearth lvl | Biomes opened | Key unlocks | Boss (Gloom Warden) |
|---|---|---|---|---|
| 1. Embers | 1–2 | Surface Meadow, Shallow Caves | Torches, Lanterns, Copperleaf frames | **The Smother**: a giant moth that eats light |
| 2. Kindling | 3–4 | Mossdeep Forest, Copper Caverns | Beacons, first Runes, settlers | **Rootmaw**: a burrowing tree that relocates through tunnels |
| 3. Blaze | 5–6 | Crystal Hollows, Ashen Desert | Light turrets, Glimmersteel, fuel automation | **The Prism Tyrant**: splits your light into hostile beams |
| 4. Inferno | 7–8 | Drowned Depths, Gloomcore Rim | Voidglass, Hungering runes, Hearth relocation | **Tidebringer**: a living Gloom Tide |
| 5. Dawn | 9–10 | The Heart of the Gloom | Sunforge, endgame runes | **The Last Dark**: final boss, beating it unlocks "Dawn Mode" (world fully lit, new endless challenge) |

- **Difficulty:** Cozy (no Tides), Standard, Unlit (permadeath of beacons, harsher Gloom).
- **Worlds:** procedurally generated, 3 sizes; seed sharing.

## 6. Art direction

- **Style:** crisp 16×16 pixel art with **dynamic per-pixel lighting** as the signature. Light is the hero of every screen.
- **Palette rule:** Gloom areas are desaturated blue-violet; Kindled areas shift warm (amber, gold, green). The player sees their progress as color spreading across the world.
- **Silhouettes first:** enemies and items must read at phone size. Max 3 shades per material.
- **Juice:** embers drift from torches, Gloom creeps visibly as animated fog, blocks "warm up" with a short glow when a beacon claims them.
- **UI:** minimal, warm parchment-and-brass theme; radial menus for touch, hotbar for keyboard.
- **Audio:** sparse ambient in the dark (low drones, distant sounds), warm acoustic instruments in Kindled zones. Music literally gets brighter as you claim territory.

## 7. Platforms & controls

- **Steam (PC):** keyboard/mouse and controller; Steam achievements, Workshop for worlds and later mods.
- **Google Play (Android):** virtual stick + contextual action button, tap-to-mine with auto-target, smart building (drag to place lines of blocks). Performance target 60 fps on mid-range phones via chunked lighting updates.
- **Cross-save** through a cloud account (later update), same save format everywhere.
- **Recommended engine:** Godot 4 (free, strong 2D, exports to both PC and Android, no royalties). Unity is the alternative if the team already knows it.

## 8. Monetization (to decide in the release plan)

- **Steam:** premium, one-time purchase. All updates free.
- **Play Store:** free demo (Act 1) with a one-time unlock for the full game. No ads, no energy timers, no pay-to-win. Optional cosmetic packs only (lantern skins, Hearth styles).

## 9. Built to be upgraded: update roadmap

The architecture keeps content data-driven (biomes, runes, frames, enemies, bosses as data packs) so updates are cheap to ship.

| Update | Theme | Content |
|---|---|---|
| **1.0 Launch** | Embers to Dawn | 5 acts, 10 biomes, 5 bosses, ~40 runes, 8 frames, 5 settler roles, single-player |
| **1.1 Hearthbound** | Co-op | 2–4 player online co-op; shared Hearth, separate lanterns; Tides scale with players |
| **1.2 Lamplight Logistics** | Automation | Fuel conveyors, light relays, settler work schedules, light-powered machines |
| **1.3 The Sky Embers** | Vertical expansion | Floating islands lit by a second "Sky Hearth"; gliders and grappling runes |
| **1.4 Deep Season** | Seasons | Seasonal Gloom behaviour (longer winter nights, summer solstice festivals), farming expansion |
| **2.0 Other Fires** | New mode | Rival Hearths: PvE factions (or opt-in PvP) competing for light on the same map |
| **Ongoing** | Workshop & mods | Rune/frame/biome data packs via Steam Workshop; curated packs ported to mobile |

Each update adds new **runes and frames**, which recombine with every existing item. That is the main multiplier that keeps old content fresh.

## 10. Prototype scope (for the prototype thread)

The smallest build that proves the hook is fun:
1. Procedural 2D tile world (surface + caves), mining and placing blocks.
2. Player movement, jump, basic melee.
3. **Light + Gloom grid:** torches light, lanterns purge Gloom; Gloom slowly regrows when unlit; visible color shift between Kindled and Gloomed.
4. A Hearth that levels up when fed 3 material types, increasing its radius.
5. One enemy type that spawns only in Gloom and targets light sources.
6. One mini Gloom Tide after night 2.
7. Modular forge stub: 2 Cores × 2 Frames × 2 Runes.

Success test: does pushing a lantern into the dark, and then defending it, feel good within 10 minutes?

## 11. Open questions

- Final name (Emberdeep is a working title; needs a trademark and store search).
- Team size and budget, which decide launch scope.
- Whether co-op should move up to launch (strong for Steam sales, costly to build).
