/* ================= STATE ================= */
const S = {
  maps: {}, map: null, ents: [], drops: [], proj: [], player: null, P: null, time: 0, nextId: 1, occ: null,
  mouse: { x: 0, y: 0, wx: 0, wy: 0, tx: 0, ty: 0, down: false, right: false }, hover: null, zoom: 1, cam: { x: 0, y: 0 },
  party: [], respawns: [], online: 1284, chatT: 4, sayT: 8, guildChatT: 20, whisperT: 90, inviteT: 150, siegeT: 600, siegeOn: 0, botT: 20, dead: false, paused: false, transT: 0, ctrl: false,
  vw: 800, vh: 600, hudH: 128, gcd: 0,
};
const CHAT = [];
function chat(ch, text, from) {
  CHAT.push({ ch, text, from, t: S.time }); if (CHAT.length > 160) CHAT.shift();
  if (window.UI) UI.chatDirty = true;
}
function sys(text) { chat('sys', text); }
function inSafe(x, y) { const s = S.map.safe; return s && x > s.x0 && x < s.x1 && y > s.y0 && y < s.y1; }

/* ================= MAP LOADING ================= */
const GEN = { ashvale: genAshvale, mine: genMine, mirewood: genMirewood, temple: genTemple, sanctum: genSanctum };
function getMap(id) {
  if (!S.maps[id]) {
    const m = GEN[id](); if (!m.reach) computeReach(m, m.start.x, m.start.y);
    buildMinimap(m);
    // BFS distance for zones
    const df = new Uint16Array(m.w * m.h).fill(65535); const q = [m.start.x, m.start.y]; df[idx(m, m.start.x, m.start.y)] = 0; let qi = 0;
    while (qi < q.length) { const x = q[qi++], y = q[qi++]; const d0 = df[idx(m, x, y)]; for (let d = 0; d < 8; d += 2) { const nx = x + DX[d], ny = y + DY[d]; if (inb(m, nx, ny) && !m.b[idx(m, nx, ny)] && df[idx(m, nx, ny)] === 65535) { df[idx(m, nx, ny)] = d0 + 1; q.push(nx, ny); } } }
    m.df = df;
    if (m.zones) for (const z of m.zones) { z.cand = []; for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) { const d = df[idx(m, x, y)]; if (d >= z.dmin && d < z.dmax && d > 6) z.cand.push(x, y); } }
    for (const sp of m.spawns) { sp.cand = []; for (let y = sp.y0; y <= sp.y1; y++) for (let x = sp.x0; x <= sp.x1; x++) if (inb(m, x, y) && m.reach[idx(m, x, y)] && !m.b[idx(m, x, y)] && !(m.safe && x >= m.safe.x0 - 1 && x <= m.safe.x1 + 1 && y >= m.safe.y0 - 1 && y <= m.safe.y1 + 1)) sp.cand.push(x, y); }
    S.maps[id] = m;
  }
  return S.maps[id];
}

/* ================= ENTITIES ================= */
function mkEnt(kind, x, y, o) {
  const e = Object.assign({ id: S.nextId++, kind, x, y, fx: x, fy: y, mt: 1, mdur: .3, dir: 4, walk: 0, idle: R() * 10, atk: -1, atkDur: .5, atkCd: 0, cast: -1, castDur: .45, hp: 1, maxhp: 1, mp: 0, maxmp: 0, dead: false, deadT: 0, flashT: 0, buffs: {}, poison: null, stunT: 0, slowT: 0, dmgT: 0, say: null, sayT: 0, faceL: R() < .5, blocks: false, path: null }, o);
  S.ents.push(e); if (e.blocks) occSet(e); return e;
}
function occSet(e) { S.occ[idx(S.map, e.x, e.y)] = e.id; }
function occClear(e) { const k = idx(S.map, e.x, e.y); if (S.occ[k] === e.id) S.occ[k] = 0; }
function entAt(x, y) { if (!inb(S.map, x, y)) return null; const id = S.occ[idx(S.map, x, y)]; return id ? S.ents.find(e => e.id === id) : null; }
function canEnter(e, x, y) {
  const m = S.map; if (!inb(m, x, y)) return false; const k = idx(m, x, y); if (m.b[k]) return false;
  if (e.blocks || e.kind === 'mon') { const o = S.occ[k]; if (o && o !== e.id) return false; }
  if (e.kind === 'mon' && inSafe(x, y)) return false;
  if (x !== e.x && y !== e.y && blocked(m, x, e.y) && blocked(m, e.x, y)) return false;
  return true;
}
function step(e, d, dur) {
  const nx = e.x + DX[d], ny = e.y + DY[d];
  if (!canEnter(e, nx, ny)) return false;
  if (e.blocks) occClear(e); e.fx = e.x; e.fy = e.y; e.x = nx; e.y = ny; e.mt = 0; e.mdur = dur; e.dir = d; if (DX[d]) e.faceL = DX[d] < 0; if (e.blocks) occSet(e);
  if (e.kind === 'player' && AU.steps && dur > .1) sfx('step');
  return true;
}
function teleportEnt(e, x, y) { if (e.blocks) occClear(e); e.x = e.fx = x; e.y = e.fy = y; e.mt = 1; e.path = null; if (e.blocks) occSet(e); }
const epx = e => (e.fx + (e.x - e.fx) * Math.min(1, e.mt)) * TW + TW / 2;
const epy = e => (e.fy + (e.y - e.fy) * Math.min(1, e.mt)) * TH + TH * .8;
function stepToward(e, tx, ty, dur) {
  const d0 = dirTo(e.x, e.y, tx, ty);
  for (const off of [0, 1, -1, 2, -2]) { const d = (d0 + off + 8) % 8; if (step(e, d, dur || e.spd)) return true; }
  return false;
}
function randomFree(m, cx, cy, r, ok) {
  for (let i = 0; i < 60; i++) { const x = cx + rnd(-r, r), y = cy + rnd(-r, r); if (inb(m, x, y) && !m.b[idx(m, x, y)] && !S.occ[idx(m, x, y)] && m.reach[idx(m, x, y)] && (!ok || ok(x, y))) return [x, y]; }
  return null;
}
function nearFree(m, cx, cy) {
  for (let r = 0; r < 6; r++) for (let j = -r; j <= r; j++) for (let i = -r; i <= r; i++) { if (Math.max(Math.abs(i), Math.abs(j)) !== r) continue; const x = cx + i, y = cy + j; if (inb(m, x, y) && !m.b[idx(m, x, y)] && !S.occ[idx(m, x, y)]) return [x, y]; }
  return [cx, cy];
}

/* ---------- A* ---------- */
function findPath(e, tx, ty, stop, maxN) {
  const m = S.map; stop = stop || 0; maxN = maxN || 2500;
  if (cheb(e.x, e.y, tx, ty) <= stop) return [];
  const W = m.w, start = e.y * W + e.x;
  const open = [[0, start]], g = new Map([[start, 0]]), came = new Map(); let best = start, bestH = 1e9, n = 0;
  const h = (k) => { const x = k % W, y = (k / W) | 0; const dx = Math.abs(x - tx), dy = Math.abs(y - ty); return Math.max(dx, dy) + .4 * Math.min(dx, dy); };
  while (open.length && n++ < maxN) {
    let bi = 0; for (let i = 1; i < open.length; i++) if (open[i][0] < open[bi][0]) bi = i;
    const [, cur] = open[bi]; open[bi] = open[open.length - 1]; open.pop();
    const cx = cur % W, cy = (cur / W) | 0;
    const hh = h(cur); if (hh < bestH) { bestH = hh; best = cur; }
    if (cheb(cx, cy, tx, ty) <= stop) { best = cur; break; }
    for (let d = 0; d < 8; d++) {
      const nx = cx + DX[d], ny = cy + DY[d]; if (!inb(m, nx, ny)) continue; const k = ny * W + nx;
      if (m.b[k]) continue; if (d & 1 && blocked(m, nx, cy) && blocked(m, cx, ny)) continue;
      const oc = S.occ[k]; if (oc && oc !== e.id && !(nx === tx && ny === ty && stop === 0)) { if (cheb(nx, ny, e.x, e.y) <= 2) continue; }
      const ng = g.get(cur) + (d & 1 ? 1.1 : 1);
      if (ng < (g.has(k) ? g.get(k) : 1e9)) { g.set(k, ng); came.set(k, cur); open.push([ng + h(k), k]); }
    }
  }
  const path = []; let k = best; while (k !== start && came.has(k)) { path.push([k % W, (k / W) | 0]); k = came.get(k); }
  return path.reverse();
}

/* ================= PLAYER STATS ================= */
function itemDef(it) { return ITEMS[it.id]; }
function computeStats() {
  const P = S.P; const s = baseStats(P.cls, P.lv);
  s.spd = 0; s.special = {};
  const addR = (k, r) => { if (!r) return; s[k] = [s[k][0] + r[0], s[k][1] + r[1]]; };
  for (const sl of EQUIP_SLOTS) {
    const it = P.equip[sl]; if (!it) continue; const d = itemDef(it);
    addR('dc', d.dc); addR('mc', d.mc); addR('sc', d.sc); addR('ac', d.ac); addR('mac', d.mac);
    s.acc += d.acc || 0; s.luck += d.luck || 0; s.spd += d.spd || 0; s.hp += d.hp || 0;
    if (d.special) s.special[d.special] = 1;
    const a = it.add || {}; for (const k of ['dc', 'mc', 'sc', 'ac', 'mac']) if (a[k]) s[k] = [s[k][0], s[k][1] + a[k]];
    s.acc += a.acc || 0; s.luck += a.luck || 0;
    if (it.r) { s.dc = [s.dc[0], s.dc[1] + it.r]; if (d.mc) s.mc = [s.mc[0], s.mc[1] + it.r]; if (d.sc) s.sc = [s.sc[0], s.sc[1] + it.r]; }
  }
  const setN = EQUIP_SLOTS.filter(sl => P.equip[sl] && ITEMS[P.equip[sl].id].raid).length; s.setN = setN;
  if (setN >= 2) s.hp += 60; if (setN >= 6) s.luck += 2;
  if (P.equip.weapon && P.equip.weapon.l) s.luck += P.equip.weapon.l;
  const sk = P.skills;
  if (sk.fencing) s.acc += 2 + sk.fencing.rank * 2;
  const pl = S.player;
  if (pl && pl.buffs.soulshield) { const r = pl.buffs.soulshield.rank; s.ac = [s.ac[0] + 1 + r, s.ac[1] + 2 + r * 2]; s.mac = [s.mac[0] + 1 + r, s.mac[1] + 2 + r * 2]; }
  for (const k of ['dc', 'mc', 'sc', 'ac', 'mac']) if (s[k][1] < s[k][0]) s[k][1] = s[k][0];
  s.atkDelay = Math.max(.55, .95 - s.spd * .08 - P.lv * .004);
  if (pl) { pl.st = s; pl.maxhp = s.hp; pl.maxmp = s.mp; pl.hp = Math.min(pl.hp, pl.maxhp); pl.mp = Math.min(pl.mp, pl.maxmp); }
  return s;
}
function playerLook() { const P = S.P; return lookFromEquip(P.equip, { skin: P.skin || '#e0b48a', hair: P.hair, fem: P.fem }); }

/* ================= ITEMS ================= */
let UID = 1;
function makeItem(id, n) {
  const d = ITEMS[id]; const it = { id, u: UID++ + '' + (Date.now() % 100000) };
  if (d.stack || d.slot === 'mat' || d.slot === 'cons') { it.n = n || 1; return it; }
  if (EQUIP_SLOTS.includes(d.slot) || ['weapon', 'armour', 'helmet', 'necklace', 'bracelet', 'ring'].includes(d.slot)) {
    if (!d.special) {
      const pool = []; for (const k of ['dc', 'mc', 'sc', 'ac', 'mac']) if (d[k]) pool.push(k); if (d.slot === 'weapon') pool.push('acc'); if (!pool.length) pool.push('acc');
      const r = R(); let n2 = r < .006 ? 3 : r < .03 ? 2 : r < .12 ? 1 : 0;
      if (n2) { it.add = {}; for (let i = 0; i < n2; i++) { const k = pick(pool); it.add[k] = (it.add[k] || 0) + 1; } if (R() < .02 && d.slot === 'weapon') it.add.luck = 1; }
    }
  }
  return it;
}
function addTotal(it) { let t = 0; if (it.add) for (const k in it.add) t += it.add[k]; return t + (it.r || 0); }
function itemName(it) { const d = ITEMS[it.id]; let n = d.name; if (it.r) n += ' +' + it.r; return n; }
function itemColor(it) { const d = ITEMS[it.id]; if (d.q === 3) return '#ff8a3a'; if (d.q === 2) return '#c58cff'; if (d.q === 1) return '#ffc94a'; if (addTotal(it) > 0) return '#7fd0ff'; return '#e9e4d6'; }
function sellPrice(it) { const d = ITEMS[it.id]; return Math.max(1, Math.floor(d.price * .35 * (1 + addTotal(it) * .35)) * (it.n || 1)); }
function invAdd(it) {
  const P = S.P; const d = ITEMS[it.id];
  if (it.n) { const ex = P.inv.find(x => x && x.id === it.id && x.n); if (ex) { ex.n += it.n; return true; } }
  const i = P.inv.findIndex(x => !x); if (i < 0) return false; P.inv[i] = it; return true;
}
function invCount(id) { return S.P.inv.reduce((a, x) => a + (x && x.id === id ? (x.n || 1) : 0), 0); }
function invTake(id, n) {
  const P = S.P; n = n || 1;
  for (let i = 0; i < P.inv.length && n > 0; i++) { const x = P.inv[i]; if (!x || x.id !== id) continue; if (x.n) { const t = Math.min(x.n, n); x.n -= t; n -= t; if (x.n <= 0) P.inv[i] = null; } else { P.inv[i] = null; n--; } }
  return n <= 0;
}
function dropItem(x, y, it, gold) {
  const m = S.map; let [dx, dy] = [x, y];
  for (let r = 0; r < 4; r++) { let found = false; for (let j = -r; j <= r && !found; j++) for (let i = -r; i <= r && !found; i++) { const X = x + i, Y = y + j; if (inb(m, X, Y) && !m.b[idx(m, X, Y)] && !S.drops.some(d => d.x === X && d.y === Y)) { dx = X; dy = Y; found = true; } } if (found) break; }
  const d = { x: dx, y: dy, it, gold, t: 0, bob: R() * 6 }; S.drops.push(d);
  if (it) { const def = ITEMS[it.id]; if (def.q || addTotal(it) > 0) { sfx(def.q === 3 ? 'mythic' : def.q ? 'rare' : 'pickup'); if (def.q) burst(dx * TW + 24, dy * TH + 20, def.q === 3 ? 70 : 30, def.q === 3 ? '255,130,40' : def.q === 2 ? '200,140,255' : '255,210,90', def.q === 3 ? 160 : 90, 1.2, 3, 0, 40); if (def.q === 3) { fx('pillar', dx * TW + 24, dy * TH + 26, { dur: 2, col: '255,130,40' }); S.shake = .3; } } }
  return d;
}

