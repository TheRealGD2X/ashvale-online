/* ================= CHARACTER STAGE =================
   Draws a rendered character large and alone: the title-screen heroes, the character-creation
   turntable, and (later) the character window. Uses the same paper doll as the world
   (ATLAS.drawEntity) with a pretend entity, so what you see here is exactly what walks in town.

   STAGE.hero(opts)             → a pretend entity: { cls, fem, head, hair, skin, variant, weapon, helm, cape, dir }
   STAGE.draw(c, e, x, y, size, t, pose)   one frame; pose: 'idle' | 'attack' | 'cast' | 'raise' | 'cheer' | 'walk'
   STAGE.floor(c, x, y, r)      the lit ground disc a hero stands on                                              */
const STAGE = {
  START_KIT: { W: { variant: 'leather_hide', weapon: 'wood' }, M: { variant: 'robe_purple', weapon: 'wood' }, T: { variant: 'tao_green', weapon: 'wood' } },
  hero(o) {
    const kit = STAGE.START_KIT[o.cls] || STAGE.START_KIT.W;
    const look = { skin: o.skin || '#e0b48a', hair: o.hair || '#2a1a0a', fem: !!o.fem, head: o.head || null, variant: o.variant || kit.variant,
      armor: { style: 'leather', c: '#7a5534', cape: o.cape || null }, weapon: { k: o.weapon || kit.weapon, c: null, glow: o.glow || null }, helm: o.helm || null };
    return { kind: 'bot', id: 'stage', name: o.name || 'Hero', cls: o.cls, look, dir: o.dir == null ? 4 : o.dir, mt: 1, walk: 0, idle: 0, atk: -1, cast: -1, castDur: .45,
      flashT: 0, dead: false, deadT: 0, buffs: {} };
  },
  /* put the pretend entity in a pose at time t (seconds into the pose) */
  pose(e, pose, t) {
    e.atk = -1; e.cast = -1; e.mt = 1; e._castRaise = false; e.emote = null; e.idle = t;
    if (pose === 'walk') { e.mt = .5; e.walk = t * 1.6; }
    else if (pose === 'attack') { e.atk = Math.min(.999, t / .45); e._alt = false; }
    else if (pose === 'cast') e.cast = Math.min(.999, t / .45);
    else if (pose === 'raise') { e.cast = Math.min(.999, t / .5); e._castRaise = true; }
    else if (pose === 'cheer') e.emote = { name: 'cheer', t };
    return e;
  },
  floor(c, x, y, r) {
    const g = c.createRadialGradient(x, y, 0, x, y, r);
    g.addColorStop(0, 'rgba(255,214,150,.28)'); g.addColorStop(.55, 'rgba(255,170,90,.10)'); g.addColorStop(1, 'rgba(0,0,0,0)');
    c.fillStyle = g; c.beginPath(); c.ellipse(x, y, r, r * .42, 0, 0, 7); c.fill();
    c.strokeStyle = 'rgba(227,194,127,.25)'; c.lineWidth = 1; c.beginPath(); c.ellipse(x, y, r * .62, r * .26, 0, 0, 7); c.stroke();
  },
  /* draw e at (x, y) feet position, `size` = scale over the in-game size; false when not loaded yet */
  draw(c, e, x, y, size) {
    c.save(); c.imageSmoothingQuality = 'high';
    const ok = ATLAS.drawEntity(c, e, x, y, { size });
    c.restore(); return ok;
  },
  /* the sets a stage needs, asked for early so they are ready when the screen opens */
  preload(cls) {
    const kit = STAGE.START_KIT[cls]; if (!kit) return;
    ATLAS.preload(['body_' + kit.variant, 'wpn_' + kit.weapon, 'head_knight', 'hair_knight', 'head_barbarian', 'hair_barbarian', 'head_mage', 'hair_mage', 'head_rogue', 'hair_rogue']);
  },
};
// the sets nearly every screen needs, asked for while the title screen is up
ATLAS.preload(['head_knight', 'hair_knight', 'head_barbarian', 'hair_barbarian', 'head_mage', 'hair_mage', 'head_rogue', 'hair_rogue', 'head_hood', 'hair_hood',
  'body_leather_hide', 'body_robe_purple', 'body_tao_green', 'body_plate_iron', 'wpn_wood', 'wpn_dragonblade', 'wpn_crystalstaff', 'wpn_bough', 'body_plate_gold', 'body_robe_arcane', 'body_tao_spirit', 'helm_dragon']);
