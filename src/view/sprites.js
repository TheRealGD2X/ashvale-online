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
     Tinting recolours a frame once and caches it (ATLAS.recolour). */
  drawFrame(c, a, key, x, y, s, o) {
    const f = a.frames[key]; if (!f) return false;
    const sc = a.scale * (s || 1); const [pg, fx, fy, w, h, ox, oy] = f;
    const page = a.pagesImg[pg];
    const flip = o && o.flip;
    if (flip) { c.save(); c.scale(-1, 1); }
    const dx = flip ? ox * sc - x : x + ox * sc, dy = y + oy * sc, dw = w * sc, dh = h * sc;
    let src = page, sx = fx, sy = fy;
    if (o && (o.tint || o.flash)) { src = ATLAS.recolour(a, key, page, f, o.tint, o.flash); sx = 0; sy = 0; }
    if (o && o.glow) {   // a soft halo of the glow colour around the silhouette (magic weapons, bosses)
      const g = ATLAS.recolour(a, key, page, f, null, false, o.glow);
      c.save(); c.globalCompositeOperation = 'lighter'; c.globalAlpha = .55 + Math.sin(S.time * 5) * .2; c.filter = 'blur(' + Math.max(2, 5 * sc) + 'px)';
      c.drawImage(g, 0, 0, w, h, dx, dy, dw, dh); c.filter = 'none'; c.globalAlpha *= .6; c.drawImage(g, 0, 0, w, h, dx, dy, dw, dh); c.restore();
    }
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
  layer(c, a, anim, dir, i, x, y, size, o, suffix) {
    if (!a) return; const [k, flip] = ATLAS.key(a, anim, dir, i); if (!k) return;
    if (suffix && !a.frames[k + suffix]) return;   // no behind-the-body part on this frame
    ATLAS.drawFrame(c, a, suffix ? k + suffix : k, x, y, size, Object.assign({ flip }, o || {}));
  },
  /* A recoloured copy of one frame: tinted (multiply keeps the shading), flashed white, or a solid
     silhouette for glows. Cached (least recently used goes first) so a tinted character costs one
     plain drawImage per frame instead of three compositing passes. */
  _rc: new Map(), RC_MAX: 1600,
  recolour(a, key, page, f, tint, flash, solid) {
    const id = a.name + '|' + key + '|' + (tint || '') + (flash ? '!' : '') + (solid ? '#' + solid : '');
    let t = ATLAS._rc.get(id);
    if (t) { ATLAS._rc.delete(id); ATLAS._rc.set(id, t); return t; }
    const [, fx, fy, w, h] = f;
    t = document.createElement('canvas'); t.width = w; t.height = h; const tc = t.getContext('2d');
    tc.drawImage(page, fx, fy, w, h, 0, 0, w, h);
    if (tint) { tc.globalCompositeOperation = 'multiply'; tc.fillStyle = tint; tc.fillRect(0, 0, w, h); tc.globalCompositeOperation = 'destination-in'; tc.drawImage(page, fx, fy, w, h, 0, 0, w, h); }
    if (flash) { tc.globalCompositeOperation = 'source-atop'; tc.fillStyle = 'rgba(255,255,255,.75)'; tc.fillRect(0, 0, w, h); }
    if (solid) { tc.globalCompositeOperation = 'source-in'; tc.fillStyle = solid; tc.fillRect(0, 0, w, h); }
    ATLAS._rc.set(id, t);
    if (ATLAS._rc.size > ATLAS.RC_MAX) ATLAS._rc.delete(ATLAS._rc.keys().next().value);
    return t;
  },
  scratch2(w, h) { const t = ATLAS._scratch2 || (ATLAS._scratch2 = document.createElement('canvas')); if (t.width < w || t.height < h) { t.width = Math.max(t.width, w); t.height = Math.max(t.height, h); } return t; },
  scratch(w, h) { const t = ATLAS._scratch || (ATLAS._scratch = document.createElement('canvas')); if (t.width < w || t.height < h) { t.width = Math.max(t.width, w); t.height = Math.max(t.height, h); } return t; },

  /* ---- which atlas for which thing ---- */
  WEAPON_SET: { wood: 'w_sword_1h', sword: 'w_sword_1h', curved: 'w_sword_1h', serrated: 'w_sword_1h', moon: 'w_sword_1h', fang: 'w_sword_1h', eternity: 'w_wand', abyssblade: 'w_sword_2h', blade: 'w_sword_1h', greatsword: 'w_sword_2h',
    long: 'w_sword_2h', dragonblade: 'w_sword_2h',
    axe: 'w_axe_1h', greataxe: 'w_axe_2h', worldbreaker: 'w_axe_2h',
    dagger: 'w_dagger', kris: 'w_dagger', leaf: 'w_dagger', jade: 'w_dagger', abyssfang: 'w_dagger',
    wand: 'w_wand', staff: 'w_staff', skullstaff: 'w_bone_staff', crystalstaff: 'w_staff', emberstaff: 'w_staff', dragonstaff: 'w_staff', abyssstaff: 'w_bone_staff', bough: 'w_staff', reaver: 'w_bone_blade',
    bow: 'w_crossbow', boneblade: 'w_bone_blade', boneaxe: 'w_bone_axe' },
  TWO_HANDED: { long: 1, dragonblade: 1, greataxe: 1, worldbreaker: 1, abyssblade: 1, greatsword: 1 },
  /* monsters drawn as one whole-figure set (skeletons, creatures) */
  MON_SET: { skeleton: 'sk_warrior', axe_skeleton: 'sk_rogue', bone_fighter: 'sk_warrior', bone_king: 'sk_king', abyss_knight: 'sk_warrior', colossus: 'sk_king', vaal: 'sk_lich', wraith: 'sk_mage',
    hen: 'cr_hen', deer: 'cr_deer', boar: 'cr_boar', old_tusk: 'cr_boar', black_boar: 'cr_boar', cave_bat: 'cr_bat', maggot: 'cr_maggot', spider: 'cr_spider', snake: 'cr_snake', moth: 'cr_moth' },
  SET_FALLBACK: { sk_king: 'sk_warrior', sk_lich: 'sk_mage' },
  /* whole-figure colour tints for monsters that share a set */
  MON_TINT: { old_tusk: '#8a6a4a', black_boar: '#4a4448', abyss_knight: '#b8a8e8', colossus: '#d8d0e8', wraith: '#a090ff' },
  /* humanoid monsters use the layered human sets: which armour group, and which weapon set */
  MON_STYLE: { scarecrow: 'leather', wildcat: 'leather', wildcat_brute: 'leather', zombie: 'leather', rot_zombie: 'leather', goblin: 'leather', goblin_fighter: 'leather', goblin_shaman: 'robe', goblin_brute: 'leather', goblin_warlord: 'plate',
    temple_archer: 'plate', stone_guardian: 'plate', cultist: 'robe', khar_elite: 'plate', minotaur: 'plate', lich_acolyte: 'robe' },
  MON_WEAPON: { stick: 'stick', hook: 'hook', rake: 'hook', club: 'club', sword: 'sword', axe: 'axe', staff: 'staff', greatsword: 'long', greataxe: 'greataxe', bow: 'bow', abyssstaff: 'abyssstaff' },
  monLook(e) {   // a synthetic `look` for a humanoid monster so it can use the human layers
    const d = e.def, st = ATLAS.MON_STYLE[d.id] || (d.stone ? 'plate' : 'leather');
    return { armor: { style: st, c: d.cloth || d.skin }, weapon: d.weapon && ATLAS.MON_WEAPON[d.weapon] ? { k: ATLAS.MON_WEAPON[d.weapon], c: d.stone ? '#8a8478' : null } : null,
      helm: d.helmet || d.crown ? { c: d.crown ? '#e0b23a' : '#7a7a80', k: d.crown ? 'crown' : 'nasal' } : null, skinTint: d.skin, hood: d.hood, hair: '#2a221a', hairStyle: d.hood ? 'hood' : 'barbarian', hoodCol: d.cloth, cape: null,
      mhead: d.bull ? 'bull' : d.ears === 2 ? 'goblin' : d.ears === 1 ? 'cat' : d.hat ? 'sack' : null };
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
  CLASS_DEFAULT: { W: 'leather_hide', M: 'robe_purple', T: 'tao_green' },
  armourIdOf(A) {
    if (!ATLAS._armourByCol) { ATLAS._armourByCol = {}; for (const id in ITEMS) { const d = ITEMS[id]; if (d.slot === 'armour' && d.look) ATLAS._armourByCol[d.look.c + '|' + d.look.style] = id; } }
    return ATLAS._armourByCol[A.c + '|' + A.style] || null;
  },
  nearestVariant(group, hex) {
    if (!hex) return group[0]; const c = hexRgb(hex).split(',').map(Number); let best = group[0], bd = 1e9;
    for (const v of group) { const k = hexRgb(ATLAS.VARIANT_COL[v]).split(',').map(Number); const d = (k[0] - c[0]) ** 2 + (k[1] - c[1]) ** 2 + (k[2] - c[2]) ** 2; if (d < bd) { bd = d; best = v; } }
    return best;
  },
  bodyVariantFor(e, L) {
    if (L && L.variant) return L.variant;   // an explicit set (character creation, title screen)
    const cls = e.kind === 'player' ? S.P.cls : (e.cls || 'W');
    if (e.kind === 'player') { const it = S.P.equip.armour; const m = it && ATLAS.ARMOUR_ITEM[it.id]; if (m && m[cls]) return m[cls]; }
    else if (L && L.armor && e.kind === 'bot') {   // bots wear real items: find the item by its look and use the same set a player would
      const id = ATLAS.armourIdOf(L.armor); const m = id && ATLAS.ARMOUR_ITEM[id]; if (m && m[cls]) return m[cls];
    }
    if (e.kind === 'mon' && L && L.armor) return ATLAS.nearestVariant(ATLAS.STYLE_GROUP[L.armor.style] || ATLAS.STYLE_GROUP.leather, L.armor.c);
    const st = L && L.armor && L.armor.style, grp = st && ATLAS.STYLE_GROUP[st];
    if (grp) { if (cls === 'M' && !st.includes('robe')) return ATLAS.nearestVariant(ATLAS.STYLE_GROUP.robe, L.armor.c); if (cls === 'T' && st !== 'taorobe') return ATLAS.nearestVariant(ATLAS.STYLE_GROUP.taorobe, L.armor.c); return ATLAS.nearestVariant(grp, L.armor.c); }
    return ATLAS.CLASS_DEFAULT[cls] || 'leather_hide';
  },
  /* ---- heads: the whole head (its hair rendered neutral grey) plus the hair alone, drawn over it
     tinted to the character's hair colour. Five heads from KayKit fit any body (one shared rig):
     knight, barbarian, mage (male), rogue (female) and the Taoist hood. */
  HEADS_M: ['knight', 'barbarian', 'mage'],
  seed(e) { const s = String(e.name || e.id || ''); let h = 7; for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0; return h; },
  headFor(e, L, base) {
    L = L || {};
    let h = L.head || L.hairStyle || (e.kind === 'player' && S.P && S.P.head);
    const sd = ATLAS.seed(e);
    if (!h && L.beard) h = /^#[c-f]/i.test(L.hair || '') ? 'mage' : 'barbarian';   // grey-bearded sages, black-bearded smiths
    if (!h) h = L.hood || (base === 'rogue' && e.kind !== 'player' && sd % 2) ? 'hood' : L.fem ? 'rogue' : e.kind === 'player' ? (base === 'rogue' ? 'knight' : base) : ATLAS.HEADS_M[sd % 3];
    const tint = h === 'hood' ? (L.hoodCol || (L.armor && L.armor.c) || '#2f6a4a') : (L.hair || '#3a2a1a');
    return { head: 'head_' + h, hair: 'hair_' + h, hairTint: tint };
  },
  /* skin tone as a multiply relative to the rendered (light) skin, so darker tones darken it */
  skinMul(hex) {
    if (!hex) return null; const c = hexRgb(hex).split(',').map(Number), b = [240, 200, 160];
    const m = c.map((v, i) => Math.min(255, Math.round(255 * Math.min(1, v / b[i]))));
    return m[0] > 248 && m[1] > 248 && m[2] > 248 ? null : '#' + m.map(v => v.toString(16).padStart(2, '0')).join('');
  },
  /* helmets: each item look has its own model (art/helmets.py → helm_<k>, colours baked in);
     the KayKit full helm / wizard hat / horned hat are neutral grey and take the item colour */
  HELM_MODEL: { cap: 1, nasal: 1, plume: 1, skull: 1, dragon: 1, abyss: 1, crown: 1, horned: 1 },
  helmFor(L, base) {
    const H = L && L.helm; if (!H) return L && L.wizhat ? { set: 'hat_mage', tint: L.armor && L.armor.c } : null;
    if (ATLAS.HELM_MODEL[H.k] && !ATLAS.missing['helm_' + H.k]) return { set: 'helm_' + H.k, tint: null };
    const set = H.k === 'wizard' ? 'hat_mage' : H.k === 'horned' || H.k === 'cap' ? 'hat_barbarian' : 'helm_knight';
    return { set, tint: H.c || null };
  },
  /* first loaded atlas from a list of candidates (later ones are fallbacks) */
  getAny(names) { for (const n of names) { if (!n) continue; const a = ATLAS.get(n); if (a) return a; if (!ATLAS.missing[n]) return null; } return null; },
  preload(names) { for (const n of names) ATLAS.get(n); },
  CR_BASE: { cr_boar: '#6a4a38', cr_deer: '#9a6b3e', cr_wolf: '#6a6a72', cr_bear: '#4a3a2e', cr_hen: '#f1eadc', cr_spider: '#3a2e2a', cr_bat: '#4a3a52', cr_moth: '#b8a87a', cr_snake: '#4a7a3a', cr_maggot: '#c9b08a' },
  bodySetFor(e, L) {   // monsters and pets: one set for the whole figure
    if (e.kind === 'mon') { const d = e.def; if (ATLAS.MON_SET[d.id]) return ATLAS.MON_SET[d.id]; if (d.bone) return d.weapon === 'staff' ? 'sk_mage' : d.weapon ? 'sk_warrior' : 'sk_minion'; if (d.body !== 'biped') return { quad: 'cr_boar', hen: 'cr_hen', worm: 'cr_maggot', flyer: 'cr_bat', spider: 'cr_spider', snake: 'cr_snake' }[d.body] || null; return null; }
    if (e.kind === 'pet') return e.petType === 'hound' ? null : 'sk_minion';
    return null;
  },
  /* every item look has its own model (art/weapons.py → wpn_<k>); the stock KayKit sets are the fallback */
  WPN_MODEL: { wood: 1, sword: 1, leaf: 1, curved: 1, serrated: 1, moon: 1, fang: 1, kris: 1, jade: 1, reaver: 1, long: 1, dragonblade: 1, abyssblade: 1, axe: 1, greataxe: 1, worldbreaker: 1,
    dagger: 1, abyssfang: 1, wand: 1, staff: 1, skullstaff: 1, crystalstaff: 1, emberstaff: 1, dragonstaff: 1, abyssstaff: 1, bough: 1, eternity: 1, stick: 1, club: 1, hook: 1 },
  WPN_ALIAS: { blade: 'sword', greatsword: 'long', rake: 'hook' },
  weaponSetFor(L) {
    const w = L && L.weapon; if (!w) return null;
    const k = ATLAS.WPN_ALIAS[w.k] || w.k;
    if (ATLAS.WPN_MODEL[k] && !ATLAS.missing['wpn_' + k]) return 'wpn_' + k;
    return ATLAS.WEAPON_SET[w.k] || null;
  },

  /* ---- animation state from the sim ---- */
  RAISE_KINDS: { heal: 1, buff: 1, summon: 1, self: 1 },
  anim(e, a, twoH, wset) {
    const has = n => !!a.anims[n];
    const frames = (n, t) => Math.floor(t * a.anims[n].frames);
    if (e.anim && has(e.anim.state)) return [e.anim.state, frames(e.anim.state, e.anim.t / Math.max(.05, e.anim.total || 1)), false];
    if (e.dead) { const an = a.anims.die; if (an && e.deadT < an.frames / an.fps) return ['die', Math.floor(e.deadT * an.fps), false]; return has('dead') ? ['dead', 0, false] : ['die', 99, false]; }
    if (e.kind === 'mon' && has('spawn') && e.idle < a.anims.spawn.frames / a.anims.spawn.fps && e.atk < 0) return ['spawn', Math.floor(e.idle * a.anims.spawn.fps), false];
    if (e.atk >= 0) {
      let n = 'attack';
      if (e.shoot && has('shoot')) n = 'shoot';
      else if (twoH && has('attack2h')) n = e._alt && has('spin') && e.kind === 'player' && S.P && S.P.toggles && S.P.toggles.halfmoon ? 'spin' : 'attack2h';
      else if (wset === 'w_dagger' && has('stab')) n = e._alt ? 'stab' : 'attack';
      else if (e._alt && has('attack2')) n = 'attack2';
      return [n, frames(n, Math.min(.999, e.atk)), false];
    }
    if (e.cast >= 0) {
      let n = e.castDur > 1.2 && has('casting') ? 'casting' : 'cast';
      if (e._castRaise && has('raise')) n = 'raise';
      return [n, frames(n, Math.min(.999, e.cast)), false];
    }
    if (e._useT > 0 && has('use')) return ['use', frames('use', 1 - e._useT / .5), false];
    if (e._hitT > 0 && has('hit')) return ['hit', frames('hit', 1 - e._hitT / .25), false];
    if (e.mt < 1) return ['walk', Math.floor((e.walk % 1) * a.anims.walk.frames), true];
    if ((e.afk || e.sitting) && has('sit')) return ['sit', Math.floor(e.idle * a.anims.sit.fps), true];
    if (e.emote && has(e.emote.name)) return [e.emote.name, Math.floor(e.emote.t * a.anims[e.emote.name].fps), false];
    if (twoH && has('idle2h')) return ['idle2h', Math.floor(e.idle * a.anims.idle2h.fps), true];
    return ['idle', Math.floor(e.idle * a.anims.idle.fps), true];
  },
  /* per-entity view bookkeeping (hit reaction timer, alternating swings, what kind of spell) */
  tick(e, dt) {
    if (e.flashT > 0 && !e._flashSeen) {
      e._flashSeen = true; if (e.atk < 0 && e.cast < 0) e._hitT = .25;
      // visual knockback away from the player when the player is on it
      const p = S.player; if (p && p !== e && p.target === e) { const dx = epx(e) - epx(p), dy = epy(e) - epy(p), l = Math.hypot(dx, dy) || 1; e._kb = { x: dx / l * 4, y: dy / l * 3, t: .14 }; }
    } else if (e.flashT <= 0) e._flashSeen = false;
    if (e._hitT > 0) e._hitT -= dt;
    if (e._useT > 0) e._useT -= dt;
    if (e._kb) { e._kb.t -= dt; if (e._kb.t <= 0) e._kb = null; }
    if (e.dead && !e._deadSeen) { e._deadSeen = true; if (e.kind === 'mon' && S.player && (e.pdmg > 0)) { VIEW.hitStop(e.def && e.def.boss ? .18 : .05); VIEW.shake(e.def && e.def.boss ? .8 : .18); } }
    else if (!e.dead) e._deadSeen = false;
    if (e.atk >= 0 && e._atkPrev < 0) e._alt = !e._alt; e._atkPrev = e.atk;
    if (e.cast >= 0 && !(e._castPrev >= 0)) {
      // which spell started? the player's comes from the last key pressed; a Taoist bot that just reset its heal timer is healing
      if (e.kind === 'player') { const k = VIEW.lastCast, d = k && SKILLS[k]; e._castRaise = !!(d && ATLAS.RAISE_KINDS[d.kind] && k !== 'dash'); }
      else e._castRaise = e.cls === 'T' && e.healCd > 2.5;
    }
    e._castPrev = e.cast;
    if (e.kind === 'player' && S.P) { const pc = S.P.potCd || 0; if (pc > (e._potPrev || 0) + .2) e._useT = .5; e._potPrev = pc; }
  },

  /* Draw a full entity as layers. Order (Mir 2 style): the behind-the-body parts of the cape and
     weapon, the body, the face, the hair, the helmet, then the in-front parts of cape and weapon.
     Layers carry their own occlusion (see art/jobs/make_jobs.py), so this order is always right.
     Returns false when the atlases needed aren't loaded yet, so the caller can fall back to the
     code-drawn figure. */
  drawEntity(c, e, x, y, o) {
    const L = e.kind === 'player' ? playerLook() : e.kind === 'mon' && e.def.body === 'biped' && !ATLAS.MON_SET[e.def.id] && !e.def.bone ? ATLAS.monLook(e) : e.look;
    const size = (o && o.size) || 1, flash = e.flashT > 0 && !e.dead;
    const monSet = ATLAS.bodySetFor(e, L);
    let body, bodyOpts = { flash };
    const under = [], over = [], fronts = [];   // [atlas, opts]
    let twoH = false, wset = null;
    if (monSet) { body = ATLAS.getAny([monSet, ATLAS.SET_FALLBACK[monSet]]); if (!body) return false; const t = e.kind === 'mon' && (ATLAS.MON_TINT[e.def.id] || (monSet.startsWith('cr_') && e.def.col !== ATLAS.CR_BASE[monSet] ? e.def.col : null)); if (t) bodyOpts.tint = t; }
    else {
      if (e.kind === 'mon' && !L) return false;
      const v = ATLAS.bodyVariantFor(e, L), cls = e.kind === 'player' ? S.P.cls : (e.cls || 'W');
      body = ATLAS.getAny(['body_' + v, 'body_' + ATLAS.CLASS_DEFAULT[cls], 'body_' + ATLAS.STYLE_GROUP[{ knight: 'plate', barbarian: 'leather', mage: 'robe', rogue: 'taorobe' }[ATLAS.BASE_OF(v)]][0]]);
      if (!body) return false;
      const base = ATLAS.BASE_OF(body.name.slice(5));
      const hd = ATLAS.headFor(e, L, base), hm = ATLAS.helmFor(L, base);
      const skin = L && L.skinTint ? L.skinTint : ATLAS.skinMul(L && L.skin);
      if (L && L.mhead && !ATLAS.missing['mhead_' + L.mhead]) {   // a monster's own head (goblin, minotaur...) replaces face and hair
        const mh = ATLAS.get('mhead_' + L.mhead); if (mh) over.push([mh, { flash }]);
      } else {
        const head = ATLAS.get(hd.head);
        if (head) over.push([head, { tint: skin, flash }]);
        if (head && head.v) { const hr = ATLAS.get(hd.hair); if (hr) over.push([hr, { tint: hd.hairTint, flash }]); }   // legacy heads have coloured hair baked in
      }
      if (hm) { const h = ATLAS.get(hm.set); if (h) over.push([h, { tint: hm.tint, flash }]); }
      const C = L && L.armor && L.armor.cape; if (C) { const cp = ATLAS.get('cape_' + base); if (cp) fronts.push([cp, { tint: C, flash }]); }
      wset = ATLAS.weaponSetFor(L); const wp = wset ? ATLAS.get(wset) : null;
      if (wp) fronts.push([wp, { tint: wset.startsWith('wpn_') ? null : L.weapon.c && L.weapon.c !== '#c7ccd2' ? L.weapon.c : null, glow: L.weapon.glow || null, flash }]);
      const wk = L && L.weapon && L.weapon.k; twoH = !!(wk && ATLAS.TWO_HANDED[wk]);
    }
    if (e.kind === 'mon' && e.def.boss && e.def.aura && !e.dead) bodyOpts.glow = e.def.aura;   // bosses carry a pulsing rim of their colour
    const [anim, i] = ATLAS.anim(e, body, twoH, wset);
    if (e._kb) { const k = e._kb.t / .14; x += e._kb.x * k; y += e._kb.y * k; }
    const d = e.dir, away = d === 7 || d === 0 || d === 1;
    // soft ground shadow (the sprites carry none, so every figure grounds the same way)
    if (!e.dead || e.deadT < .4) { c.fillStyle = 'rgba(0,0,0,.28)'; c.beginPath(); c.ellipse(x, y + 1, 15 * size, 6 * size, 0, 0, 7); c.fill(); }
    // behind-the-body parts (legacy atlases without them fall back to the old facing rule)
    for (const [a, op] of fronts) { if (a.back) ATLAS.layer(c, a, anim, d, i, x, y, size, op, '/b'); else if (away) ATLAS.layer(c, a, anim, d, i, x, y, size, op); }
    ATLAS.layer(c, body, anim, d, i, x, y, size, bodyOpts);
    for (const [a, op] of over) ATLAS.layer(c, a, anim, d, i, x, y, size, op);
    for (const [a, op] of fronts) { if (a.back || !away) ATLAS.layer(c, a, anim, d, i, x, y, size, op); }
    return true;
  }
};
