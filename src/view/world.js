/* ================= WORLD GENERATION ================= */
// ground ids
const G = { GRASS: 0, GRASS2: 1, DIRT: 2, ROAD: 3, PAVE: 4, WATER: 5, CAVE: 6, CAVE2: 7, TFLOOR: 8, CARPET: 9, SAND: 10, MOSS: 11, VOID: 12, FLOWERS: 13, FARM: 14, ABYSS: 15 };
const WALLH = { 1: 46, 2: 60, 3: 42, 4: 70 };

function newMap(id, name, w, h, fill) {
  const m = { id, name, w, h, g: new Uint8Array(w * h).fill(fill), b: new Uint8Array(w * h), wall: new Uint8Array(w * h), objs: [], portals: [], spawns: [], bosses: [], npcs: [], guards: [], lights: [], safe: null, dark: 0, outdoor: true, start: { x: 5, y: 5 }, chunks: new Map(), reach: null };
  return m;
}
const idx = (m, x, y) => y * m.w + x;
const inb = (m, x, y) => x >= 0 && y >= 0 && x < m.w && y < m.h;
function setG(m, x, y, v) { if (inb(m, x, y)) m.g[idx(m, x, y)] = v; }
function getG(m, x, y) { return inb(m, x, y) ? m.g[idx(m, x, y)] : G.VOID; }
function blocked(m, x, y) { return !inb(m, x, y) || m.b[idx(m, x, y)] !== 0; }
function addObj(m, o, blockIt) {
  m.objs.push(o);
  if (blockIt) { const fw = o.fw || 1, fh = o.fh || 1; for (let j = 0; j < fh; j++) for (let i = 0; i < fw; i++) if (inb(m, o.x + i, o.y - j)) m.b[idx(m, o.x + i, o.y - j)] = 1; }
}
function setWall(m, x, y, t) { if (!inb(m, x, y)) return; const k = idx(m, x, y); m.wall[k] = t; m.b[k] = t ? 1 : 0; }
function freeSpot(m, x, y) { return inb(m, x, y) && !m.b[idx(m, x, y)] && m.g[idx(m, x, y)] !== G.WATER; }
function computeReach(m, sx, sy) {
  const r = new Uint8Array(m.w * m.h); const q = [sx, sy]; r[idx(m, sx, sy)] = 1;
  while (q.length) { const y = q.pop(), x = q.pop(); for (let d = 0; d < 8; d += 2) { const nx = x + DX[d], ny = y + DY[d]; if (inb(m, nx, ny) && !r[idx(m, nx, ny)] && !m.b[idx(m, nx, ny)]) { r[idx(m, nx, ny)] = 1; q.push(nx, ny); } } }
  m.reach = r; return r;
}
function carveLine(m, x0, y0, x1, y1, rad, gv, rng) {
  let x = x0, y = y0; let guard = 0;
  while ((Math.abs(x - x1) > 1 || Math.abs(y - y1) > 1) && guard++ < 4000) {
    for (let j = -rad; j <= rad; j++) for (let i = -rad; i <= rad; i++) { if (i * i + j * j > rad * rad + 1) continue; const cx = Math.round(x + i), cy = Math.round(y + j); if (!inb(m, cx, cy) || cx < 1 || cy < 1 || cx >= m.w - 1 || cy >= m.h - 1) continue; setWall(m, cx, cy, 0); if (gv != null) setG(m, cx, cy, gv); }
    const dx = x1 - x, dy = y1 - y, l = Math.hypot(dx, dy);
    x += dx / l + (rng() - .5) * 1.1; y += dy / l + (rng() - .5) * 1.1;
  }
}

/* ---------- ASHVALE ---------- */
function genAshvale() {
  const W = 150, H = 120, rng = mulberry(1337);
  const m = newMap('ashvale', 'Ashvale Province', W, H, G.GRASS);
  m.outdoor = true; m.dark = 0;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const n = fbm(x * .06, y * .06, 3);
    let g = n > .58 ? G.GRASS2 : G.GRASS;
    if (fbm(x * .15, y * .15, 9) > .72) g = G.FLOWERS;
    setG(m, x, y, g);
  }
  // lake SW
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const d = dist(x, y, 32, 92) / 11 + (fbm(x * .15, y * .15, 5) - .5) * .7;
    if (d < 1) { setG(m, x, y, G.WATER); m.b[idx(m, x, y)] = 2; } else if (d < 1.18) setG(m, x, y, G.SAND);
  }
  // farm fields south of town
  for (let y = 78; y < 94; y++) for (let x = 58; x < 96; x++) if (!((x - 58) % 13 === 12)) { setG(m, x, y, G.FARM); if (x % 2 === 0 && y % 3 === 1 && rng() < .5) addObj(m, { type: 'crop', x, y, v: rng() * 3 | 0 }); }
  // town
  const T = { x0: 62, y0: 46, x1: 90, y1: 72 };
  m.safe = T;
  for (let y = T.y0; y <= T.y1; y++) for (let x = T.x0; x <= T.x1; x++) setG(m, x, y, G.PAVE);
  // roads
  const road = (x0, y0, x1, y1) => carveLine(m, x0, y0, x1, y1, 1.3, G.ROAD, rng);
  road(91, 59, 149, 57); road(76, 73, 78, 119); road(61, 59, 0, 62); road(76, 45, 76, 30); road(76, 30, 24, 20);
  road(76, 30, 128, 22);
  m.objs = m.objs.filter(o => o.type !== 'crop' || getG(m, o.x, o.y) === G.FARM);
  // walls
  for (let x = T.x0; x <= T.x1; x++) { if (Math.abs(x - 76) > 1) { setWall(m, x, T.y0, 3); setWall(m, x, T.y1, 3); } }
  for (let y = T.y0; y <= T.y1; y++) { if (Math.abs(y - 59) > 1) { setWall(m, T.x0, y, 3); setWall(m, T.x1, y, 3); } }
  for (let y = T.y0 + 1; y < T.y1; y++) for (let x = T.x0 + 1; x < T.x1; x++) setG(m, x, y, G.PAVE);
  // houses (x,y = bottom-left tile, fw x fh footprint)
  const houses = [
    { x: 64, y: 50, role: 'weapons', roof: '#8a3a2a' }, { x: 69, y: 50, role: 'armour', roof: '#4a5a6a' },
    { x: 79, y: 50, role: 'jeweler', roof: '#6a2a5a' }, { x: 84, y: 50, role: 'potions', roof: '#2a6a4a' },
    { x: 64, y: 68, role: 'books', roof: '#2a3a6a' }, { x: 69, y: 68, role: 'smith', roof: '#3a3a3a' },
    { x: 79, y: 68, role: 'storage', roof: '#7a5a2a' }, { x: 84, y: 68, role: 'guild', roof: '#7a1a1a' },
  ];
  for (const h of houses) { addObj(m, { type: 'house', x: h.x, y: h.y, fw: 5, fh: 3, roof: h.roof, role: h.role, v: rng() * 3 | 0 }, true); m.npcs.push({ id: h.role, x: h.x + 2, y: h.y + 1 }); }
  addObj(m, { type: 'fountain', x: 75, y: 60, fw: 3, fh: 3 }, true);
  m.npcs.push({ id: 'elder', x: 73, y: 57 }, { id: 'gate', x: 79, y: 57 });
  // fix: npc stands in front of door (row below footprint)
  for (const n of m.npcs) { if (houses.find(h => h.role === n.id)) n.y = houses.find(h => h.role === n.id).y + 1; }
  m.guards.push({ x: 74, y: 47 }, { x: 78, y: 47 }, { x: 74, y: 71 }, { x: 78, y: 71 }, { x: 63, y: 57 }, { x: 63, y: 61 }, { x: 89, y: 57 }, { x: 89, y: 61 });
  for (const [x, y] of [[66, 56], [86, 56], [66, 63], [86, 63], [72, 53], [80, 53]]) { addObj(m, { type: 'lamp', x, y }, true); m.lights.push({ x, y, r: 5, c: '255,190,110' }); }
  for (const [x, y] of [[70, 62], [82, 62], [68, 54], [84, 65]]) addObj(m, { type: rng() < .5 ? 'barrel' : 'crate', x, y }, true);
  // mine entrance
  addObj(m, { type: 'cave_mouth', x: 21, y: 18, fw: 5, fh: 3 }, true);
  for (let y = 19; y < 22; y++) for (let x = 21; x < 26; x++) { m.b[idx(m, x, y)] = 0; setG(m, x, y, G.DIRT); }
  m.portals.push({ x0: 22, y0: 19, x1: 24, y1: 19, to: 'mine', tx: 9, ty: 10, label: 'Hollow Mine' });
  m.portals.push({ x0: 148, y0: 53, x1: 149, y1: 61, to: 'mirewood', tx: 3, ty: 55, label: 'Mirewood Forest' });
  addObj(m, { type: 'sign', x: 30, y: 21, text: 'Hollow Mine' }, true);
  addObj(m, { type: 'sign', x: 140, y: 55, text: 'Mirewood' }, true);
  // trees & rocks
  const border = 3;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const k = idx(m, x, y); if (m.b[k] || m.wall[k]) continue;
    const g = m.g[k]; if (g === G.ROAD || g === G.PAVE || g === G.FARM || g === G.WATER || g === G.SAND) continue;
    if (x > T.x0 - 4 && x < T.x1 + 4 && y > T.y0 - 4 && y < T.y1 + 4) continue;
    if (x >= 18 && x <= 28 && y >= 14 && y <= 23) continue;
    const edge = x < border || y < border || x >= W - border || y >= H - border;
    const dens = fbm(x * .09, y * .09, 21);
    if (edge ? rng() < .8 : (dens > .64 && rng() < .35) || rng() < .012) { if (!nearObj(m, x, y)) addObj(m, { type: 'tree', x, y, v: rng() * 4 | 0, s: .85 + rng() * .35 }, true); }
    else if (rng() < .006) addObj(m, { type: 'rock', x, y, v: rng() * 3 | 0 }, true);
    else if (rng() < .012) addObj(m, { type: 'bush', x, y, v: rng() * 2 | 0 });
  }
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if ((x === 0 || y === 0 || x === W - 1 || y === H - 1) && !m.portals.some(p => x >= p.x0 && x <= p.x1 && y >= p.y0 && y <= p.y1)) m.b[idx(m, x, y)] = m.b[idx(m, x, y)] || 1;
  m.start = { x: 76, y: 63 };
  m.townSpawn = { x: 76, y: 63 };
  m.spawns = [
    { mon: 'hen', n: 16, x0: 92, y0: 48, x1: 118, y1: 72 },
    { mon: 'hen', n: 10, x0: 40, y0: 44, x1: 60, y1: 60 },
    { mon: 'deer', n: 14, x0: 92, y0: 30, x1: 125, y1: 50 },
    { mon: 'deer', n: 8, x0: 40, y0: 62, x1: 58, y1: 76 },
    { mon: 'scarecrow', n: 16, x0: 58, y0: 76, x1: 96, y1: 95 },
    { mon: 'wildcat', n: 18, x0: 96, y0: 76, x1: 145, y1: 115 },
    { mon: 'wildcat', n: 12, x0: 4, y0: 30, x1: 40, y1: 60 },
    { mon: 'boar', n: 12, x0: 100, y0: 6, x1: 145, y1: 30 },
    { mon: 'wildcat_brute', n: 14, x0: 4, y0: 100, x1: 55, y1: 116 },
    { mon: 'wildcat_brute', n: 6, x0: 120, y0: 95, x1: 146, y1: 116 },
    { mon: 'boar', n: 6, x0: 30, y0: 26, x1: 55, y1: 42 },
  ];
  m.bosses = [{ mon: 'old_tusk', x: 128, y: 16 }];
  return m;
}
function nearObj(m, x, y) {
  for (let j = -1; j <= 1; j++) for (let i = -1; i <= 1; i++) { if (inb(m, x + i, y + j) && m.b[idx(m, x + i, y + j)] === 1) return true; }
  return false;
}

