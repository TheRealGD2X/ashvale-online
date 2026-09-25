# Start here — presentation worker (art, animation, effects, audio, UI)

You own everything the player sees and hears: `src/view/**`, `index.html`, `art/**`, `assets/**`.
The rules of the game (`src/sim/**`) belong to the systems worker; never edit them. Read
`docs/DESIGN.md` (the bible) and `docs/ENGINEERING.md` (the seam between sim and view) first.
The owner, GD2X, is not technical: talk in plain English, and end every session with a note in
`CHANGELOG.md` saying what changed, what to try, and what's next.

## The brief, in the owner's words
Classic World of Warcraft's heart in a Legend of Mir 2 body, single player, PC only (mouse and
keyboard, 1080p–4K, no phone layouts). It must look and play like a AAA game: polished, satisfying
animations and skills, one cohesive look, weapons and armour that show on the character with lots of
variety, items that scale with the content, bosses that drop specific items. The current UI is
"rushed and janky", with no context menus; that rebuild is yours too.

## State of play (25 Sep 2026, end of the first art session)
**Decided and built**
- **Art pipeline (`art/`)** — Blender (`pip install bpy`) renders 3D models into sprite atlases from the
  game's fixed camera (48×32 tile projection, 8 directions clockwise from north, 4 = facing camera).
  `art/README.md` explains it. Style: Classic-WoW chunky low-poly, flat colours, top-front light, no
  baked shadows (the game draws a soft ellipse). Symmetric layers render 5 directions and mirror.
- **Layered paper doll** (Mir 2 style): body armour, head, helmet, cape and weapon are separate sets
  on one rig, composed in `src/view/sprites.js` (`ATLAS.drawEntity`). Armour variants come from
  `art/variants.py` (palette-cell recolours of KayKit's textures → `art/models/variants/`), listed in
  `art/jobs/make_jobs.py`. Helmets and capes render neutral grey and are tinted live.
- **Creatures** (`art/creatures.py`) are built from primitives with bone rigs and keyframed Idle/
  Walk/Attack/Hit/Die/Dead: boar, deer, wolf, bear, hen, spider, bat, moth, snake, maggot. Their
  forward axis is −X, so their jobs carry `"yaw": 90`. Shapes are first-pass; refine freely.
- **Sources**: KayKit Adventurers, Skeletons, Dungeon Remastered, Medieval Hexagon (CC0) cloned from
  github.com/KayKit-Game-Assets. Only GitHub is reachable from the cloud sandbox (itch/quaternius/
  kenney/opengameart are blocked), so anything else must be built in Blender.
- **Game feel** (`src/view/feel.js`): smoothed camera with look-ahead, trauma shake, hit-stop on
  crits/kills (time scale in `boot.js`), visual knockback, popping combat text (`draw.js`
  `floatText`), radial cooldown sweeps + countdown + ready flash on the hotbar (`ui.js`, `style.css`).
- **Monster mapping** in `sprites.js`: skeleton family → `sk_*` sets; animals → `cr_*`; humanoid
  monsters (goblins, zombies, cultists…) reuse the human layers with skin/cloth tints (`monLook`).
  Anything without an atlas falls back to the old code-drawn figure, so the game never breaks.
- **Renderer stays Canvas 2D** for now (incremental, no dependencies). Revisit WebGL (PixiJS) only if
  palette-mask tinting or lighting demands it.

**Rendering queue**: `sh art/run_all.sh` renders every job in priority order and packs each into
`assets/sprites/`. It takes ~2–3 h on two CPU cores for everything (~53 sets: 17 armour bodies,
4 heads, 3 helmets, 4 capes, 11 weapons, 4 skeletons, 10 creatures). Check `assets/sprites/*.js`
to see what exists; `art/_render/<name>/meta.json` marks a finished render. Re-run `run_all.sh`
any time — it skips finished sets. Whatever is missing when you start, render it first.

**Verified**: `python3 tests/smoke_test.py` green; `python3 tests/shot.py W` screenshots the game
with sprites loaded (`tests/_shots/`). The Knight body/head/helmet/cape/sword layers compose
correctly (checked frame by frame).

## Next, in order
1. Finish the render queue; commit `assets/sprites/` as sets complete (they're small, ~0.5 MB each).
2. In-game check of every set: scale, anchor, mirrored directions, weapon behind/in-front rule,
   tint colours, monster sizes (`def.size`). Fix `ATLAS.VARIANT_COL` nearest-colour picks for bots.
3. Hair colour tint for heads (`P.hair`), female heads (none in KayKit — consider a second head
   set built in Blender), and the `hood` for Taoists (currently the hooded rogue head).
4. Bosses need presence: size, tint, aura glow, and a crown/horn layer (Minotaur, Khar, Bone King).
5. World: replace the code-drawn town/dungeon with pre-rendered tiles, buildings, trees and props
   from the Dungeon and Medieval Hexagon packs through the same camera (`art/` job kind "prop"),
   ground tile atlases with variants/transitions/decals, always-on lighting with a warm day grade.
6. Effects: sprite-based impact FX, weapon trails, dust on footsteps, spell projectiles and ground
   telegraphs for bosses; ability visuals keyed to `events.hit` frames and ability ranks.
7. Audio: layered weapon hits (transient + thud + material), UI sounds, combat music ducking,
   low-HP heartbeat; keep the generative music (it's good).
8. UI rebuild (all of it, PC-first): window manager that remembers positions, right-click menus on
   everything, target frame with cast bar and debuffs, party frames with roles, comparison tooltips,
   chat tabs, UI scale slider, one visual language (strip the bevels/gloss, keep the Mir orb, belt
   and gem buttons). Add the save-to-file / load-from-file buttons in the menu (promised to GD2X).
9. Title screen and character creation with the real sprites turning on a turntable.

## Working with GD2X
- Publish through GitHub Desktop on his PC (it's installed and signed in; the repo is
  github.com/TheRealGD2X/ashvale-online, live at https://therealgd2x.github.io/ashvale-online/).
  With computer control you can do the commit + push clicks yourself; see README.md.
- The systems worker will change `src/sim/**` in parallel; when it lands `e.anim`, `cast`, `gcd`,
  `cooldowns`, `procs`, `threatTop`, `con` (ENGINEERING.md §3) switch `ATLAS.anim()` and the HUD
  to those fields. Until then the view derives animation from the old fields.
- He wants to be shown things: screenshots in the chat, and a build on the web address he can
  refresh, every session.
