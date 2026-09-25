# Art pipeline

Every character, weapon and monster in the game is a **pre-rendered sprite**: a 3D model is posed by
Blender, photographed from the game's fixed camera in 8 directions for every animation, and packed
into an atlas. This is how Legend of Mir 2 was made, and it means a new weapon or a new armour
colour is a re-render, not a redraw.

```
art/models/kaykit/     3D sources (KayKit packs, CC0 — see LICENSE-*.txt)
art/jobs/*.json        one job per sprite set: model, which meshes, which animations, how many frames
art/jobs/make_jobs.py  writes the job files (edit this, not the JSON)
art/render.py          bpy script: job → art/_render/<name>/*.png (+ meta.json)
art/pack.py            frames → assets/sprites/<name>.png pages + <name>.json + <name>.js
art/run_all.sh         renders and packs every job, skipping ones already rendered
assets/sprites/        what the game loads (committed)
```

## Camera and scale
Orthographic, pitched 41.8° above the horizon so a 1×1 ground tile projects to 48×32 px (Mir's
tile). Directions are numbered clockwise from north: 0 faces away from the camera, 4 faces it.
A KayKit character is ~2.4 units tall; at zoom 1 it is drawn ~72 px tall (`scale` in the atlas
JSON). Frames are rendered at 256 px so they stay crisp when the game zooms in.

The sun is fixed in the world (upper left, warm), with a cool fill and a rim light, so a character's
lit side changes as it turns. The ground is a shadow catcher: the soft shadow is baked into body
frames and travels with the sprite.

## Adding things
* **A new body / monster:** drop the .glb in `art/models/…`, add a `body(...)` line in
  `make_jobs.py` (prefix = the mesh name prefix that belongs to the character; everything else in
  the file is hidden), run `make_jobs.py`, then `sh art/run_all.sh <name>`.
* **A new weapon:** `weapon(...)` with either `obj=` (a weapon mesh that ships inside a character
  file, already fitted to the hand) or `model=` (a standalone mesh, attached to `handslot.r` with
  KayKit's offset and a −90° X rotation). Weapon layers are rendered with the body hidden and share
  the rig, so one layer fits every body. The game draws the weapon behind the body for the three
  away-facing directions and in front otherwise.
* **Monsters holding things:** `attach=[…]` renders the weapon together with the body.
* **Colour variants (armour tiers, rare weapons):** `"tint": [r,g,b]` multiplies the material
  colours; `"texture": "path.png"` swaps the body texture. Cheap, so use it freely.
* **Animation events:** `"events": {"hit": 3}` marks the frame on which the blow lands; the game
  fires impact sounds and effects on that frame.

## Rendering
`python3 art/render.py art/jobs/knight.json --quick --dirs 4 --anims idle,attack` previews in
seconds. Full quality is ~2 s a frame on two CPU cores (Cycles, 8 samples + denoise), so a full
player body (69 animation frames × 8 directions) takes about 20 minutes. `run_all.sh` is meant to
run in the background: `nohup sh art/run_all.sh > art/_render/log.txt 2>&1 &`.

## In the game
`src/view/sprites.js` loads atlases lazily by name, derives the animation from the sim's fields
(direction, movement, attack/cast progress, hit flash, death), and falls back to the old
code-drawn characters for anything that has no atlas yet, so the game is never broken by a missing
sprite.
