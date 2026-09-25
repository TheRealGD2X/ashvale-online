# Ashvale Online — Engineering Handover

*For the systems worker (the model GD2X picks to build the rules of the game). Written by the presentation worker (Claude), who owns everything the player sees and hears. Read `docs/DESIGN.md` first; this document is about how to build it without the two of us colliding.*

---

## 1. Ground rules

1. **Two workers, one repo, hard file ownership.**
   - **You (systems)** own `src/sim/**` — the rules: data tables, combat, abilities, threat, AI, loot, quests, progression, bots, save/load, time.
   - **Presentation (me)** owns `src/view/**` and `index.html` — rendering, art, animation, camera, effects, audio, the HUD and every window, input mapping to commands.
   - **Shared:** `src/shared/**` (currently `events.js`), `docs/**`, `tests/**`, `README.md`. Anyone may edit these, but a change to `src/shared/events.js` must be described in `CHANGELOG.md` under a `[contract]` tag on the same commit.
   - If you truly must touch a `src/view` file (for example to keep the game running while you rename a function), make the smallest possible change, and note it in `CHANGELOG.md` with `[cross]` so I can absorb it.
2. **The seam is `S` (state), `EV` (events) and `G` (commands).** The sim never touches `document`, `window.getContext`, `AU`/`sfx`, `UI`, or any DOM id. When something happens that should be seen or heard, `EV.emit(...)` and move on. The view reads `S` freely, never writes it, and drives the sim only through `G.*`.
3. **No build step.** `index.html` loads plain `<script>` tags in a fixed order (top-level `function`/`const`/`let` declarations are shared across classic scripts, so the old single-file behaviour is preserved). Later scripts may re-declare a function to override it — that is how `src/sim/bots.js` currently patches `src/sim/game.js`. Prefer *not* to add more of that; it was tolerated in the draft, not designed.
4. **`python3 tests/smoke_test.py` must pass before every commit** (zero `PAGEERR`). Add sim-level tests as you go (§7).
5. **One worker in the folder at a time.** The owner runs each of us in the same folder with GitHub Desktop; if two sessions write the same file concurrently the later write wins silently. Pull before you start, commit when you stop.
6. **Every commit gets a line in `CHANGELOG.md`** (newest first): date, worker, what changed, anything the other worker must know.
7. **Design changes go in `docs/DESIGN.md` first**, then code. If a number in the design turns out to be wrong in play, change it in both places in the same commit and say why in the changelog.

---

## 2. The command API — `G` (you implement this in `src/sim/`)

Create `src/sim/api.js` (loaded after `game.js`/`bots.js`, before `src/view/*`) exposing one global object `G`. Every function validates its input, does nothing harmful on bad input, returns `true`/`false` (or a small result object), and emits events for whatever it changed. This is the *only* way the view changes the world.

