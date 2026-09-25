/* ================= RENDERER ================= */
const APP = document.getElementById('app'), cv = document.getElementById('cv'), ctx = cv.getContext('2d');
const lightCv = document.createElement('canvas'), lctx = lightCv.getContext('2d');
const tintCv = document.createElement('canvas'), tctx = tintCv.getContext('2d');
const LRES = 4;
let DPR = 1;
function resize() {
  DPR = Math.min(2, window.devicePixelRatio || 1);
  S.vw = APP.clientWidth; S.vh = APP.clientHeight; cv.width = Math.round(S.vw * DPR); cv.height = Math.round(S.vh * DPR);
  S.hudH = document.getElementById('hud').offsetHeight;
  S.zoom = S.vw < 760 ? clamp(S.vw / (TW * 12), .55, 1) : clamp(Math.min(S.vw / (TW * 19), (S.vh - S.hudH) / (TH * 17)), .7, 1.6);
  lightCv.width = tintCv.width = Math.ceil(S.vw / LRES); lightCv.height = tintCv.height = Math.ceil(S.vh / LRES);
}
window.addEventListener('resize', resize);

function monLook(e) {
  const d = e.def;
  return { skin: d.skin, cloth: d.cloth, armor: { c: d.cloth || shade(d.skin, -.3), t: shade(d.cloth || d.skin, .3), style: d.helmet && !d.stone ? 'chain' : 'tunic' }, bone: d.bone, stone: d.stone, hunch: d.hunch, ears: d.ears, tail: d.tail, hat: d.hat, hood: d.hood, horns: d.horns, bull: d.bull, crown: d.crown, shield: d.shield, warpaint: d.warpaint, helm: d.helmet ? { c: d.stone ? '#7a7468' : '#8a929e', k: 'helm' } : null, weapon: d.weapon ? { k: d.weapon, c: d.stone ? '#8a8478' : d.boss ? '#e8eef4' : '#a8b0b8', glow: d.boss ? d.aura : null } : null, size: (d.size || 1) * HSC };
}
const HSC = 1.2;
function drawEntity(c, e) {
  const x = epx(e), y = epy(e);
  const fall = e.dead ? Math.min(1, e.deadT / .35) : 0;
  const life = e.kind === 'mon' ? 5 : 3;
  c.save();
  if (e.dead) c.globalAlpha = e.deadT > life - 1 ? Math.max(0, life - e.deadT) : 1;
  if (e.gone && e.dead) { c.restore(); return; }
  const tgt = S.player && S.player.target === e, hov = S.hover === e;
  if ((tgt || hov) && !e.dead) {
    const col = e.kind === 'npc' ? '255,220,120' : isEnemy(S.player, e) || e.kind === 'mon' ? '255,80,60' : '120,220,140';
    const sz = (e.def && e.def.size || 1);
    c.strokeStyle = `rgba(${col},${tgt ? .9 : .55})`; c.lineWidth = 2; c.beginPath(); c.ellipse(x, y, 16 * sz, 6 * sz, 0, 0, 7); c.stroke();
  }
  if (e.def && e.def.boss && !e.dead) { c.save(); c.globalCompositeOperation = 'lighter'; const a = .25 + Math.sin(S.time * 3) * .08; glow(c, x, y - 4, 50 * e.def.size, hexRgb(e.def.aura), a); c.restore(); }
  const flash = e.flashT > 0;
  if (e.kind === 'player' || e.kind === 'bot' || e.kind === 'npc' || e.kind === 'guard') {
    const L = e.kind === 'player' ? playerLook() : e.look;
    if (e.kind === 'player' && !e.dead) { const setN = e.st.setN || 0;
      if (e.buffs.lich) { c.save(); c.globalCompositeOperation = 'lighter'; glow(c, x, y - 30, 70, '150,60,255', .45 + Math.sin(S.time * 6) * .1); c.restore(); drawWings(c, x, y, '#2a1040', '#b070ff', S.time, HSC); }
      else if (e.buffs.dragon) { c.save(); c.globalCompositeOperation = 'lighter'; glow(c, x, y - 30, 70, '255,110,30', .4 + Math.sin(S.time * 8) * .1); c.restore(); drawWings(c, x, y, '#8a1a0a', '#ffb040', S.time * 1.3, HSC * 1.1); if (R() < .5) part(x + (R() - .5) * 30, y - R() * 50, { vy: -50, life: .5, max: .5, size: 3, col: '255,140,40' }); }
      else if (setN >= 4 && R() < .25) part(x + (R() - .5) * 26, y - R() * 40, { vy: -25, life: .8, max: .8, size: 2.2, col: '170,90,255' });
      if (e.buffs.sanct) { c.save(); c.globalCompositeOperation = 'lighter'; glow(c, x, y - 24, 46, '140,255,170', .35); c.restore(); }
    }
    drawHuman(c, x, y, Object.assign({}, L, { dir: e.dir, walk: e.walk, moving: e.mt < 1, idle: e.idle, atk: e.atk, cast: e.cast, flash, fall, size: HSC }));
    if (e.kind === 'npc' && e.def.role === 'quest') { const P = S.P, q = QUESTS[P.q]; const mark = q && ((!P.qa && P.lv >= q.lv) || (P.qa && P.qn >= q.n)); if (mark) { const by = y - 78 + Math.sin(S.time * 3) * 2; c.save(); c.globalCompositeOperation = 'lighter'; glow(c, x, by, 14, '255,220,60', .5); c.restore(); textOut(c, P.qa ? '?' : '!', x, by + 7, '#ffe04a', '800 22px "Alegreya Sans", sans-serif'); } }
    if (e.cast >= 0) { c.save(); c.globalCompositeOperation = 'lighter'; const col = e.kind === 'player' ? ({ M: '255,150,60', T: '255,240,150', W: '255,200,120' }[S.P.cls]) : e.cls === 'M' ? '255,150,60' : '255,240,150'; glow(c, x + (e.faceL ? -10 : 10), y - 40, 22, col, .6 * Math.sin(e.cast * Math.PI)); c.restore(); }
  } else if (e.kind === 'mon') {
    const d = e.def; const o = { col: d.col, size: d.size || 1, walk: e.walk, moving: e.mt < 1, idle: e.idle, atk: e.atk, flash, fall, faceL: e.faceL, tusks: d.tusks, antlers: d.antlers, wing: d.wing, moth: d.moth, mark: d.mark };
    switch (d.body) {
      case 'biped': drawHuman(c, x, y, Object.assign(monLook(e), { dir: e.dir, walk: e.walk, moving: e.mt < 1, idle: e.idle, atk: e.atk, cast: -1, flash, fall })); break;
      case 'quad': drawQuad(c, x, y, o); break; case 'hen': drawHen(c, x, y, o); break; case 'worm': drawWorm(c, x, y, o); break;
      case 'flyer': drawFlyer(c, x, y, o); break; case 'spider': drawSpider(c, x, y, o); break; case 'snake': drawSnake(c, x, y, o); break;
    }
    if (e.frozenT > 0 && !e.dead) { c.save(); c.globalCompositeOperation = 'lighter'; const sz2 = d.size || 1; c.fillStyle = 'rgba(150,220,255,.28)'; c.beginPath(); c.ellipse(x, y - 20 * sz2, 18 * sz2, 26 * sz2, 0, 0, 7); c.fill(); c.strokeStyle = 'rgba(210,245,255,.7)'; c.lineWidth = 1.2; c.stroke(); c.restore(); }
    if (e.stunT > 0 && !e.dead && !(e.frozenT > 0)) { for (let i = 0; i < 3; i++) { const a = S.time * 5 + i * 2.1; c.fillStyle = '#ffe070'; c.beginPath(); c.arc(x + Math.cos(a) * 10, y - 48 * (d.size || 1) + Math.sin(a) * 3, 2, 0, 7); c.fill(); } }
  } else if (e.kind === 'pet') {
    if (e.abyss && !e.dead) { c.save(); c.globalCompositeOperation = 'lighter'; glow(c, x, y - 20, 40, '160,70,255', .35); c.restore(); }
    if (e.petType === 'hound') drawSummonHound(c, x, y, { walk: e.walk, moving: e.mt < 1, idle: e.idle, atk: e.atk, flash, fall, faceL: e.faceL, size: 1.1 });
    else drawHuman(c, x, y, { bone: 1, skin: '#e8e2cc', cloth: '#3a2a5a', weapon: { k: 'sword', c: '#c8d0d8' }, shield: 1, helm: e.rank >= 2 ? { c: '#8a929e', k: 'nasal' } : null, dir: e.dir, walk: e.walk, moving: e.mt < 1, idle: e.idle, atk: e.atk, cast: -1, flash, fall, size: HSC * (1 + e.rank * .05) });
  }
  if (!e.dead) {
    if (e.buffs.shield) { c.save(); c.globalCompositeOperation = 'lighter'; const a = .18 + Math.sin(S.time * 4) * .05; c.fillStyle = `rgba(110,170,255,${a})`; c.strokeStyle = `rgba(170,210,255,${a + .25})`; c.lineWidth = 1.5; c.beginPath(); c.ellipse(x, y - 22, 20, 29, 0, 0, 7); c.fill(); c.stroke(); c.restore(); }
    if (e.buffs.soulshield) { c.save(); c.globalCompositeOperation = 'lighter'; c.strokeStyle = `rgba(255,215,120,${.35 + Math.sin(S.time * 3) * .1})`; c.lineWidth = 2; c.beginPath(); c.ellipse(x, y, 20, 7, 0, 0, 7); c.stroke(); c.restore(); }
    if (e.buffs.flaming && R() < .6) part(x + (e.faceL ? -14 : 14) + (R() - .5) * 8, y - 30 - R() * 14, { vy: -40, life: .4, max: .4, size: 3, col: '255,130,40' });
    if (e.poison && R() < .2) part(x + (R() - .5) * 14, y - 20 - R() * 20, { vy: -25, life: .6, max: .6, size: 2.5, col: '120,255,90' });
    if (e.slowT > 0 && R() < .15) part(x + (R() - .5) * 18, y - R() * 30, { vy: 20, life: .5, max: .5, size: 2, col: '190,230,255' });
  }
  c.restore();
}
function hexRgb(h) { if (!h) return '255,255,255'; const c = h.replace('#', ''); return `${parseInt(c.slice(0, 2), 16)},${parseInt(c.slice(2, 4), 16)},${parseInt(c.slice(4, 6), 16)}`; }

