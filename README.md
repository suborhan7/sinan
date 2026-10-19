# Emberdeep

*Working title.* A 2D sandbox survival and crafting game in the spirit of Terraria, built in Godot 4.3, aimed at **Steam (PC) first, then Google Play (Android)**.

**The hook:** light is territory. The world is covered by a living fog called the Gloom. Every torch, lantern and beacon you place claims tiles back from it, and the Gloom fights to retake them during Gloom Tides. Gear is modular: every tool or weapon is a **Core + Frame + Runes**, so each new part added later multiplies existing builds.

## Catch up in 15 minutes

1. **Read the design doc:** [`design/game-design.md`](design/game-design.md). The pitch, what makes it different from Terraria, core systems (Light & Gloom, the Hearth, Gloom Tides, modular forging), and the prototype scope.
2. **Play the prototype:** grab a build from [`prototype/builds/`](prototype/builds/) (see table below) and try the suggested first 10 minutes in [`prototype/README.md`](prototype/README.md).
3. **Read the launch plan:** [`launch/launch-plan.md`](launch/launch-plan.md). Accounts and fees, Steam and Play Store technical requirements, timeline. Steam Early Access first, Google Play later.

## Repo layout

```
design/game-design.md     the game design document (v0.1)
launch/launch-plan.md     Steam + Google Play launch plan
prototype/                the Godot 4.3 project
  project.godot           open this in Godot
  scripts/                all game code (GDScript); content data is in scripts/data.gd
  tests/autotest.gd       scripted gameplay test, 24 checks
  screenshots/            screenshots from the last test run
  builds/                 ready-to-run builds (Windows, Linux, Android)
```

## Play the builds

| Platform | File | Notes |
|---|---|---|
| Windows | `prototype/builds/Emberdeep.exe` | Just run it. SmartScreen may warn (unsigned): "More info", then "Run anyway". |
| Linux | `prototype/builds/Emberdeep.x86_64` | `chmod +x` then run. |
| Android | `prototype/builds/Emberdeep.apk` | Sideload it. Signed with a throwaway test key, not a Play Store key. Not yet tested on a real phone. |

## Open the project in Godot

1. Install **Godot 4.3** (standard build, not .NET) from https://godotengine.org/download/archive/4.3-stable/.
2. In the Project Manager click **Import**, pick `prototype/project.godot`, then **Import & Edit**.
3. Press **F5** to run. Controls are listed in [`prototype/README.md`](prototype/README.md#controls).
4. Run the test suite from a terminal: `godot --path prototype -- --autotest`

There are no asset files yet: the world, art and UI are all generated in code, so the first import is quick.

## Where things stand

- Prototype covers design doc section 10: procedural world, movement and melee, the light + Gloom grid, Hearth levels, Gloomlings, the night-2 Gloom Tide, and a Core/Frame/Rune forge stub. All 24 autotest checks pass.
- Open decision: co-op at launch or in the first update (currently assumed first update).
- Known gaps: no audio, placeholder art, untested on real phones, light updates may need chunking for mobile performance.
- Releasing on Play Store needs our own upload key and an AAB export; never commit keystores to this repo.