```
// targeting & combat
G.target(entityId | null)         // set/clear the player's target
G.targetNearestHostile()          // Space
G.tabTarget(dir = +1)             // Tab / Shift+Tab: cycle hostiles in view, nearest first
G.attack()                        // start auto-attack on current hostile target
G.stopAttack()
G.cast(abilityId, targetId?)      // respects GCD, range, resource, cast time; returns { ok, reason }
G.cancelCast()
G.setStance(stanceId)             // warrior
G.petCommand(cmd)                 // 'passive' | 'defensive' | 'aggressive' | 'attack' | 'follow' | 'dismiss'
// movement
G.move(dx, dy)                    // WASD, unit vector in 8 directions; called every frame while held
G.moveTo(x, y)                    // click-to-move (pathfinds)
G.stopMove()
G.interact(entityId)              // talk to NPC / loot corpse / open door / pick up drop
G.hearth()                        // hearthstone
G.travel(hubId)                   // gatekeeper
// items
G.useItem(invSlot)                // consumables, scrolls; equips gear if it is gear
G.useBelt(beltSlot)               // Q/E and belt clicks
G.equip(invSlot)  G.unequip(equipSlot)
G.moveItem(fromSlot, toSlot)      // inventory ↔ inventory / belt / storage (slot ids are strings: 'inv:3', 'belt:0', 'sto:12', 'eq:ring1')
G.splitStack(invSlot, n)
G.dropItem(invSlot)               // to the ground (view asks for confirmation on q>=1)
G.sell(invSlot, n)  G.buy(shopId, itemId, n)  G.buyback(i)
G.repair(all = true | equipSlot)
G.useMythic()                     // R
// abilities & hotbar
G.setKey(slot 0..7, abilityId | null)
G.learn(abilityId)                // at the trainer
// social
G.say(channel, text, to?)         // 'say'|'shout'|'guild'|'group'|'whisper'
G.emote(name)                     // 'wave'|'dance'|'sit'|'laugh'|'cheer'|'cry'...
G.sit(bool)
G.party.invite(name)  G.party.accept()  G.party.decline()  G.party.leave()  G.party.kick(name)  G.party.setLeader(name)
G.loot.vote(rollId, 'need'|'greed'|'pass')
G.trade.open(name)  G.trade.offer({ gold, items: [invSlot] })  G.trade.accept()  G.trade.cancel()
G.guild.join(guildId) G.guild.leave() G.guild.found(name)
// quests
G.quest.accept(id)  G.quest.abandon(id)  G.quest.turnIn(id, rewardChoice?)  G.quest.track(id, bool)
G.npc.choose(npcId, optionIndex)  // dialogue option
// meta
G.save()  G.exportSave() -> string  G.importSave(string) -> { ok, reason }
G.newCharacter({ name, cls, fem, hair })  G.selectCharacter(id)  G.deleteCharacter(id)
G.setOption(key, value)           // audio/UI options persisted in the profile
G.tooltip.item(itemInstance) -> { name, q, ilvl, req, slot, stats: [{k, v, cmp}], set, use, bind, dur, sell, flavour }
G.tooltip.ability(abilityId) -> { name, rank, cost, range, castTime, cd, school, desc, nextRank }
G.tooltip.entity(id) -> { name, lv, con, type, elite, rare, boss, guild, title }
```

Tooltips return **structured data**; the view formats it. Never build HTML in the sim.

---

## 3. The state read model — `S` (you own it; the view reads it)

Keep `S` as the single world-state object (already the case). Fields the view depends on — add, don't rename, and keep them updated every tick:

- `S.player` and every entity in `S.ents`: `id, kind ('player'|'mon'|'bot'|'npc'|'guard'|'pet'), name, lv, cls, role, x, y, mt, mdur, dir (0–7 clockwise from north), hp, maxhp, mp, maxmp, resource {type, val, max}, anim {state, t, total}, look, buffs [{id, t, total, stacks, debuff, school}], cast {ability, t, total, channel}, gcd {t, total}, target, threatTop (mon: id of top threat), con ('grey'|'green'|'yellow'|'orange'|'red'), elite, rare, boss, type, dead, ghost, sitting, afk, emote {name, t}, guild, title, faction, inCombat`.
  - `anim.state` ∈ `idle | walk | run | attack | cast | channel | hit | die | dead | sit | eat | mount`. `t` counts up in seconds, `total` is the nominal length (weapon speed for `attack`, cast time for `cast`, 0.8 s for `die`). The view chooses frames from these; it never guesses from hp deltas.
- `S.player` extras: `cooldowns {abilityId: {t, total}}, procs {abilityId: expiresAt}, rested, restedMax, xp, xpNeed, keys[8], belt[6], inv[], storage[], equip {}, durability via item.dur, quests {active: [...], tracked: [...]}, rep {faction: value}, pity {bossId: n}, lockouts {instanceId: resetAt}, gold, title, stance, pet, party {members: [ids], leader}, mounted`.
- `S.map`: `id, name, w, h, tiles (Uint8 index into a tileset table), objects [{type, x, y, w, h, variant}], spawns, graveyard {x,y}, hub, portals, indoor, ambience`.
- `S.time`: `{ now (ms, real), hour, minute, phase (0..1), dark (0..1), weather ('clear'|'rain'|'fog'|'snow') }`.
- `S.drops`: `[{ id, item, q, x, y, owner, rollId, t }]`.
- `S.online`: roster entries currently "logged in" (for the `/who` list and the population counter).
- `S.chat`: `[{ t, ch, from, to, text, kind }]` capped at 400; the view renders channels/tabs from `ch`.
- `S.roll`: current need/greed window or `null`: `{ id, item, q, ends, votes: {name: vote|null} }`.
- `S.trade`, `S.npcDialog` (`{ npcId, name, text, options: [{label, kind}] }`), `S.shop` (`{ id, items: [...], buyback: [...] }`) — the sim owns the *content* of these; the view owns the windows.