/* ================= COMBAT ================= */
function roll(r, luck) { if (!r) return 0; const [a, b] = r; if (luck > 0 && R() < luck * .1) return b; if (luck < 0 && R() < -luck * .12) return a; return a + Math.floor(R() * (b - a + 1)); }
function hitChance(acc, agi) { return clamp(.82 + (acc - agi) * .03, .35, .98); }
function isEnemy(a, b) {
  if (!a || !b || a === b || b.dead) return false;
  const pk = x => x.kind === 'bot' && (x.red || x.greyT > 0 || x.target === S.player);
  if (a.kind === 'player') return b.kind === 'mon' || (b.kind === 'bot' && (pk(b) || S.ctrl || b === S.forcePK) && !b.party);
  if (a.kind === 'pet') return b.kind === 'mon' || (b.kind === 'bot' && pk(b) && b.target && (b.target === S.player || b.target.kind === 'pet'));
  if (a.kind === 'mon') return b.kind === 'player' || b.kind === 'pet' || b.kind === 'bot';
  if (a.kind === 'bot') { if (b.kind === 'mon') return true; if (a.red || a.pkOn) return b.kind === 'player' || b.kind === 'pet'; return false; }
  if (a.kind === 'guard') return (b.kind === 'player' && S.P.pk >= 200) || (b.kind === 'bot' && b.red) || b.kind === 'mon';
  return false;
}
function dealDamage(src, t, dmg, o) {
  o = o || {};
  if (!t || t.dead) return 0;
  if (src && src.kind === 'player') { if (src.buffs.dragon) dmg *= 1.4; if (src.buffs.lich) dmg *= 1.5; }
  if (t.frozenT > 0) dmg *= 1.3;
  dmg = Math.max(0, Math.round(dmg));
  if (t.kind === 'player') {
    if (t.buffs.sanct) dmg = Math.round(dmg * .5);
    if (t.buffs.shield) dmg = Math.round(dmg * (1 - t.buffs.shield.red));
    if (t.st.special.protect && t.mp > 0) { const m = Math.min(t.mp, Math.round(dmg * .3)); t.mp -= m; dmg -= m; }
    if (dmg > 0) sfx('hurt');
    S.combatT = 6;
  }
  t.hp -= dmg; t.flashT = .12; t.dmgT = 4;
  const x = epx(t), y = epy(t) - (t.def && t.def.size ? t.def.size * 20 : 20);
  if (t.kind === 'player') floatText(x, y, dmg ? '-' + dmg : 'Miss', '#ff6a55', dmg > t.maxhp * .15);
  else if (src && (src.kind === 'player' || src.kind === 'pet')) { floatText(x, y, dmg ? String(dmg) : 'Miss', o.crit ? '#ffd24a' : o.col || '#ffffff', o.crit); }
  else if (t.party || (src && src.party)) floatText(x, y, String(dmg), 'rgba(220,220,220,.8)');
  if (dmg > 0) burst(x, y + 6, o.mag ? 4 : 6, o.col2 || (t.def && (t.def.bone || t.def.stone) ? '230,225,210' : '200,30,30'), 70, .4, 2.2, 160, 30);
  if (t.kind === 'mon') {
    if (src && src.kind === 'player') { t.pdmg = (t.pdmg || 0) + dmg; }
    if (src && (!t.target || t.target.dead || R() < .25) && isEnemy(t, src)) t.target = src;
    t.returning = false;
  }
  if (t.kind === 'bot' && src) { if (src.kind === 'player' && !t.red && !(t.greyT > 0) && t.target !== S.player) { S.player.greyT = 60; } if (!t.party) t.target = t.target || src; if (src.kind === 'player' || src.kind === 'pet') t.pkOn = true; }
  if (t.kind === 'pet' && src && src.kind === 'mon') t.target = t.target || src;
  if (src && src.kind === 'player' && dmg > 0) {
    if (src.buffs.lich) src.hp = Math.min(src.maxhp, src.hp + Math.max(1, Math.round(dmg * .05)));
    if ((src.st.setN || 0) >= 2 && !o.proc && R() < .08 && t.hp > 0) { const x2 = epx(t), y2 = epy(t); fx('halfmoon', x2, y2, { dur: .35, ang: R() * 6 }); burst(x2, y2 - 20, 22, '180,90,255', 140, .6, 3.5); sfx('thunder'); setTimeoutGame(.08, () => dealDamage(src, t, dmg * 1.5, { proc: 1, col: '#d8a0ff', crit: 1 })); }
  }
  if (src && src.kind === 'pet' && src.abyss && dmg > 0 && !S.dead) S.player.hp = Math.min(S.player.maxhp, S.player.hp + Math.max(1, Math.round(dmg * .03)));
  if (t.kind === 'player') {
    if (t.buffs.lich && t.hp < 1) t.hp = 1;
    if ((t.st.setN || 0) >= 6 && t.hp > 0 && t.hp < t.maxhp * .3 && !((S.P.lichCd || 0) > 0) && !t.buffs.lich) { S.P.lichCd = 180; t.buffs.lich = { t: 10 }; fx('pillar', epx(t), epy(t), { dur: 1.4, col: '170,70,255' }); fx('ring', epx(t), epy(t), { dur: 1, col: '190,90,255', r: 140, w: 10 }); burst(epx(t), epy(t) - 30, 60, '180,90,255', 180, 1, 4); sfx('boss'); S.shake = .5; say(t, 'The void answers!'); if (window.UI) UI.toast('Heir of Vaal', 'raid'); }
  }
  if (t.hp <= 0) { t.hp = 0; killEnt(t, src); }
  return dmg;
}
function applyPoison(t, dps, dur, acDown, src) { t.poison = { dps, t: dur, tick: 1, src, acDown }; }
function playerCredit(src) { return src && (src.kind === 'player' || (src.kind === 'pet' && src.owner === S.player)); }

function killEnt(e, src) {
  e.dead = true; e.deadT = 0; e.atk = -1; e.cast = -1; if (e.blocks) occClear(e);
  const P = S.P;
  if (e.kind === 'mon') {
    const def = e.def; sfx(def.boss ? 'boss' : 'mdie', e);
    if (def.boss) { S.bossNext[S.map.id + ':' + def.id] = Date.now() + def.respawn * 1000; const who = playerCredit(src) || (e.pdmg || 0) > e.maxhp * .4 ? P.name : src && src.name ? src.name : 'Someone'; chat('shout', `${def.name} has been slain by ${who}!`, 'System'); }
    else if (e.spawn && !e.minion) S.respawns.push({ t: S.time + 18 + R() * 20, sp: e.spawn });
    const credited = playerCredit(src) || (e.pdmg || 0) >= e.maxhp * .5;
    const partyKill = src && src.party && cheb(src.x, src.y, S.player.x, S.player.y) < 14;
    if (credited || partyKill) {
      let xp = e.st.xp; if (e.def.lv < P.lv - 12) xp *= .5; if (e.minion) xp *= .3;
      xp *= 1 + S.party.length * .08; if (P.guild && S.castle === P.guild.name) xp *= 1.1; if (!credited) xp *= .6;
      gainXP(Math.round(xp));
      const q = QUESTS[P.q]; if (q && P.qa && P.qn < q.n && q.need === def.id) { P.qn++; if (P.qn >= q.n) { sys(`Quest complete: ${q.name}. Return to Elder Rowan.`); sfx('rare'); } else if (window.UI) UI.questDirty = true; }
      P.kills = (P.kills || 0) + 1;
      // drops
      const drops = def.drops || [];
      const mult = 1 + (S.player.st.luck > 0 ? .1 : 0);
      for (const [id, ch] of drops) if (R() < ch * mult * (e.minion ? .2 : 1)) dropItem(e.x, e.y, makeItem(id));
      if (def.loot && !e.minion) { const n = rnd(def.loot.n[0], def.loot.n[1]); for (let i = 0; i < n; i++) { const it = makeItem(rollLoot(def)); dropItem(e.x, e.y, it); } }
      if (def.gold) dropItem(e.x, e.y, null, rnd(def.gold[0], def.gold[1]));
      else if (R() < .45 && !e.minion) dropItem(e.x, e.y, null, rnd(def.lv * 2 + 1, def.lv * 6 + 5));
    } else if (src && src.kind === 'bot' && (e.pdmg || 0) > 0 && R() < .5) { botSay(src, pick(['ks lol', 'mine', 'sorry', 'too slow', 'ty for the xp'])); }
  } else if (e.kind === 'bot') {
    if (playerCredit(src)) {
      if (!e.red && !(e.greyT > 0) && e.target !== S.player && !e.pkOn) { P.pk += 100; sys(P.pk >= 200 ? `You murdered ${e.name}. Your name burns red. Guards will attack you on sight.` : `You murdered ${e.name}. Your name turns yellow.`); }
      else sys(`You have defeated ${e.name}.`);
      dropItem(e.x, e.y, null, rnd(e.lv * 20, e.lv * 60));
      if (e.red && R() < .3) dropItem(e.x, e.y, makeItem(pick(['hp_m', 'sun_potion', 'random_scroll'])));
      whisperFrom(e.name, pick(['wtf', 'gg', 'you will pay for that', 'lol ok', 'reported', 'nice one']));
    }
    if (e.party) leaveParty(e, true);
    S.botRespawnT = Math.min(S.botRespawnT || 30, 30);
  } else if (e.kind === 'pet') { sys('Your summon has been destroyed.'); S.pet = null; }
  else if (e.kind === 'player') { playerDied(src); }
}
function rollLoot(def) {
  const P = S.P; const pool = def.loot.pool.map(id => { const d = ITEMS[id]; let w = d.q === 3 ? (def.raid ? .07 : .012) : def.raid ? (d.raid ? 1 : .3) : (d.q === 2 ? .1 : d.q === 1 ? .3 : 1); if (d.cls && d.cls !== P.cls) w *= .3; return [id, w]; });
  let t = pool.reduce((a, b) => a + b[1], 0), r = R() * t; for (const [id, w] of pool) { r -= w; if (r <= 0) return id; } return pool[0][0];
}
function gainXP(n) {
  const P = S.P; if (P.lv >= MAXLV) return;
  P.xp += n; chat('xp', `Experience +${fmt(n)}`);
  while (P.lv < MAXLV && P.xp >= xpNeed(P.lv)) {
    P.xp -= xpNeed(P.lv); P.lv++; computeStats(); const p = S.player; p.hp = p.maxhp; p.mp = p.maxmp;
    fx('pillar', epx(p), epy(p), { dur: 1.6, col: '255,210,110' }); fx('ring', epx(p), epy(p), { dur: 1, col: '255,220,140', r: 80, w: 6 }); burst(epx(p), epy(p) - 20, 50, '255,220,130', 140, 1.2, 3, -20, 60);
    sfx('level'); sys(`Level up! You are now level ${P.lv}.`);
    const nb = Object.entries(SKILLS).filter(([k, s]) => s.cls === P.cls && s.lv === P.lv); for (const [k, s] of nb) sys(`New skill available: ${s.name}. Buy the book from Sage Orrin.`);
    if (window.UI) UI.toast(`Level ${P.lv}`, 'level');
  }
}