/* ---------- HOLLOW MINE ---------- */
function genMine() {
  const W = 100, H = 90, rng = mulberry(4242);
  const m = newMap('mine', 'Hollow Mine', W, H, G.CAVE);
  m.outdoor = false; m.dark = .8;
  let a = new Uint8Array(W * H);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) a[y * W + x] = (x < 2 || y < 2 || x >= W - 2 || y >= H - 2 || rng() < .47) ? 1 : 0;
  for (let it = 0; it < 5; it++) {
    const b = new Uint8Array(W * H);
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
      let c = 0; for (let j = -1; j <= 1; j++) for (let i = -1; i <= 1; i++) { const nx = x + i, ny = y + j; if (nx < 0 || ny < 0 || nx >= W || ny >= H || a[ny * W + nx]) c++; }
      b[y * W + x] = (x < 2 || y < 2 || x >= W - 2 || y >= H - 2) ? 1 : c >= 5 ? 1 : 0;
    }
    a = b;
  }
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (a[y * W + x]) setWall(m, x, y, 1);
  // entrance and boss chambers + tunnels
  const carveRoom = (cx, cy, r) => { for (let j = -r; j <= r; j++) for (let i = -r - 2; i <= r + 2; i++) if ((i / (r + 2)) ** 2 + (j / r) ** 2 <= 1 && inb(m, cx + i, cy + j) && cx + i > 1 && cy + j > 1 && cx + i < W - 2 && cy + j < H - 2) setWall(m, cx + i, cy + j, 0); };
  carveRoom(9, 9, 4); carveRoom(84, 76, 7);
  carveLine(m, 9, 9, 50, 45, 1.4, null, rng); carveLine(m, 50, 45, 84, 76, 1.4, null, rng); carveLine(m, 50, 45, 20, 78, 1.2, null, rng); carveLine(m, 50, 45, 88, 12, 1.2, null, rng);
  computeReach(m, 9, 9);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) { const k = idx(m, x, y); if (!m.wall[k] && !m.reach[k]) setWall(m, x, y, 1); }
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) { const k = idx(m, x, y); if (!m.wall[k]) setG(m, x, y, fbm(x * .2, y * .2, 77) > .55 ? G.CAVE2 : G.CAVE); }
  // decor: torches, crystals, bones, carts
  for (let y = 2; y < H - 2; y++) for (let x = 2; x < W - 2; x++) {
    const k = idx(m, x, y); if (m.wall[k]) continue;
    if (m.wall[idx(m, x, y - 1)] && rng() < .045) { addObj(m, { type: 'torch', x, y: y - 1, wallTorch: 1 }); m.lights.push({ x, y: y - .5, r: 4.5, c: '255,150,70' }); }
    else if (rng() < .012) addObj(m, { type: 'crystal', x, y, v: rng() * 3 | 0 }, true), m.lights.push({ x, y, r: 2.2, c: '120,180,255' });
    else if (rng() < .012) addObj(m, { type: 'bones', x, y, v: rng() * 2 | 0 });
    else if (rng() < .005) addObj(m, { type: 'minecart', x, y }, true);
  }
  addObj(m, { type: 'ladder', x: 7, y: 7 });
  m.lights.push({ x: 7, y: 7, r: 5, c: '255,220,160' });
  m.portals.push({ x0: 7, y0: 7, x1: 7, y1: 7, to: 'ashvale', tx: 23, ty: 21, label: 'Ashvale Province' });
  m.start = { x: 9, y: 10 };
  computeReach(m, 9, 10);
  m.zones = [
    { mons: ['cave_bat', 'maggot', 'skeleton'], dmin: 0, dmax: 35, n: 45 },
    { mons: ['skeleton', 'axe_skeleton', 'zombie'], dmin: 30, dmax: 70, n: 55 },
    { mons: ['bone_fighter', 'rot_zombie', 'axe_skeleton'], dmin: 60, dmax: 200, n: 50 },
  ];
  m.bosses = [{ mon: 'bone_king', x: 84, y: 76 }];
  return m;
}

/* ---------- MIREWOOD ---------- */
function genMirewood() {
  const W = 140, H = 110, rng = mulberry(9001);
  const m = newMap('mirewood', 'Mirewood Forest', W, H, G.MOSS);
  m.outdoor = true; m.dark = .28;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const n = fbm(x * .07, y * .07, 31);
    setG(m, x, y, n > .6 ? G.GRASS2 : n < .38 ? G.DIRT : G.MOSS);
  }
  // swamps
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) { const n = fbm(x * .05, y * .05, 55); if (n > .7 && x > 10) { setG(m, x, y, G.WATER); m.b[idx(m, x, y)] = 2; } }
  const path = (x0, y0, x1, y1, r) => carveLine(m, x0, y0, x1, y1, r || 1.3, G.DIRT, rng);
  path(0, 55, 40, 45); path(40, 45, 80, 60); path(80, 60, 132, 50); path(80, 60, 108, 86); path(40, 45, 55, 15); path(40, 45, 30, 90); path(80, 60, 90, 20);
  // unblock water on paths
  for (let k = 0; k < W * H; k++) if (m.g[k] === G.DIRT && m.b[k] === 2) m.b[k] = 0;
  // clearings
  const clear = (cx, cy, r, gv) => { for (let j = -r; j <= r; j++) for (let i = -r; i <= r; i++) if (i * i + j * j <= r * r && inb(m, cx + i, cy + j)) { m.b[idx(m, cx + i, cy + j)] = 0; setG(m, cx + i, cy + j, gv); } };
  clear(108, 88, 9, G.DIRT); clear(40, 45, 6, G.GRASS2); clear(55, 15, 6, G.MOSS); clear(30, 90, 7, G.MOSS); clear(90, 20, 6, G.MOSS); clear(130, 50, 5, G.ROAD);
  const keep = (x, y) => (Math.abs(x - 108) < 11 && Math.abs(y - 88) < 11) || x < 4 && Math.abs(y - 55) < 4 || x > 124 && Math.abs(y - 50) < 7;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const k = idx(m, x, y); if (m.b[k] || m.g[k] === G.DIRT || m.g[k] === G.ROAD || m.g[k] === G.WATER || keep(x, y)) continue;
    const edge = x < 3 || y < 3 || x >= W - 3 || y >= H - 3;
    const dens = fbm(x * .08, y * .08, 41);
    if ((edge && rng() < .85) || (dens > .45 && rng() < .3) || rng() < .05) { if (!nearObj(m, x, y)) addObj(m, { type: rng() < .45 ? 'pine' : 'tree', x, y, v: rng() * 4 | 0, s: .95 + rng() * .45, dark: 1 }, true); }
    else if (rng() < .02) addObj(m, { type: 'bush', x, y, v: rng() * 2 | 0 });
    else if (rng() < .006) addObj(m, { type: 'rock', x, y, v: rng() * 3 | 0 }, true);
    else if (rng() < .01) addObj(m, { type: 'mushroom', x, y, v: rng() * 2 | 0 });
  }
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (x === 0 || y === 0 || x === W - 1 || y === H - 1) if (!(x === 0 && Math.abs(y - 55) < 3)) m.b[idx(m, x, y)] = m.b[idx(m, x, y)] || 1;
  addObj(m, { type: 'temple_gate', x: 132, y: 49, fw: 5, fh: 2 }, true);
  for (let x = 133; x < 136; x++) m.b[idx(m, x, 49)] = 0;
  m.lights.push({ x: 131, y: 49, r: 4, c: '255,160,80' }, { x: 137, y: 49, r: 4, c: '255,160,80' });
  m.portals.push({ x0: 133, y0: 48, x1: 135, y1: 49, to: 'temple', tx: 8, ty: 50, label: 'Sunken Temple of Khar' });
  m.portals.push({ x0: 0, y0: 52, x1: 0, y1: 58, to: 'ashvale', tx: 146, ty: 57, label: 'Ashvale Province' });
  m.start = { x: 3, y: 55 };
  computeReach(m, 3, 55);
  m.zones = [
    { mons: ['goblin', 'goblin_fighter', 'spider'], dmin: 0, dmax: 55, n: 50 },
    { mons: ['goblin_fighter', 'goblin_shaman', 'spider', 'black_boar', 'snake'], dmin: 45, dmax: 100, n: 60 },
    { mons: ['goblin_brute', 'goblin_shaman', 'snake', 'black_boar'], dmin: 90, dmax: 300, n: 45 },
  ];
  m.bosses = [{ mon: 'goblin_warlord', x: 108, y: 88 }];
  return m;
}

