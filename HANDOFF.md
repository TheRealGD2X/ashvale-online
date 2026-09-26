# Handoff: where Ashvale Online stands (2026-09-26)

Read this first, then `godot/README`-style notes in `README.md`, `CHANGELOG.md` (newest first), `docs/UI-DIRECTION.md` and `docs/LIVING-WORLD.md`.

## The game
- **Engine and art:** Ashvale Online, a PC single-player MMO in **Godot 4** (the project lives in `godot/`). Art is Quaternius plus licensed kits.
- **Controls:** point-and-click in the style of Albion Online.
- **Classes:** Warrior, Wizard and Cleric. Level cap 60.
- **World:** 10 zones along one road (ashvale, hollow, mirewood, ashslopes, highlands, varn, saltmere, emberreach, palereach, scar), plus dungeons.
- **Systems:** quests, crafting and a market, mounts at 40, and the Abyssal Sanctum raid (10 players, 4 bosses).
- **Simulated players:** they quest, fight, chat, group and raid.
- **Owner's standing instructions:**
  - Keep working milestone after milestone without waiting for approval.
  - Publishing is fine.
  - Any local LLM has to run on his laptop (32 GB RAM, 8 GB VRAM), and NPCs must sound human.

## Milestones
- M1–M7 are done: foundations, Ashvale 1–10, the Hollow and dungeons, crafting and the market, zones up to level 40 and mounts, zones 40–60, and the raid.
- **M8 (polish) is in progress.** The owner's direction is in `docs/UI-DIRECTION.md`:
  - Albion-style UI with Diablo orbs and a bottom hotbar.
  - Every icon and every spell effect must look extremely polished.
- **Next, the owner wants the living world** (`docs/LIVING-WORLD.md`):
  - A persistent server population whose clock only runs while he plays.
  - Mixed levelling paces, newcomers and alts, so there's always a crowd at his level.
  - Guilds, friends, trade and LFG chat, a moving economy and world bosses.
  - Also lots more content.

## M8 status
**Done:**
- **HUD:** liquid orbs and a painted hotbar (`src/ui/game_hud.gd`, `shaders/orb.gdshader`, `shaders/bar.gdshader`).
- **Painted panels and buttons:** `src/ui/ui_skin.gd`, painted by `art/ui_art.py panels`.
- **Ability icons:** `art/spell_icons.py`. Buff and monster-spell icons: `art/buff_icons.py`.
- **Item icons:** all 277 keys rendered in Blender (`art/item_models.py`, then `art/item_paint.py`). The mapping is `ItemIcon.key_of`, and the key list comes from `tools/icon_keys.gd`.
- **VFX rebuilt on painted textures:** flipbooks, flares, streaks and decals (`art/vfx_textures.py`, then `godot/assets/fx`; `src/fx/fx.gd`).

**To do:**
1. **Screenshot-check the new VFX in game.** They compile, but haven't been looked at yet. Try `--demo=fireball:8,fireball:22,frost_nova:8,flamestrike:10` (see `tools/shot.sh`) and tune sizes and brightness.
2. **Screenshot the bags, character and vendor windows** with the new panels (`--ui=bags,char,vendor`), then polish.
3. **Weaker item icons to redo:** crab_shell, bat_wing, moth_wing, seal, the Noble pauldrons, bones.
4. **Remaining balance:** warriors levelling 40+ die a lot in Saltmere.

## Performance (measured 2026-09-26, Claude Code, owner's laptop: RTX 5060 Laptop, 3440x1440)
The owner says performance is horrible; fix this before more content. Measure with the new benchmark:
`godot --path godot -- --play --bench=6 --level=5 [--zone=z] [--off=grass,veg,shadow,lights,ssao,glow,gi,fog,meshes,particles] [--scale=0.6]`
(`tools/bench.gd`: walks the hero in a circle, prints avg/p95 frame ms, GPU ms, draw calls, triangles, top node types.)

Ashvale baseline: **~26 fps, GPU ~37 ms/frame, ~3,200 draw calls, ~7.6M triangles.** GPU ms with one thing switched off:
- `veg` (trees/bushes/rocks MultiMeshes in `src/world/vegetation.gd`): **11 ms** (the biggest cost). Each kind is ONE MultiMesh
  over the whole 256 m map, so no frustum culling, no distance culling (visibility_range acts on the whole instance) and every
  tree renders into all 4 shadow splits. Fix: bucket `_build`'s transforms into ~32 m cells (one MultiMeshInstance per kind per
  cell), give tall trees a visibility range, and cast shadows only from trunks/near cells.
- `shadow` (all lights): 22 ms. `lights` (omni/spot lamps hidden): 21 ms, so village lamps are costly, probably shadowed omnis.
  Check `village.gd`/`life.gd` lamps: turn off omni shadows or cap them, and use visibility ranges on lamp lights.
- `grass`: 34 ms (only ~3 ms, it's fine). `ssao,glow,gi,fog`: 33 ms (~4 ms). `particles`: no gain.
- Physics runs 20–35 ms per frame at low fps (1,500 CollisionShape3Ds; Jolt). Worth a look once the GPU is fixed.
- Also seen in the run: a repeated `SCRIPT ERROR: Trying to assign value of type 'Array' to a variable of type 'Dictionary'`
  and `Required object "rp_style" is null` (UI code), not yet traced.

Setting up a new PC: the paid [Source] art packs are not in git. Put the Quaternius zips/folders in Downloads and run
`tools/setup_godot.ps1` (or `Play Ashvale.bat`), or characters and skeletons will be missing.

## Running things
- **Play:** `Play Ashvale.bat`, or `godot --path godot`.
- **Headless tests** (from `godot/`): `godot --headless --path . --fixed-fps 30 -- --play --questtest=N --zone=<z> --level=<n> --class=<c> --done=<zone>`. Also `--raidtest` (zone scar, level 60), `--zonetour` and `--duel=kind:lvl`.
- **Screenshots:** `sh tools/shot.sh out.png --play --lite ...` (slow on software rendering).
- **Icons:**
  - Item icons: `python art/item_models.py [key prefixes]`, then `python art/item_paint.py`. This needs the `bpy` Python module (Blender 4.5), numpy, scipy and PIL.
  - Spell icons: `python art/spell_icons.py`.
  - Other painted art: `python art/buff_icons.py`, `python art/ui_art.py`, `python art/vfx_textures.py`.
  - After adding items, run `godot --headless --path godot -s tools/icon_keys.gd` to refresh `art/item_keys.txt`.