Anything the view needs and can't find in `S` is a request to you, logged in `CHANGELOG.md` with `[need]`.

---

## 4. Events — `EV` (`src/shared/events.js`)

The catalogue and payloads are in the file header. Rules:
- Emit **at the moment it happens**, inside the sim tick, never batched or deferred.
- Payloads carry **entity ids and item instances**, not DOM ids or colours.
- `combat:hit` is emitted once per damage instance including DoT ticks (`ability` set, `tick: true`).
- `ui:dirty` replaces the draft's `UI.invDirty = true` pattern. The sim sets nothing on `UI`.
- New events: add them to the catalogue in the header first; the view ignores unknown events safely, so adding is never breaking. Renaming or changing a payload is a `[contract]` change.

---

## 5. Repo layout and running it

```
index.html                 the game (open it in any browser; no server needed)
src/shared/events.js       EV bus + event catalogue  (shared)
src/sim/data.js            classes, xp, abilities, items, monsters, quests, NPCs   (yours)
src/sim/game.js            world state S, entities, movement, combat, loot, AI, maps, update()  (yours)
src/sim/bots.js            bot life layer (personalities, groups, trade, chat, help)  (yours)
src/sim/save.js            save/load, new profile  (yours)
src/view/style.css         all CSS
src/view/world.js          map generators + ground/wall/object drawing
src/view/draw.js           weapons, monster bodies, particles, FX
src/view/human.js          paper-doll character renderer
src/view/audio.js          synthesized SFX + generative music
src/view/render.js         camera, render pipeline, lighting, labels
src/view/ui.js             HUD, windows, tooltips, drag/drop, input bindings
src/view/boot.js           title, character creation, main loop, boot
tests/smoke_test.py        headless Playwright run: python3 tests/smoke_test.py [--shots]
build.sh                   optional: makes dist/ashvale.html, a single-file copy
docs/                      DESIGN.md (the bible), this file, START-HERE-WORKER-B.md
```

Run: double-click `index.html`, or `python3 -m http.server` in the folder and open `http://localhost:8000`. Test: `python3 tests/smoke_test.py` (needs `pip install playwright && playwright install chromium`).

**Load order** (in `index.html`) is the contract for globals: `shared/events → sim/data → view/world → view/draw → view/human → view/audio → sim/game → sim/bots → view/render → view/ui → sim/save → view/boot`. When you add `src/sim/api.js` (and later `abilities.js`, `threat.js`, `roster.js`, `quests.js`…), insert them after `sim/bots.js` and tell me in the changelog; I'll keep `index.html` in step. Note `view/world.js` currently sits *before* `sim/game.js` because map generation lives there and `changeMap` calls it — see §6.3 for the plan to split map *data* from map *drawing*.

---

## 6. Conventions

### 6.1 Style
- Plain ES2020, no modules, no transpiling. One statement per line where a human will read it; the draft's 300-column lines are the reason nobody can review it. Break them up as you touch them.
- Globals are the namespace: `S`, `G`, `EV`, `ABILITIES`, `ITEMS`, `MON`, `QUESTS`, `ROSTER`, `TIME`. No new bare globals for internals — hang helpers on a module object (`const Combat = {...}`).
- Data tables are **data**: an ability is an object with `school, cost, cd, castTime, range, gcd, effect: [...]` interpreted by one executor, not a `switch` of 40 cases. Same for monster behaviours (flags) and boss mechanics (a small script list: `{ at: 0.5, do: 'spawn', ... }`).
- Units: seconds for time, tiles for distance, real ms only in `S.time.now`.
- Randomness: `R()` for gameplay. Anything that must be reproducible across sessions (bot schedules, rare-spawn windows, daily quests) uses a seeded RNG keyed on the calendar day (`mulberry(dayIndex)`).

