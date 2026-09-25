# Ashvale Online — the 3D game (Godot 4.7)

Play: double-click `Play Ashvale.bat` in the repo root. The first run calls `tools/setup_godot.ps1`, which unpacks Godot and the Quaternius kits from Downloads.

## Layout
| Path | What |
|---|---|
| `src/main.gd` | Builds the world. Also takes command-line options for screenshots (`--shot`, `--hour`, `--cam`, `--lite`...). |
| `src/world/world_data.gd` | The shape of the land. Holds heights, roads, the town plateau and the pond, all baked to a grid. Everything that places things asks here. |
| `src/world/terrain.gd` + `shaders/terrain.gdshader` | Ground mesh and collision. The shader paints meadow, road, cobbles, shore and rock. |
| `src/world/grass.gd` + `shaders/grass.gdshader` | GPU-placed meadow grass. Near and far layers, wind, and grass parting around the hero. |
| `src/world/vegetation.gd` + `shaders/foliage.gdshader` | Trees, bushes, flowers and rocks as MultiMeshes, with shared wind. Trees fade when they hide the hero. |
| `src/world/village.gd` | Houses built from the Medieval Village kit, plus the market, garden, woodpile, lanterns and chimney smoke. |
| `src/world/water.gd` + `shaders/water.gdshader` | The pond, its mirrored reflection camera, lily pads, the jetty and fish rings. |
| `src/world/day_night.gd` + `shaders/sky.gdshader` | Sun, moon, sky, fog and exposure through the day. Sets the global shader values `wind_time` and `hero_pos`. |
| `src/world/life.gd` + `shaders/critter.gdshader` | Villagers and their routines, butterflies and fireflies. |
| `src/actors/humanoid.gd` / `anim_lib.gd` / `hero.gd` | A person's body plus animations fitted to their skeleton. `hero.gd` is the player controller. |
| `src/camera/orbit_camera.gd` | Albion-style follow camera: orbit, zoom, never under the ground. |
| `src/ui/hud.gd` | Clock, controls card, FPS. |
| `assets/characters/` | Our built people. Rebuild with `python3 art/godot/characters.py` (Blender, needs the kits unpacked in `$PACKS`). |
| `assets/{nature,village,props,anims}/` | The Quaternius kits, unpacked by the setup script. Not in git. |

## Testing in the cloud workspace
`sh tools/shot.sh out.png --hour=10 --dist=15 --pitch=-30 --yaw=150 --hero=x,z --lite` renders one frame with software Vulkan (lavapipe under Xvfb) and quits. `--lite` turns off SDFGI and volumetric fog, which don't fit in the workspace's memory. Real GPUs always run the full lighting.