function drawObj(c, o, px, py) {
  const s = objSprite(o); if (!s) return;
  const sc = s.sc || 1;
  let alpha = 1;
  if ((o.type === 'tree' || o.type === 'pine') && S.player) { const p = S.player; const ex = epx(p), ey = epy(p); if (ey < py - 4 && ey > py - 140 * sc && Math.abs(ex - px) < 44 * sc) alpha = .45; }
  c.globalAlpha = alpha;
  c.drawImage(s.s, Math.round(px - s.ax * sc), Math.round(py - s.ay * sc), s.s.width * sc, s.s.height * sc);
  c.globalAlpha = 1;
  if (s.flame) { const fy = s.flame === 2 ? py - 38 : py - 30, fl = Math.sin(S.time * 17 + o.x) * .15 + Math.sin(S.time * 7 + o.y) * .1;
    c.save(); c.globalCompositeOperation = 'lighter'; glow(c, px, fy, 24 + fl * 20, '255,140,40', .55);
    c.fillStyle = 'rgba(255,190,80,.9)'; c.beginPath(); c.moveTo(px - 5, fy + 4); c.quadraticCurveTo(px - 4, fy - 8, px + fl * 10, fy - 14 - (s.flame === 2 ? 8 : 0)); c.quadraticCurveTo(px + 5, fy - 6, px + 5, fy + 4); c.fill();
    c.fillStyle = 'rgba(255,250,200,.9)'; c.beginPath(); c.ellipse(px, fy, 2.5, 4, 0, 0, 7); c.fill(); c.restore();
    if (R() < .15) part(px + (R() - .5) * 6, fy - 10, { vy: -40, vx: (R() - .5) * 10, life: .6, max: .6, size: 1.5, col: '255,180,80' }); }
  if (o.type === 'lamp') { c.save(); c.globalCompositeOperation = 'lighter'; glow(c, px, py - 66, 20, '255,210,130', .5); c.restore(); }
  if (o.type === 'fountain') { c.save(); c.globalCompositeOperation = 'lighter'; for (let i = 0; i < 2; i++) part(px + 76 + (R() - .5) * 4, py - 72, { vx: (R() - .5) * 60, vy: -80 - R() * 30, grav: 260, life: .9, max: .9, size: 1.8, col: '170,210,255' }); c.restore(); }
  if (s.glow) { c.save(); c.globalCompositeOperation = 'lighter'; glow(c, px, py - 16, 26, o.type === 'altar' ? '255,140,40' : '120,170,255', .3 + Math.sin(S.time * 2 + o.x) * .08); c.restore(); }
}
function drawDrop(c, d) {
  const x = d.x * TW + TW / 2, y = d.y * TH + TH / 2 + 2 + Math.sin(S.time * 3 + d.bob) * 1.2;
  c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(x, y + 8, 10, 3, 0, 0, 7); c.fill();
  if (d.gold) { c.fillStyle = '#b8901a'; for (let i = 0; i < Math.min(6, 2 + (d.gold / 200 | 0)); i++) { const ox = (i % 3 - 1) * 5, oy = -(i / 3 | 0) * 3; c.beginPath(); c.ellipse(x + ox, y + 4 + oy, 4.5, 2.5, 0, 0, 7); c.fill(); c.fillStyle = '#ffd860'; c.beginPath(); c.ellipse(x + ox, y + 3 + oy, 4, 2, 0, 0, 7); c.fill(); c.fillStyle = '#b8901a'; } return; }
  const def = ITEMS[d.it.id]; const q = def.q || 0, add = addTotal(d.it) > 0;
  if (q || add) { c.save(); c.globalCompositeOperation = 'lighter'; const col = q === 3 ? '255,120,40' : q === 2 ? '200,140,255' : q === 1 ? '255,200,80' : '120,200,255'; const g = c.createLinearGradient(0, y - 90, 0, y + 6); g.addColorStop(0, `rgba(${col},0)`); g.addColorStop(1, `rgba(${col},${.45 + Math.sin(S.time * 4) * .1})`); c.fillStyle = g; c.fillRect(x - 5, y - 90, 10, 96); glow(c, x, y, 22, col, .5); c.restore(); }
  const ic = itemIconCanvas(d.it.id); c.drawImage(ic, x - 15, y - 16, 30, 30);
}
function portalFx(c) {
  for (const p of S.map.portals) { const x = ((p.x0 + p.x1) / 2) * TW + TW / 2, y = ((p.y0 + p.y1) / 2) * TH + TH * .8; drawEffect(c, { type: 'portal', x, y, col: '140,190,255' }, 0); }
}