/* ---------- SUNKEN TEMPLE ---------- */
function genTemple() {
  const W = 112, H = 100, rng = mulberry(777);
  const m = newMap('temple', 'Sunken Temple of Khar', W, H, G.TFLOOR);
  m.outdoor = false; m.dark = .72;
  for (let k = 0; k < W * H; k++) { m.wall[k] = 2; m.b[k] = 1; }
  const rooms = [{ x: 4, y: 45, w: 10, h: 10 }];
  let tries = 0;
  while (rooms.length < 17 && tries++ < 3000) {
    const w = 8 + (rng() * 10 | 0), h = 7 + (rng() * 8 | 0), x = 4 + (rng() * (W - w - 30) | 0), y = 3 + (rng() * (H - h - 6) | 0);
    if (rooms.some(r => x < r.x + r.w + 3 && x + w + 3 > r.x && y < r.y + r.h + 3 && y + h + 3 > r.y)) continue;
    rooms.push({ x, y, w, h });
  }
  const boss = { x: 88, y: 38, w: 20, h: 24, boss: 1 };
  rooms.push(boss);
  const carveRect = (r, gv) => { for (let y = r.y; y < r.y + r.h; y++) for (let x = r.x; x < r.x + r.w; x++) { setWall(m, x, y, 0); setG(m, x, y, gv); } };
  for (const r of rooms) carveRect(r, G.TFLOOR);
  // connect: order by x then chain + some extra
  const cen = r => ({ x: r.x + (r.w >> 1), y: r.y + (r.h >> 1) });
  const order = rooms.slice(0, -1).sort((a, b) => cen(a).x - cen(b).x);
  const corr = (a, b) => {
    const A = cen(a), B = cen(b);
    const hz = (x0, x1, y) => { for (let x = Math.min(x0, x1); x <= Math.max(x0, x1); x++) for (let j = -1; j <= 1; j++) if (inb(m, x, y + j) && y + j > 0 && y + j < H - 1) { setWall(m, x, y + j, 0); setG(m, x, y + j, G.TFLOOR); } };
    const vt = (y0, y1, x) => { for (let y = Math.min(y0, y1); y <= Math.max(y0, y1); y++) for (let i = -1; i <= 1; i++) if (inb(m, x + i, y) && x + i > 0 && x + i < W - 1) { setWall(m, x + i, y, 0); setG(m, x + i, y, G.TFLOOR); } };
    if (rng() < .5) { hz(A.x, B.x, A.y); vt(A.y, B.y, B.x); } else { vt(A.y, B.y, A.x); hz(A.x, B.x, B.y); }
  };
  for (let i = 1; i < order.length; i++) corr(order[i - 1], order[i]);
  for (let i = 0; i < 5; i++) corr(order[rng() * order.length | 0], order[rng() * order.length | 0]);
  // boss connection: from the rightmost normal room
  corr(order[order.length - 1], boss);
  // carpets in big rooms + pillars
  for (const r of rooms) {
    if (r.w >= 12 && r.h >= 9 || r.boss) {
      const cy = r.y + (r.h >> 1);
      for (let x = r.x + 1; x < r.x + r.w - 1; x++) for (let y = cy - 1; y <= cy + 1; y++) setG(m, x, y, G.CARPET);
      for (let x = r.x + 2; x < r.x + r.w - 2; x += 4) { addObj(m, { type: 'pillar', x, y: r.y + 1 }, true); addObj(m, { type: 'pillar', x, y: r.y + r.h - 2 }, true); }
    }
    // wall torches
    for (let x = r.x + 1; x < r.x + r.w - 1; x += 5) if (m.wall[idx(m, x, r.y - 1)]) { addObj(m, { type: 'torch', x, y: r.y - 1, wallTorch: 1 }); m.lights.push({ x, y: r.y - .5, r: 5, c: '255,150,60' }); }
    if (rng() < .5 && !r.boss) addObj(m, { type: 'statue', x: r.x + 1, y: r.y + r.h - 1 }, true);
  }
  // boss room: altar and braziers
  addObj(m, { type: 'altar', x: boss.x + 14, y: boss.y + 12, fw: 3, fh: 2 }, true);
  for (const [x, y] of [[boss.x + 3, boss.y + 3], [boss.x + 16, boss.y + 3], [boss.x + 3, boss.y + 20], [boss.x + 16, boss.y + 20]]) { addObj(m, { type: 'brazier', x, y }, true); m.lights.push({ x, y, r: 7, c: '255,140,50' }); }
  addObj(m, { type: 'stairs', x: 6, y: 49 });
  m.lights.push({ x: 6, y: 49, r: 6, c: '200,220,255' });
  m.portals.push({ x0: 5, y0: 49, x1: 6, y1: 50, to: 'mirewood', tx: 134, ty: 52, label: 'Mirewood Forest' });
  m.start = { x: 8, y: 50 };
  computeReach(m, 8, 50);
  m.zones = [
    { mons: ['moth', 'temple_archer'], dmin: 0, dmax: 30, n: 30 },
    { mons: ['temple_archer', 'stone_guardian', 'moth', 'cultist'], dmin: 25, dmax: 60, n: 45 },
    { mons: ['stone_guardian', 'cultist', 'khar_elite'], dmin: 55, dmax: 400, n: 40 },
  ];
  m.bosses = [{ mon: 'minotaur', x: boss.x + 10, y: boss.y + 12 }];
  return m;
}

/* ---------- ABYSSAL SANCTUM (raid) ---------- */
function genSanctum() {
  const W = 120, H = 60, rng = mulberry(666);
  const m = newMap('sanctum', 'Abyssal Sanctum', W, H, G.ABYSS);
  m.outdoor = false; m.dark = .8;
  for (let k = 0; k < W * H; k++) { m.wall[k] = 4; m.b[k] = 1; }
  const rooms = [{ x: 3, y: 24, w: 12, h: 12 }, { x: 24, y: 18, w: 18, h: 24 }, { x: 52, y: 16, w: 20, h: 28 }, { x: 82, y: 12, w: 34, h: 36, boss: 1 }];
  const carve = (x0, y0, w, h) => { for (let y = y0; y < y0 + h; y++) for (let x = x0; x < x0 + w; x++) { setWall(m, x, y, 0); setG(m, x, y, G.ABYSS); } };
  for (const r of rooms) carve(r.x, r.y, r.w, r.h);
  for (let i = 1; i < rooms.length; i++) { const a = rooms[i - 1], b = rooms[i]; carve(a.x + a.w - 1, 28, b.x - a.x - a.w + 2, 4); }
  for (const r of rooms) {
    const cy = r.y + (r.h >> 1);
    for (let x = r.x + 1; x < r.x + r.w - 1; x++) for (let y = cy - 1; y <= cy + 1; y++) setG(m, x, y, G.CARPET);
    for (let x = r.x + 2; x < r.x + r.w - 2; x += 5) { addObj(m, { type: 'pillar', x, y: r.y + 1, abyss: 1 }, true); addObj(m, { type: 'pillar', x, y: r.y + r.h - 2, abyss: 1 }, true); }
    for (let x = r.x + 2; x < r.x + r.w - 1; x += 6) { addObj(m, { type: 'torch', x, y: r.y - 1, wallTorch: 1 }); m.lights.push({ x, y: r.y - .5, r: 5, c: '190,90,255' }); }
    if (!r.boss && r.x > 10) for (let i = 0; i < 3; i++) { const x = r.x + 2 + (rng() * (r.w - 4) | 0), y = r.y + 2 + (rng() * (r.h - 4) | 0); if (!m.b[idx(m, x, y)]) addObj(m, { type: 'bones', x, y, v: rng() * 2 | 0 }); }
  }
  const B = rooms[3];
  addObj(m, { type: 'altar', x: B.x + 26, y: B.y + 19, fw: 3, fh: 2 }, true);
  for (const [x, y] of [[B.x + 4, B.y + 4], [B.x + 29, B.y + 4], [B.x + 4, B.y + 31], [B.x + 29, B.y + 31], [B.x + 16, B.y + 3], [B.x + 16, B.y + 32]]) { addObj(m, { type: 'brazier', x, y }, true); m.lights.push({ x, y, r: 8, c: '170,80,255' }); }
  addObj(m, { type: 'stairs', x: 5, y: 29 }); m.lights.push({ x: 5, y: 29, r: 6, c: '200,220,255' });
  m.portals.push({ x0: 4, y0: 29, x1: 5, y1: 30, to: 'ashvale', tx: 80, ty: 58, label: 'Leave raid' });
  m.start = { x: 8, y: 30 };
  computeReach(m, 8, 30);
  m.zones = [
    { mons: ['abyss_knight', 'wraith'], dmin: 14, dmax: 40, n: 10 },
    { mons: ['abyss_knight', 'lich_acolyte', 'wraith'], dmin: 40, dmax: 72, n: 14 },
  ];
  m.bosses = [{ mon: 'colossus', x: 62, y: 30 }, { mon: 'vaal', x: B.x + 20, y: B.y + 18 }];
  return m;
}