/* ---------- player attacks & skills ---------- */
function skillRank(k) { const s = S.P.skills[k]; return s ? s.rank : -1; }
function trainSkill(k, amt) {
  const s = S.P.skills[k]; if (!s || s.rank >= 3) return; const def = SKILLS[k];
  if (S.P.lv < def.lv + s.rank * 3) return;
  s.pts += amt || rnd(1, 3);
  if (s.pts >= def.train[s.rank]) { s.pts = 0; s.rank++; sys(`${def.name} has reached rank ${s.rank}!`); sfx('buff'); const p = S.player; fx('ring', epx(p), epy(p), { dur: .8, col: '140,200,255', r: 50 }); if (window.UI) UI.toast(`${def.name} rank ${s.rank}`, 'skill'); }
  if (window.UI) UI.skillsDirty = true;
}
function playerSwing(p, t) {
  const st = p.st, P = S.P; sfx('swing');
  let acc = st.acc, bonus = 0, crit = false;
  const sl = skillRank('slaying');
  if (sl >= 0 && R() < .2 + sl * .06) { bonus = 4 + sl * 5 + Math.floor(P.lv / 4); acc += 5 + sl * 2; crit = true; trainSkill('slaying'); }
  if (skillRank('fencing') >= 0) trainSkill('fencing', 1);
  const ang = Math.atan2(epy(t) - epy(p), epx(t) - epx(p));
  if (R() > hitChance(acc, t.st.agi)) { floatText(epx(t), epy(t) - 20, 'Miss', '#aaa'); sfx('miss'); return; }
  let dmg = roll(st.dc, st.luck) + bonus - roll(t.st.ac);
  if (p.buffs.flaming) {
    const r = p.buffs.flaming.rank; dmg = Math.round(dmg * (1.8 + r * .35)) + roll(st.dc) + 10 + r * 6; delete p.buffs.flaming; crit = true;
    fx('flash', epx(t), epy(t) - 20, { dur: .5, col: '255,120,30', r: 80 }); burst(epx(t), epy(t) - 20, 40, '255,130,40', 160, .7, 5, -60, 40); sfx('fire'); trainSkill('flaming');
  }
  sfx('hit', t);
  fx('slash', epx(t), epy(t), { dur: .22, ang: ang + Math.PI / 2, col: crit ? '255,220,120' : '255,255,255' });
  dealDamage(p, t, Math.max(1, dmg), { crit });
  if (st.special.paralyze && R() < .1 && !t.dead) { t.stunT = t.def && t.def.boss ? .6 : 2; floatText(epx(t), epy(t) - 44, 'Paralysed', '#c58cff'); }
  // thrusting
  if (P.toggles.thrusting && skillRank('thrusting') >= 0) {
    const d = dirTo(p.x, p.y, t.x, t.y); const b = entAt(t.x + DX[d], t.y + DY[d]);
    const r = skillRank('thrusting');
    fx('slash', epx(t) + DX[d] * 30, epy(t) + DY[d] * 20, { dur: .25, ang: ang + Math.PI / 2, col: '200,230,255' });
    if (b && isEnemy(p, b)) { dealDamage(p, b, Math.max(1, Math.round((roll(st.dc, st.luck) - roll(b.st.ac)) * (.7 + r * .1)))); }
    trainSkill('thrusting', 1);
  }
  const W4 = P.cls === 'W' && (st.setN || 0) >= 4;
  p.swingN = (p.swingN || 0) + 1;
  if (W4 && p.swingN % 5 === 0) { fx('ring', epx(p), epy(p), { dur: .5, col: '180,90,255', r: 110, w: 10 }); fx('halfmoon', epx(p), epy(p), { dur: .4, ang }); sfx('thunder'); for (const b of S.ents) if (b !== t && !b.dead && isEnemy(p, b) && cheb(b.x, b.y, p.x, p.y) <= 2) dealDamage(p, b, Math.max(1, Math.round(roll(st.dc, st.luck) * .8)), { proc: 1, col: '#d8a0ff' }); }
  if (p.buffs.dragon) { const d0 = dirTo(p.x, p.y, t.x, t.y); for (let i = 1; i <= 3; i++) for (const off of [-1, 0, 1]) { const dd = (d0 + off + 8) % 8; const X = p.x + DX[dd] * i, Y = p.y + DY[dd] * i; burst(X * TW + 24, Y * TH + 10, 5, R() < .5 ? '255,150,40' : '255,80,20', 70, .5, 5, -40); const b = entAt(X, Y); if (b && b !== t && isEnemy(p, b)) dealDamage(p, b, Math.max(1, Math.round(roll(st.dc, st.luck) * .6)), { proc: 1, col: '#ffb070' }); } sfx('fire'); }
  if (P.toggles.halfmoon && skillRank('halfmoon') >= 0 && (p.mp >= 3 || W4)) {
    if (!W4) p.mp -= 3; const r = skillRank('halfmoon');
    fx('halfmoon', epx(p), epy(p), { dur: .35, ang });
    for (let d = 0; d < 8; d++) { const b = entAt(p.x + DX[d], p.y + DY[d]); if (b && b !== t && isEnemy(p, b)) dealDamage(p, b, Math.max(1, Math.round((roll(st.dc, st.luck) - roll(b.st.ac)) * (.6 + r * .12)))); }
    trainSkill('halfmoon', 1);
  }
}
function hoveredTargetFor(kind) {
  const h = S.hover;
  if (kind === 'heal') { if (h && !h.dead && (h.kind === 'pet' || (h.kind === 'bot' && h.party))) return h; return S.player; }
  if (h && isEnemy(S.player, h)) return h;
  const p = S.player; if (p.target && !p.target.dead && isEnemy(p, p.target)) return p.target;
  let best = null, bd = 99; for (const e of S.ents) if (e.kind === 'mon' && !e.dead && cheb(e.x, e.y, p.x, p.y) < bd && cheb(e.x, e.y, p.x, p.y) <= 7) { bd = cheb(e.x, e.y, p.x, p.y); best = e; }
  return best;
}
function castSkill(k, forced, echo) {
  const p = S.player, P = S.P, def = SKILLS[k]; const sk = P.skills[k];
  if (!sk || S.dead) return;
  if (echo) return castEcho(k, forced);
  if (def.kind === 'passive') { sys(`${def.name} is a passive skill.`); return; }
  if (def.kind === 'toggle') { P.toggles[k] = !P.toggles[k]; sys(`${def.name} ${P.toggles[k] ? 'on' : 'off'}.`); sfx('click'); if (window.UI) UI.skillsDirty = true; return; }
  if (S.gcd > 0 || p.cast >= 0 || p.atk >= 0) { p.queued = k; return; }
  if (sk.cd > 0) { return; }
  if (p.mp < def.mp) { sys('Not enough MP.'); sfx('error'); return; }
  const r = sk.rank;
  let tgt = null, tx = p.x, ty = p.y;
  if (def.kind === 'target') { tgt = forced || hoveredTargetFor(); if (!tgt) { sys('No target.'); return; } tx = tgt.x; ty = tgt.y; }
  if (def.kind === 'heal') { tgt = forced || hoveredTargetFor('heal'); tx = tgt.x; ty = tgt.y; }
  if (def.kind === 'ground') { if (S.hover && S.hover.kind === 'mon') { tx = S.hover.x; ty = S.hover.y; } else if (p.target && !p.target.dead) { tx = p.target.x; ty = p.target.y; } else { tx = S.mouse.tx; ty = S.mouse.ty; } }
  if (def.range && cheb(p.x, p.y, tx, ty) > def.range) { p.pending = { k, tgt, tx, ty }; p.target = tgt && tgt.kind === 'mon' ? tgt : p.target; p.path = findPath(p, tx, ty, def.range - 1); return; }
  p.pending = null;
  p.mp -= def.mp; S.gcd = .75; if (def.cd) sk.cd = def.cd - (k === 'flaming' ? r : 0);
  p.cast = 0; p.castDur = .45; if (tx !== p.x || ty !== p.y) { p.dir = dirTo(p.x, p.y, tx, ty); if (DX[p.dir]) p.faceL = DX[p.dir] < 0; }
  const st = p.st, x0 = epx(p), y0 = epy(p);
  const mag = (m, base) => Math.round(roll(st.mc, st.luck) * m + base);
  const spi = (m, base) => Math.round(roll(st.sc, st.luck) * m + base);
  if (tgt && tgt.kind === 'mon') p.target = tgt;
  switch (k) {
    case 'fireball': sfx('fire'); S.proj.push({ x: x0, y: y0, tgt, kind: 'fireball', rank: r, spd: 520, src: p, onHit: t => { const d = mag(1 + .14 * r, 4 + r * 3) - roll(t.st.mac); dealDamage(p, t, Math.max(1, d), { mag: 1, col: '#ffb070', col2: '255,140,40' }); burst(epx(t), epy(t) - 22, 16 + r * 6, '255,140,40', 120, .5, 4, -40); } }); break;
    case 'thunder': { sfx('thunder'); fx('thunder', epx(tgt), epy(tgt), { dur: .45, rank: r }); let d = mag(1.25 + .15 * r, 8 + r * 4) - roll(tgt.st.mac); if (tgt.def && tgt.def.undead) d = Math.round(d * 1.5); dealDamage(p, tgt, Math.max(1, d), { mag: 1, col: '#bcd8ff', col2: '180,210,255' }); burst(epx(tgt), epy(tgt) - 10, 20, '180,210,255', 150, .4, 2.5); break; }
    case 'hellfire': {
      sfx('fire'); const d0 = dirTo(p.x, p.y, tx, ty); const len = 4 + r;
      for (let i = 1; i <= len; i++) { const X = p.x + DX[d0] * i, Y = p.y + DY[d0] * i; if (blocked(S.map, X, Y) && !entAt(X, Y)) break; setTimeoutGame(i * .06, () => { const e2 = fx('fireground', X * TW + 24, Y * TH + 26, { dur: .7, below: 1 }); burst(X * TW + 24, Y * TH + 10, 12, '255,120,30', 90, .6, 6, -80, 40); const t = entAt(X, Y); if (t && isEnemy(p, t)) dealDamage(p, t, Math.max(1, mag(1.1 + .12 * r, 6 + r * 3) - roll(t.st.mac)), { mag: 1, col: '#ffb070' }); }); }
      break;
    }
    case 'icestorm': {
      sfx('ice'); fx('ice', tx * TW + 24, ty * TH + 26, { dur: 1 });
      setTimeoutGame(.35, () => { for (let j = -1; j <= 1; j++) for (let i = -1; i <= 1; i++) { burst((tx + i) * TW + 24, (ty + j) * TH + 16, 6, '190,230,255', 80, .6, 3, 60); const t = entAt(tx + i, ty + j); if (t && isEnemy(p, t)) { dealDamage(p, t, Math.max(1, mag(1.2 + .15 * r, 10 + r * 4) - roll(t.st.mac)), { mag: 1, col: '#bfe6ff' }); t.slowT = 3 + r; } } });
      break;
    }
    case 'firewall': {
      sfx('fire'); const tiles = r >= 2 ? [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]] : [[0, 0], [1, 0], [-1, 0]];
      for (const [i, j] of tiles) { const X = tx + i, Y = ty + j; if (blocked(S.map, X, Y) && !entAt(X, Y)) continue; const dur = 6 + r * 2; fx('fireground', X * TW + 24, Y * TH + 26, { dur, below: 1, tick: 0, update: (e2, dt) => { e2.tick -= dt; if (e2.tick <= 0) { e2.tick = 1; const t = entAt(X, Y); if (t && isEnemy(p, t)) dealDamage(p, t, Math.max(1, mag(.5, 4 + r * 3) - roll(t.st.mac) / 2), { mag: 1, col: '#ffb070' }); } } }); }
      break;
    }
    case 'repulsion': {
      sfx('buff'); fx('ring', x0, y0, { dur: .5, col: '200,220,255', r: 90, w: 8 });
      for (let d = 0; d < 8; d++) { const t = entAt(p.x + DX[d], p.y + DY[d]); if (t && t.kind === 'mon' && !t.def.boss && t.def.lv <= P.lv + 2) { for (let i = 0; i < 2 + (r >> 1); i++) step(t, d, .08); t.stunT = .6; dealDamage(p, t, mag(.4, 2)); } }
      break;
    }
    case 'shield': { sfx('buff'); p.buffs.shield = { t: 30 + r * 15, red: .25 + r * .07, rank: r }; fx('shieldpop', x0, y0, { dur: .6, col: '120,180,255' }); break; }
    case 'flaming': { sfx('fire'); p.buffs.flaming = { t: 12, rank: r }; burst(x0, y0 - 24, 20, '255,120,30', 80, .6, 3, -40); break; }
    case 'dash': {
      sfx('swing'); const d = p.dir; let moved = 0;
      for (let i = 0; i < 3; i++) {
        const nx = p.x + DX[d], ny = p.y + DY[d]; const b = entAt(nx, ny);
        if (b && b.kind === 'mon' && !b.def.boss && b.def.lv <= P.lv + 3) { step(b, d, .08); b.stunT = 1 + r * .3; dealDamage(p, b, roll(st.dc) + r * 3); }
        if (!step(p, d, .07)) break; moved++; burst(epx(p), epy(p), 6, '180,160,120', 50, .5, 3, 0, 0);
      }
      if (moved) p.mt = .5; break;
    }
    case 'healing': { sfx('heal'); const amt = spi(1.5 + .2 * r, 12 + r * 6); tgt.hp = Math.min(tgt.maxhp, tgt.hp + amt); healFx(tgt, amt); break; }
    case 'massheal': { sfx('heal'); fx('ring', x0, y0, { dur: .8, col: '140,255,160', r: 160, w: 6 }); for (const e of S.ents) if (!e.dead && (e === p || e.kind === 'pet' || e.party) && cheb(e.x, e.y, p.x, p.y) <= 4) { const amt = spi(1.2 + .15 * r, 10 + r * 5); e.hp = Math.min(e.maxhp, e.hp + amt); healFx(e, amt); } break; }
    case 'poison': { sfx('drink'); S.proj.push({ x: x0, y: y0, tgt, kind: 'poison', rank: r, spd: 400, src: p, onHit: t => { const dps = Math.max(1, Math.round((roll(st.sc) * 1.1 + 5 + r * 3) / 4)); applyPoison(t, dps, 8 + r * 2, 2 + r, p); if (!t.target && t.kind === 'mon') t.target = p; floatText(epx(t), epy(t) - 40, 'Poisoned', '#9cff7a'); } }); break; }
    case 'soulfire': sfx('fire'); S.proj.push({ x: x0, y: y0, tgt, kind: 'soulfire', rank: r, spd: 460, src: p, onHit: t => { dealDamage(p, t, Math.max(1, spi(1.2 + .14 * r, 6 + r * 3) - roll(t.st.mac)), { mag: 1, col: '#fff2a0', col2: '255,240,160' }); burst(epx(t), epy(t) - 22, 14, '255,240,150', 110, .5, 3); } }); break;
    case 'soulshield': { sfx('buff'); const b = { t: 60 + r * 20, rank: r }; p.buffs.soulshield = { ...b }; for (const e of S.party) e.buffs.soulshield = { ...b }; fx('ring', x0, y0, { dur: .8, col: '255,220,120', r: 80 }); computeStats(); break; }
    case 'skeleton': case 'hound': summonPet(k, r); break;
  }
  if (!P.setEchoing) trainSkill(k);
  if (!P.setEchoing && P.cls === 'M' && (p.st.setN || 0) >= 4 && ['fireball', 'thunder', 'hellfire', 'icestorm', 'firewall'].includes(k) && R() < .15) { p.mp = Math.min(p.maxmp, p.mp + def.mp); floatText(x0, y0 - 60, 'Void Echo', '#d8a0ff', true); setTimeoutGame(.45, () => castSkill(k, tgt && !tgt.dead ? tgt : null, true)); }
}
function castEcho(k, tgt) {
  // re-run a spell without cost, cooldown or animation lock (4-piece Wizard set bonus)
  const p = S.player, P = S.P, sk = P.skills[k]; const savedMp = p.mp, savedGcd = S.gcd, savedCd = sk.cd;
  S.gcd = 0; sk.cd = 0; p.mp = 9999; const c0 = p.cast, a0 = p.atk; p.cast = -1; p.atk = -1;
  const hv = S.hover; if (tgt) S.hover = tgt;
  const P2 = P.setEchoing; P.setEchoing = 1; try { castSkill(k, tgt || undefined); } finally { P.setEchoing = P2; }
  S.hover = hv; p.mp = savedMp; S.gcd = savedGcd; sk.cd = savedCd; fx('ring', epx(p), epy(p), { dur: .5, col: '180,90,255', r: 50 });
}
function healFx(t, amt) { floatText(epx(t), epy(t) - 30, '+' + amt, '#8cff9a'); fx('ring', epx(t), epy(t), { dur: .6, col: '140,255,160', r: 36 }); for (let i = 0; i < 14; i++) part(epx(t) + (R() - .5) * 26, epy(t) - R() * 30, { vy: -50 - R() * 30, life: .8, max: .8, size: 2.5, col: '160,255,170' }); }
const TIMERS = [];
function setTimeoutGame(d, fn) { TIMERS.push({ t: S.time + d, fn }); }
function summonPet(k, r) {
  const p = S.player, P = S.P;
  if (S.pet && !S.pet.dead) { S.pet.dead = true; S.pet.deadT = 99; }
  const spot = nearFree(S.map, p.x + DX[p.dir], p.y + DY[p.dir]);
  const lv = k === 'hound' ? P.lv + r * 2 : Math.min(P.lv, 12 + r * 5 + Math.floor(P.lv / 3));
  const hp = k === 'hound' ? 140 + lv * 12 + r * 60 : 50 + lv * 7 + r * 30;
  const pet = mkEnt('pet', spot[0], spot[1], { name: (k === 'hound' ? 'Spirit Hound' : 'Skeleton') + ` (${P.name})`, petType: k, owner: p, lv, hp, maxhp: hp, spd: k === 'hound' ? .24 : .3, st: { dmg: k === 'hound' ? [lv, Math.round(lv * 2) + r * 4] : [Math.round(lv * .6), Math.round(lv * 1.3) + r * 2], ac: [0, Math.round(lv / 4)], mac: [0, Math.round(lv / 5)], acc: 10 + lv / 2, agi: 8 }, rank: r, atkDelay: k === 'hound' ? 1 : 1.1 });
  if (P.cls === 'T' && (p.st.setN || 0) >= 4) { pet.abyss = 1; pet.maxhp = pet.hp = Math.round(pet.maxhp * 1.5); pet.st.dmg = pet.st.dmg.map(v => Math.round(v * 1.5)); pet.name = 'Abyssal ' + pet.name; }
  S.pet = pet; fx('smoke', epx(pet), epy(pet), { dur: 1, col: k === 'hound' ? '200,80,30' : '90,40,120' }); fx('pillar', epx(pet), epy(pet), { dur: .8, col: k === 'hound' ? '255,120,40' : '160,100,255' });
  sfx('portal');
}

