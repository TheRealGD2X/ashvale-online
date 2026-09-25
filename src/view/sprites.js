/* ================= SPRITE ATLASES =================
   Pre-rendered characters, weapons and monsters (see art/README.md). Atlases live in assets/sprites/
   as <name>.png pages plus <name>.js, which calls ATLAS.register(json). Script tags are used instead
   of fetch() so the game still works when index.html is opened straight from disk.

   Draw model: every frame is stored trimmed, with its offset from the sprite's anchor — the point on
   the ground under the feet. drawFrame(c, atlas, key, x, y, s) is one drawImage.

   Animation is derived from the sim's fields (dir, mt/walk, atk, cast, dead/deadT, flashT, idle, afk)
   until the systems worker lands `e.anim` (ENGINEERING.md §3); when it exists it takes precedence. */
const ATLAS = {
  atlases: {}, loading: {}, missing: {},
  register(json) {
    const a = json; a.pagesImg = []; a.ready = false; let left = a.pages.length;
    a.pages.forEach((fn, i) => { const im = new Image(); im.onload = () => { if (--left === 0) a.ready = true; }; im.onerror = () => { ATLAS.missing[a.name] = true; }; im.src = 'assets/sprites/' + fn; a.pagesImg[i] = im; });
    ATLAS.atlases[a.name] = a;
  },
  get(name) {
    if (!name || ATLAS.missing[name]) return null;
    const a = ATLAS.atlases[name]; if (a) return a.ready ? a : null;
    if (!ATLAS.loading[name]) { ATLAS.loading[name] = true; const s = document.createElement('script'); s.src = 'assets/sprites/' + name + '.js'; s.onerror = () => { ATLAS.missing[name] = true; }; document.head.appendChild(s); }
    return null;
  },
  frameKey(a, anim, dir, i) {
    const an = a.anims[anim]; if (!an) return null;
    const n = an.frames; i = an.loop ? ((i % n) + n) % n : Math.max(0, Math.min(n - 1, i));
    return anim + '/' + dir + '/' + i;
  },
  /* Draw one frame with its anchor at world (x, y). s = extra scale. o: {tint, glow, flash, alpha}
     Tinting recolours through a small scratch canvas (multiply keeps the shading), per draw. */
  drawFrame(c, a, key, x, y, s, o) {
    const f = a.frames[key]; if (!f) return false;
    const sc = a.scale * (s || 1); const [pg, fx, fy, w, h, ox, oy] = f;
    const page = a.pagesImg[pg];
    const flip = o && o.flip;
    if (flip) { c.save(); c.scale(-1, 1); }
    const dx = flip ? ox * sc - x : x + ox * sc, dy = y + oy * sc, dw = w * sc, dh = h * sc;
    let src = page, sx = fx, sy = fy;
    if (o && (o.tint || o.flash)) {
      const t = ATLAS.scratch(w, h), tc = t.getContext('2d'); tc.clearRect(0, 0, w, h); tc.drawImage(page, fx, fy, w, h, 0, 0, w, h);
      if (o.tint) { tc.globalCompositeOperation = 'multiply'; tc.fillStyle = o.tint; tc.fillRect(0, 0, w, h); tc.globalCompositeOperation = 'destination-in'; tc.drawImage(page, fx, fy, w, h, 0, 0, w, h); }
      if (o.flash) { tc.globalCompositeOperation = 'source-atop'; tc.fillStyle = 'rgba(255,255,255,.75)'; tc.fillRect(0, 0, w, h); }
      tc.globalCompositeOperation = 'source-over'; src = t; sx = 0; sy = 0;
    }
    if (o && o.glow) { c.save(); c.globalCompositeOperation = 'lighter'; c.globalAlpha = .5 + Math.sin(S.time * 6) * .15; c.shadowColor = o.glow; c.shadowBlur = 12; c.drawImage(src, sx, sy, w, h, dx, dy, dw, dh); c.restore(); }
    c.drawImage(src, sx, sy, w, h, dx, dy, dw, dh);
    if (flip) c.restore();
    return true;
  },
  /* resolve (anim, dir, i) to a frame key, mirroring directions 5–7 for 5-direction atlases */
  key(a, anim, dir, i) {
    let flip = false; if (a.mirror && dir > 4) { dir = 8 - dir; flip = true; }
    const k = ATLAS.frameKey(a, anim, dir, i) || ATLAS.frameKey(a, 'idle', dir, 0);
    return [k, flip];
  },
  layer(c, a, anim, dir, i, x, y, size, o) {
    if (!a) return; const [k, flip] = ATLAS.key(a, anim, dir, i); if (!k) return;
    ATLAS.drawFrame(c, a, k, x, y, size, Object.assign({ flip }, o || {}));
  },
  scratch(w, h) { const t = ATLAS._scratch || (ATLAS._scratch = document.createElement('canvas')); if (t.width < w || t.height < h) { t.width = Math.max(t.width, w); t.height = Math.max(t.height, h); } return t; },

  /* ---- which atlas for which thing ---- */
  WEAPON_SET: { wood: 'w_sword_1h', sword: 'w_sword_1h', curved: 'w_sword_1h', serrated: 'w_sword_1h', moon: 'w_sword_1h', fang: 'w_sword_1h', eternity: 'w_sword_1h', abyssblade: 'w_sword_1h',
    long: 'w_sword_2h', dragonblade: 'w_sword_2h',
    axe: 'w_axe_1h', greataxe: 'w_axe_2h', worldbreaker: 'w_axe_2h',
    dagger: 'w_dagger', kris: 'w_dagger', leaf: 'w_dagger', jade: 'w_dagger', abyssfang: 'w_dagger',
    wand: 'w_wand', skullstaff: 'w_staff', crystalstaff: 'w_staff', emberstaff: 'w_staff', dragonstaff: 'w_staff', abyssstaff: 'w_staff', bough: 'w_staff', reaver: 'w_staff' },
  TWO_HANDED: { long: 1, dragonblade: 1, greataxe: 1, worldbreaker: 1 },
  /* monsters drawn as one whole-figure set (skeletons, creatures) */
  MON_SET: { skeleton: 'sk_warrior', axe_skeleton: 'sk_rogue', bone_fighter: 'sk_warrior', bone_king: 'sk_warrior', abyss_knight: 'sk_warrior', colossus: 'sk_warrior', vaal: 'sk_mage', wraith: 'sk_mage',
    hen: 'cr_hen', deer: 'cr_deer', boar: 'cr_boar', old_tusk: 'cr_boar', black_boar: 'cr_boar', cave_bat: 'cr_bat', maggot: 'cr_maggot', spider: 'cr_spider', snake: 'cr_snake', moth: 'cr_moth' },
  /* whole-figure colour tints for monsters that share a set */
  MON_TINT: { old_tusk: '#8a6a4a', black_boar: '#4a4448', abyss_knight: '#b8a8e8', colossus: '#f0e8d8', vaal: '#c8b8ff', wraith: '#a090ff', bone_king: '#e8d8ff' },
  /* humanoid monsters use the layered human sets: which armour group, and which weapon set */
  MON_STYLE: { scarecrow: 'leather', wildcat: 'leather', wildcat_brute: 'leather', zombie: 'leather', rot_zombie: 'leather', goblin: 'leather', goblin_fighter: 'leather', goblin_shaman: 'robe', goblin_brute: 'leather', goblin_warlord: 'plate',
    temple_archer: 'plate', stone_guardian: 'plate', cultist: 'robe', khar_elite: 'plate', minotaur: 'plate', lich_acolyte: 'robe' },
  MON_WEAPON: { stick: 'w_staff', hook: 'w_dagger', rake: 'w_dagger', club: 'w_axe_1h', sword: 'w_sword_1h', axe: 'w_axe_1h', staff: 'w_staff', greatsword: 'w_sword_2h', greataxe: 'w_axe_2h', bow: 'w_crossbow', abyssstaff: 'w_staff' },
  monLook(e) {   // a synthetic `look` for a humanoid monster so it can use the human layers
    const d = e.def, st = ATLAS.MON_STYLE[d.id] || (d.stone ? 'plate' : 'leather');
    return { armor: { style: st, c: d.cloth || d.skin }, weapon: d.weapon && ATLAS.MON_WEAPON[d.weapon] ? { k: Object.keys(ATLAS.WEAPON_SET).find(k => ATLAS.WEAPON_SET[k] === ATLAS.MON_WEAPON[d.weapon]), c: d.stone ? '#8a8478' : null } : null,
      helm: d.helmet || d.crown ? { c: d.crown ? '#e0b23a' : '#7a7a80', k: 'nasal' } : null, skinTint: d.skin, cape: null };
  },
  /* body armour variants: item id → set, else nearest colour within the style group */
  ARMOUR_ITEM: { light_armour: { W: 'leather_hide', M: 'robe_purple', T: 'tao_green' }, medium_armour: { W: 'plate_dark', M: 'robe_purple', T: 'tao_green' }, heavy_armour: { W: 'plate_iron', M: 'robe_purple', T: 'tao_green' },
    mage_robe: { M: 'robe_blue' }, arcane_robe: { M: 'robe_arcane' }, abyss_robe: { M: 'robe_abyss' }, soul_robe: { T: 'tao_green' }, spirit_robe: { T: 'tao_spirit' }, abyss_vest: { T: 'tao_abyss' },
    wargod: { W: 'plate_gold' }, abyss_plate: { W: 'plate_abyss' } },
  STYLE_GROUP: { plate: ['plate_iron', 'plate_dark', 'plate_bronze', 'plate_gold', 'plate_abyss'], chain: ['plate_dark', 'plate_iron'], leather: ['leather_hide', 'leather_dark', 'leather_green'],
    robe: ['robe_purple', 'robe_blue', 'robe_arcane', 'robe_abyss', 'robe_red'], taorobe: ['tao_green', 'tao_spirit', 'tao_abyss', 'tao_blue'] },
  VARIANT_COL: { plate_iron: '#9aa2ac', plate_dark: '#4a4e58', plate_bronze: '#b07a3a', plate_gold: '#e0b23a', plate_abyss: '#3a2a5a', leather_hide: '#7a5534', leather_dark: '#4a3628', leather_green: '#5a6a3a',
    robe_purple: '#6a4a9a', robe_blue: '#3b3f8a', robe_arcane: '#1d1b52', robe_abyss: '#140a24', robe_red: '#8a2020', tao_green: '#2f6a4a', tao_spirit: '#ece6d4', tao_abyss: '#2a2238', tao_blue: '#2f4a8a' },
  BASE_OF: v => v.startsWith('plate') ? 'knight' : v.startsWith('leather') ? 'barbarian' : v.startsWith('robe') ? 'mage' : 'rogue',
  HELM_OF: { knight: 'helm_knight', barbarian: 'hat_barbarian', mage: 'hat_mage', rogue: null },
  CLASS_DEFAULT: { W: 'leather_hide', M: 'robe_purple', T: 'tao_green' },
  nearestVariant(group, hex) {
    if (!hex) return group[0]; const c = hexRgb(hex).split(',').map(Number); let best = group[0], bd = 1e9;
    for (const v of group) { const k = hexRgb(ATLAS.VARIANT_COL[v]).split(',').map(Number); const d = (k[0] - c[0]) ** 2 + (k[1] - c[1]) ** 2 + (k[2] - c[2]) ** 2; if (d < bd) { bd = d; best = v; } }
    return best;
  },
  bodyVariantFor(e, L) {
    const cls = e.kind === 'player' ? S.P.cls : (e.cls || 'W');
    if (e.kind === 'player') { const it = S.P.equip.armour; const m = it && ATLAS.ARMOUR_ITEM[it.id]; if (m && m[cls]) return m[cls]; }
    if (e.kind === 'mon' && L && L.armor) return ATLAS.nearestVariant(ATLAS.STYLE_GROUP[L.armor.style] || ATLAS.STYLE_GROUP.leather, L.armor.c);
    const st = L && L.armor && L.armor.style, grp = st && ATLAS.STYLE_GROUP[st];
    if (grp) { if (cls === 'M' && !st.includes('robe')) return ATLAS.nearestVariant(ATLAS.STYLE_GROUP.robe, L.armor.c); if (cls === 'T' && st !== 'taorobe') return ATLAS.nearestVariant(ATLAS.STYLE_GROUP.taorobe, L.armor.c); return ATLAS.nearestVariant(grp, L.armor.c); }
    return ATLAS.CLASS_DEFAULT[cls] || 'leather_hide';
  },
  /* first loaded atlas from a list of candidates (later ones are fallbacks) */
  getAny(names) { for (const n of names) { if (!n) continue; const a = ATLAS.get(n); if (a) return a; if (!ATLAS.missing[n]) return null; } return null; },
  CR_BASE: { cr_boar: '#6a4a38', cr_deer: '#9a6b3e', cr_wolf: '#6a6a72', cr_bear: '#4a3a2e', cr_hen: '#f1eadc', cr_spider: '#3a2e2a', cr_bat: '#4a3a52', cr_moth: '#b8a87a', cr_snake: '#4a7a3a', cr_maggot: '#c9b08a' },
  bodySetFor(e, L) {   // monsters and pets: one set for the whole figure
    if (e.kind === 'mon') { const d = e.def; if (ATLAS.MON_SET[d.id]) return ATLAS.MON_SET[d.id]; if (d.bone) return d.weapon === 'staff' ? 'sk_mage' : d.weapon ? 'sk_warrior' : 'sk_minion'; if (d.body !== 'biped') return { quad: 'cr_boar', hen: 'cr_hen', worm: 'cr_maggot', flyer: 'cr_bat', spider: 'cr_spider', snake: 'cr_snake' }[d.body] || null; return null; }
    if (e.kind === 'pet') return e.petType === 'hound' ? null : 'sk_minion';
    return null;
  },
  weaponSetFor(L) { const w = L && L.weapon; return w ? ATLAS.WEAPON_SET[w.k] || null : null; },

  /* ---- animation state from the sim ---- */
  anim(e, a, twoH) {
    const has = n => !!a.anims[n];
    if (e.anim && has(e.anim.state)) return [e.anim.state, Math.floor((e.anim.t / Math.max(.05, e.anim.total || 1)) * a.anims[e.anim.state].frames), false];
    if (e.dead) { const an = a.anims.die; if (an && e.deadT < an.frames / an.fps) return ['die', Math.floor(e.deadT * an.fps), false]; return has('dead') ? ['dead', 0, false] : ['die', 99, false]; }
    if (e.kind === 'mon' && has('spawn') && e.idle < a.anims.spawn.frames / a.anims.spawn.fps && e.atk < 0) return ['spawn', Math.floor(e.idle * a.anims.spawn.fps), false];
    if (e.atk >= 0) { const n = twoH && has('attack2h') ? 'attack2h' : (e._alt && has('attack2')) ? 'attack2' : 'attack'; return [n, Math.floor(e.atk * a.anims[n].frames), false]; }
    if (e.cast >= 0) { const n = e.castDur > 1.2 && has('casting') ? 'casting' : 'cast'; return [n, Math.floor(e.cast * a.anims[n].frames), false]; }
    if (e._hitT > 0 && has('hit')) return ['hit', Math.floor((1 - e._hitT / .25) * a.anims.hit.frames), false];
    if (e.mt < 1) return ['walk', Math.floor((e.walk % 1) * a.anims.walk.frames), true];
    if ((e.afk || e.sitting) && has('sit')) return ['sit', Math.floor(e.idle * a.anims.sit.fps), true];
    if (e.emote && has(e.emote.name)) return [e.emote.name, Math.floor(e.emote.t * a.anims[e.emote.name].fps), false];
    return ['idle', Math.floor(e.idle * a.anims.idle.fps), true];
  },
  /* per-entity view bookkeeping (hit reaction timer, alternating swings) */
  tick(e, dt) {
    if (e.flashT > 0 && !e._flashSeen) {
      e._flashSeen = true; if (e.atk < 0) e._hitT = .25;
      // visual knockback away from the player when the player is on it
      const p = S.player; if (p && p !== e && p.target === e) { const dx = epx(e) - epx(p), dy = epy(e) - epy(p), l = Math.hypot(dx, dy) || 1; e._kb = { x: dx / l * 4, y: dy / l * 3, t: .14 }; }
    } else if (e.flashT <= 0) e._flashSeen = false;
    if (e._hitT > 0) e._hitT -= dt;
    if (e._kb) { e._kb.t -= dt; if (e._kb.t <= 0) e._kb = null; }
    if (e.dead && !e._deadSeen) { e._deadSeen = true; if (e.kind === 'mon' && S.player && (e.pdmg > 0)) { VIEW.hitStop(e.def && e.def.boss ? .18 : .05); VIEW.shake(e.def && e.def.boss ? .8 : .18); } }
    else if (!e.dead) e._deadSeen = false;
    if (e.atk >= 0 && e._atkPrev < 0) e._alt = !e._alt; e._atkPrev = e.atk;
  },

  /* Draw a full entity as layers (cape, body, head, helmet, weapon). Returns false when the
     atlases needed aren't loaded yet, so the caller can fall back to the code-drawn figure. */
  drawEntity(c, e, x, y, o) {
    const L = e.kind === 'player' ? playerLook() : e.kind === 'mon' && e.def.body === 'biped' && !ATLAS.MON_SET[e.def.id] && !e.def.bone ? ATLAS.monLook(e) : e.look;
    const size = (o && o.size) || 1, flash = e.flashT > 0 && !e.dead;
    const monSet = ATLAS.bodySetFor(e, L);
    let body, head = null, helm = null, cape = null, wp = null, wopts = null, hopts = null, copts = null;
    let bodyOpts = { flash }, headOpts = { flash };
    if (monSet) { body = ATLAS.get(monSet); if (!body) return false; const t = e.kind === 'mon' && (ATLAS.MON_TINT[e.def.id] || (monSet.startsWith('cr_') && e.def.col !== ATLAS.CR_BASE[monSet] ? e.def.col : null)); if (t) bodyOpts.tint = t; }
    else {
      if (e.kind === 'mon' && !L) return false;
      const v = ATLAS.bodyVariantFor(e, L), base = ATLAS.BASE_OF(v), cls = e.kind === 'player' ? S.P.cls : (e.cls || 'W');
      if (L && L.skinTint) headOpts.tint = L.skinTint;
      body = ATLAS.getAny(['body_' + v, 'body_' + ATLAS.CLASS_DEFAULT[cls], 'body_' + ATLAS.STYLE_GROUP[base === 'knight' ? 'plate' : base === 'barbarian' ? 'leather' : base === 'mage' ? 'robe' : 'taorobe'][0]]);
      if (!body) return false;
      const bname = body.name.slice(5), b2 = ATLAS.BASE_OF(bname);
      head = ATLAS.get('head_' + b2);
      const H = L && L.helm; if (H && ATLAS.HELM_OF[b2]) { const hn = H.k === 'cap' && b2 === 'knight' ? 'hat_barbarian' : ATLAS.HELM_OF[b2]; helm = ATLAS.get(hn); hopts = { tint: H.c || null, flash }; }
      const C = L && L.armor && L.armor.cape; if (C) { cape = ATLAS.get('cape_' + b2); copts = { tint: C, flash }; }
      const wName = ATLAS.weaponSetFor(L); wp = wName ? ATLAS.get(wName) : null;
      if (wp) wopts = { tint: L.weapon.c && L.weapon.c !== '#c7ccd2' ? L.weapon.c : null, glow: L.weapon.glow || null, flash };
    }
    const wk = L && L.weapon && L.weapon.k, twoH = !!(wk && ATLAS.TWO_HANDED[wk]);
    const [anim, i] = ATLAS.anim(e, body, twoH);
    if (e._kb) { const k = e._kb.t / .14; x += e._kb.x * k; y += e._kb.y * k; }
    const d = e.dir, away = d === 7 || d === 0 || d === 1;
    // soft ground shadow (the sprites carry none, so every figure grounds the same way)
    if (!e.dead || e.deadT < .4) { c.fillStyle = 'rgba(0,0,0,.28)'; c.beginPath(); c.ellipse(x, y + 1, 15 * size, 6 * size, 0, 0, 7); c.fill(); }
    if (cape && !away) ATLAS.layer(c, cape, anim, d, i, x, y, size, copts);
    if (wp && away) ATLAS.layer(c, wp, anim, d, i, x, y, size, wopts);
    ATLAS.layer(c, body, anim, d, i, x, y, size, bodyOpts);
    if (head) ATLAS.layer(c, head, anim, d, i, x, y, size, headOpts);
    if (helm) ATLAS.layer(c, helm, anim, d, i, x, y, size, hopts);
    if (cape && away) ATLAS.layer(c, cape, anim, d, i, x, y, size, copts);
    if (wp && !away) ATLAS.layer(c, wp, anim, d, i, x, y, size, wopts);
    return true;
  }
};