/* ================= GROUND TEXTURING (per-pixel, chunk-cached) ================= */
const CH = 8; // tiles per chunk
function groundColor(m, wx, wy) {
  const fx = wx / TW, fy = wy / TH;
  const j1 = vnoise(wx * .06, wy * .06, 101) - .5, j2 = vnoise(wx * .06 + 50, wy * .06, 102) - .5;
  let tx = Math.floor(fx + j1 * .55), ty = Math.floor(fy + j2 * .55);
  let g = getG(m, tx, ty);
  const own = getG(m, Math.floor(fx), Math.floor(fy));
  if (own === G.PAVE || own === G.TFLOOR || own === G.CARPET || own === G.FARM || g === G.VOID) g = own; // crisp edges for built surfaces
  if (g === G.PAVE || g === G.TFLOOR || g === G.CARPET) { if (own !== g) g = own; }
  const big = vnoise(wx * .005, wy * .005, 7) - .5;
  const h = hash2(wx, wy, 3), h2 = hash2(wx >> 1, wy >> 1, 4);
  let r, gg, b;
  switch (g) {
    case G.GRASS: case G.FLOWERS: case G.GRASS2: {
      const dk = g === G.GRASS2 ? -14 : 0;
      const n = vnoise(wx * .12, wy * .12, 11);
      r = 86 + big * 30 + n * 16 + dk; gg = 100 + big * 24 + n * 20 + dk; b = 50 + big * 10 + dk * .5;
      const dry = vnoise(wx * .012, wy * .012, 77); if (dry > .58) { const t = Math.min(1, (dry - .58) * 4); r = lerp(r, 138 + n * 14, t); gg = lerp(gg, 118 + n * 12, t); b = lerp(b, 74 + n * 8, t); }
      const blade = hash2(wx >> 1, Math.floor(wy / 4) + (wx & 1), 12);
      if (blade > .86) { r += 18; gg += 26; b += 6; } else if (blade < .1) { r -= 16; gg -= 20; b -= 8; }
      if (g === G.FLOWERS) { const fh = hash2(wx >> 2, wy >> 2, 13); if (fh > .965) { const c = hash2(wx >> 2, wy >> 2, 14); if (c < .33) { r = 230; gg = 220; b = 120; } else if (c < .66) { r = 210; gg = 120; b = 150; } else { r = 235; gg = 235; b = 230; } } }
      break;
    }
    case G.MOSS: {
      const n = vnoise(wx * .1, wy * .1, 15);
      r = 48 + big * 20 + n * 12; gg = 70 + big * 22 + n * 16; b = 38 + n * 8;
      if (h > .93) { r += 14; gg += 20; } if (h2 < .04) { r = 90; gg = 80; b = 60; }
      break;
    }
    case G.DIRT: case G.SAND: case G.FARM: {
      const n = vnoise(wx * .09, wy * .09, 16);
      if (g === G.SAND) { r = 176 + n * 18; gg = 158 + n * 16; b = 110 + n * 10; }
      else if (g === G.FARM) { const fur = Math.sin(wy * .45) * .5 + .5; r = 92 + fur * 22 + n * 10; gg = 66 + fur * 16 + n * 8; b = 42 + fur * 8; }
      else { r = 116 + n * 22 + big * 20; gg = 90 + n * 16 + big * 14; b = 60 + n * 10; }
      if (h > .94) { r += 22; gg += 20; b += 16; } else if (h < .05) { r -= 24; gg -= 20; b -= 14; }
      break;
    }
    case G.ROAD: {
      const cw = 13, chh = 9; const row = Math.floor(wy / chh); const ox = (row & 1) * 6; const col = Math.floor((wx + ox) / cw);
      const lx = (wx + ox) % cw, ly = wy % chh; const cv = hash2(col, row, 17);
      const edgeD = Math.min(lx, cw - 1 - lx, ly, chh - 1 - ly);
      r = 118 + cv * 30 + big * 16; gg = 110 + cv * 26 + big * 12; b = 96 + cv * 20;
      if (edgeD < 1) { r = 70; gg = 64; b = 52; } else if (edgeD < 2) { r -= 12; gg -= 12; b -= 10; } else if (ly < 3) { r += 10; gg += 10; b += 8; }
      if (h > .97) { r -= 20; gg -= 20; b -= 20; }
      break;
    }
    case G.PAVE: {
      const sw = 24, sh = 16; const row = Math.floor(wy / sh); const ox = (row & 1) * 12; const col = Math.floor((wx + ox) / sw);
      const lx = (wx + ox) % sw, ly = wy % sh; const cv = hash2(col, row, 18);
      r = 150 + cv * 22 + big * 14; gg = 138 + cv * 20 + big * 12; b = 116 + cv * 16;
      if (lx < 1 || ly < 1) { r = 92; gg = 84; b = 70; } else if (lx < 2 || ly < 2) { r -= 10; gg -= 10; b -= 8; } else if (lx > sw - 3 || ly > sh - 3) { r += 8; gg += 8; b += 6; }
      if (h > .985) { r -= 30; gg -= 30; b -= 30; }
      break;
    }
    case G.WATER: {
      const n = vnoise(wx * .03, wy * .05, 19), n2 = vnoise(wx * .15, wy * .3, 20);
      r = 30 + n * 16; gg = 64 + n * 24; b = 84 + n * 26;
      if (n2 > .78) { r += 30; gg += 36; b += 40; }
      break;
    }
    case G.CAVE: case G.CAVE2: {
      const n = vnoise(wx * .08, wy * .08, 21), n2 = vnoise(wx * .3, wy * .3, 22);
      r = 72 + n * 22 + big * 18; gg = 62 + n * 18 + big * 14; b = 54 + n * 14 + big * 10;
      if (g === G.CAVE2) { r -= 8; gg -= 6; b -= 2; }
      if (n2 > .8) { r += 16; gg += 14; b += 12; } else if (n2 < .15) { r -= 18; gg -= 16; b -= 14; }
      if (h > .97) { r += 30; gg += 28; b += 24; }
      break;
    }
    case G.TFLOOR: case G.CARPET: {
      const own2 = own;
      const lx = wx % TW, ly = wy % TH; const tv = hash2(Math.floor(wx / TW), Math.floor(wy / TH), 23);
      if (own2 === G.CARPET) {
        const ty2 = Math.floor(fy); const top = getG(m, Math.floor(fx), ty2 - 1) !== G.CARPET, bot = getG(m, Math.floor(fx), ty2 + 1) !== G.CARPET;
        r = 118 + big * 20; gg = 26; b = 34; const n = vnoise(wx * .2, wy * .2, 24); r += n * 16;
        if ((top && ly < 5) || (bot && ly > TH - 6)) { r = 186; gg = 146; b = 64; if ((top && ly < 2) || (bot && ly > TH - 3)) { r = 90; gg = 20; b = 20; } }
        else if ((wx % 24 === 12 || wy % 16 === 8) && ((wx + wy) % 3 === 0)) { r = 150; gg = 110; b = 50; }
      } else {
        r = 100 + tv * 18 + big * 16; gg = 94 + tv * 16 + big * 14; b = 84 + tv * 12 + big * 10;
        if (lx < 1 || ly < 1) { r = 52; gg = 48; b = 42; } else if (lx < 3 || ly < 2) { r += 14; gg += 13; b += 10; } else if (lx > TW - 3 || ly > TH - 3) { r -= 16; gg -= 15; b -= 12; }
        const crack = Math.abs(vnoise(wx * .05, wy * .05, 25 + (tv * 10 | 0)) - .5);
        if (crack < .012) { r -= 30; gg -= 30; b -= 26; }
        if (vnoise(wx * .04, wy * .04, 26) > .7) { r -= 8; gg += 6; b -= 10; } // moss tint
      }
      break;
    }
    case G.ABYSS: {
      const lx = wx % TW, ly = wy % TH; const tv = hash2(Math.floor(wx / TW), Math.floor(wy / TH), 41);
      r = 44 + tv * 12 + big * 10; gg = 38 + tv * 10 + big * 8; b = 54 + tv * 14 + big * 10;
      if (lx < 1 || ly < 1) { r = 18; gg = 14; b = 26; } else if (lx < 3 || ly < 2) { r += 10; gg += 8; b += 14; }
      const vein = Math.abs(vnoise(wx * .03, wy * .03, 42) - .5); if (vein < .009) { r = 120; gg = 60; b = 190; } else if (vein < .02) { r += 18; gg += 6; b += 38; }
      break;
    }
    default: r = 8; gg = 8; b = 10;
  }
  // subtle per-pixel grain
  const gr = (h - .5) * 8; return [r + gr, gg + gr, b + gr];
}
function buildChunk(m, cx, cy) {
  const cw = CH * TW, chh = CH * TH;
  const c = document.createElement('canvas'); c.width = cw; c.height = chh;
  const ctx = c.getContext('2d'); const img = ctx.createImageData(cw, chh); const d = img.data;
  const ox = cx * cw, oy = cy * chh;
  for (let y = 0; y < chh; y++) for (let x = 0; x < cw; x++) {
    const [r, g, b] = groundColor(m, ox + x, oy + y);
    const i = (y * cw + x) * 4; d[i] = r; d[i + 1] = g; d[i + 2] = b; d[i + 3] = 255;
  }
  ctx.putImageData(img, 0, 0);
  // ambient occlusion at walls base & water edges
  for (let ty = 0; ty < CH; ty++) for (let tx = 0; tx < CH; tx++) {
    const X = cx * CH + tx, Y = cy * CH + ty; if (!inb(m, X, Y)) continue; const k = idx(m, X, Y);
    const px = tx * TW, py = ty * TH;
    if (!m.wall[k]) {
      if (inb(m, X, Y - 1) && m.wall[idx(m, X, Y - 1)]) { const gr = ctx.createLinearGradient(0, py, 0, py + 18); gr.addColorStop(0, 'rgba(0,0,0,.55)'); gr.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = gr; ctx.fillRect(px, py, TW, 18); }
      if (inb(m, X - 1, Y) && m.wall[idx(m, X - 1, Y)]) { const gr = ctx.createLinearGradient(px, 0, px + 12, 0); gr.addColorStop(0, 'rgba(0,0,0,.35)'); gr.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = gr; ctx.fillRect(px, py, 12, TH); }
      if (inb(m, X + 1, Y) && m.wall[idx(m, X + 1, Y)]) { const gr = ctx.createLinearGradient(px + TW, 0, px + TW - 12, 0); gr.addColorStop(0, 'rgba(0,0,0,.35)'); gr.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = gr; ctx.fillRect(px + TW - 12, py, 12, TH); }
    } else { ctx.fillStyle = 'rgba(0,0,0,.6)'; ctx.fillRect(px, py, TW, TH); }
    if (m.g[k] === G.WATER && inb(m, X, Y - 1) && m.g[idx(m, X, Y - 1)] !== G.WATER) { ctx.fillStyle = 'rgba(0,0,0,.25)'; ctx.fillRect(px, py, TW, 5); }
  }
  // flat decor baked into ground
  return c;
}
function getChunk(m, cx, cy) {
  const key = cx + ',' + cy; let c = m.chunks.get(key);
  if (!c) { c = buildChunk(m, cx, cy); m.chunks.set(key, c); }
  return c;
}