/* ================= MYTHIC POWERS (R) ================= */
function mythicItems() { const P = S.P; return EQUIP_SLOTS.map(sl => P.equip[sl]).filter(it => it && ITEMS[it.id].use); }
function useMythic() {
  const P = S.P, p = S.player; if (S.dead) return; P.mcd = P.mcd || {};
  const list = mythicItems(); if (!list.length) { sys('Equip a Mythic item to use its power (R).'); return; }
  for (const it of list) { const u = ITEMS[it.id].use; if ((P.mcd[u.id] || 0) > 0) continue; if (doMythic(u.id) !== false) { P.mcd[u.id] = u.cd; floatText(epx(p), epy(p) - 70, u.name, '#ff9a4a', true); } return; }
  const u = ITEMS[list[0].id].use; sys(`${u.name} recharges in ${Math.ceil(P.mcd[u.id])}s.`); sfx('error');
}
function doMythic(id) {
  const p = S.player, st = p.st, x0 = epx(p), y0 = epy(p);
  if (id === 'meteor') {
    let tx = S.mouse.tx, ty = S.mouse.ty; const h = S.hover && S.hover.kind === 'mon' ? S.hover : p.target && !p.target.dead ? p.target : null; if (h) { tx = h.x; ty = h.y; }
    if (cheb(tx, ty, p.x, p.y) > 10) { tx = p.x; ty = p.y; }
    const X = tx * TW + 24, Y = ty * TH + 26; fx('telegraph', X, Y, { dur: .9, r: 2.6 * TW, below: 1 });
    const m = fx('flash', X, Y - 400, { dur: .9, col: '255,120,30', r: 60, update: (e, dt) => { e.y += 480 * dt; part(e.x + (R() - .5) * 20, e.y, { vy: -120, life: .5, max: .5, size: 7, col: R() < .5 ? '255,160,40' : '255,70,10' }); } });
    sfx('fire'); setTimeoutGame(.9, () => { fx('ring', X, Y, { dur: .8, col: '255,140,40', r: 200, w: 16 }); fx('flash', X, Y - 20, { dur: .8, col: '255,120,30', r: 260 }); burst(X, Y - 10, 90, '255,140,40', 280, 1.1, 6, 200, 120); burst(X, Y, 40, '90,70,60', 160, 1.2, 5, 120, 40); sfx('thunder'); S.shake = .8;
      for (const b of S.ents) if (!b.dead && isEnemy(p, b) && cheb(b.x, b.y, tx, ty) <= 2) { dealDamage(p, b, roll(st.dc, st.luck) * 3 + 60, { proc: 1, crit: 1, col: '#ffb070' }); b.stunT = Math.max(b.stunT, 1); }
      for (let j = -1; j <= 1; j++) for (let i = -1; i <= 1; i++) fx('fireground', (tx + i) * TW + 24, (ty + j) * TH + 26, { dur: 4, below: 1, tick: 1, update: (e2, dt) => { e2.tick -= dt; if (e2.tick <= 0) { e2.tick = 1; const b = entAt(tx + i, ty + j); if (b && isEnemy(p, b)) dealDamage(p, b, roll(st.dc) * .5 + 10, { proc: 1, col: '#ffb070' }); } } }); });
  } else if (id === 'timestop') {
    fx('ring', x0, y0, { dur: 1.2, col: '160,230,255', r: 7 * TW, w: 8 }); fx('flash', x0, y0 - 30, { dur: .7, col: '180,240,255', r: 340 }); sfx('ice'); S.shake = .3;
    let n = 0; for (const b of S.ents) if (!b.dead && isEnemy(p, b) && cheb(b.x, b.y, p.x, p.y) <= 7) { b.stunT = Math.max(b.stunT, b.def && b.def.boss ? 2 : 4); b.frozenT = b.def && b.def.boss ? 2 : 4; b.atk = -1; n++; burst(epx(b), epy(b) - 20, 10, '200,240,255', 60, .8, 3); }
    if (!n) sys('Time stops... but nothing was near.');
  } else if (id === 'sanctuary') {
    sfx('heal'); fx('pillar', x0, y0, { dur: 1.6, col: '140,255,160' }); fx('ring', x0, y0, { dur: 1, col: '140,255,160', r: 180, w: 8 });
    for (const e of [p, S.pet, ...S.party]) if (e && !e.dead) { const amt = e.maxhp - e.hp; e.hp = e.maxhp; healFx(e, Math.round(amt)); }
    p.buffs.sanct = { t: 6 }; for (let i = 0; i < 40; i++) part(x0 + (R() - .5) * 120, y0 - R() * 60, { vy: -30 - R() * 40, vx: (R() - .5) * 20, life: 1.4, max: 1.4, size: 2.5, col: R() < .5 ? '255,190,230' : '140,255,160' });
  } else if (id === 'dragonform') {
    p.buffs.dragon = { t: 15 }; fx('pillar', x0, y0, { dur: 1.2, col: '255,120,30' }); fx('ring', x0, y0, { dur: .9, col: '255,150,40', r: 140, w: 12 }); burst(x0, y0 - 30, 70, '255,130,30', 200, 1, 5, -30); sfx('boss'); S.shake = .5; say(p, 'RAAAWR');
  } else if (id === 'blink') {
    const tx = S.mouse.tx, ty = S.mouse.ty; const m = S.map;
    if (!inb(m, tx, ty) || m.b[idx(m, tx, ty)] || S.occ[idx(m, tx, ty)] || cheb(tx, ty, p.x, p.y) > 8 || !m.reach[idx(m, tx, ty)]) { sys('You cannot step there.'); sfx('error'); return false; }
    const ox = p.x, oy = p.y; fx('smoke', x0, y0, { dur: .8, col: '90,30,160' }); teleportEnt(p, tx, ty); p.path = null; sfx('portal');
    fx('ring', ox * TW + 24, oy * TH + 26, { dur: 3, col: '150,70,255', r: 60, w: 4, below: 1 }); fx('pillar', epx(p), epy(p), { dur: .6, col: '160,90,255' });
    for (let k2 = 0; k2 < 3; k2++) setTimeoutGame(k2 * 1, () => { burst(ox * TW + 24, oy * TH + 16, 16, '160,80,255', 120, .6, 3); for (const b of S.ents) if (!b.dead && isEnemy(p, b) && cheb(b.x, b.y, ox, oy) <= 1) dealDamage(p, b, roll(st.dc.map((v, i) => Math.max(v, st.mc[i], st.sc[i])), st.luck) * 1.2 + 15, { proc: 1, col: '#d8a0ff' }); });
  }
}

/* ================= PLAYER DEATH / REVIVE ================= */
function playerDied(src) {
  const p = S.player, P = S.P;
  if (p.st.special.revive && (!P.reviveCd || P.reviveCd <= 0)) { p.dead = false; p.hp = Math.round(p.maxhp * .5); P.reviveCd = 300; occSet(p); sys('Your Revival Ring flares and you rise again!'); fx('pillar', epx(p), epy(p), { dur: 1.4, col: '200,150,255' }); sfx('level'); return; }
  S.dead = true; sfx('die');
  const lose = Math.floor(xpNeed(P.lv) * .04); P.xp = Math.max(0, P.xp - lose);
  sys(`You have been slain${src && src.name ? ' by ' + src.name : ''}. You lost ${fmt(lose)} experience.`);
  if (P.pk >= 200) { const items = P.inv.map((x, i) => [x, i]).filter(([x]) => x); if (items.length) { const [it, i] = pick(items); P.inv[i] = null; dropItem(p.x, p.y, it); sys(`As a murderer, you dropped ${itemName(it)}.`); } }
  if (window.UI) UI.showDeath(src);
}
function revive() {
  S.dead = false; const p = S.player; p.dead = false; p.hp = Math.round(p.maxhp * .6); p.mp = Math.round(p.maxmp * .6); p.target = null; p.path = null; p.buffs = {};
  changeMap('ashvale', 76, 63);
}

