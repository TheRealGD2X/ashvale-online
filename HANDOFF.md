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

## Running things
- **Play:** `Play Ashvale.bat`, or `godot --path godot`.
- **Headless tests** (from `godot/`): `godot --headless --path . --fixed-fps 30 -- --play --questtest=N --zone=<z> --level=<n> --class=<c> --done=<zone>`. Also `--raidtest` (zone scar, level 60), `--zonetour` and `--duel=kind:lvl`.
- **Screenshots:** `sh tools/shot.sh out.png --play --lite ...` (slow on software rendering).
- **Icons:**
  - Item icons: `python art/item_models.py [key prefixes]`, then `python art/item_paint.py`. This needs the `bpy` Python module (Blender 4.5), numpy, scipy and PIL.
  - Spell icons: `python art/spell_icons.py`.
  - Other painted art: `python art/buff_icons.py`, `python art/ui_art.py`, `python art/vfx_textures.py`.
  - After adding items, run `godot --headless --path godot -s tools/icon_keys.gd` to refresh `art/item_keys.txt`.