/* ================= SPRITE CACHE: walls & objects ================= */
const SPR = new Map();
function sprite(key, w, h, fn) {
  let s = SPR.get(key); if (s) return s;
  const c = document.createElement('canvas'); c.width = w; c.height = h; const x = c.getContext('2d'); fn(x, w, h); SPR.set(key, c); return c;
}
function wallSprite(type, v, front, left, right) {
  const WH = WALLH[type];
  return sprite(`w${type}_${v}_${front}${left}${right}`, TW, TH + WH, (c) => {
    const top = TH; // top face 0..TH, front face TH..TH+WH
    if (type === 1) { // cave rock
      for (let y = 0; y < TH; y++) for (let x = 0; x < TW; x++) { const n = vnoise(x * .15 + v * 9, y * .2, 31); const l = 34 + n * 26; c.fillStyle = `rgb(${l + 6},${l},${l - 4})`; c.fillRect(x, y, 1, 1); }
      if (front) {
        for (let y = 0; y < WH; y++) for (let x = 0; x < TW; x++) {
          const n = vnoise(x * .12 + v * 7, y * .06, 32), s = vnoise(x * .5 + v, y * .04, 33);
          const t = y / WH; let l = 92 - t * 52 + n * 30 + (s > .7 ? 14 : 0);
          c.fillStyle = `rgb(${l + 10 | 0},${l + 2 | 0},${l - 8 | 0})`; c.fillRect(x, top + y, 1, 1);
        }
        const g = c.createLinearGradient(0, top, 0, top + 6); g.addColorStop(0, 'rgba(255,230,200,.25)'); g.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = g; c.fillRect(0, top, TW, 6);
      }
      if (left) { c.fillStyle = 'rgba(0,0,0,.35)'; c.fillRect(0, 0, 3, TH + (front ? WH : 0)); }
      if (right) { c.fillStyle = 'rgba(0,0,0,.35)'; c.fillRect(TW - 3, 0, 3, TH + (front ? WH : 0)); }
    } else if (type === 2) { // temple
      c.fillStyle = '#3a342c'; c.fillRect(0, 0, TW, TH);
      for (let y = 0; y < TH; y++) for (let x = 0; x < TW; x++) if (hash2(x, y, v) > .9) { c.fillStyle = 'rgba(0,0,0,.25)'; c.fillRect(x, y, 1, 1); }
      c.strokeStyle = 'rgba(255,240,200,.08)'; c.strokeRect(.5, .5, TW - 1, TH - 1);
      if (front) {
        const bh = 12;
        for (let r = 0; r * bh < WH; r++) {
          const off = (r & 1) * 12;
          for (let bx = -off; bx < TW; bx += 24) {
            const cv = hash2(bx + v * 5, r, 34); const l = 104 + cv * 26 - r * 5;
            c.fillStyle = `rgb(${l | 0},${l - 8 | 0},${l - 20 | 0})`; c.fillRect(bx + 1, top + r * bh + 1, 22, bh - 2);
            c.fillStyle = `rgba(255,240,210,.12)`; c.fillRect(bx + 1, top + r * bh + 1, 22, 2);
          }
        }
        c.fillStyle = '#6a5e4c'; c.fillRect(0, top, TW, 4);
        const g = c.createLinearGradient(0, top + WH - 14, 0, top + WH); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(0,0,0,.45)'); c.fillStyle = g; c.fillRect(0, top + WH - 14, TW, 14);
      }
      if (left) { c.fillStyle = 'rgba(0,0,0,.3)'; c.fillRect(0, 0, 3, TH + (front ? WH : 0)); }
      if (right) { c.fillStyle = 'rgba(0,0,0,.3)'; c.fillRect(TW - 3, 0, 3, TH + (front ? WH : 0)); }
    } else if (type === 4) { // obsidian
      c.fillStyle = '#16121e'; c.fillRect(0, 0, TW, TH); c.strokeStyle = 'rgba(180,100,255,.18)'; c.strokeRect(.5, .5, TW - 1, TH - 1);
      if (front) {
        const bh = 14;
        for (let r = 0; r * bh < WH; r++) { const off = (r & 1) * 12; for (let bx = -off; bx < TW; bx += 24) { const cv = hash2(bx + v * 5, r, 44); const l = 40 + cv * 18 - r * 3; c.fillStyle = `rgb(${l | 0},${l - 6 | 0},${l + 14 | 0})`; c.fillRect(bx + 1, top + r * bh + 1, 22, bh - 2); c.fillStyle = 'rgba(200,160,255,.08)'; c.fillRect(bx + 1, top + r * bh + 1, 22, 2); } }
        if (v % 2 === 0) { c.strokeStyle = 'rgba(190,100,255,.7)'; c.lineWidth = 1.2; c.beginPath(); c.moveTo(10 + v * 6, top + 6); c.lineTo(16 + v * 5, top + 26); c.lineTo(12 + v * 6, top + 44); c.stroke(); }
        c.fillStyle = '#2a2236'; c.fillRect(0, top, TW, 4);
        const g = c.createLinearGradient(0, top + WH - 16, 0, top + WH); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(0,0,0,.5)'); c.fillStyle = g; c.fillRect(0, top + WH - 16, TW, 16);
      }
      if (left) { c.fillStyle = 'rgba(0,0,0,.35)'; c.fillRect(0, 0, 3, TH + (front ? WH : 0)); }
      if (right) { c.fillStyle = 'rgba(0,0,0,.35)'; c.fillRect(TW - 3, 0, 3, TH + (front ? WH : 0)); }
    } else { // town wall
      c.fillStyle = '#8a8272'; c.fillRect(0, 0, TW, TH);
      c.fillStyle = '#a49a86'; c.fillRect(0, 0, TW, 6); c.fillStyle = '#6a6254'; c.fillRect(0, TH - 4, TW, 4);
      for (let i = 0; i < 3; i++) { c.fillStyle = '#9c927e'; c.fillRect(4 + i * 16, 6, 10, 10); c.fillStyle = 'rgba(0,0,0,.2)'; c.fillRect(4 + i * 16, 14, 10, 2); }
      if (front) {
        const bh = 10;
        for (let r = 0; r * bh < WH; r++) { const off = (r & 1) * 10; for (let bx = -off; bx < TW; bx += 20) { const cv = hash2(bx + v * 3, r, 35); const l = 150 + cv * 24 - r * 6; c.fillStyle = `rgb(${l | 0},${l - 8 | 0},${l - 22 | 0})`; c.fillRect(bx + 1, top + r * bh + 1, 18, bh - 2); } }
        const g = c.createLinearGradient(0, top + WH - 12, 0, top + WH); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(0,0,0,.4)'); c.fillStyle = g; c.fillRect(0, top + WH - 12, TW, 12);
      }
      if (left) { c.fillStyle = 'rgba(0,0,0,.25)'; c.fillRect(0, 0, 2, TH + (front ? WH : 0)); }
      if (right) { c.fillStyle = 'rgba(0,0,0,.25)'; c.fillRect(TW - 2, 0, 2, TH + (front ? WH : 0)); }
    }
  });
}
function treeSprite(v, dark, pine) {
  return sprite(`tree${v}${dark ? 'd' : ''}${pine ? 'p' : ''}`, 120, 170, (c, w, h) => {
    const cx = 60, base = 160;
    c.fillStyle = 'rgba(0,0,0,.28)'; c.beginPath(); c.ellipse(cx + 6, base - 2, 34, 11, 0, 0, 7); c.fill();
    const tr = c.createLinearGradient(cx - 7, 0, cx + 7, 0); tr.addColorStop(0, '#3a2718'); tr.addColorStop(.5, '#5e4128'); tr.addColorStop(1, '#2a1c10');
    c.fillStyle = tr; c.beginPath(); c.moveTo(cx - 8, base); c.lineTo(cx - 5, base - 60); c.lineTo(cx + 5, base - 60); c.lineTo(cx + 9, base); c.fill();
    const rng = mulberry(v * 97 + (dark ? 5 : 0) + (pine ? 11 : 0));
    const hues = dark ? [[34, 64, 34], [44, 78, 40], [58, 96, 48]] : [[48, 88, 38], [64, 110, 46], [88, 136, 58]];
    if (pine) {
      for (let i = 0; i < 5; i++) {
        const yy = base - 40 - i * 22, ww = 44 - i * 7;
        for (let k = 0; k < 3; k++) { const [r, g, b] = hues[k]; c.fillStyle = `rgb(${r - 10},${g},${b + 6})`; c.beginPath(); c.moveTo(cx - ww + k * 4, yy); c.lineTo(cx + k * 2, yy - 38 + k * 4); c.lineTo(cx + ww - k * 6, yy); c.closePath(); c.fill(); }
      }
    } else {
      const blobs = [];
      for (let i = 0; i < 16; i++) { const a = rng() * Math.PI * 2, rr = rng() * 26; blobs.push([cx + Math.cos(a) * rr * 1.2, base - 90 + Math.sin(a) * rr * .9 - rng() * 10, 16 + rng() * 12]); }
      blobs.sort((a, b) => a[1] - b[1]);
      for (let k = 0; k < 3; k++) for (const [bx, by, br] of blobs) {
        const [r, g, b] = hues[k]; c.fillStyle = `rgb(${r},${g},${b})`;
        c.beginPath(); c.arc(bx - k * 3 + 2, by - k * 4 + 4, br * (1 - k * .22), 0, 7); c.fill();
      }
      for (let i = 0; i < 90; i++) { const [bx, by, br] = blobs[rng() * blobs.length | 0]; const a = rng() * 7, rr = rng() * br; c.fillStyle = rng() < .5 ? `rgba(255,255,200,.12)` : 'rgba(0,20,0,.2)'; c.fillRect(bx + Math.cos(a) * rr - 4, by + Math.sin(a) * rr - 6, 3, 2); }
    }
  });
}
function objSprite(o) {
  switch (o.type) {
    case 'tree': case 'pine': return { s: treeSprite(o.v, o.dark, o.type === 'pine'), ax: 60, ay: 160, sc: o.s || 1 };
    case 'rock': return { s: sprite('rock' + o.v, 60, 50, (c) => { c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(32, 42, 24, 7, 0, 0, 7); c.fill(); const rng = mulberry(o.v + 3); c.beginPath(); c.moveTo(8, 42); for (let i = 0; i <= 8; i++) { const a = Math.PI + i / 8 * Math.PI; c.lineTo(30 + Math.cos(a) * (20 + rng() * 6), 40 + Math.sin(a) * (22 + rng() * 8)); } c.closePath(); const g = c.createLinearGradient(0, 14, 0, 44); g.addColorStop(0, '#a8a296'); g.addColorStop(1, '#5a564e'); c.fillStyle = g; c.fill(); c.strokeStyle = 'rgba(0,0,0,.3)'; c.stroke(); c.fillStyle = 'rgba(255,255,255,.15)'; c.beginPath(); c.ellipse(24, 26, 8, 4, -.4, 0, 7); c.fill(); }), ax: 30, ay: 44 };
    case 'bush': return { s: sprite('bush' + o.v, 50, 40, (c) => { c.fillStyle = 'rgba(0,0,0,.25)'; c.beginPath(); c.ellipse(26, 34, 18, 5, 0, 0, 7); c.fill(); const cols = ['#3e6a2e', '#4e7e38', '#6a9a48']; for (let k = 0; k < 3; k++) { c.fillStyle = cols[k]; for (let i = 0; i < 5; i++) { c.beginPath(); c.arc(12 + i * 6.5, 26 - k * 3 - Math.sin(i) * 3, 9 - k * 2, 0, 7); c.fill(); } } if (o.v) { c.fillStyle = '#c83a3a'; for (let i = 0; i < 6; i++) { c.beginPath(); c.arc(12 + i * 5, 20 + (i % 2) * 5, 1.8, 0, 7); c.fill(); } } }), ax: 25, ay: 34 };
    case 'crop': return { s: sprite('crop' + o.v, 30, 34, (c) => { c.strokeStyle = o.v === 2 ? '#c9a84a' : '#6a9a3a'; c.lineWidth = 2; for (let i = 0; i < 4; i++) { c.beginPath(); c.moveTo(8 + i * 5, 30); c.quadraticCurveTo(6 + i * 5, 16, 10 + i * 4, 6 + i % 2 * 3); c.stroke(); } if (o.v === 2) { c.fillStyle = '#e0c060'; for (let i = 0; i < 4; i++) c.fillRect(8 + i * 4, 4 + i % 2 * 3, 3, 6); } }), ax: 15, ay: 30 };
    case 'mushroom': return { s: sprite('mush' + o.v, 24, 20, (c) => { c.fillStyle = '#e8dcc0'; c.fillRect(10, 10, 4, 8); c.fillStyle = o.v ? '#b83a2a' : '#8a6a3a'; c.beginPath(); c.ellipse(12, 10, 9, 5, 0, Math.PI, 0); c.fill(); c.fillStyle = '#fff'; c.fillRect(8, 7, 2, 2); c.fillRect(14, 6, 2, 2); }), ax: 12, ay: 18 };
    case 'lamp': return { s: sprite('lamp', 24, 84, (c) => { c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(12, 80, 9, 3, 0, 0, 7); c.fill(); c.fillStyle = '#2a2622'; c.fillRect(10, 20, 4, 60); c.fillRect(6, 76, 12, 5); c.fillStyle = '#3a342c'; c.fillRect(5, 6, 14, 16); c.fillStyle = '#ffd88a'; c.fillRect(7, 8, 10, 12); c.fillStyle = '#2a2622'; c.fillRect(4, 3, 16, 4); c.fillRect(11, 8, 2, 12); }), ax: 12, ay: 80 };
    case 'barrel': return { s: sprite('barrel', 34, 44, (c) => { c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(17, 40, 14, 4, 0, 0, 7); c.fill(); const g = c.createLinearGradient(4, 0, 30, 0); g.addColorStop(0, '#5a3a1e'); g.addColorStop(.5, '#8a5e32'); g.addColorStop(1, '#4a2e16'); c.fillStyle = g; c.beginPath(); c.ellipse(17, 26, 13, 15, 0, 0, 7); c.fill(); c.fillStyle = '#6a4a2a'; c.beginPath(); c.ellipse(17, 12, 11, 4, 0, 0, 7); c.fill(); c.fillStyle = '#3a3a3a'; c.fillRect(5, 17, 24, 2); c.fillRect(5, 33, 24, 2); }), ax: 17, ay: 40 };
    case 'crate': return { s: sprite('crate', 40, 44, (c) => { c.fillStyle = 'rgba(0,0,0,.3)'; c.fillRect(6, 36, 32, 6); c.fillStyle = '#9a7040'; c.fillRect(4, 14, 30, 24); c.fillStyle = '#b8884e'; c.fillRect(4, 6, 30, 9); c.strokeStyle = '#5a3e1e'; c.lineWidth = 2; c.strokeRect(5, 15, 28, 22); c.beginPath(); c.moveTo(5, 15); c.lineTo(33, 37); c.stroke(); }), ax: 19, ay: 38 };
    case 'crystal': return { s: sprite('crys' + o.v, 40, 54, (c) => { c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(20, 48, 14, 4, 0, 0, 7); c.fill(); const cols = [['#6ab0ff', '#b8e0ff'], ['#b070ff', '#e0c0ff'], ['#60e0c0', '#c0fff0']][o.v]; for (let i = 0; i < 4; i++) { const x = 8 + i * 7, hh = 20 + ((i * 7) % 13) + (i === 1 ? 14 : 0); c.fillStyle = cols[0]; c.beginPath(); c.moveTo(x, 48); c.lineTo(x + 3, 48 - hh); c.lineTo(x + 8, 48); c.fill(); c.fillStyle = cols[1]; c.beginPath(); c.moveTo(x + 2, 46); c.lineTo(x + 3, 48 - hh); c.lineTo(x + 4, 46); c.fill(); } }), ax: 20, ay: 48, glow: 1 };
    case 'bones': return { s: sprite('bones' + o.v, 40, 24, (c) => { c.strokeStyle = '#d8d0b8'; c.lineWidth = 3; c.lineCap = 'round'; c.beginPath(); c.moveTo(6, 16); c.lineTo(26, 10); c.moveTo(12, 6); c.lineTo(20, 20); c.stroke(); c.fillStyle = '#e8e0cc'; c.beginPath(); c.arc(30, 14, 5, 0, 7); c.fill(); c.fillStyle = '#222'; c.fillRect(28, 13, 2, 2); c.fillRect(31, 13, 2, 2); }), ax: 20, ay: 18 };
    case 'minecart': return { s: sprite('cart', 56, 48, (c) => { c.fillStyle = 'rgba(0,0,0,.3)'; c.fillRect(8, 40, 42, 6); c.fillStyle = '#4a3a2a'; c.fillRect(8, 16, 40, 22); c.fillStyle = '#6a5a4a'; c.fillRect(6, 12, 44, 6); c.fillStyle = '#3a3a44'; for (let i = 0; i < 6; i++) { c.beginPath(); c.arc(14 + i * 6, 12, 5, 0, 7); c.fill(); } c.fillStyle = '#222'; c.beginPath(); c.arc(16, 40, 6, 0, 7); c.arc(40, 40, 6, 0, 7); c.fill(); }), ax: 28, ay: 42 };
    case 'torch': return { s: sprite('torch', 20, 40, (c) => { c.fillStyle = '#3a2a1a'; c.fillRect(8, 16, 4, 20); c.fillStyle = '#5a5a5a'; c.fillRect(6, 30, 8, 3); }), ax: 10, ay: 40, flame: 1 };
    case 'ladder': return { s: sprite('ladder', 50, 70, (c) => { c.fillStyle = 'rgba(0,0,0,.5)'; c.beginPath(); c.ellipse(25, 62, 22, 8, 0, 0, 7); c.fill(); c.strokeStyle = '#8a6a3a'; c.lineWidth = 4; c.beginPath(); c.moveTo(14, 64); c.lineTo(16, 4); c.moveTo(36, 64); c.lineTo(34, 4); c.stroke(); c.lineWidth = 3; for (let y = 10; y < 62; y += 10) { c.beginPath(); c.moveTo(15, y); c.lineTo(35, y); c.stroke(); } }), ax: 25, ay: 62 };
    case 'stairs': return { s: sprite('stairs', 96, 70, (c) => { for (let i = 0; i < 6; i++) { const l = 140 - i * 16; c.fillStyle = `rgb(${l},${l - 6},${l - 16})`; c.fillRect(8 + i * 2, 10 + i * 9, 80 - i * 4, 10); c.fillStyle = 'rgba(0,0,0,.3)'; c.fillRect(8 + i * 2, 18 + i * 9, 80 - i * 4, 2); } }), ax: 30, ay: 60 };
    case 'pillar': return { s: sprite('pillar', 44, 120, (c) => { c.fillStyle = 'rgba(0,0,0,.35)'; c.beginPath(); c.ellipse(24, 112, 20, 6, 0, 0, 7); c.fill(); c.fillStyle = '#6a6254'; c.fillRect(4, 100, 36, 12); c.fillRect(4, 8, 36, 12); const g = c.createLinearGradient(8, 0, 36, 0); g.addColorStop(0, '#5a5448'); g.addColorStop(.35, '#a49a86'); g.addColorStop(1, '#4a4438'); c.fillStyle = g; c.fillRect(9, 18, 26, 84); c.strokeStyle = 'rgba(0,0,0,.2)'; for (let x = 14; x < 34; x += 5) { c.beginPath(); c.moveTo(x, 20); c.lineTo(x, 100); c.stroke(); } c.fillStyle = '#8a8272'; c.fillRect(2, 4, 40, 6); }), ax: 22, ay: 110 };
    case 'statue': return { s: sprite('statue', 50, 110, (c) => { c.fillStyle = 'rgba(0,0,0,.35)'; c.beginPath(); c.ellipse(25, 104, 20, 6, 0, 0, 7); c.fill(); c.fillStyle = '#6a6254'; c.fillRect(6, 86, 38, 18); const g = c.createLinearGradient(10, 0, 40, 0); g.addColorStop(0, '#5a5448'); g.addColorStop(.4, '#9a927e'); g.addColorStop(1, '#4a4438'); c.fillStyle = g; c.beginPath(); c.moveTo(12, 86); c.lineTo(15, 40); c.lineTo(35, 40); c.lineTo(38, 86); c.fill(); c.beginPath(); c.arc(25, 30, 10, 0, 7); c.fill(); c.beginPath(); c.moveTo(15, 26); c.quadraticCurveTo(4, 18, 8, 8); c.lineTo(17, 22); c.moveTo(35, 26); c.quadraticCurveTo(46, 18, 42, 8); c.lineTo(33, 22); c.fill(); }), ax: 25, ay: 104 };
    case 'altar': return { s: sprite('altar', 150, 110, (c) => { c.fillStyle = 'rgba(0,0,0,.4)'; c.fillRect(6, 92, 140, 14); c.fillStyle = '#4a4238'; c.fillRect(8, 60, 136, 40); c.fillStyle = '#6a6050'; c.fillRect(4, 50, 144, 12); c.fillStyle = '#8a1a14'; c.fillRect(40, 50, 72, 50); c.fillStyle = '#c9a040'; c.fillRect(40, 50, 72, 4); c.fillStyle = '#2a2420'; c.beginPath(); c.moveTo(60, 50); c.lineTo(76, 10); c.lineTo(92, 50); c.fill(); c.fillStyle = '#ff9a3a'; c.beginPath(); c.arc(76, 28, 5, 0, 7); c.fill(); }), ax: 20, ay: 100, glow: 1 };
    case 'brazier': return { s: sprite('brazier', 40, 60, (c) => { c.fillStyle = 'rgba(0,0,0,.35)'; c.beginPath(); c.ellipse(20, 56, 14, 4, 0, 0, 7); c.fill(); c.fillStyle = '#3a3028'; c.fillRect(17, 30, 6, 26); c.fillRect(10, 52, 20, 4); c.fillStyle = '#5a4a3a'; c.beginPath(); c.moveTo(4, 22); c.lineTo(36, 22); c.lineTo(30, 34); c.lineTo(10, 34); c.fill(); }), ax: 20, ay: 56, flame: 2 };
    case 'fountain': return { s: sprite('fountain', 160, 130, (c) => {
      c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(78, 106, 70, 20, 0, 0, 7); c.fill();
      c.fillStyle = '#8a8272'; c.beginPath(); c.ellipse(76, 96, 68, 24, 0, 0, 7); c.fill(); c.fillStyle = '#a49a86'; c.beginPath(); c.ellipse(76, 90, 68, 24, 0, 0, 7); c.fill();
      c.fillStyle = '#3a6a8a'; c.beginPath(); c.ellipse(76, 90, 58, 18, 0, 0, 7); c.fill(); c.fillStyle = 'rgba(180,220,255,.25)'; c.beginPath(); c.ellipse(64, 86, 30, 7, 0, 0, 7); c.fill();
      c.fillStyle = '#9a927e'; c.fillRect(70, 44, 12, 46); c.beginPath(); c.ellipse(76, 46, 22, 7, 0, 0, 7); c.fill();
      c.fillStyle = '#b0a894'; c.beginPath(); c.ellipse(76, 44, 20, 6, 0, 0, 7); c.fill(); c.fillStyle = '#4a7a9a'; c.beginPath(); c.ellipse(76, 44, 16, 4, 0, 0, 7); c.fill();
    }), ax: 4, ay: 110, water: 1 };
    case 'cave_mouth': return { s: sprite('cavemouth', 260, 180, (c) => {
      c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(128, 160, 120, 22, 0, 0, 7); c.fill();
      const rng = mulberry(5);
      for (let i = 0; i < 26; i++) { const x = 20 + rng() * 220, y = 40 + rng() * 110, r = 20 + rng() * 28; const g = c.createRadialGradient(x - 8, y - 10, 2, x, y, r); g.addColorStop(0, '#9a9284'); g.addColorStop(1, '#4a463e'); c.fillStyle = g; c.beginPath(); c.arc(x, y, r, 0, 7); c.fill(); }
      c.fillStyle = '#0a0806'; c.beginPath(); c.moveTo(78, 160); c.quadraticCurveTo(80, 84, 128, 80); c.quadraticCurveTo(176, 84, 178, 160); c.fill();
      const g = c.createLinearGradient(0, 80, 0, 160); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(255,140,60,.12)'); c.fillStyle = g; c.fill();
      c.strokeStyle = '#6a4a2a'; c.lineWidth = 7; c.beginPath(); c.moveTo(84, 162); c.lineTo(88, 92); c.lineTo(168, 92); c.lineTo(172, 162); c.stroke();
    }), ax: 8, ay: 160 };
    case 'temple_gate': return { s: sprite('tgate', 260, 200, (c) => {
      c.fillStyle = 'rgba(0,0,0,.35)'; c.fillRect(10, 176, 240, 16);
      const col = (x) => { const g = c.createLinearGradient(x, 0, x + 34, 0); g.addColorStop(0, '#5a5448'); g.addColorStop(.4, '#a49a86'); g.addColorStop(1, '#4a4438'); c.fillStyle = g; c.fillRect(x, 40, 34, 140); c.fillStyle = '#6a6254'; c.fillRect(x - 4, 170, 42, 12); };
      col(30); col(196);
      c.fillStyle = '#7a7262'; c.fillRect(14, 20, 232, 26); c.fillStyle = '#8a8272'; c.fillRect(10, 14, 240, 10);
      c.fillStyle = '#0c0a08'; c.fillRect(64, 46, 132, 134); const g = c.createLinearGradient(0, 46, 0, 180); g.addColorStop(0, 'rgba(255,120,40,.02)'); g.addColorStop(1, 'rgba(255,120,40,.18)'); c.fillStyle = g; c.fillRect(64, 46, 132, 134);
      c.fillStyle = '#c9a040'; c.font = 'bold 13px serif'; c.textAlign = 'center'; c.fillText('ᛟ ᚲ ᚺ ᚨ ᚱ ᛟ', 130, 38);
      c.fillStyle = 'rgba(60,100,40,.6)'; for (let i = 0; i < 40; i++) c.fillRect(14 + Math.random() * 230, 14 + Math.random() * 30, 3, 6 + Math.random() * 14);
    }), ax: 10, ay: 180 };
    case 'sign': return { s: sprite('sign' + o.text, 90, 70, (c) => { c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(45, 64, 12, 3, 0, 0, 7); c.fill(); c.fillStyle = '#4a321a'; c.fillRect(42, 26, 6, 38); c.fillStyle = '#8a6438'; c.fillRect(6, 10, 78, 22); c.strokeStyle = '#4a321a'; c.lineWidth = 2; c.strokeRect(6, 10, 78, 22); c.fillStyle = '#2a1a0a'; c.font = 'bold 11px Georgia, serif'; c.textAlign = 'center'; c.fillText(o.text, 45, 25); }), ax: 45, ay: 64 };
    case 'house': return { s: houseSprite(o), ax: 0, ay: 5 * 0 + 150, footprint: 1 };
  }
  return null;
}
const ROLE_ICON = { weapons: '⚔', armour: '⛨', jeweler: '◈', potions: '⚗', books: '❦', smith: '⚒', storage: '▣', guild: '⚑' };
function houseSprite(o) {
  return sprite('house' + o.role, 5 * TW, 150 + 10, (c) => {
    const w = 5 * TW, base = 150; // bottom of footprint at y=150
    const wallTop = base - 62, depth = 3 * TH;
    c.fillStyle = 'rgba(0,0,0,.35)'; c.fillRect(6, base - 6, w - 4, 14);
    // front wall
    const g = c.createLinearGradient(0, wallTop, 0, base); g.addColorStop(0, '#d8cbb0'); g.addColorStop(1, '#b8a88a'); c.fillStyle = g; c.fillRect(6, wallTop, w - 12, base - wallTop);
    c.fillStyle = '#6a6254'; c.fillRect(4, base - 12, w - 8, 12);
    c.fillStyle = '#4a3220'; c.fillRect(6, wallTop, w - 12, 6); for (const x of [6, w / 2 - 3, w - 12]) c.fillRect(x, wallTop, 6, base - wallTop - 12);
    c.beginPath(); c.moveTo(12, wallTop + 6); c.lineTo(w / 2 - 3, base - 14); c.moveTo(w - 12, wallTop + 6); c.lineTo(w / 2 + 3, base - 14); c.lineWidth = 4; c.strokeStyle = '#4a3220'; c.stroke();
    // door
    c.fillStyle = '#3a2412'; c.beginPath(); c.moveTo(w / 2 - 15, base - 2); c.lineTo(w / 2 - 15, base - 38); c.quadraticCurveTo(w / 2, base - 50, w / 2 + 15, base - 38); c.lineTo(w / 2 + 15, base - 2); c.fill();
    c.fillStyle = '#6a4424'; c.fillRect(w / 2 - 12, base - 38, 24, 36); c.fillStyle = '#c9a040'; c.fillRect(w / 2 + 6, base - 20, 3, 3);
    // windows
    for (const x of [36, w - 64]) { c.fillStyle = '#2a2016'; c.fillRect(x, wallTop + 16, 28, 22); c.fillStyle = '#ffcf7a'; c.fillRect(x + 3, wallTop + 19, 22, 16); c.fillStyle = '#2a2016'; c.fillRect(x + 13, wallTop + 19, 2, 16); c.fillRect(x + 3, wallTop + 26, 22, 2); }
    // roof
    const rTop = wallTop - depth + 6;
    const rg = c.createLinearGradient(0, rTop, 0, wallTop + 4); rg.addColorStop(0, shade(o.roof, .15)); rg.addColorStop(1, shade(o.roof, -.35));
    c.fillStyle = rg; c.beginPath(); c.moveTo(-2, wallTop + 6); c.lineTo(14, rTop); c.lineTo(w - 14, rTop); c.lineTo(w + 2, wallTop + 6); c.closePath(); c.fill();
    c.strokeStyle = 'rgba(0,0,0,.25)'; c.lineWidth = 1;
    for (let y = rTop + 8; y < wallTop + 6; y += 8) { c.beginPath(); const t = (y - rTop) / (wallTop + 6 - rTop); c.moveTo(14 - 16 * t, y); c.lineTo(w - 14 + 16 * t, y); c.stroke(); for (let x = 20 + ((y / 8) % 2) * 8; x < w - 14; x += 16) { c.beginPath(); c.moveTo(x, y - 8); c.lineTo(x, y); c.stroke(); } }
    c.fillStyle = shade(o.roof, -.5); c.fillRect(10, rTop - 4, w - 20, 6);
    c.fillStyle = 'rgba(0,0,0,.35)'; c.fillRect(-2, wallTop + 4, w + 4, 4);
    // chimney
    c.fillStyle = '#6a5e50'; c.fillRect(w - 50, rTop - 26, 14, 28); c.fillStyle = '#4a4238'; c.fillRect(w - 52, rTop - 30, 18, 5);
    // sign
    c.fillStyle = '#3a2412'; c.fillRect(w / 2 - 34, wallTop - 4, 68, 4);
    c.fillStyle = '#8a6438'; c.fillRect(w / 2 - 20, wallTop - 20, 40, 18); c.strokeStyle = '#3a2412'; c.lineWidth = 2; c.strokeRect(w / 2 - 20, wallTop - 20, 40, 18);
    c.fillStyle = '#f4e4b0'; c.font = '14px serif'; c.textAlign = 'center'; c.textBaseline = 'middle'; c.fillText(ROLE_ICON[o.role] || '', w / 2, wallTop - 11);
  });
}