/* ================= MONSTERS ================= */
function spawnMon(id, x, y, o) {
  const def = MON[id]; const st = monStats(def);
  const e = mkEnt('mon', x, y, Object.assign({ name: def.name, def, st, hp: st.hp, maxhp: st.hp, hx: x, hy: y, spd: def.spd, blocks: true, thinkT: R(), atkDelay: def.boss ? 1.25 : 1.5, dir: rnd(0, 7) }, o));
  return e;
}
function spawnFromSpawn(sp, far) {
  const m = S.map; const c = sp.cand; if (!c || !c.length) return;
  for (let i = 0; i < 12; i++) { const k = rnd(0, c.length / 2 - 1) * 2; const x = c[k], y = c[k + 1]; if (S.occ[idx(m, x, y)]) continue; if (far && S.player && cheb(x, y, S.player.x, S.player.y) < 10) continue; spawnMon(sp.mon || pick(sp.mons), x, y, { spawn: sp }); return; }
}
function populateMap() {
  const m = S.map;
  for (const sp of m.spawns) for (let i = 0; i < sp.n; i++) spawnFromSpawn(sp);
  if (m.zones) for (const z of m.zones) { z.cand = z.cand; for (let i = 0; i < z.n; i++) spawnFromSpawn(z); }
  for (const b of m.bosses) { const k = m.id + ':' + b.mon; if (!S.bossNext[k] || Date.now() >= S.bossNext[k]) spawnBoss(b); }
}
function spawnBoss(b) { const [x, y] = nearFree(S.map, b.x, b.y); const e = spawnMon(b.mon, x, y, { boss: 1, summonT: 12, stompT: 8 }); e.hx = b.x; e.hy = b.y; return e; }
function findFoe(e, r) {
  let best = null, bd = r + 1;
  const consider = (t) => { if (!t || t.dead) return; const d = cheb(e.x, e.y, t.x, t.y); if (d < bd && isEnemy(e, t)) { if (t.kind === 'player' && (inSafe(t.x, t.y) || S.dead)) return; bd = d; best = t; } };
  consider(S.player); if (S.pet) consider(S.pet);
  for (const b of S.ents) if (b.kind === 'bot' && !b.dead && !b.hidden) consider(b);
  return best;
}
function monAI(e, dt) {
  const def = e.def; if (e.stunT > 0 || e.atk >= 0 || e.mt < 1) return;
  const spd = e.spd * (e.slowT > 0 ? 1.8 : 1) * (e.hp < e.maxhp * .3 && def.boss ? .75 : 1);
  if (e.target && (e.target.dead || e.target.gone || cheb(e.x, e.y, e.target.x, e.target.y) > 16 || (e.target.kind === 'player' && (inSafe(e.target.x, e.target.y) || S.dead)))) e.target = null;
  if (cheb(e.x, e.y, e.hx, e.hy) > (def.boss ? 12 : 18) && !e.minion) { e.target = null; e.returning = true; }
  if (e.returning) { if (cheb(e.x, e.y, e.hx, e.hy) <= 2) e.returning = false; else { stepToward(e, e.hx, e.hy, spd * .8); e.hp = Math.min(e.maxhp, e.hp + e.maxhp * .03); return; } }
  e.thinkT -= dt;
  if (!e.target && def.aggro && e.thinkT <= 0) { e.thinkT = .4 + R() * .3; e.target = findFoe(e, def.aggro); if (e.target && R() < .6) sfx('aggro', e); }
  if (e.target) {
    const t = e.target, d = cheb(e.x, e.y, t.x, t.y);
    if (def.boss) bossAbilities(e, t, dt);
    if (def.ranged && d <= def.ranged.r && d > 1) {
      if (e.atkCd <= 0) { e.atk = 0; e.atkDur = .5; e.atkCd = e.atkDelay * 1.1; e.dir = dirTo(e.x, e.y, t.x, t.y); if (DX[e.dir]) e.faceL = DX[e.dir] < 0; e.shoot = t; }
      else if (R() < .02) stepToward(e, t.x, t.y, spd);
      return;
    }
    if (d <= 1 && !(t.x !== e.x && t.y !== e.y && blocked(S.map, t.x, e.y) && blocked(S.map, e.x, t.y))) {
      if (e.atkCd <= 0) { e.atk = 0; e.atkDur = def.boss ? .7 : .55; e.atkCd = e.atkDelay; e.dir = dirTo(e.x, e.y, t.x, t.y); if (DX[e.dir]) e.faceL = DX[e.dir] < 0; e.hitT = t; }
      return;
    }
    if (!stepToward(e, t.x, t.y, spd) && R() < .3) step(e, rnd(0, 7), spd);
  } else if (R() < dt * .3) {
    const d = rnd(0, 7); const nx = e.x + DX[d], ny = e.y + DY[d]; if (cheb(nx, ny, e.hx, e.hy) <= 5) step(e, d, spd * 1.4);
  }
}
function bossAbilities(e, t, dt) {
  const def = e.def;
  e.summonT -= dt; e.stompT -= dt;
  if (def.summons && e.summonT <= 0) {
    e.summonT = 16 + R() * 6; const n = e.hp < e.maxhp * .5 ? 3 : 2;
    for (let i = 0; i < n; i++) { const s = randomFree(S.map, e.x, e.y, 3); if (s) { const mn = spawnMon(def.summons, s[0], s[1], { minion: 1 }); mn.target = t; fx('smoke', epx(mn), epy(mn), { dur: 1, col: '120,40,160' }); } }
    say(e, pick(['Rise, my servants!', 'To me!', 'Crush them!'])); sfx('boss');
  }
  if (def.nova) { e.novaT = (e.novaT == null ? 10 : e.novaT) - dt; if (e.novaT <= 0) { e.novaT = 15 + R() * 5; const x = epx(e), y = epy(e); fx('telegraph', x, y, { dur: 2, r: 5 * TW, below: 1 }); say(e, pick(['Kneel before the void!', 'Your souls are mine!', 'Darkness, consume them!'])); sfx('boss'); e.atk = 0; e.atkDur = 2; e.stomping = 1;
    setTimeoutGame(2, () => { if (e.dead) return; e.stomping = 0; fx('ring', x, y, { dur: .9, col: '190,90,255', r: 260, w: 14 }); fx('flash', x, y - 30, { dur: .6, col: '180,80,255', r: 300 }); burst(x, y - 20, 80, '200,120,255', 260, 1, 4, 0, 40); sfx('thunder'); S.shake = .6;
      for (const h of [S.player, S.pet, ...S.ents.filter(b => b.kind === 'bot')]) if (h && !h.dead && cheb(h.x, h.y, e.x, e.y) <= 5) dealDamage(e, h, Math.round(roll(e.st.dmg) * 1.7 - roll(h.st ? h.st.mac : [0, 0])), { mag: 1 }); }); return; } }
  if ((def.stomp || def.lv >= 23) && e.stompT <= 0 && cheb(e.x, e.y, t.x, t.y) <= 2) {
    e.stompT = 9 + R() * 4; const x = epx(e), y = epy(e); fx('telegraph', x, y, { dur: 1.1, r: 2.4 * TW, below: 1 });
    e.atk = 0; e.atkDur = 1.1; e.stomping = 1;
    setTimeoutGame(1.1, () => { if (e.dead) return; e.stomping = 0; fx('ring', x, y, { dur: .6, col: '255,160,80', r: 130, w: 10 }); burst(x, y, 40, '160,130,100', 160, .8, 4, 200, 60); sfx('thunder'); S.shake = .4;
      const hits = [S.player, S.pet, ...S.ents.filter(b => b.kind === 'bot')]; for (const h of hits) if (h && !h.dead && cheb(h.x, h.y, e.x, e.y) <= 2) { dealDamage(e, h, Math.round(roll(e.st.dmg) * 1.4 - roll(h.st.ac))); h.stunT = .5; } });
  }
}
function monHit(e) {
  const t = e.hitT; e.hitT = null; if (!t || t.dead || cheb(e.x, e.y, t.x, t.y) > 1) return;
  const agi = t.st ? t.st.agi : 8;
  if (R() > hitChance(e.st.acc, agi)) { if (t.kind === 'player') floatText(epx(t), epy(t) - 30, 'Miss', '#aaa'); return; }
  const mag = e.def.mag; const def = t.st ? (mag ? t.st.mac : t.st.ac) : [0, 0];
  const ac = t.poison && t.poison.acDown ? Math.max(0, roll(def) - t.poison.acDown) : roll(def);
  if (t.kind !== 'player') sfx('mhit', t);
  dealDamage(e, t, Math.max(1, roll(e.st.dmg) - ac));
  fx('slash', epx(t), epy(t), { dur: .2, ang: R() * 3, col: '255,120,100' });
  if (e.def.poisonHit && R() < .2 && !t.dead) applyPoison(t, Math.max(1, Math.round(e.def.lv / 5)), 5, 0, e);
}
function monShoot(e) {
  const t = e.shoot; e.shoot = null; if (!t || t.dead) return;
  const kind = e.def.ranged.proj; sfx(kind === 'arrow' ? 'arrow' : 'swing', e);
  S.proj.push({ x: epx(e), y: epy(e), tgt: t, kind, spd: kind === 'arrow' ? 560 : 360, src: e, rank: 0, onHit: tt => {
    if (R() > hitChance(e.st.acc, tt.st ? tt.st.agi : 8)) { if (tt.kind === 'player') floatText(epx(tt), epy(tt) - 30, 'Miss', '#aaa'); return; }
    const mag = e.def.mag; const dd = mag ? tt.st.mac : tt.st.ac;
    dealDamage(e, tt, Math.max(1, Math.round(roll(e.st.dmg) * .9) - roll(dd)));
    if (e.def.poisonHit && R() < .25 && !tt.dead) applyPoison(tt, Math.max(1, Math.round(e.def.lv / 5)), 5, 0, e);
  } });
}

/* ================= PETS ================= */
function petAI(e, dt) {
  const p = S.player; if (e.stunT > 0 || e.atk >= 0 || e.mt < 1) return;
  if (e.target && (e.target.dead || cheb(e.x, e.y, e.target.x, e.target.y) > 12 || !isEnemy(e, e.target))) e.target = null;
  if (!e.target) { const pt = p.target; if (pt && !pt.dead && isEnemy(e, pt)) e.target = pt; else { for (const m of S.ents) if (m.kind === 'mon' && !m.dead && m.target && (m.target === p || m.target === e) && cheb(m.x, m.y, e.x, e.y) < 9) { e.target = m; break; } } }
  const dP = cheb(e.x, e.y, p.x, p.y);
  if (dP > 14) { const s = nearFree(S.map, p.x, p.y); teleportEnt(e, s[0], s[1]); return; }
  if (e.target) {
    const t = e.target, d = cheb(e.x, e.y, t.x, t.y);
    if (e.petType === 'hound' && d <= 3 && d > 1 && e.atkCd <= 0) { e.atk = 0; e.atkDur = .5; e.atkCd = e.atkDelay; e.faceL = t.x < e.x; S.proj.push({ x: epx(e), y: epy(e), tgt: t, kind: 'houndfire', spd: 380, src: e, rank: 0, onHit: tt => dealDamage(e, tt, Math.max(1, roll(e.st.dmg) - roll(tt.st.mac)), { col: '#ffb070' }) }); return; }
    if (d <= 1) { if (e.atkCd <= 0) { e.atk = 0; e.atkDur = .5; e.atkCd = e.atkDelay; e.dir = dirTo(e.x, e.y, t.x, t.y); e.faceL = t.x < e.x; e.hitT = t; } return; }
    if (!e.path || !e.path.length || R() < .1) e.path = findPath(e, t.x, t.y, 1, 600);
    const n = e.path && e.path.shift(); if (n) step(e, dirTo(e.x, e.y, n[0], n[1]), e.spd); return;
  }
  if (dP > 2) { if (!e.path || !e.path.length || R() < .15) e.path = findPath(e, p.x, p.y, 1, 600); const n = e.path && e.path.shift(); if (n) step(e, dirTo(e.x, e.y, n[0], n[1]), e.spd * (dP > 5 ? .7 : 1)); }
}
function petHit(e) { const t = e.hitT; e.hitT = null; if (!t || t.dead || cheb(e.x, e.y, t.x, t.y) > 1) return; sfx('hit', e); if (R() > hitChance(e.st.acc, t.st.agi)) return; dealDamage(e, t, Math.max(1, roll(e.st.dmg) - roll(t.st.ac))); fx('slash', epx(t), epy(t), { dur: .2, ang: R() * 3 }); }

