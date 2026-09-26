# UI direction (from the owner, 2026-09-26)

- **Layout:** Albion Online's UI, paired with Diablo's:
  - Health and mana (or rage) **orbs** at the bottom corners.
  - The **hotbar along the bottom centre**, between the orbs.
  - Albion's clean, readable panels and windows everywhere else.
- **Icons are the priority.** Every icon (items, spells, abilities, buffs, materials) is something the player looks at all the time. Each one must look **extremely polished and pleasing to the eye**. No simple shapes or cut-outs. Each icon gets real work:
  - Painted or rendered look.
  - Lighting, depth and material detail.
  - A consistent frame and quality border.
- The same standard applies to the **whole UI**: frames, fonts, spacing, hover states, tooltips and animations.

## Plan for the UI milestone (M8)

1. **Item and weapon icons:**
   - Render the actual 3D models (weapons, armour pieces, props) in Blender.
   - Use a studio light rig, rim light and a soft background vignette.
   - One icon per item, with a colour-graded frame by quality.
2. **Ability and buff icons:**
   - Paint-style scenes built and rendered in Blender for each ability: flame, frost, holy light, shadow, weapon strikes.
   - Use strong silhouettes and glow, with a per-school palette.
   - Hand-check every one.
3. **Materials, consumables and quest items:** rendered props in the same studio style.
4. **HUD:**
   - Diablo-style liquid orbs, animated and with a glass highlight.
   - A bottom-centre hotbar in an ornate frame, with cooldown sweeps and keybind labels.
   - Albion-style panels for bags, the character sheet, the map and the market.
5. **Review:** screenshot every window and icon sheet, and iterate until each icon reads well at 40 px and looks good at 80 px.

## Spell and ability effects (VFX), from the owner the same day

Every spell, ability and impact effect must be **real, carefully made VFX**, never simple shapes. Players see them all the time, so they must look good. The plan:

- **Textures:** hand-made flipbook textures for fire, frost shards, smoke, sparks, holy rays, shadow wisps, slashes and shock rings, rendered or painted, not flat circles.
- **Layered effects:** a core and glow, trailing particles, a distortion or heat shimmer where it fits, a light flash on the scene and an impact decal on the ground.
- **Per-ability design:**
  - Fireball: wind-up in the hands, a flickering trail, then an impact burst with embers and a scorch.
  - Frostbolt: ice crystals, a mist trail, a shatter.
  - Holy spells: rays of light and motes.
  - Shadow: smoky tendrils.
  - Warrior strikes: weapon arcs and sparks.
  - Auras: a subtle looping shell.
- **Reference:** WoW Classic's readability, with modern particle quality.
- **Review:** check each effect in a screenshot or short capture, and iterate until it looks right.