function buildMinimap(m) {
  const c = document.createElement('canvas'); c.width = m.w; c.height = m.h; const x = c.getContext('2d'); const img = x.createImageData(m.w, m.h);
  const col = { [G.ABYSS]: [50, 40, 64], [G.GRASS]: [70, 104, 48], [G.GRASS2]: [58, 90, 40], [G.FLOWERS]: [80, 110, 56], [G.DIRT]: [120, 94, 62], [G.ROAD]: [150, 140, 120], [G.PAVE]: [170, 160, 140], [G.WATER]: [40, 80, 110], [G.CAVE]: [90, 78, 66], [G.CAVE2]: [84, 72, 62], [G.TFLOOR]: [110, 104, 92], [G.CARPET]: [120, 40, 40], [G.SAND]: [180, 160, 110], [G.MOSS]: [52, 76, 42], [G.FARM]: [100, 74, 48], [G.VOID]: [10, 10, 10] };
  for (let y = 0; y < m.h; y++) for (let X = 0; X < m.w; X++) {
    const k = idx(m, X, y); let c3 = col[m.g[k]] || [0, 0, 0];
    if (m.wall[k]) c3 = m.wall[k] === 3 ? [200, 190, 170] : m.wall[k] === 4 ? [14, 10, 20] : [24, 20, 18];
    else if (m.b[k] === 1) c3 = m.outdoor ? [30, 56, 26] : [60, 54, 46];
    const i = k * 4; img.data[i] = c3[0]; img.data[i + 1] = c3[1]; img.data[i + 2] = c3[2]; img.data[i + 3] = 255;
  }
  for (const o of m.objs) if (o.type === 'house') for (let j = 0; j < 3; j++) for (let i = 0; i < 5; i++) { const k = idx(m, o.x + i, o.y - j) * 4; img.data[k] = 150; img.data[k + 1] = 70; img.data[k + 2] = 50; }
  x.putImageData(img, 0, 0); m.mini = c;
}