/* ================= BOTS (fake players) ================= */
const BOT_CFG = { ashvale: { town: 10, field: 7, lv: [1, 14] }, mine: { town: 0, field: 7, lv: [9, 24] }, mirewood: { town: 0, field: 7, lv: [15, 32] }, temple: { town: 0, field: 5, lv: [24, 40] }, sanctum: { town: 0, field: 0, lv: [34, 40] } };
function usedNames() { return new Set(S.ents.filter(e => e.kind === 'bot').map(e => e.name).concat(S.party.map(b => b.name))); }
function botGear(cls, lv) {
  const W = { W: [[1, 'bronze_sword'], [9, 'short_sword'], [13, 'bronze_axe'], [17, 'iron_sword'], [22, 'crescent'], [27, 'war_axe'], [31, 'ravager'], [35, 'dragon_slayer']], M: [[1, 'wooden_sword'], [9, 'magic_wand'], [16, 'bone_staff'], [22, 'crystal_staff'], [28, 'ember_staff'], [35, 'dragon_staff']], T: [[1, 'wooden_sword'], [9, 'serpent_sword'], [16, 'spirit_blade'], [22, 'moon_sword'], [28, 'soul_reaver'], [35, 'dragon_fang']] }[cls];
  let w = W[0][1]; for (const [l, id] of W) if (lv >= l && (l < 31 || R() < .5)) w = id;
  const a = lv < 11 ? 'light_armour' : lv < 21 ? 'medium_armour' : lv < 32 || R() < .55 ? { W: 'heavy_armour', M: 'mage_robe', T: 'soul_robe' }[cls] : { W: 'wargod', M: 'arcane_robe', T: 'spirit_robe' }[cls];
  const h = lv < 5 ? null : lv < 14 ? (R() < .6 ? 'leather_cap' : null) : lv < 20 ? 'bronze_helm' : lv < 26 ? 'magic_helm' : lv < 33 ? 'skull_helm' : (R() < .45 ? 'dragon_helm' : 'skull_helm');
  const cand = sl => Object.values(ITEMS).filter(d => d.slot === sl && (!d.cls || d.cls === cls) && d.lv <= lv && !d.special);
  const pk = sl => { const c = cand(sl); return c.length && R() < .85 ? { id: pick(c.slice(-3)).id } : null; };
  const eq = { weapon: { id: w, r: lv > 20 && R() < .4 ? rnd(1, Math.min(7, lv / 5 | 0)) : 0 }, armour: { id: a }, helmet: h ? { id: h } : null, necklace: pk('necklace'), braceletL: pk('bracelet'), braceletR: pk('bracelet'), ringL: pk('ring'), ringR: lv >= 20 && R() < .12 ? { id: pick(['ring_paralysis', 'ring_protection', 'ring_healing', 'ring_revival', 'ring_teleport']) } : pk('ring') };
  return lookFromEquip(eq, { skin: pick(['#e0b48a', '#c8966a', '#f0c8a0', '#a8764a']), hair: pick(['#2a1a0a', '#6a3a1a', '#d8b060', '#1a1a1a', '#a02a1a', '#e8e8e8', '#4a2a6a']), fem: R() < .4 });
}
function makeBot(x, y, o) {
  const used = usedNames(); let name = pick(BOT_NAMES.filter(n => !used.has(n) && n !== S.P.name)) || ('Player' + rnd(100, 999));
  const cls = o.cls || pick(['W', 'W', 'M', 'T']); const lv = o.lv;
  const bs = baseStats(cls, lv); const hp = Math.round(bs.hp * 1.25);
  const guild = o.guild !== undefined ? o.guild : (R() < .55 ? pick(GUILDS).name : null);
  const e = mkEnt('bot', x, y, Object.assign({ name, cls, lv, hp, maxhp: hp, mp: 100, maxmp: 100, look: botGear(cls, lv), guild, spd: .27, st: { ac: [Math.floor(lv / 6), Math.floor(lv / 2.5)], mac: [0, Math.floor(lv / 4)], acc: 10 + lv / 2, agi: 12 + lv / 4 }, atkDelay: cls === 'W' ? .9 : 1.1, mode: 'hunt', thinkT: R(), potCd: 0, greyT: 0, life: 240 + R() * 900 }, o));
  e.hx = x; e.hy = y; return e;
}
function populateBots() {
  const cfg = BOT_CFG[S.map.id]; const m = S.map;
  for (let i = 0; i < cfg.town; i++) { const s = randomFree(m, 76, 60, 11, (x, y) => inSafe(x, y)); if (s) makeBot(s[0], s[1], { lv: rnd(3, 40), mode: 'town' }); }
  for (let i = 0; i < cfg.field; i++) spawnFieldBot(false);
}
function spawnFieldBot(announce) {
  const cfg = BOT_CFG[S.map.id], m = S.map;
  const lv = rnd(cfg.lv[0], cfg.lv[1]);
  const red = S.map.id !== 'ashvale' && R() < .14 || (S.map.id === 'ashvale' && R() < .04);
  const s = randomFree(m, rnd(5, m.w - 5), rnd(5, m.h - 5), 4, (x, y) => !inSafe(x, y) && (!S.player || cheb(x, y, S.player.x, S.player.y) > 10));
  if (!s) return;
  const b = makeBot(s[0], s[1], { lv: red ? Math.max(lv, S.P.lv + rnd(-2, 4)) : lv, red, guild: red ? null : undefined, mode: 'hunt' });
  if (red) { b.pk = 200; b.name = b.name; }
  if (announce) fx('pillar', epx(b), epy(b), { dur: .8, col: '140,180,255' });
}
function botSay(e, text) { say(e, text); if (cheb(e.x, e.y, S.player.x, S.player.y) < 16) chat('say', text, e.name); }
function say(e, text) { e.say = text; e.sayT = 4.5; }
function whisperFrom(name, text) { chat('whisper', text, name); sfx('whisper'); S.lastWhisper = name; }
function botDamage(e) { const L = e.lv; return e.cls === 'W' ? rnd(Math.round(L * .9), Math.round(L * 2)) + 4 : e.cls === 'M' ? rnd(Math.round(L * 1.1), Math.round(L * 2.3)) + 6 : rnd(Math.round(L * .8), Math.round(L * 1.7)) + 4; }
function botAI(e, dt) {
  if (e.stunT > 0 || e.atk >= 0 || e.cast >= 0 || e.mt < 1) return;
  e.thinkT -= dt; e.potCd -= dt;
  const p = S.player;
  // survival
  if (e.hp < e.maxhp * .35 && e.potCd <= 0) { e.potCd = 6; const h = Math.round(e.maxhp * .35); e.hp = Math.min(e.maxhp, e.hp + h); if (e.cls === 'T') { healFx(e, h); } else burst(epx(e), epy(e) - 20, 8, '255,90,90', 40, .5, 2.5, -30); }
  if (e.hp < e.maxhp * .15 && !e.party && R() < .5) { botLeave(e, 'teleport'); return; }
  // party follow
  if (e.party) {
    if (cheb(e.x, e.y, p.x, p.y) > 16) { const s = nearFree(S.map, p.x, p.y); teleportEnt(e, s[0], s[1]); fx('pillar', epx(e), epy(e), { dur: .6, col: '140,180,255' }); return; }
    if (e.cls === 'T' && p.hp < p.maxhp * .6 && e.healCd <= 0 && !S.dead) { e.healCd = 3; e.cast = 0; e.castDur = .45; e.faceL = p.x < e.x; const amt = Math.round(e.lv * 1.8 + 10); setTimeoutGame(.3, () => { if (!S.dead) { p.hp = Math.min(p.maxhp, p.hp + amt); healFx(p, amt); sfx('heal'); } }); return; }
    e.healCd = (e.healCd || 0) - dt;
    if (!e.target || e.target.dead) { e.target = null; if (p.target && !p.target.dead && p.target.kind === 'mon') e.target = p.target; else for (const m of S.ents) if (m.kind === 'mon' && !m.dead && m.target && (m.target === p || m.target === e) && cheb(m.x, m.y, e.x, e.y) < 10) { e.target = m; break; } }
    if (!e.target) { if (cheb(e.x, e.y, p.x, p.y) > 2) botMove(e, p.x, p.y, 1); return; }
  }
  // PK bots hunt the player
  if ((e.red || e.pkOn) && !e.party && !S.dead && !inSafe(p.x, p.y) && cheb(e.x, e.y, p.x, p.y) < 14 && e.thinkT <= 0 && (!e.target || e.target.kind === 'mon')) { if (e.red && R() < .5 && e.target !== p) { e.target = p; if (R() < .6) botSay(e, pick(['your gear is mine', 'lol free kill', 'run', 'hi :)', 'die'])); } }
  if (e.pkOn && e.target === p && (inSafe(p.x, p.y) || S.dead)) { e.target = null; e.pkOn = e.red; }
  if (e.target && (e.target.dead || e.target.gone || cheb(e.x, e.y, e.target.x, e.target.y) > 18)) e.target = null;
  if (e.mode === 'town') {
    if (e.thinkT <= 0) { e.thinkT = 3 + R() * 6; if (R() < .35) { const s = randomFree(S.map, e.x, e.y, 5, (x, y) => inSafe(x, y)); if (s) e.dest = s; } }
    if (e.dest) { if (cheb(e.x, e.y, e.dest[0], e.dest[1]) === 0) e.dest = null; else botMove(e, e.dest[0], e.dest[1], 0); }
    return;
  }
  if (!e.target && e.thinkT <= 0) {
    e.thinkT = .6 + R() * .6;
    let best = null, bd = 11;
    for (const m of S.ents) { if (m.kind !== 'mon' || m.dead) continue; const d = cheb(m.x, m.y, e.x, e.y); if (d >= bd) continue; if (m.def.lv > e.lv + 5) continue; if (m.def.boss && (e.lv < m.def.lv - 4 || R() < .7)) continue; if (m.target === p && R() < .7) continue; bd = d; best = m; }
    e.target = best;
    if (!best && (!e.dest || R() < .1)) { const s = randomFree(S.map, e.x, e.y, 12, (x, y) => !inSafe(x, y)); if (s) e.dest = s; }
  }
  if (e.target) {
    const t = e.target, d = cheb(e.x, e.y, t.x, t.y);
    const range = e.cls === 'M' ? 6 : e.cls === 'T' ? 5 : 1;
    if (d <= range && e.atkCd <= 0) {
      e.dir = dirTo(e.x, e.y, t.x, t.y); if (DX[e.dir]) e.faceL = DX[e.dir] < 0; e.atkCd = e.atkDelay;
      if (e.cls === 'W') { if (d <= 1) { e.atk = 0; e.atkDur = .5; e.hitT = t; } else botMove(e, t.x, t.y, 1); }
      else { e.cast = 0; e.castDur = .45; const dmg = () => Math.max(1, botDamage(e) - roll(t.st.mac || [0, 0]));
        if (e.cls === 'M') { if (e.lv >= 12 && R() < .5) { setTimeoutGame(.25, () => { if (t.dead) return; fx('thunder', epx(t), epy(t), { dur: .4, rank: 1 }); sfx('thunder', t); dealDamage(e, t, dmg(), { mag: 1 }); }); } else S.proj.push({ x: epx(e), y: epy(e), tgt: t, kind: 'fireball', rank: Math.min(3, e.lv / 10 | 0), spd: 500, src: e, onHit: tt => dealDamage(e, tt, dmg(), { mag: 1 }) }); }
        else S.proj.push({ x: epx(e), y: epy(e), tgt: t, kind: 'soulfire', rank: Math.min(3, e.lv / 10 | 0), spd: 460, src: e, onHit: tt => dealDamage(e, tt, dmg(), { mag: 1 }) });
      }
      return;
    }
    if (d > range || (e.cls === 'W' && d > 1)) botMove(e, t.x, t.y, e.cls === 'W' ? 1 : range - 1);
    return;
  }
  if (e.dest) { if (cheb(e.x, e.y, e.dest[0], e.dest[1]) <= 0) e.dest = null; else botMove(e, e.dest[0], e.dest[1], 0); }
}
function botMove(e, tx, ty, stop) {
  if (!e.path || !e.path.length || e.pathT <= 0 || e.pathTo !== tx + ',' + ty) { e.path = findPath(e, tx, ty, stop, 700); e.pathT = .8; e.pathTo = tx + ',' + ty; }
  const n = e.path.shift(); if (n) { if (!step(e, dirTo(e.x, e.y, n[0], n[1]), e.spd)) e.path = null; }
}
function botHit(e) {
  const t = e.hitT; e.hitT = null; if (!t || t.dead || cheb(e.x, e.y, t.x, t.y) > 1) return;
  sfx('swing', e);
  fx('slash', epx(t), epy(t), { dur: .2, ang: R() * 3 });
  if (t.st && R() > hitChance(e.st.acc, t.st.agi)) return;
  dealDamage(e, t, Math.max(1, botDamage(e) - roll(t.st ? t.st.ac : [0, 0])));
}
function botLeave(e, how) {
  if (how === 'teleport') { fx('pillar', epx(e), epy(e), { dur: .7, col: '140,180,255' }); burst(epx(e), epy(e) - 20, 16, '160,200,255', 80, .6, 3); }
  e.gone = true; e.dead = true; e.deadT = 99;
  if (e.party) leaveParty(e, true);
}
/* party */
function inviteBot(b) {
  if (S.party.includes(b)) return;
  if (S.party.length >= 4) { sys('Your group is full (5 members).'); return; }
  if (b.red) { whisperFrom(b.name, 'lol no'); return; }
  const ok = Math.abs(b.lv - S.P.lv) <= 10 && R() < .75 && b.mode !== 'town' || (b.mode === 'town' && R() < .35);
  setTimeoutGame(1 + R() * 2, () => {
    if (b.dead) return;
    if (!ok) { whisperFrom(b.name, pick(['no thx', 'solo atm', 'maybe later', 'too low lvl sorry', 'already in a group'])); return; }
    joinParty(b);
  });
}
function joinParty(b) {
  b.party = true; b.mode = 'hunt'; b.target = null; b.dest = null; b.partyUntil = S.time + 300 + R() * 700; S.party.push(b);
  sys(`${b.name} has joined your group.`); chat('party', pick(['hi', 'hey all', 'lets go', 'ty for inv', 'where we hunting?']), b.name);
  if (window.UI) UI.partyDirty = true;
}
function leaveParty(b, silent) {
  const i = S.party.indexOf(b); if (i < 0) return; S.party.splice(i, 1); b.party = false;
  if (!silent) sys(`${b.name} has left the group.`); if (window.UI) UI.partyDirty = true;
}

