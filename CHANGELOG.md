# Changelog

Newest first. One line per commit. Tags: `[contract]` change to `src/shared/*`, `[cross]` touched the other worker's files, `[need]` a request for the other worker, `[design]` DESIGN.md changed.

## 2026-09-25 (night) — presentation worker (Claude)
**In plain English:** Ashvale is becoming a real 3D PC game. There's now a first walkable 3D version of the town, built in the Godot engine, in the `godot/` folder. The web game keeps running as it is for now.

**What changed**
- **The 3D world (`godot/`):** a 256 m valley with rolling hills and a flat town plateau, dirt roads, cobbled streets and a pond.
  - 11 timber-and-stone houses built from the Medieval Village kit around a market square, with stalls, barrels, benches, lanterns and a great red ash tree in the middle. Windows glow and lamps light up at dusk, and chimneys smoke.
  - A soft, dense meadow of grass that the wind rolls across and that parts around the hero's feet. Forests to the north, lone trees, bushes, flowers, ferns, mushrooms and boulders.
  - The pond: clear water with reflections and gentle ripples, foam at the shore, lily pads and blossoms, reeds, pebbles, a jetty, and fish ripples.
  - A full day and night cycle: sun, moon, stars, drifting clouds, dawn mist and a warm sunset.
  - A hooded ranger hero: WASD or click-to-move, run, walk and jump, with a camera you can orbit and zoom. Trees turn see-through when they would hide the hero.
  - Townsfolk with things to do: stall keepers, neighbours chatting, someone on a bench, a woodcutter with his axe and woodpile, a gardener at a fenced carrot patch, and walkers going door to door. Most go home at night. Butterflies by day, fireflies by night.
- **People:** built by `art/godot/characters.py` (Quaternius outfit + head + hair on one skeleton). Every animation in the Universal Animation Library is fitted to each body at load time (`godot/src/actors/anim_lib.gd`).
- **Web game:**
  - Rendered 3D houses, trees and rocks.
  - Heads with live hair colour and 4 hairstyles plus a hood.
  - A new character-creation screen with a turntable.
  - Monster heads, helmets and 30 weapons from our own pipeline.
  - "Save to file / Load from file".
  - The sprite queue is part-way through: sets not yet rendered fall back to the old drawings.

**What to try**
- Double-click **Play Ashvale.bat**. The first time, it unpacks Godot and the free art packs from your Downloads folder, which takes a couple of minutes.
- Controls: walk around, hold **T** to watch a day go by, **F1** shows the controls and **F3** shows frames per second.

**What's next**
- Tuning on real hardware.
- A title screen and character creation in 3D.
- Monsters and combat in the wild (Bestiary kit and our own creatures).
- Moving the game rules (`src/sim`) from JavaScript to GDScript with the systems worker.
- The paid packs (more outfits and monsters) once GD2X has approved the 3D look.

## 2026-09-25 (evening) — presentation worker (Claude)
- Art pipeline: `art/render.py` (Blender → sprite frames from the game camera), `art/pack.py` (WebP atlases + JSON/JS), `art/variants.py` (armour recolours), `art/creatures.py` (animals built in code), `art/jobs/make_jobs.py` (53 sprite sets), `art/run_all.sh` (background queue). See `art/README.md`.
- Layered paper doll in `src/view/sprites.js`: body/head/helmet/cape/weapon sets compose on one rig; tints; mirrored directions; fallback to old drawing when a set is missing. Wired into `render.js` `drawEntity` for players, bots, NPCs, guards, monsters and pets.
- Game feel: `src/view/feel.js` (camera smoothing, shake, hit-stop), knockback, popping combat text, radial cooldown sweeps with countdown and ready flash.
- `tests/shot.py` for visual checks. Rendered sets committed so far are in `assets/sprites/`; the rest render from the pipeline (`sh art/run_all.sh`).
- For GD2X: the Warrior in town now uses the new rendered model; more sets arrive as the queue finishes. Next session: finish the queue, check every set in game, then world tiles/buildings, effects, and the UI rebuild. `docs/START-HERE-PRESENTATION.md` is the note for whoever continues.

## 2026-09-25 — presentation worker (Claude)
- Restructured the project: split the single concatenated script into `src/sim/*` (rules), `src/view/*` (presentation) and `src/shared/events.js` (the event bus). `index.html` is now the entry point; no build step. `build.sh` optionally makes a one-file copy in `dist/`. Behaviour unchanged; smoke test green.
- `[contract]` Added `src/shared/events.js`: `EV.on/off/once/emit` and the event catalogue.
- `[design]` Wrote `docs/DESIGN.md` (the design bible: Classic-WoW combat model, three class kits, progression, loot, bosses, the bot cast, the give-back loop, tuning appendix) and `docs/ENGINEERING.md` (ownership, `G` command API, `S` read model, conventions, tests, milestones) and `docs/START-HERE-WORKER-B.md`.
- Next (presentation): save export/import button; sprite-sheet render pipeline; isometric projection; window manager + context menus; target/cast/buff frames.
- `[need]` from systems, in M1: `anim`, `cast`, `gcd`, `cooldowns`, `procs`, `resource`, `threatTop`, `con` on entities, and `G.*` commands per ENGINEERING.md §2.