### 6.2 Time
`S.time.now` is real wall-clock time and drives day/night, schedules, lockouts, respawns and rested XP. `update(dt)` runs the simulation at up to 60 Hz with `dt` clamped to 0.05 s (already so in `frame()`). **Nothing may be frame-rate dependent**: the draft's `Math.max(1, dt*60)` potion drain and per-frame `R() < .02` mob repositioning are bugs to remove. Offline catch-up runs once at login: simulate the world in coarse steps (one per 10 real minutes, max 30 lines of chat generated).

### 6.3 Maps
Today `src/view/world.js` both *lays out* a map (tiles, houses, spawns) and *draws* it. Target: the sim owns **map data** (`src/sim/maps.js`: grid, blocking, spawn tables, NPC placement, portals, graveyard, hub, object list with types) and the view owns **how it looks** (tilesets, sprites, decoration). Until that split lands, keep calling `getMap(id)` from `view/world.js` as now; don't add gameplay data to it — add it to `sim/data.js` and read it from there.

### 6.4 Save format
`S.P` remains the per-character profile; add `S.W` for **world** state shared by all characters (roster, guild history, boss timers, market, server-firsts). Bump `P.v`/`W.v` and write a `migrate(obj)` chain in `save.js` — never let an old save crash into the title screen (today, renaming an item id does exactly that). Saves live in `localStorage` (`ashvale_online_v2`), plus `G.exportSave()` / `G.importSave()` for the file backup the owner asked for. Multiple characters: `ashvale_chars` index + one key per character.

### 6.5 Performance budget
`update(dt)` ≤ 2 ms at 250 entities on a mid laptop. Distance-gate bot and monster thinking (the draft gates monsters but runs A* for every bot every 0.8 s). Replace the linear-scan open list in `findPath` with a binary heap before adding more bots. No per-frame allocations in hot loops.

### 6.6 What to keep from the draft
Keep and build on: the entity model and `S`, `findPath`, `computeStats` structure, the item instance shape (`{id, u, n, add, r, l}` — extend with `dur, ilvl, affix, bind`), `MON` flags, `QUESTS` shape, the bot persona/typing-style machinery in `bots.js` (`blStyle`, `blPers`, help state machine), `setTimeoutGame`/`TIMERS`. Replace: `playerSwing`/`castSkill`/`monHit` (new combat model), `rollLoot`/`killEnt` loot paths, `raidFinder`/`enterRaid`, `botAI`/`botDamage`, `worldTick`, `changeMap`'s world wipe, the level/quest content past level 12, all prices (×0.01), the potion code (`useItem` instant path), `dealDamage`'s `R() < .25` retarget (threat table instead).

### 6.7 Known bugs in the draft (fix as you replace)
- `game.js` `useItem`: `instant` consumables skip `potCd` — infinite Sun Potion.
- `game.js` `dealDamage`: 25 %-per-hit retarget, no threat.
- `game.js` `monAI`: boss `< 30 %` multiplies step *duration* by 0.75 (speeds up); ranged mobs reposition per frame.
- `game.js` `update`: potion pool drain frame-rate dependent.
- `game.js` `changeMap`: wipes `S.ents`, `S.drops`, `S.respawns`, `TIMERS` — bots, pending help offers and ground loot vanish on every portal.
- `game.js` `computeStats`: `ITEMS[it.id].dc` with no guard — an unknown item id in a save throws and the title shows no character.
- `bots.js` `blConvPre`: help intent checked before thanks/no ("ty for the help" spawns another offer).
- `bots.js` `blReactRare`: triggers on hex colour strings; economy `blBuyOffer` pays up to 2.75× vendor; `joinParty` wrapper silently no-ops when full; help offers point at stale entity objects after a map change.
- Everywhere: reactions keyed on `sys()` message wording (regexes over English strings). Key them on events instead.

---

## 7. Testing