/* ================= GUARDS & NPCs ================= */
function populateTown() {
  const m = S.map;
  for (const n of m.npcs) { const def = NPCS.find(d => d.id === n.id); mkEnt('npc', n.x, n.y, { name: def.name, def, title: def.title, blocks: true, dir: 4, look: { skin: '#e0b48a', hair: def.look.hair, fem: def.look.fem, beard: def.look.beard, apron: def.look.apron, armor: { c: def.look.robe, t: shade(def.look.robe, .45), style: def.look.armour ? 'plate' : def.look.apron ? 'leather' : def.id === 'guild' || def.id === 'gate' || def.id === 'elder' || def.id === 'books' ? 'robe' : 'taorobe', cape: def.look.armour ? '#4a0a0a' : null }, wizhat: def.look.hat, neck: def.id === 'jeweler' ? { m: '#e8c050', g: '#e0463a', q: 1, big: 1 } : null, weapon: def.look.armour ? { k: 'blade', c: '#dfe6ec' } : def.id === 'books' || def.id === 'elder' ? { k: 'staff', c: '#8ad0ff' } : null } }); }
  for (const g of m.guards) mkEnt('guard', g.x, g.y, { name: 'Guard', blocks: true, dir: 4, hp: 9999, maxhp: 9999, st: { ac: [99, 99], mac: [99, 99], agi: 99 }, atkCd: 0, look: { skin: '#d8a880', armor: { c: '#8a929e', t: '#d8b060', style: 'plate', cape: '#2a3a6a' }, helm: { c: '#9aa2ae', k: 'plume', p: '#2a4aa8' }, weapon: { k: 'greatsword', c: '#e8eef4' }, shield: 1, braceL: { m: '#d8b060' }, braceR: { m: '#d8b060' } } });
}
function guardAI(e, dt) {
  if (e.atk >= 0) return; if (e.atkCd > 0) return;
  for (const t of [S.player, ...S.ents]) {
    if (!t || t.dead || t === e || cheb(e.x, e.y, t.x, t.y) > 6) continue;
    const bad = (t.kind === 'player' && S.P.pk >= 200) || (t.kind === 'bot' && t.red) || (t.kind === 'mon');
    if (!bad) continue;
    e.atk = 0; e.atkDur = .5; e.atkCd = 1.2; e.dir = dirTo(e.x, e.y, t.x, t.y); if (DX[e.dir]) e.faceL = DX[e.dir] < 0;
    fx('thunder', epx(t), epy(t), { dur: .3, rank: 0 }); sfx('thunder', t);
    dealDamage(e, t, Math.max(30, Math.round(t.maxhp * .35)));
    if (t.kind === 'player') say(e, pick(['Murderer!', 'Halt, criminal!', 'Leave this town!']));
    return;
  }
}

/* ================= MAP CHANGE ================= */
function changeMap(id, x, y) {
  const prevParty = S.party.slice(); const hadPet = S.pet && !S.pet.dead ? { type: S.pet.petType, hp: S.pet.hp / S.pet.maxhp } : null;
  S.map = getMap(id); S.P.map = id; S.P.visited[id] = 1;
  S.occ = new Int32Array(S.map.w * S.map.h); S.ents = []; S.drops = []; S.proj = []; FX.length = 0; PARTS.length = 0; FLOATS.length = 0; TIMERS.length = 0; S.respawns = [];
  const pOld = S.player;
  const p = mkEnt('player', x, y, { name: S.P.name, blocks: true, spd: .26, hp: pOld ? pOld.hp : 1, mp: pOld ? pOld.mp : 1, buffs: pOld ? pOld.buffs : {}, dir: 4 });
  S.player = p; computeStats(); if (!pOld) { p.hp = S.P.hp || p.maxhp; p.mp = S.P.mp || p.maxmp; }
  if (id === 'ashvale') populateTown();
  populateMap(); populateBots();
  S.party = [];
  for (const b of prevParty) { if (b.gone) continue; const s = nearFree(S.map, x, y); const nb = mkEnt('bot', s[0], s[1], Object.assign({}, b, { id: S.nextId++, x: s[0], y: s[1], fx: s[0], fy: s[1], mt: 1, path: null, target: null, dead: false })); S.party.push(nb); }
  if (hadPet) { const r = skillRank(hadPet.type); if (r >= 0) { summonPet(hadPet.type, r); S.pet.hp = Math.max(1, Math.round(S.pet.maxhp * hadPet.hp)); } }
  else S.pet = null;
  S.transT = 1; sfx('portal');
  for (const b of S.ents) if (b.kind === 'bot' && !b.party && b.mode !== 'town' && R() < .5 && b.red === false) b.thinkT = R() * 3;
  if (window.UI) { UI.onMapChange(); }
  sys(`You entered ${S.map.name}.`);
}
function raidFinder() {
  const P = S.P; if (P.lv < 30) { sys('Raid groups only take level 30+.'); sfx('error'); return; }
  const need = Math.max(0, 4 - S.party.length); if (!need) { sys('Your group is ready. Speak to Lys to enter the Sanctum.'); return; }
  chat('shout', `LFM Abyssal Sanctum, need ${need}, lvl 30+`, P.name); sys('Searching for raiders...');
  for (let i = 0; i < need; i++) setTimeoutGame(3 + i * 2.5 + R() * 3, () => {
    if (S.party.length >= 4) return; const s = nearFree(S.map, S.player.x + rnd(-3, 3), S.player.y + rnd(-3, 3));
    const cls = ['T', 'M', 'W', 'T'][S.party.length % 4]; const b = makeBot(s[0], s[1], { lv: rnd(Math.max(30, P.lv - 3), Math.min(40, P.lv + 5)), cls, mode: 'hunt', guild: pick(GUILDS).name });
    fx('pillar', epx(b), epy(b), { dur: .8, col: '140,180,255' }); whisperFrom(b.name, pick(['inv for sanctum', 'lvl ' + b.lv + ' ' + CLASSES[cls].name + ', inv pls', 'can i join? have pots', 'x']));
    setTimeoutGame(1.2, () => { if (!b.dead) joinParty(b); });
  });
}
function enterRaid() {
  const P = S.P; if (P.lv < 30) { sys('The Sanctum rejects you. You must be level 30.'); sfx('error'); return false; }
  if (S.party.length < 2) { sys('You need a group of at least 3 to enter the Abyssal Sanctum. Use the raid finder or invite players.'); sfx('error'); return false; }
  P.visited.sanctum = 1; const m = getMap('sanctum'); changeMap('sanctum', m.start.x, m.start.y); chat('party', pick(['lets do this', 'stack on me for the boss', 'pots ready?', 'dont pull the boss early lol']), pick(S.party).name); return true;
}
function randomTeleport() { const m = S.map; for (let i = 0; i < 200; i++) { const x = rnd(2, m.w - 3), y = rnd(2, m.h - 3); if (m.reach[idx(m, x, y)] && !m.b[idx(m, x, y)] && !S.occ[idx(m, x, y)]) { const p = S.player; fx('pillar', epx(p), epy(p), { dur: .6, col: '160,200,255' }); teleportEnt(p, x, y); p.target = null; fx('pillar', epx(p), epy(p), { dur: .8, col: '160,200,255' }); sfx('portal'); return; } } }

/* ================= CONSUMABLES ================= */
function useItem(slotIdx) {
  const P = S.P, it = P.inv[slotIdx]; if (!it || S.dead) return; const d = ITEMS[it.id]; const p = S.player;
  if (d.slot === 'cons') {
    if (d.oil) { const w = P.equip.weapon; if (!w) { sys('Equip the weapon you want to bless first.'); sfx('error'); return; } const L = w.l || 0; if (L >= 7) { sys('This weapon cannot hold more luck.'); return; }
      invTake(it.id, 1); const ch = [.85, .55, .35, .22, .14, .09, .05][Math.max(0, L)] || .85;
      if (L < 0 || R() < ch) { w.l = L + 1; sys(w.l > 0 ? `The oil sinks into the steel. Luck +${w.l}.` : `The curse weakens. Luck ${w.l}.`); sfx('rare'); fx('pillar', epx(p), epy(p), { dur: 1, col: '255,220,120' }); if (w.l >= 3 && window.UI) UI.toast(`Luck +${w.l}`, 'rare'); }
      else if (R() < .25) { w.l = L - 1; sys(`The oil curdles. Your weapon is cursed (Luck ${w.l}).`); sfx('die'); fx('smoke', epx(p), epy(p), { dur: 1, col: '90,20,40' }); }
      else { sys('Nothing happens.'); sfx('error'); }
      computeStats(); if (window.UI) { UI.invDirty = UI.charDirty = true; } return; }
    if (d.scroll === 'town') { sys('You read the scroll...'); invTake(it.id, 1); fx('pillar', epx(p), epy(p), { dur: .8, col: '160,200,255' }); setTimeoutGame(.6, () => changeMap('ashvale', 76, 63)); return; }
    if (d.scroll === 'random') { invTake(it.id, 1); randomTeleport(); return; }
    if (P.potCd > 0 && !d.instant) return;
    invTake(it.id, 1); sfx('drink');
    if (d.instant) { if (d.heal) p.hp = Math.min(p.maxhp, p.hp + d.heal); if (d.mana) p.mp = Math.min(p.maxmp, p.mp + d.mana); healFx(p, d.heal); }
    else { if (d.heal) p.hpPool = (p.hpPool || 0) + d.heal; if (d.mana) p.mpPool = (p.mpPool || 0) + d.mana; P.potCd = .35; }
    if (window.UI) UI.invDirty = true; return;
  }
  if (d.slot === 'book') {
    if (d.cls !== P.cls) { sys('Your class cannot learn this.'); sfx('error'); return; }
    if (P.lv < d.lv) { sys(`You must be level ${d.lv} to learn ${SKILLS[d.skill].name}.`); sfx('error'); return; }
    if (P.skills[d.skill]) { sys('You already know this skill.'); return; }
    P.inv[slotIdx] = null; P.skills[d.skill] = { rank: 0, pts: 0, cd: 0 };
    const free = P.keys.findIndex(k => !k); if (free >= 0 && SKILLS[d.skill].kind !== 'passive') P.keys[free] = d.skill;
    sys(`You learned ${SKILLS[d.skill].name}!`); sfx('level'); fx('ring', epx(p), epy(p), { dur: .8, col: '140,200,255', r: 60 });
    if (window.UI) { UI.invDirty = true; UI.skillsDirty = true; } return;
  }
  if (['weapon', 'armour', 'helmet', 'necklace', 'bracelet', 'ring'].includes(d.slot)) equipItem(slotIdx);
}
function quaff(kind) {
  const P = S.P; const ok = kind === 'hp' ? (d => d && d.slot === 'cons' && d.heal) : (d => d && d.slot === 'cons' && d.mana && !d.heal);
  const pref = P.belt[kind === 'hp' ? 0 : 1];
  let i = pref && ok(ITEMS[pref]) ? P.inv.findIndex(x => x && x.id === pref) : -1;
  if (i < 0) { const order = kind === 'hp' ? ['hp_l', 'hp_m', 'hp_s', 'sun_potion'] : ['mp_l', 'mp_m', 'mp_s', 'sun_potion']; for (const id of order) { i = P.inv.findIndex(x => x && x.id === id); if (i >= 0) break; } }
  if (i < 0) { sys(kind === 'hp' ? 'You have no health potions.' : 'You have no mana potions.'); sfx('error'); return; }
  useItem(i); if (window.UI) UI.beltDirty = true;
}
function canEquip(d) { const P = S.P; if (d.cls && d.cls !== P.cls) return 'Your class cannot use this.'; if (d.lv && P.lv < d.lv) return `Requires level ${d.lv}.`; return null; }
function equipItem(slotIdx) {
  const P = S.P, it = P.inv[slotIdx], d = ITEMS[it.id]; const err = canEquip(d); if (err) { sys(err); sfx('error'); return; }
  let sl = d.slot; if (sl === 'bracelet') sl = !P.equip.braceletL ? 'braceletL' : !P.equip.braceletR ? 'braceletR' : 'braceletL'; if (sl === 'ring') sl = !P.equip.ringL ? 'ringL' : !P.equip.ringR ? 'ringR' : 'ringL';
  const old = P.equip[sl]; P.equip[sl] = it; P.inv[slotIdx] = old || null; computeStats(); sfx('pickup');
  if (window.UI) { UI.invDirty = true; UI.charDirty = true; }
}
function unequip(sl) { const P = S.P; const it = P.equip[sl]; if (!it) return; const i = P.inv.findIndex(x => !x); if (i < 0) { sys('Your bag is full.'); return; } P.inv[i] = it; P.equip[sl] = null; computeStats(); if (window.UI) { UI.invDirty = true; UI.charDirty = true; } }

/* ================= CHAT SIM & WORLD EVENTS ================= */
function worldTick(dt) {
  S.chatT -= dt; S.sayT -= dt; S.guildChatT -= dt; S.whisperT -= dt; S.inviteT -= dt; S.siegeT -= dt; S.botT -= dt;
  if (R() < dt * .2) S.online = clamp(S.online + rnd(-6, 6), 980, 1620);
  if (S.chatT <= 0) { S.chatT = 7 + R() * 14; chat('shout', pick(SHOUTS), pick(BOT_NAMES)); }
  if (S.sayT <= 0) { S.sayT = 9 + R() * 16; const near = S.ents.filter(e => e.kind === 'bot' && !e.dead && cheb(e.x, e.y, S.player.x, S.player.y) < 12); if (near.length) botSay(pick(near), pick(SAYS)); }
  const G2 = S.P.guild;
  if (G2 && S.guildChatT <= 0) { S.guildChatT = 25 + R() * 40; const on = G2.members.filter(m => m.on); if (on.length) chat('guild', pick(['anyone need help?', 'gz ' + S.P.name, 'siege prep tonight', 'who wants to farm mine?', 'lol', 'got a Coral Ring drop', 'brb food', 'hi guild', 'anyone have spare sun pots?', 'Kael says we need more members']), pick(on).name); }
  if (S.whisperT <= 0) { S.whisperT = 120 + R() * 180; const b = pick(BOT_NAMES); whisperFrom(b, pick(['hey want to group?', 'selling hp pots cheap', 'u in a guild?', 'nice gear', 'can u help me with Old Tusk?', 'wanna duel lol'])); }
  if (S.inviteT <= 0) { S.inviteT = 240 + R() * 240; const c = S.ents.filter(e => e.kind === 'bot' && !e.dead && !e.party && !e.red && e.mode !== 'town' && Math.abs(e.lv - S.P.lv) < 8); if (c.length && S.party.length < 4 && window.UI) UI.invitePrompt(pick(c)); }
  if (S.siegeT <= 0) {
    if (!S.siegeOn) { S.siegeOn = 1; S.siegeT = 120; chat('shout', 'The siege of Castle Varn has begun!', 'System'); if (G2) chat('guild', 'SIEGE STARTED, everyone to Varn!!', pick(G2.members).name); }
    else { S.siegeOn = 0; S.siegeT = 900 + R() * 300; const contenders = GUILDS.map(g => g.name).concat(G2 && G2.own ? [G2.name] : []);
      let w = pick(contenders); if (G2 && R() < (G2.own ? .15 + G2.members.length * .01 : .3)) w = G2.name; S.castle = w;
      chat('shout', `${w} has conquered Castle Varn!`, 'System'); if (G2 && w === G2.name) { sys('Your guild holds Castle Varn! Guild members gain +10% experience.'); sfx('rare'); } }
  }
  // bot churn
  if (S.botT <= 0) {
    S.botT = 25 + R() * 30; const cfg = BOT_CFG[S.map.id];
    const field = S.ents.filter(e => e.kind === 'bot' && !e.dead && e.mode !== 'town' && !e.party);
    if (field.length < cfg.field) spawnFieldBot(true);
    else if (R() < .4 && field.length) { const b = pick(field); if (cheb(b.x, b.y, S.player.x, S.player.y) > 8) botLeave(b, 'teleport'); }
  }
  if (S.P.guild) { for (const m of S.P.guild.members) if (R() < dt * .004) m.on = !m.on; }
  // party members leave eventually
  for (const b of S.party.slice()) if (S.time > b.partyUntil) { chat('party', pick(['gtg, thx for the group', 'bed time, cya', 'ty all, logging']), b.name); leaveParty(b); botLeave(b, 'teleport'); }
}

