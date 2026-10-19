# Emberdeep prototype

A playable Godot 4.3 prototype of the design in [../design/game-design.md](../design/game-design.md). It's built to answer the doc's success test: does pushing a lantern into the dark, and then defending it, feel good within 10 minutes?

## Play it

| Platform | File | Notes |
|---|---|---|
| Windows | `builds/Emberdeep.exe` | Single file, just run it. Windows SmartScreen may warn because it is unsigned: click "More info", then "Run anyway". |
| Android | `builds/Emberdeep.apk` | Sideload: copy to the phone, open it, allow "install unknown apps". arm64 and armv7. Signed with a throwaway test key, **not** a Play Store key. |
| Linux | `builds/Emberdeep.x86_64` | `chmod +x` and run. |
| Editor | open `project.godot` in Godot 4.3+ | Press F5. |

The game autosaves every 30 seconds and on quit.

## Controls

| Action | Keyboard / mouse | Touch | Controller |
|---|---|---|---|
| Move | A / D or arrows | `<` `>` buttons | Left stick, d-pad |
| Jump | Space / W | Jump | A |
| Mine | Hold left click on a block | Hold on a block | |
| Place | Right click (selected block) | Tap empty space | |
| Attack | Left click a Gloomling, or F | Tap a Gloomling, or Hit | X |
| Hearth (feed + forge) | E, or click the fire | Tap the fire | Y |
| Crafting | C | Craft button | |
| Hotbar | 1 to 0, mouse wheel | Tap a slot | |
| Toggle touch buttons | F1 | | |
| New world | F9 twice | Craft panel, press twice | |

## What's in it (doc section 10)

1. **Procedural world**: 480 x 220 tiles, rolling hills, deserts, trees, caves and tunnels, coal, copperleaf and iron ore, background walls.
2. **Player**: smooth run and jump with coyote time, jump buffering, auto step-up over 1-tile ledges, melee swing.
3. **Light + Gloom grid**: every tile has light (0-15, flood fill from the sun, torches, lanterns, the Hearth and the player's belt lamp) and Gloom (0-100). Torches only light. Lanterns and the Hearth purge Gloom in a radius. Unlit tiles next to Gloom slowly fill back in, so the dark creeps back at night. Kindled areas tint warm, Gloomed areas tint violet, even the sky.
4. **The Hearth**: feed it three material types to level it (3 level-ups in the prototype). Each level widens its purge radius and raises its health.
5. **Gloomlings**: spawn only in Gloomed tiles, drift through rock toward the nearest light, and snuff out torches and lanterns. Kindled light burns them. They drop Gloom Shards. They hurt the player on contact.
6. **Gloom Tide**: on night 2 (and every second night after) a wave rises around the Hearth and hunts your lights. Smother the Hearth and it goes dark for 25 seconds. Repel it for a shard reward.
7. **Modular forge stub**: 2 Cores (Pick, Blade) x 2 Frames (Copperleaf: 1 rune slot, Iron: 2) x 2 Runes (Ignite: burn damage or +50% dig speed; Echo: repeat hits or a 2-tile mining strip).

Also: crafting (planks, torches, stone brick, lanterns), a 10-slot hotbar, regeneration in Kindled zones, death returns you to the Hearth, day and night cycle (200 seconds per day), save and load.

A suggested first 10 minutes: walk off the meadow and chop a tree, dig down for coal and copperleaf, craft a lantern, place it out in the violet Gloom and watch it burn the fog away, then defend it when Gloomlings come for it. Feed the Hearth before night 2.

## Project layout

```
project.godot, main.tscn     entry point (everything else is built in code)
scripts/data.gd              all content: blocks, recipes, Hearth levels, cores/frames/runes
scripts/world.gd             generation, tiles, light flood fill, Gloom simulation, overlay
scripts/main.gd              game rules: input, mining, placing, combat, day/night, Tides, saving
scripts/player.gd            movement and swing
scripts/wisp.gd              Gloomling enemy
scripts/hud.gd               HUD, hotbar, crafting and Hearth/forge panels, touch layout
scripts/touch_button.gd      multitouch on-screen button
scripts/textures.gd          procedural placeholder pixel art (no asset files yet)
scripts/hearth_fx.gd, cursor.gd
tests/autotest.gd            scripted gameplay test (24 checks) + screenshots
tools/make_icon.gd           regenerates icon.png
```

Content is plain data in `data.gd` so it can move to JSON packs later, per the doc's "built to be upgraded" plan.

## Testing

```
godot --path . -- --autotest
```

Runs 24 checks (generation, walking, jumping, mining, placing, Hearth feeding, crafting, forging and rune slot limits, lantern purging Gloom, Gloomling spawning and attacks, combat, the night-2 Tide, save/load) and writes screenshots to `build/shots/`. Last run: all 24 passed. Screenshots from that run are in `screenshots/`.

## Known limits and next steps

- **Not yet tested on a real phone.** Touch controls were checked by screenshot only. The APK is a release build signed with a test key; Play Store needs your own upload key and an AAB built with Godot's Gradle export.
- **Performance**: light + overlay updates take about 7-11 ms every 0.12 s on a software-rendered desktop CPU. Fine on PC; on mid-range phones this should move to chunked updates or C#/GDExtension (doc section 7 already plans this).
- Art is procedural placeholder pixel art; no audio yet.
- Gloom only simulates near the player; the world outside that window is frozen until you return.
- Next candidates from the doc: settlers, beacons with fuel, Ember Journal, the first boss (The Smother), more runes and frames as data.