- `tests/smoke_test.py` stays green (it already checks the event bus exists).
- Add `tests/sim_harness.js`: a Node script that loads `src/shared/events.js` and `src/sim/*.js` into a `vm` context with stubs for the view-side globals the sim still calls during the transition (`sfx, fx, burst, floatText, healFx, UI, $, resize, drawHuman`… — make the stub a no-op function factory and log any name hit so the list shrinks over time). Then `tests/sim_*.js` files can run scenarios without a browser: "Warrior holds two mobs off a Taoist bot for 30 s", "potion cooldown is 120 s", "need/greed with 4 bots always resolves within 30 s", "level 1→40 with quests only takes N XP", "save → migrate → load round-trips". `node tests/run.js` runs them all. Keep each under a second.
- Balance checks are tests too: encode the §12 targets (TTK per class at levels 5/20/40, three-mob downtime) as assertions with ±25 % tolerance so a data change that breaks the curve fails loudly.

---

## 8. Milestones and what the view needs from each

Each milestone ends with the game playable end-to-end, the smoke test green, a changelog entry, and `docs/DESIGN.md` updated where reality diverged.

| # | Milestone | Acceptance | The view will need |
|---|---|---|---|
| M1 | Combat core (`G` targeting/attack/cast, GCD, resources, hit table, threat + taunt, con, speed rule, potion cd, death/ghost/graveyard, durability) | A Warrior can hold two even mobs off a Taoist bot with Taunt + Sunder, and can lose. All `combat:*`, `player:*` events fire. | `anim`, `cast`, `gcd`, `cooldowns`, `procs`, `resource`, `threatTop`, `con`, `ghost`; `G.tooltip.*` |
| M2 | Classes (three ability tables with ranks, trainers, stances, pets, bots on the same tables by role) | A 5-man Mine run with role bots works: no teleporting, no magic self-heals, bots die and drink. | per-ability `school` and `fx` tags I can map to visuals; `emote`, `sitting`, `eat` states |
| M3 | Loot & items (rarity/ilvl/affix/bind, need/greed with votes, boss tables with pity, junk, repair, prices) | A dungeon boss kill opens a roll window and everyone votes; the winner equips visibly. | `S.roll`, `loot:*` events, `item.dur`, `G.tooltip.item` with comparison data |
| M4 | Progression (quest hubs to 40, markers, tracker data, rested/discovery XP, rep, dailies, lockouts, milestones, hearth/inn/gatekeepers, real-time day, offline catch-up) | A fresh character can quest to 40; log out at the inn and rested XP appears next day. | quest marker state per NPC, `S.time`, `rested`, `lockouts`, `rep` |
| M5 | The cast (roster, schedules, per-zone presence, memory, LFG/travel, guild life, ambient chat generator, dialogue fallback + optional LLM hook) | Change zones and the same people are still there; a bot who said "omw" walks in; whisper a bot and get a sensible 4-turn conversation. | `S.online`, `S.chat` channels, `bot:emote`, `party:*` |
| M6 | Bosses & raid (signature mechanics, enrage, phases, raid leader, 10-player raid, weekly lockout, Mythics with pity, server-firsts, world events) | Sanctum is clearable in 40–60 min by a competent player with a few wipes. | boss `telegraph` data (`{shape, x, y, r, t, total}`) so I can draw it, phase events |

The view will be rebuilt in parallel. **Expect `index.html` and everything under `src/view/` to change under you**; do not depend on any DOM id, CSS class, canvas or `UI.*` field. If the game won't run because I changed a view function you still call, that's my bug — say so in the changelog and I'll fix it the same day.

---

## 9. Working alongside the presentation worker

- I will replace the renderer with a sprite-sheet pipeline, move to an isometric projection (tile coordinates, `S.occ`, pathfinding and `dir` stay exactly as they are — only the *projection* changes, in `view/render.js`), rebuild every window, and route all effects through `EV`. None of that needs anything from you beyond §3 and §4.
- When I need a new field or event, I'll add a `[need]` line in the changelog with the exact name and shape. When you add one, tag it `[contract]`.
- If we both need to change `src/shared/events.js` in the same week, whoever commits second merges by hand and keeps both.
- Questions for the owner go in `docs/QUESTIONS.md` (create it) — one line each, with the default you'll take if there's no answer. GD2X is not technical: write questions in plain English, and prefer picking a sensible default over blocking.