/* ================= MAIN UPDATE ================= */
function update(dt) {
  S.time += dt; S.gcd = Math.max(0, S.gcd - dt); if (S.shake) S.shake = Math.max(0, S.shake - dt);
  const P = S.P, p = S.player;
  if (P.mcd) for (const k in P.mcd) if (P.mcd[k] > 0) P.mcd[k] -= dt; if (P.lichCd > 0) P.lichCd -= dt;
  if (P.potCd > 0) P.potCd -= dt; if (P.reviveCd > 0) P.reviveCd -= dt; if (P.tpCd > 0) P.tpCd -= dt;
  if (P.pk > 0) { P.pkT = (P.pkT || 0) + dt; if (P.pkT > 6) { P.pkT = 0; P.pk--; } }
  if (p.greyT > 0) p.greyT -= dt;
  for (const k in P.skills) if (P.skills[k].cd > 0) P.skills[k].cd -= dt;
  for (let i = TIMERS.length - 1; i >= 0; i--) if (S.time >= TIMERS[i].t) { const f = TIMERS[i].fn; TIMERS.splice(i, 1); f(); }
  // respawns
  for (let i = S.respawns.length - 1; i >= 0; i--) if (S.time >= S.respawns[i].t) { spawnFromSpawn(S.respawns[i].sp, true); S.respawns.splice(i, 1); }
  for (const b of S.map.bosses) { const k = S.map.id + ':' + b.mon; if (S.bossNext[k] && Date.now() >= S.bossNext[k] && !S.ents.some(e => e.kind === 'mon' && e.def.id === b.mon && !e.dead)) { delete S.bossNext[k]; spawnBoss(b); chat('shout', `${MON[b.mon].name} has appeared in ${S.map.name}!`, 'System'); } }
  if (!S.dead) playerUpdate(dt);
  for (const e of S.ents) {
    if (e.dead) { e.deadT += dt; continue; }
    if (e.mt < 1) { e.mt = Math.min(1, e.mt + dt / e.mdur); e.walk += dt / (e.mdur * 2); }
    e.idle += dt; if (e.flashT > 0) e.flashT -= dt; if (e.dmgT > 0) e.dmgT -= dt; if (e.sayT > 0) e.sayT -= dt; if (e.stunT > 0) e.stunT -= dt; if (e.frozenT > 0) e.frozenT -= dt; if (e.slowT > 0) e.slowT -= dt; if (e.greyT > 0) e.greyT -= dt;
    if (e.atkCd > 0) e.atkCd -= dt;
    for (const b in e.buffs) { e.buffs[b].t -= dt; if (e.buffs[b].t <= 0) { delete e.buffs[b]; if (e === p && b === 'soulshield') computeStats(); } }
    if (e.poison) { const po = e.poison; po.t -= dt; po.tick -= dt; if (po.tick <= 0) { po.tick = 1; dealDamage(po.src && !po.src.dead ? po.src : null, e, po.dps, { col: '#9cff7a' }); if (e.kind === 'player') {} part(epx(e), epy(e) - 30, { vy: -30, life: .6, max: .6, size: 3, col: '120,255,90' }); } if (po.t <= 0) e.poison = null; if (e.dead) continue; }
    // attack animation progress
    if (e.atk >= 0) { const prev = e.atk; e.atk += dt / e.atkDur; const hitAt = e.stomping ? 2 : .5; if (prev < hitAt && e.atk >= hitAt) { if (e.kind === 'player') { if (e.swingT && !e.swingT.dead) playerSwing(e, e.swingT); } else if (e.kind === 'mon') { if (e.shoot) monShoot(e); else monHit(e); } else if (e.kind === 'pet') petHit(e); else if (e.kind === 'bot') botHit(e); } if (e.atk >= 1) e.atk = -1; }
    if (e.cast >= 0) { e.cast += dt / e.castDur; if (e.cast >= 1) e.cast = -1; }
    const near = cheb(e.x, e.y, p.x, p.y) < 26;
    if (e.kind === 'mon' && (near || e.target)) monAI(e, dt);
    else if (e.kind === 'pet') petAI(e, dt);
    else if (e.kind === 'bot') botAI(e, dt);
    else if (e.kind === 'guard') guardAI(e, dt);
  }
  // cleanup dead
  for (let i = S.ents.length - 1; i >= 0; i--) { const e = S.ents[i]; if (e.dead && e !== p && e.deadT > (e.kind === 'mon' ? 5 : 3)) { if (e.kind === 'bot' && e.party) leaveParty(e, true); S.ents.splice(i, 1); } }
  // projectiles
  for (let i = S.proj.length - 1; i >= 0; i--) {
    const pr = S.proj[i]; pr.t = (pr.t || 0) + dt; const t = pr.tgt;
    const tx = t ? epx(t) : pr.tx, ty = t ? epy(t) : pr.ty; const dx = tx - pr.x, dy = ty - pr.y, l = Math.hypot(dx, dy);
    pr.ang = Math.atan2(dy, dx);
    if (l < 12 || pr.t > 3) { S.proj.splice(i, 1); if (t && !t.dead && pr.t <= 3) pr.onHit(t); continue; }
    const v = pr.spd * dt; pr.x += dx / l * Math.min(v, l); pr.y += dy / l * Math.min(v, l);
  }
  // drops decay
  for (let i = S.drops.length - 1; i >= 0; i--) { const d = S.drops[i]; d.t += dt; if (d.t > 240) S.drops.splice(i, 1); }
  // regen
  S.regT = (S.regT || 0) + dt; S.combatT = Math.max(0, (S.combatT || 0) - dt);
  if (S.regT >= 2 && !S.dead) {
    S.regT = 0; const f = S.combatT > 0 ? 1 : 2.5;
    p.hp = Math.min(p.maxhp, p.hp + Math.max(1, Math.round((p.maxhp * .012 + P.lv * .1) * f)) + (p.st.special.regen ? Math.round(p.maxhp * .02) : 0));
    p.mp = Math.min(p.maxmp, p.mp + Math.max(1, Math.round((p.maxmp * .015 + P.lv * .1) * f)));
    for (const b of S.ents) if (b.kind === 'bot' && !b.dead) b.hp = Math.min(b.maxhp, b.hp + b.maxhp * .02);
    if (S.pet && !S.pet.dead) S.pet.hp = Math.min(S.pet.maxhp, S.pet.hp + S.pet.maxhp * .01);
  }
  if (p.hpPool > 0) { const a = Math.min(p.hpPool, Math.max(1, dt * 60)); p.hpPool -= a; p.hp = Math.min(p.maxhp, p.hp + a); }
  if (p.mpPool > 0) { const a = Math.min(p.mpPool, Math.max(1, dt * 60)); p.mpPool -= a; p.mp = Math.min(p.maxmp, p.mp + a); }
  worldTick(dt);
  updateFX(dt);
  if (S.transT > 0) S.transT = Math.max(0, S.transT - dt * 1.6);
}

/* ---------- player per-frame ---------- */
function playerUpdate(dt) {
  const p = S.player, m = S.map, P = S.P;
  if (p.stunT > 0 || p.cast >= 0 || p.atk >= 0) return;
  const kd = S.keys || {}; const mx = (kd.d ? 1 : 0) - (kd.a ? 1 : 0), my = (kd.s ? 1 : 0) - (kd.w ? 1 : 0);
  if ((mx || my) && p.mt >= 1) {
    p.target = null; p.talkTo = null; p.pending = null; p.path = null; p.dest = null;
    const d0 = dirTo(0, 0, mx, my); const spd = p.spd * (p.slowT > 0 ? 1.7 : 1);
    if (!step(p, d0, spd)) { const alts = mx && my ? [dirTo(0, 0, mx, 0), dirTo(0, 0, 0, my)] : [(d0 + 1) % 8, (d0 + 7) % 8]; for (const d2 of alts) if (step(p, d2, spd)) break; }
    return;
  }
  if (p.queued && S.gcd <= 0) { const k = p.queued; p.queued = null; castSkill(k); if (p.cast >= 0) return; }
  if (p.mt < 1) return;
  // arrival checks
  const portal = m.portals.find(q => p.x >= q.x0 && p.x <= q.x1 && p.y >= q.y0 && p.y <= q.y1);
  if (portal && !p.justPorted) { p.justPorted = true; changeMap(portal.to, portal.tx, portal.ty); return; }
  if (!portal) p.justPorted = false;
  const di = S.drops.findIndex(d => d.x === p.x && d.y === p.y);
  if (di >= 0) pickup(di);
  // pending cast
  if (p.pending) { const pd = p.pending; const def = SKILLS[pd.k]; const tx = pd.tgt ? pd.tgt.x : pd.tx, ty = pd.tgt ? pd.tgt.y : pd.ty; if (pd.tgt && pd.tgt.dead) p.pending = null; else if (cheb(p.x, p.y, tx, ty) <= def.range) { p.pending = null; castSkill(pd.k, pd.tgt); return; } }
  // mouse held → continuous move
  if (S.mouse.down && S.mouse.mode === 'move') { const tx = S.mouse.tx, ty = S.mouse.ty; if (!p.dest || p.dest[0] !== tx || p.dest[1] !== ty) { p.dest = [tx, ty]; p.path = findPath(p, tx, ty, 0); } }
  const t = p.target;
  if (t && (t.dead || t.gone || !isEnemy(p, t) && t.kind !== 'npc')) { p.target = null; }
  if (p.target && p.target.kind !== 'npc') {
    const tt = p.target; const d = cheb(p.x, p.y, tt.x, tt.y);
    if (d <= 1 && !(tt.x !== p.x && tt.y !== p.y && blocked(m, tt.x, p.y) && blocked(m, p.x, tt.y))) {
      if (p.atkCd <= 0) { p.atk = 0; p.atkDur = .42; p.atkCd = p.st.atkDelay; p.swingT = tt; p.dir = dirTo(p.x, p.y, tt.x, tt.y); if (DX[p.dir]) p.faceL = DX[p.dir] < 0; p.path = null; }
      return;
    }
    if (!p.path || !p.path.length || p.pathT <= 0) { p.path = findPath(p, tt.x, tt.y, 1); p.pathT = .35; }
  }
  if (p.talkTo) { const n = p.talkTo; if (cheb(p.x, p.y, n.x, n.y) <= 2) { p.talkTo = null; p.path = null; p.dir = dirTo(p.x, p.y, n.x, n.y); if (window.UI) UI.openNPC(n); return; } if (!p.path || !p.path.length) p.path = findPath(p, n.x, n.y, 1); }
  p.pathT = (p.pathT || 0) - dt;
  if (p.path && p.path.length) {
    const n = p.path[0];
    if (step(p, dirTo(p.x, p.y, n[0], n[1]), p.spd * (p.slowT > 0 ? 1.7 : 1))) { p.path.shift(); }
    else { p.blockT = (p.blockT || 0) + dt; if (p.blockT > .25) { p.blockT = 0; const goal = p.path[p.path.length - 1]; p.path = findPath(p, goal[0], goal[1], p.target ? 1 : 0); if (!p.path.length) p.path = null; } }
  } else if (p.dest && !S.mouse.down) p.dest = null;
}
function pickup(i) {
  const d = S.drops[i], P = S.P;
  if (d.gold) { P.gold += d.gold; chat('xp', `Picked up ${fmt(d.gold)} gold`); sfx('gold'); S.drops.splice(i, 1); if (window.UI) UI.invDirty = true; return; }
  if (!invAdd(d.it)) { sys('Your bag is full.'); sfx('error'); return; }
  const def = ITEMS[d.it.id]; chat('loot', `Picked up ${itemName(d.it)}${d.it.n > 1 ? ' x' + d.it.n : ''}`, itemColor(d.it)); sfx(def.q === 3 ? 'mythic' : def.q ? 'rare' : 'pickup');
  if (def.q) { UI && UI.toast(itemName(d.it), def.q === 3 ? 'mythic' : def.q === 2 ? 'legend' : 'rare'); } if (def.q === 3) chat('shout', `${S.P.name} has found a Mythic item: ${def.name}!`, 'System');
  S.drops.splice(i, 1); if (window.UI) UI.invDirty = true;
}
