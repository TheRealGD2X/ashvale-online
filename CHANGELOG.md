# Changelog

Newest first. One line per commit. Tags: `[contract]` change to `src/shared/*`, `[cross]` touched the other worker's files, `[need]` a request for the other worker, `[design]` DESIGN.md changed.

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
