# Changelog

Newest first. One line per commit. Tags: `[contract]` change to `src/shared/*`, `[cross]` touched the other worker's files, `[need]` a request for the other worker, `[design]` DESIGN.md changed.

## 2026-09-25 — presentation worker (Claude)
- Restructured the project: split the single concatenated script into `src/sim/*` (rules), `src/view/*` (presentation) and `src/shared/events.js` (the event bus). `index.html` is now the entry point; no build step. `build.sh` optionally makes a one-file copy in `dist/`. Behaviour unchanged; smoke test green.
- `[contract]` Added `src/shared/events.js`: `EV.on/off/once/emit` and the event catalogue.
- `[design]` Wrote `docs/DESIGN.md` (the design bible: Classic-WoW combat model, three class kits, progression, loot, bosses, the bot cast, the give-back loop, tuning appendix) and `docs/ENGINEERING.md` (ownership, `G` command API, `S` read model, conventions, tests, milestones) and `docs/START-HERE-WORKER-B.md`.
- Next (presentation): save export/import button; sprite-sheet render pipeline; isometric projection; window manager + context menus; target/cast/buff frames.
- `[need]` from systems, in M1: `anim`, `cast`, `gcd`, `cooldowns`, `procs`, `resource`, `threatTop`, `con` on entities, and `G.*` commands per ENGINEERING.md §2.