function render() {
  const m = S.map, p = S.player; if (!m || !p) return;
  const z = S.zoom * DPR;
  let cx = epx(p), cy = epy(p) - 18;
  if (S.shake > 0) { cx += (R() - .5) * 10 * S.shake; cy += (R() - .5) * 10 * S.shake; }
  let ox = cx - S.vw / 2 / S.zoom, oy = cy - (S.vh - S.hudH) / 2 / S.zoom;
  { const vwW = S.vw / S.zoom, vhW = (S.vh - S.hudH) / S.zoom, mw = m.w * TW, mh = m.h * TH; ox = mw > vwW ? clamp(ox, 0, mw - vwW) : (mw - vwW) / 2; oy = mh > vhW ? clamp(oy, -40, mh - vhW) : (mh - vhW) / 2; }
  ox = Math.round(ox * z) / z; oy = Math.round(oy * z) / z;
  S.cam.ox = ox; S.cam.oy = oy;
  const vw = S.vw / S.zoom, vh = S.vh / S.zoom;
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.fillStyle = '#050505'; ctx.fillRect(0, 0, cv.width, cv.height);
  ctx.setTransform(z, 0, 0, z, -ox * z, -oy * z);
  ctx.imageSmoothingEnabled = true;
  // ground
  const cwp = CH * TW, chp = CH * TH; let budget = S.buildAll ? 999 : 2; S.buildAll = false;
  for (let gy = Math.floor(oy / chp); gy <= Math.floor((oy + vh) / chp); gy++) for (let gx = Math.floor(ox / cwp); gx <= Math.floor((ox + vw) / cwp); gx++) {
    if (gx < 0 || gy < 0 || gx * CH >= m.w || gy * CH >= m.h) continue;
    const key = gx + ',' + gy; let ch = m.chunks.get(key);
    if (!ch && budget > 0) { budget--; ch = getChunk(m, gx, gy); }
    if (ch) ctx.drawImage(ch, gx * cwp, gy * chp); else { ctx.fillStyle = m.outdoor ? '#3a5230' : '#2a2420'; ctx.fillRect(gx * cwp, gy * chp, cwp, chp); }
  }
  // prebuild one nearby chunk when idle
  if (budget > 0) { outer: for (let r = 0; r < 2; r++) for (let gy = Math.floor(oy / chp) - 1; gy <= Math.floor((oy + vh) / chp) + 1; gy++) for (let gx = Math.floor(ox / cwp) - 1; gx <= Math.floor((ox + vw) / cwp) + 1; gx++) { if (gx < 0 || gy < 0 || gx * CH >= m.w || gy * CH >= m.h) continue; if (!m.chunks.has(gx + ',' + gy)) { getChunk(m, gx, gy); break outer; } } }
  const tx0 = Math.max(0, Math.floor(ox / TW) - 2), tx1 = Math.min(m.w - 1, Math.ceil((ox + vw) / TW) + 2), ty0 = Math.max(0, Math.floor(oy / TH) - 2), ty1 = Math.min(m.h - 1, Math.ceil((oy + vh) / TH) + 5);
  // water shimmer
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  for (let y = ty0; y <= ty1; y++) for (let x = tx0; x <= tx1; x++) if (m.g[idx(m, x, y)] === G.WATER) { const a = Math.sin(S.time * 1.6 + x * 1.3 + y * .7) * .5 + .5; if (a > .6) { ctx.fillStyle = `rgba(150,200,230,${(a - .6) * .35})`; ctx.fillRect(x * TW + 8 + Math.sin(S.time + y) * 6, y * TH + 12, 18, 1.5); } }
  ctx.restore();
  portalFx(ctx);
  for (const d of S.drops) if (d.x >= tx0 && d.x <= tx1 && d.y >= ty0 && d.y <= ty1) drawDrop(ctx, d);
  drawFXLayer(ctx, true);
  // sortable
  const L = [];
  for (let y = ty0; y <= ty1; y++) for (let x = tx0; x <= tx1; x++) {
    const k = idx(m, x, y), w = m.wall[k]; if (!w) continue;
    const below = y + 1 < m.h ? m.wall[idx(m, x, y + 1)] : 1;
    L.push([(y + 1) * TH - 1, 0, x, y, w, !below ? 1 : 0, x > 0 && !m.wall[k - 1] ? 1 : 0, x < m.w - 1 && !m.wall[k + 1] ? 1 : 0]);
  }
  const bx0 = ox - 200, bx1 = ox + vw + 200, by0 = oy - 40, by1 = oy + vh + 220;
  for (const o of m.objs) {
    const multi = (o.fw || 1) > 1; const px = multi ? o.x * TW : o.x * TW + TW / 2, py = multi ? (o.y + 1) * TH : o.y * TH + TH - 4;
    if (px < bx0 - (multi ? 200 : 0) || px > bx1 || py < by0 || py > by1) continue;
    L.push([o.wallTorch ? (o.y + 1) * TH : py, 1, o, px, py]);
  }
  for (const e of S.ents) { const x = epx(e), y = epy(e); if (x < ox - 80 || x > ox + vw + 80 || y < oy - 40 || y > oy + vh + 120) continue; L.push([y + (e.dead ? -12 : 0), 3, e]); }
  L.sort((a, b) => a[0] - b[0]);
  for (const it of L) {
    if (it[1] === 0) { const [, , x, y, w, fr, lf, rt] = it; const WH = WALLH[w]; ctx.drawImage(wallSprite(w, (x * 7 + y * 13) % 4, fr, lf, rt), x * TW, y * TH - WH); }
    else if (it[1] === 1) drawObj(ctx, it[2], it[3], it[4]);
    else drawEntity(ctx, it[2]);
  }
  for (const pr of S.proj) drawProjectile(ctx, pr);
  drawFXLayer(ctx, false);
  drawParticles(ctx);
  // lighting
  const hours = dayPhase(); const night = m.outdoor ? hours.night * .62 : 0;
  const dark = Math.min(.92, m.dark + night);
  if (dark > .02) {
    const lw = lightCv.width, lh = lightCv.height, ls = S.zoom / LRES;
    lctx.globalCompositeOperation = 'source-over'; lctx.clearRect(0, 0, lw, lh);
    lctx.fillStyle = m.outdoor ? `rgba(10,14,34,${dark})` : `rgba(6,5,10,${dark})`; lctx.fillRect(0, 0, lw, lh);
    lctx.globalCompositeOperation = 'destination-out';
    const hole = (wx, wy, r, a) => { const sx = (wx - ox) * ls, sy = (wy - oy) * ls, sr = r * ls; if (sx < -sr || sy < -sr || sx > lw + sr || sy > lh + sr) return; const g = lctx.createRadialGradient(sx, sy, 0, sx, sy, sr); g.addColorStop(0, `rgba(0,0,0,${a})`); g.addColorStop(.55, `rgba(0,0,0,${a * .6})`); g.addColorStop(1, 'rgba(0,0,0,0)'); lctx.fillStyle = g; lctx.fillRect(sx - sr, sy - sr, sr * 2, sr * 2); };
    hole(epx(p), epy(p) - 16, TW * (m.outdoor ? 6 : 5.2), 1);
    for (const l of m.lights) { const fl = 1 + Math.sin(S.time * 9 + l.x * 3) * .04; hole(l.x * TW + 24, l.y * TH + 16, l.r * TW * fl, .95); }
    for (const e of FX) if (e.type === 'fireground') hole(e.x, e.y - 10, 110, .8); else if (e.type === 'thunder' || e.type === 'pillar' || e.type === 'flash') hole(e.x, e.y - 30, 220, .9 * (1 - e.t / e.dur));
    for (const pr of S.proj) hole(pr.x, pr.y - 22, 90, .85);
    for (const e of S.ents) { if (e.def && e.def.boss && !e.dead) hole(epx(e), epy(e) - 20, 120, .6); if (e.kind === 'bot' && !e.dead && m.dark > .5) hole(epx(e), epy(e) - 16, 150, .7); }
    if (S.pet && !S.pet.dead && S.pet.petType === 'hound') hole(epx(S.pet), epy(S.pet) - 16, 120, .8);
    ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.imageSmoothingEnabled = true; ctx.drawImage(lightCv, 0, 0, cv.width, cv.height);
    // warm light tint (low-res, composited once)
    tctx.globalCompositeOperation = 'source-over'; tctx.clearRect(0, 0, lw, lh); tctx.globalCompositeOperation = 'lighter';
    for (const l of m.lights) { const sx = (l.x * TW + 24 - ox) * ls, sy = (l.y * TH + 16 - oy) * ls, sr = l.r * TW * .8 * ls; if (sx < -sr || sy < -sr || sx > lw + sr || sy > lh + sr) continue; const g = tctx.createRadialGradient(sx, sy, 0, sx, sy, sr); g.addColorStop(0, `rgba(${l.c},${.12 * dark + .04})`); g.addColorStop(1, `rgba(${l.c},0)`); tctx.fillStyle = g; tctx.fillRect(sx - sr, sy - sr, sr * 2, sr * 2); }
    ctx.save(); ctx.globalCompositeOperation = 'lighter'; ctx.drawImage(tintCv, 0, 0, cv.width, cv.height);
    ctx.restore();
  }
  // labels
  ctx.setTransform(z, 0, 0, z, -ox * z, -oy * z);
  drawLabels(ctx);
  drawFloats(ctx);
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  if (S.transT > 0) document.getElementById('fade').style.opacity = S.transT; else document.getElementById('fade').style.opacity = 0;
}
function dayPhase() { const ph = ((S.P ? S.P.playT : 0) / 900 + .15) % 1; const v = Math.cos(ph * Math.PI * 2); return { ph, night: clamp((.25 - v) / 1.05, 0, 1), hour: (ph * 24 + 12) % 24 }; }
function textOut(c, t, x, y, col, font) { c.font = font || '700 12px "Alegreya Sans", system-ui, sans-serif'; c.textAlign = 'center'; c.lineJoin = 'round'; c.strokeStyle = 'rgba(0,0,0,.9)'; c.lineWidth = 3; c.strokeText(t, x, y); c.fillStyle = col; c.fillText(t, x, y); }
function drawLabels(c) {
  const p = S.player, P = S.P;
  for (const d of S.drops) { if (d.gold) continue; const def = ITEMS[d.it.id]; const hov = S.mouse.tx === d.x && S.mouse.ty === d.y; if (def.q || addTotal(d.it) > 0 || hov) textOut(c, itemName(d.it), d.x * TW + 24, d.y * TH - 2, itemColor(d.it), '700 11px "Alegreya Sans", sans-serif'); }
  for (const q of S.map.portals) { const x = ((q.x0 + q.x1) / 2) * TW + TW / 2, y = Math.min(q.y0, q.y1) * TH - 8; textOut(c, '⇢ ' + q.label, x, y, '#a8ccff', '700 12px "Alegreya Sans", sans-serif'); }
  for (const e of S.ents) {
    if (e.dead) continue; const x = epx(e); const sz = e.def ? (e.def.size || 1) : 1; const human = e.kind !== 'mon' || e.def.body === 'biped'; let y = epy(e) - (human ? 66 : 52) * sz - (e.kind === 'mon' && e.def.body === 'flyer' ? 26 : 0);
    if (e.kind === 'mon' && ['hen', 'worm', 'spider', 'snake', 'quad'].includes(e.def.body)) y = epy(e) - 32 * sz;
    const hov = S.hover === e, tgt = p.target === e;
    if (e.sayT > 0 && e.say) { c.font = '500 12px "Alegreya Sans", sans-serif'; const w = Math.min(220, c.measureText(e.say).width + 14); c.fillStyle = 'rgba(10,9,8,.8)'; rr(c, x - w / 2, y - 44, w, 20, 5); c.fill(); c.strokeStyle = 'rgba(227,194,127,.4)'; c.lineWidth = 1; c.stroke(); c.fillStyle = '#f4efe2'; c.textAlign = 'center'; c.fillText(e.say.length > 34 ? e.say.slice(0, 33) + '…' : e.say, x, y - 30); }
    if (e.kind === 'player') {
      const col = P.pk >= 200 ? '#ff4a3a' : P.pk >= 100 ? '#ffe04a' : p.greyT > 0 ? '#b89878' : '#ffffff';
      if (P.guild) textOut(c, '<' + P.guild.name + '>', x, y - 14, S.castle === P.guild.name ? '#ffd24a' : '#9ad0ff', '700 11px "Alegreya Sans", sans-serif');
      textOut(c, P.name, x, y, col);
      c.fillStyle = '#000'; c.fillRect(x - 16, y + 3, 32, 4); c.fillStyle = '#e03a2a'; c.fillRect(x - 15.5, y + 3.5, 31 * p.hp / p.maxhp, 3);
    } else if (e.kind === 'bot') {
      const col = e.red ? '#ff5a4a' : (e.greyT > 0 || e.pkOn) ? '#c8a888' : e.party ? '#9fd0ff' : '#f0ece0';
      if (e.guild) textOut(c, '<' + e.guild + '>', x, y - 14, S.castle === e.guild ? '#ffd24a' : '#9ad0ff', '700 11px "Alegreya Sans", sans-serif');
      textOut(c, e.name, x, y, col);
      if (e.party || e.dmgT > 0 || hov) { c.fillStyle = '#000'; c.fillRect(x - 16, y + 3, 32, 4); c.fillStyle = e.party ? '#4ac86a' : '#e03a2a'; c.fillRect(x - 15.5, y + 3.5, 31 * e.hp / e.maxhp, 3); }
    } else if (e.kind === 'npc') { textOut(c, e.def.title || '', x, y - 13, '#b8e8a8', '600 11px "Alegreya Sans", sans-serif'); textOut(c, e.name, x, y, '#6aff6a'); }
    else if (e.kind === 'guard') { if (hov) textOut(c, 'Guard', x, y, '#d8d0c0'); }
    else if (e.kind === 'pet') { textOut(c, e.name, x, y, '#b8f0c0', '700 11px "Alegreya Sans", sans-serif'); c.fillStyle = '#000'; c.fillRect(x - 16, y + 3, 32, 4); c.fillStyle = '#4ac86a'; c.fillRect(x - 15.5, y + 3.5, 31 * e.hp / e.maxhp, 3); }
    else if (e.kind === 'mon') {
      if (hov || tgt || e.def.boss) textOut(c, e.def.boss ? `${e.name}` : e.name, x, y, e.def.boss ? '#ffb04a' : '#f0ece0', e.def.boss ? '700 14px "Alegreya Sans", sans-serif' : undefined);
      if (e.dmgT > 0 || tgt) { const w = e.def.boss ? 60 : 32; c.fillStyle = '#000'; c.fillRect(x - w / 2, y + 3, w, 4); c.fillStyle = '#e03a2a'; c.fillRect(x - w / 2 + .5, y + 3.5, (w - 1) * e.hp / e.maxhp, 3); }
    }
  }
}
function pickHover() {
  const p = S.player; if (!p) return null;
  const wx = S.cam.ox + S.mouse.x / S.zoom, wy = S.cam.oy + S.mouse.y / S.zoom;
  S.mouse.wx = wx; S.mouse.wy = wy; S.mouse.tx = Math.floor(wx / TW); S.mouse.ty = Math.floor(wy / TH);
  let best = null, by = -1e9;
  for (const e of S.ents) {
    if (e.dead || e === p) continue; const x = epx(e), y = epy(e); const s = e.def ? (e.def.size || 1) : 1; const fly = e.def && e.def.body === 'flyer' ? 26 : 0;
    const hh = (!e.def || e.def.body === 'biped') ? 64 : 44; if (Math.abs(wx - x) < 15 * s + 5 && wy < y + 6 && wy > y - hh * s - fly) { if (y > by) { by = y; best = e; } }
  }
  return best;
}
