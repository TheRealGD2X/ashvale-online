/* ================= WORLD PROPS =================
   Houses, trees, rocks, lamps and crates rendered from 3D through the same camera and sun as the
   characters (art/render_props.py → assets/sprites/props_*.webp), so the world and the people in it
   are one picture. Anything without a rendered prop keeps its old code-drawn sprite (world.js).

   PROPS.draw(c, o, px, py) → true when it drew the object (px, py as render.js passes them: the
   tile's bottom centre for one-tile objects, the footprint's bottom-left corner for big ones).     */
const PROPS = {
  /* object → [set, key]; v picks a variant */
  pick(o) {
    const v = o.v || 0;
    switch (o.type) {
      case 'house': return ['props_town', 'house_' + o.role];
      case 'fountain': return ['props_town', 'fountain'];
      case 'cave_mouth': return ['props_town', 'cave_mouth'];
      case 'lamp': return ['props_town', 'lamp'];
      case 'barrel': return ['props_town', 'barrel'];
      case 'crate': return ['props_town', 'crate'];
      case 'tree': return ['props_nature', o.dark ? (v % 2 ? 'darkoak' : 'pine_dark') : 'oak' + (v % 4)];
      case 'pine': return ['props_nature', o.dark ? 'pine_dark' : 'pine' + (v % 2)];
      case 'rock': return ['props_nature', 'rock' + (v % 5)];
      case 'bush': return ['props_nature', 'bush' + (v % 2)];
      case 'crop': return ['props_nature', 'crop' + (v % 3)];
      case 'mushroom': return ['props_nature', 'mushroom' + (v % 2)];
    }
    return null;
  },
  draw(c, o, px, py) {
    const p = PROPS.pick(o); if (!p) return false;
    const a = ATLAS.get(p[0]); if (!a) return false;
    const f = a.frames[p[1] + '/0/0']; if (!f) return false;
    const multi = (o.fw || 1) > 1, s = multi ? 1 : (o.s || 1);
    // one-tile props stand on the middle of their tile; big ones sit on their footprint corner
    const y = multi ? py : py - 10;
    let alpha = 1;
    if ((o.type === 'tree' || o.type === 'pine') && S.player) {   // see-through when the player walks behind a tree
      const e = S.player, ex = epx(e), ey = epy(e), sc = a.scale * s, top = y + f[6] * sc, w = f[3] * sc;
      if (ey < y - 4 && ey > top + 30 && Math.abs(ex - px) < w * .38) alpha = .45;
    }
    if (alpha < 1) c.globalAlpha = alpha;
    ATLAS.drawFrame(c, a, p[1] + '/0/0', px, y, s);
    if (alpha < 1) c.globalAlpha = 1;
    return true;
  },
  preload() { ATLAS.preload(['props_town', 'props_nature']); },
};
PROPS.preload();
