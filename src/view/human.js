/* ================= DETAILED CHARACTER RENDERER =================
 Pre-rendered-sprite look: every body part is shaded as a lit volume (light from upper left),
 outlined, and every equipped item changes the silhouette. */
const OUTL = 'rgba(16,10,6,.82)';
let LS = 1; // light side sign (flips with character)
let MAILPAT = null;
function mailPattern(c) {
  if (MAILPAT) return MAILPAT; const p = document.createElement('canvas'); p.width = 4; p.height = 3; const x = p.getContext('2d');
  x.fillStyle = 'rgba(0,0,0,.35)'; x.fillRect(0, 0, 1, 1); x.fillRect(2, 1.5, 1, 1); x.fillStyle = 'rgba(255,255,255,.22)'; x.fillRect(1, 0, 1, 1); x.fillRect(3, 1.5, 1, 1);
  MAILPAT = c.createPattern(p, 'repeat'); return MAILPAT;
}
function gH(c, x0, x1, col, hi, lo) {
  if (LS < 0) { const t = x0; x0 = x1; x1 = t; }
  const g = c.createLinearGradient(x0, 0, x1, 0); g.addColorStop(0, shade(col, (hi == null ? .3 : hi) * .5)); g.addColorStop(.28, shade(col, hi == null ? .3 : hi)); g.addColorStop(.62, col); g.addColorStop(1, shade(col, lo == null ? -.5 : lo)); return g;
}
function cap(c, x0, y0, x1, y1, w, col, noOut) {
  c.lineCap = 'round';
  if (!noOut) { c.strokeStyle = OUTL; c.lineWidth = w + 1.6; c.beginPath(); c.moveTo(x0, y0); c.lineTo(x1, y1); c.stroke(); }
  const a = Math.atan2(y1 - y0, x1 - x0), nx = -Math.sin(a) * w / 2, ny = Math.cos(a) * w / 2, mx = (x0 + x1) / 2, my = (y0 + y1) / 2;
  const s = (nx * LS) < 0 ? 1 : -1; const g = c.createLinearGradient(mx + nx * s, my + ny * s, mx - nx * s, my - ny * s);
  g.addColorStop(0, shade(col, .32)); g.addColorStop(.45, col); g.addColorStop(1, shade(col, -.45));
  c.strokeStyle = g; c.lineWidth = w; c.beginPath(); c.moveTo(x0, y0); c.lineTo(x1, y1); c.stroke();
}
function outFill(c, fill, lw) { c.fillStyle = fill; c.fill(); c.strokeStyle = OUTL; c.lineWidth = lw || 1.1; c.stroke(); }
function gem(c, x, y, r, col, glowIt) {
  if (glowIt) { c.save(); c.globalCompositeOperation = 'lighter'; glow(c, x, y, r * 4, hexRgb(col), .55); c.restore(); }
  c.fillStyle = OUTL; c.beginPath(); c.arc(x, y, r + .6, 0, 7); c.fill();
  const g = c.createRadialGradient(x - r * .4, y - r * .4, 0, x, y, r); g.addColorStop(0, '#fff'); g.addColorStop(.35, col); g.addColorStop(1, shade(col, -.5)); c.fillStyle = g; c.beginPath(); c.arc(x, y, r, 0, 7); c.fill();
}
const SPECIAL_COL = { paralyze: '#c070ff', revive: '#ffd860', protect: '#70b0ff', teleport: '#60f0ff', regen: '#70ff90' };

function drawHuman(c, x, y, o) {
  const s = o.size || 1;
  const dir = o.dir, dx = DX[dir], dy = DY[dir];
  const face = dy > 0 ? 'front' : dy < 0 ? 'back' : 'side';
  const q3 = dx !== 0 && dy !== 0; const flip = dx < 0; LS = flip ? -1 : 1;
  const A = o.armor || { c: o.cloth || '#6a5a4a', t: shade(o.cloth || '#6a5a4a', .25) };
  const bone = o.bone, stone = o.stone;
  let style = bone ? 'bone' : A.style || (A.robe ? 'robe' : o.plate ? 'plate' : 'tunic');
  const robe = style === 'robe' || style === 'taorobe';
  const skin = o.skin || '#e0b48a';
  c.save(); c.translate(x, y);
  // ground shadow (soft, pre-rendered feel)
  const sg = c.createRadialGradient(0, 0, 1, 0, 0, 16 * s); sg.addColorStop(0, 'rgba(0,0,0,.45)'); sg.addColorStop(1, 'rgba(0,0,0,0)'); c.fillStyle = sg; c.beginPath(); c.ellipse(0, 0, 16 * s, 5.5 * s, 0, 0, 7); c.fill();
  if (o.fall) c.rotate(o.fall * 1.45 * (flip ? -1 : 1));
  c.scale(s * (flip ? -1 : 1), s);
  if (o.flash) c.filter = 'brightness(2.2)';
  c.lineJoin = 'round';
  const moving = o.moving; const W = moving ? Math.sin(o.walk * Math.PI * 2) : 0;
  const bob = moving ? -Math.abs(Math.cos(o.walk * Math.PI * 2)) * 1.6 : Math.sin(o.idle * 2) * .45;
  const hunch = o.hunch ? 1 : 0;
  const hipY = -19, waistY = -23 + bob, chestY = -30 + bob, shY = -35.5 + bob + hunch * 3, neckY = -38.5 + bob + hunch * 3, headY = -45 + bob + hunch * 5;
  const hx0 = face === 'side' ? 1.2 + hunch * 5 : (q3 ? 1.4 : 0);
  const wm = face === 'side' ? .66 : q3 ? .86 : 1;
  const sw = 9.6 * wm * (style === 'plate' ? 1.08 : 1), ww = 6.8 * wm, hw = 7.6 * wm;
  const front = face !== 'back';
  // ---- arm pose
  let armA = W * .55, bend = .18;
  if (o.atk >= 0) { const t = o.atk; armA = t < .35 ? lerp(0, -2.5, t / .35) : lerp(-2.5, 1.15, Math.min(1, (t - .35) / .28)); bend = t < .35 ? .6 : .1; }
  if (o.cast >= 0) { armA = -1.5 - Math.sin(o.cast * Math.PI) * .7; bend = -.3; }
  if (hunch && o.atk < 0) { armA = -1.35 + W * .2; bend = .1; }
  const backA = o.cast >= 0 ? -1.2 : hunch ? -1.2 : -W * .5;
  const proj = face === 'side' ? 1 : .42;

  // ---- colours by style
  const legCol = bone ? skin : stone ? shade(skin, -.15) : style === 'plate' ? shade(A.c, .05) : style === 'chain' ? '#7c8288' : style === 'leather' ? '#4a3626' : shade(A.c, -.5);
  const bootCol = style === 'plate' ? shade(A.c, -.2) : style === 'chain' ? '#3a3a40' : bone ? skin : '#2e2016';

  // ---- cape (behind)
  const drawCape = (over) => {
    if (!A.cape) return; const sway = W * 2 + Math.sin(o.idle * 1.7) * .8;
    if (!over) {
      if (face === 'side') { c.beginPath(); c.moveTo(-2, shY); c.quadraticCurveTo(-10, -18, -13 - sway, -3); c.lineTo(-2, -4); c.closePath(); outFill(c, gH(c, -13, -2, A.cape, .2, -.55)); c.strokeStyle = A.t; c.lineWidth = 1; c.beginPath(); c.moveTo(-13 - sway, -3); c.lineTo(-2, -4); c.stroke(); }
      else if (front) { c.beginPath(); c.moveTo(-sw + 1, shY); c.quadraticCurveTo(-sw - 4, -16, -sw - 3 - sway, -3); c.lineTo(sw + 3 - sway, -3); c.quadraticCurveTo(sw + 4, -16, sw - 1, shY); c.closePath(); outFill(c, shade(A.cape, -.45)); }
    } else if (face === 'back') {
      c.beginPath(); c.moveTo(-sw + .5, shY - .5); c.quadraticCurveTo(0, shY - 2.5, sw - .5, shY - .5); c.quadraticCurveTo(sw + 4, -18, sw + 4 + sway, -2); c.lineTo(-sw - 4 + sway, -2); c.quadraticCurveTo(-sw - 4, -18, -sw + .5, shY - .5); c.closePath();
      outFill(c, gH(c, -sw - 4, sw + 4, A.cape, .22, -.5));
      c.strokeStyle = 'rgba(0,0,0,.25)'; c.lineWidth = 1; for (const fx2 of [-4, 0, 4]) { c.beginPath(); c.moveTo(fx2 * .6, shY + 3); c.quadraticCurveTo(fx2, -14, fx2 * 1.3 + sway, -3); c.stroke(); }
      c.strokeStyle = A.t; c.lineWidth = 1.4; c.beginPath(); c.moveTo(-sw - 4 + sway, -2.5); c.lineTo(sw + 4 + sway, -2.5); c.stroke();
      if (A.stars) { c.save(); c.globalCompositeOperation = 'lighter'; for (let i = 0; i < 7; i++) { const tw = Math.sin(o.idle * 3 + i * 2) * .5 + .5; c.fillStyle = `rgba(255,230,160,${.4 + tw * .5})`; c.fillRect(-7 + (i * 37 % 14), shY + 5 + (i * 23 % 24), 1.2, 1.2); } c.restore(); }
    }
  };
  // ---- legs
  const drawLegs = () => {
    if (robe) { // boots peek under robe
      const f1 = face === 'side' ? W * 4 : 0, f2 = face === 'side' ? -W * 4 : 0;
      c.fillStyle = bootCol; c.strokeStyle = OUTL; c.lineWidth = 1;
      for (const [fx2, ox] of [[f2, -2.6], [f1, 2.6]]) { c.beginPath(); c.ellipse((face === 'side' ? 1 : ox) + fx2, -1.2, face === 'side' ? 4 : 2.6, 1.8, 0, 0, 7); c.fill(); c.stroke(); }
      return;
    }
    const lw = bone ? 2.8 : 5.4;
    const leg = (hipX, a, lift, near) => {
      const kx = hipX + Math.sin(a) * 9.5, ky = hipY + Math.cos(a) * 9.5 - lift;
      const fa = a - Math.max(0, a) * .9 - (moving ? .12 : 0); const fx2 = kx + Math.sin(fa) * 9.5, fy = Math.min(-1.4, ky + Math.cos(fa) * 9.5);
      const col = near ? legCol : shade(legCol, -.18);
      cap(c, hipX, hipY, kx, ky, lw * (style === 'plate' ? 1.1 : 1), col); cap(c, kx, ky, fx2, fy, lw * .88, col);
      if (style === 'plate') { gem(c, kx, ky, 1.9, shade(A.c, .2)); c.strokeStyle = A.t; c.lineWidth = .8; c.beginPath(); c.arc(kx, ky, 2.3, 0, 7); c.stroke(); }
      if (style === 'leather' || style === 'tunic') { cap(c, fx2 + (face === 'side' ? .4 : 0), fy - 3, fx2, fy, lw * .98, bootCol); c.fillStyle = shade(bootCol, .25); c.fillRect(fx2 - lw * .5, fy - 4.2, lw, 1.2); }
      // boot
      c.fillStyle = bootCol; c.strokeStyle = OUTL; c.lineWidth = 1; c.beginPath();
      if (face === 'side') c.ellipse(fx2 + 2, fy + .3, 4.2, 1.9, 0, 0, 7); else c.ellipse(fx2, fy + .5, 2.9, 2, 0, 0, 7);
      c.fill(); c.stroke();
    };
    if (face === 'side' || q3) { const amp = q3 ? .45 : .6; const sp = q3 ? 2.6 : .8; leg(-sp, -W * amp, 0, false); leg(sp, W * amp, 0, true); }
    else { leg(-3.8, 0, Math.max(0, W) * 3, face === 'front'); leg(3.8, 0, Math.max(0, -W) * 3, face !== 'front'); }
  };
  // ---- torso
  const torsoPath = () => {
    c.beginPath();
    if (face === 'side') { c.moveTo(-4.5, shY + .5); c.quadraticCurveTo(-5, chestY, -4.2, waistY); c.lineTo(-4.8, hipY + 1.5); c.lineTo(4.8, hipY + 1.5); c.lineTo(4.4, waistY); c.quadraticCurveTo(6.8, chestY - 1, 4.5, shY + .5); c.quadraticCurveTo(0, shY - 1.5, -4.5, shY + .5); }
    else { c.moveTo(-sw, shY + 1); c.quadraticCurveTo(-sw - .4, chestY, -ww, waistY); c.lineTo(-hw, hipY + 1.5); c.lineTo(hw, hipY + 1.5); c.lineTo(ww, waistY); c.quadraticCurveTo(sw + .4, chestY, sw, shY + 1); c.quadraticCurveTo(0, shY - 2, -sw, shY + 1); }
    c.closePath();
  };
  const robeSkirt = () => {
    const hem = style === 'taorobe' ? -2.2 : -1.2, sway = W * 2.2, fl = face === 'side' ? 7.5 : 11 * wm;
    c.beginPath(); c.moveTo(-ww - .5, waistY); c.lineTo(-fl + sway * .6, hem); c.quadraticCurveTo(0 + sway * .3, hem + 1.2, fl + sway * .6, hem); c.lineTo(ww + .5, waistY); c.closePath();
    outFill(c, gH(c, -fl, fl, A.c, .25, -.55));
    // folds
    c.strokeStyle = 'rgba(0,0,0,.22)'; c.lineWidth = .9; for (const f of [-.5, 0, .5]) { c.beginPath(); c.moveTo(f * ww, waistY + 2); c.lineTo(f * fl + sway * .5, hem); c.stroke(); }
    // hem trim
    c.strokeStyle = A.t; c.lineWidth = 1.8; c.beginPath(); c.moveTo(-fl + sway * .6 + .6, hem - 1); c.quadraticCurveTo(sway * .3, hem + .2, fl + sway * .6 - .6, hem - 1); c.stroke();
    if (front && face !== 'side') { c.strokeStyle = A.t; c.lineWidth = 1.3; c.beginPath(); c.moveTo(0, waistY + 2); c.lineTo(sway * .35, hem); c.stroke(); }
    if (A.stars || style === 'robe') { c.fillStyle = A.t; for (let i = -2; i <= 2; i++) { const px = i * fl / 3 + sway * .6, py = hem - 3; c.beginPath(); c.moveTo(px, py - 1.4); c.lineTo(px + 1, py); c.lineTo(px, py + 1.4); c.lineTo(px - 1, py); c.fill(); } }
  };
  const drawTorso = () => {
    if (bone) {
      c.strokeStyle = OUTL; c.lineWidth = 3.4; c.beginPath(); c.moveTo(0, shY); c.lineTo(0, hipY); c.stroke();
      c.strokeStyle = skin; c.lineWidth = 2; c.beginPath(); c.moveTo(0, shY); c.lineTo(0, hipY); c.stroke();
      for (let i = 0; i < 4; i++) { c.strokeStyle = OUTL; c.lineWidth = 2.6; c.beginPath(); c.ellipse(0, shY + 3.5 + i * 3.2, 6.5 * wm - i * .6, 1.3, 0, 0, 7); c.stroke(); c.strokeStyle = skin; c.lineWidth = 1.4; c.stroke(); }
      c.fillStyle = skin; c.beginPath(); c.ellipse(0, hipY, 5.5 * wm, 2.2, 0, 0, 7); c.fill(); c.strokeStyle = OUTL; c.lineWidth = 1; c.stroke();
      if (o.cloth) { c.beginPath(); c.moveTo(-6 * wm, hipY - 2); c.lineTo(6 * wm, hipY - 2); c.lineTo(7 * wm + W, hipY + 9); c.lineTo(-7 * wm + W, hipY + 9); c.closePath(); outFill(c, gH(c, -7, 7, o.cloth)); c.strokeStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.moveTo(-3, hipY + 9); c.lineTo(-2, hipY + 5); c.moveTo(2, hipY + 9); c.lineTo(3, hipY + 6); c.stroke(); }
      return;
    }
    if (robe) robeSkirt();
    torsoPath(); outFill(c, gH(c, -sw, sw, A.c, .3, -.5));
    const F = face !== 'back' && face !== 'side';
    c.save(); torsoPath(); c.clip();
    if (style === 'chain') { c.fillStyle = mailPattern(c); c.fillRect(-sw - 2, shY - 2, sw * 2 + 4, hipY - shY + 6); }
    if (stone) { c.strokeStyle = 'rgba(0,0,0,.3)'; c.lineWidth = .9; c.beginPath(); c.moveTo(-3, shY + 2); c.lineTo(1, shY + 8); c.lineTo(-1, waistY); c.moveTo(4, chestY); c.lineTo(2, waistY + 2); c.stroke(); }
    // top light rim
    const rg = c.createLinearGradient(0, shY - 2, 0, shY + 6); rg.addColorStop(0, 'rgba(255,245,220,.25)'); rg.addColorStop(1, 'rgba(255,245,220,0)'); c.fillStyle = rg; c.fillRect(-sw - 2, shY - 2, sw * 2 + 4, 8);
    const bg = c.createLinearGradient(0, waistY, 0, hipY + 2); bg.addColorStop(0, 'rgba(0,0,0,0)'); bg.addColorStop(1, 'rgba(0,0,0,.25)'); c.fillStyle = bg; c.fillRect(-sw - 2, waistY, sw * 2 + 4, hipY - waistY + 3);
    if (style === 'leather') {
      if (F || q3) { c.fillStyle = skin; c.beginPath(); c.moveTo(-2.6, shY - .5); c.lineTo(2.6, shY - .5); c.lineTo(0, shY + 5); c.fill(); }
      c.strokeStyle = shade(A.c, -.5); c.lineWidth = 2.4; c.beginPath(); c.moveTo(-sw + 1.5, shY + 1.5); c.lineTo(hw - 1, waistY + 1); c.stroke();
      c.fillStyle = '#d8b060'; for (let i = 1; i <= 3; i++) { const t = i / 4; c.beginPath(); c.arc(lerp(-sw + 1.5, hw - 1, t), lerp(shY + 1.5, waistY + 1, t), .8, 0, 7); c.fill(); }
      c.strokeStyle = 'rgba(0,0,0,.25)'; c.lineWidth = .7; c.setLineDash([1.2, 1.2]); c.beginPath(); c.moveTo(-ww + 1.5, chestY - 1); c.lineTo(-ww + 1, waistY); c.moveTo(ww - 1.5, chestY - 1); c.lineTo(ww - 1, waistY); c.stroke(); c.setLineDash([]);
    } else if (style === 'chain' && (F || q3)) {
      const tg = c.createLinearGradient(0, shY, 0, hipY + 3); tg.addColorStop(0, shade(A.t, .15)); tg.addColorStop(1, shade(A.t, -.35)); c.fillStyle = tg; c.fillRect(-3.2 * wm, shY + 1, 6.4 * wm, hipY - shY + 3);
      c.strokeStyle = OUTL; c.lineWidth = .8; c.strokeRect(-3.2 * wm, shY + 1, 6.4 * wm, hipY - shY + 3); gem(c, 0, chestY + .5, 1.6, '#d8b060');
    } else if (style === 'plate') {
      if (F || q3) {
        c.strokeStyle = 'rgba(255,255,255,.45)'; c.lineWidth = 1; c.beginPath(); c.moveTo(-.5, shY + 3); c.lineTo(-.5, waistY); c.stroke();
        c.strokeStyle = 'rgba(0,0,0,.35)'; c.beginPath(); c.arc(-3.3, chestY - 1.5, 3.8, .2, 2.4); c.moveTo(7, chestY - 1.5); c.arc(3.3, chestY - 1.5, 3.8, .7, 2.9); c.stroke();
      }
      c.strokeStyle = 'rgba(0,0,0,.35)'; c.lineWidth = .9; for (let i = 0; i < 3; i++) { const yy = waistY + .5 + i * 1.6; c.beginPath(); c.moveTo(-hw, yy); c.lineTo(hw, yy); c.stroke(); }
      c.strokeStyle = A.t; c.lineWidth = 1.5; c.beginPath(); c.moveTo(-sw + 1, shY + 1.2); c.quadraticCurveTo(0, shY + (F ? 4 : -1), sw - 1, shY + 1.2); c.stroke();
      if (A.q && (F || q3)) gem(c, 0, chestY + .5, 2, A.q === 2 ? '#c070ff' : '#ff4a2a', true);
    } else if (robe) {
      if (style === 'robe' && (F || q3)) { c.strokeStyle = A.t; c.lineWidth = 1.4; c.beginPath(); c.moveTo(0, shY + 1); c.lineTo(0, hipY + 2); c.stroke(); c.beginPath(); c.moveTo(-3.5, shY); c.lineTo(0, shY + 4); c.lineTo(3.5, shY); c.stroke(); }
      if (style === 'taorobe' && (F || q3)) { c.strokeStyle = A.t; c.lineWidth = 2.2; c.beginPath(); c.moveTo(-sw + 2, shY + .5); c.lineTo(2, waistY); c.moveTo(sw - 2, shY + .5); c.lineTo(-1, waistY - 1); c.stroke(); }
      if (A.stars) { c.save(); c.globalCompositeOperation = 'lighter'; for (let i = 0; i < 5; i++) { const tw = Math.sin(o.idle * 3 + i * 1.7) * .5 + .5; c.fillStyle = `rgba(255,230,160,${.3 + tw * .6})`; c.fillRect(-5 + (i * 29 % 10), shY + 3 + (i * 17 % 10), 1.1, 1.1); } c.restore(); }
    }
    if (o.warpaint) { c.strokeStyle = '#c82a1a'; c.lineWidth = 1.5; c.beginPath(); c.moveTo(-5, shY + 3); c.lineTo(3, shY + 9); c.moveTo(-5, shY + 7); c.lineTo(3, shY + 13); c.stroke(); }
    if (o.apron && F) { c.fillStyle = '#4a2e18'; c.fillRect(-5, shY + 4, 10, hipY - shY + 2); }
    c.restore();
    // belt / sash
    if (robe) {
      c.fillStyle = A.t; c.fillRect(-ww - .3, waistY - .6, (ww + .3) * 2, 2.6); c.strokeStyle = OUTL; c.lineWidth = .7; c.strokeRect(-ww - .3, waistY - .6, (ww + .3) * 2, 2.6);
      if (F || q3) { gem(c, 1, waistY + .7, 1.3, shade(A.t, .2)); c.strokeStyle = A.t; c.lineWidth = 1.4; c.beginPath(); c.moveTo(1.5, waistY + 1.5); c.quadraticCurveTo(3 + W, waistY + 6, 2 + W * 1.5, waistY + 10); c.stroke(); }
      if (A.talismans) for (const tx of [-4, 4.5]) { const sway = Math.sin(o.idle * 2 + tx) * .8 + W; c.fillStyle = '#f2e27a'; c.fillRect(tx + sway * .3, waistY + 2, 2, 5); c.fillStyle = '#c8281a'; c.fillRect(tx + .5 + sway * .3, waistY + 3.2, 1, 2.6); }
    } else if (style !== 'bone') {
      const bc = style === 'plate' ? A.t : '#2c1c10';
      c.fillStyle = bc; c.fillRect(-ww - .6, waistY - .3, (ww + .6) * 2, 2.5); c.strokeStyle = OUTL; c.lineWidth = .7; c.strokeRect(-ww - .6, waistY - .3, (ww + .6) * 2, 2.5);
      if (face !== 'back') { c.fillStyle = '#e0c060'; c.fillRect(-1.2 + (face === 'side' ? 3 : 0), waistY - .3, 2.4, 2.5); }
      if (style === 'leather' && face !== 'back') { c.fillStyle = shade(A.c, -.3); c.beginPath(); rr(c, hw - 3.5, waistY + 1.8, 3.4, 3.6, 1); outFill(c, shade(A.c, -.25), .7); }
      if (style === 'plate') { for (const sd of [-1, 1]) { c.beginPath(); c.moveTo(sd * 1, waistY + 2); c.lineTo(sd * hw, waistY + 2); c.lineTo(sd * (hw + .5), hipY + 5); c.lineTo(sd * 1.5, hipY + 4); c.closePath(); outFill(c, gH(c, -hw, hw, A.c, .25, -.45), .8); c.strokeStyle = A.t; c.lineWidth = .8; c.beginPath(); c.moveTo(sd * (hw + .5), hipY + 4.6); c.lineTo(sd * 1.5, hipY + 3.6); c.stroke(); } }
    }
  };
  // ---- necklace
  const drawNeck = () => {
    const n = o.neck; if (!n) return;
    if (face === 'back') { c.strokeStyle = n.m; c.lineWidth = .9; c.beginPath(); c.moveTo(-2.6, neckY + 1.5); c.quadraticCurveTo(0, neckY + 2.6, 2.6, neckY + 1.5); c.stroke(); return; }
    const ox = face === 'side' ? 2.6 : q3 ? 1 : 0; const py = shY + 5.8;
    c.strokeStyle = OUTL; c.lineWidth = 1.8; c.beginPath(); c.moveTo(ox - 3.2 * wm, shY + .2); c.quadraticCurveTo(ox, py + 1, ox + 3.2 * wm, shY + .2); c.stroke();
    c.strokeStyle = n.m; c.lineWidth = n.s === 'beads' ? 1.6 : .95; c.stroke();
    if (n.s === 'beads') { c.fillStyle = n.g; for (let i = -2; i <= 2; i++) { const t = (i + 2) / 4; c.beginPath(); c.arc(ox + lerp(-3.2 * wm, 3.2 * wm, t), shY + .2 + Math.sin(t * Math.PI) * (py + 1 - shY) * .9, .9, 0, 7); c.fill(); } }
    if (n.s === 'fang') { c.beginPath(); c.moveTo(ox - 1.2, py); c.quadraticCurveTo(ox, py + 5, ox + .6, py + 5.5); c.quadraticCurveTo(ox + 1.4, py + 2, ox + 1.2, py); c.closePath(); outFill(c, n.g, .6); return; }
    if (n.s === 'skull') { c.beginPath(); c.arc(ox, py + 1.6, 2, 0, 7); outFill(c, n.g, .6); c.fillStyle = '#1a0a08'; c.fillRect(ox - 1.1, py + 1.1, .8, .8); c.fillRect(ox + .3, py + 1.1, .8, .8); return; }
    if (n.s === 'shard') { c.beginPath(); c.moveTo(ox, py - .5); c.lineTo(ox + 1.4, py + 2.5); c.lineTo(ox, py + 6); c.lineTo(ox - 1.4, py + 2.5); c.closePath(); outFill(c, n.g, .6); c.save(); c.globalCompositeOperation = 'lighter'; glow(c, ox, py + 2.5, 6, '140,210,255', .5); c.restore(); return; }
    if (n.s === 'disc') { c.beginPath(); c.arc(ox, py + 1.6, 2.2, 0, 7); outFill(c, n.g, .6); c.fillStyle = shade(n.g, -.4); c.beginPath(); c.arc(ox, py + 1.6, .8, 0, 7); c.fill(); return; }
    if (n.s === 'heart') { gem(c, ox, py + 1.8, 2.4, n.g, true); c.strokeStyle = '#8a60c0'; c.lineWidth = .8; c.beginPath(); c.arc(ox, py + 1.8, 3.4, 0, 7); c.stroke(); return; }
    if (n.s === 'clover' || n.luck) { c.fillStyle = '#ffd860'; for (let i = 0; i < 4; i++) { c.beginPath(); c.arc(ox + Math.cos(i * Math.PI / 2) * 1.4, py + 1 + Math.sin(i * Math.PI / 2) * 1.4, 1.1, 0, 7); c.fill(); } c.save(); c.globalCompositeOperation = 'lighter'; glow(c, ox, py + 1, 7, '255,220,90', .5); c.restore(); }
    else gem(c, ox, py + 1, n.big ? 2.1 : 1.6, n.g, n.q > 0 || n.enh);
  };
  // ---- arms
  const arm = (isFront) => {
    const sx = face === 'side' ? (isFront ? 1.5 : -1.5) : (isFront ? sw - 1.2 : -sw + 1.2);
    const sy = shY + 1.6; const a = isFront ? armA : backA; const b2 = isFront ? bend : .15;
    const ex = sx - Math.sin(a) * 8 * proj, ey = sy + Math.cos(a) * 8;
    const hx = ex - Math.sin(a + b2) * 7.5 * proj, hy = ey + Math.cos(a + b2) * 7.5;
    const upCol = bone ? skin : stone ? skin : style === 'plate' ? A.c : style === 'chain' ? '#8a9096' : style === 'leather' ? shade(A.c, .05) : A.c;
    const loCol = bone ? skin : stone ? skin : style === 'plate' ? shade(A.c, .08) : style === 'chain' ? '#8a9096' : robe ? A.c : skin;
    const dk = isFront ? 0 : -.15;
    const aw = bone ? 2.4 : 4.6;
    cap(c, sx, sy, ex, ey, aw * (style === 'plate' ? 1.12 : 1), shade(upCol, dk));
    if (robe) { // bell sleeve
      const a2 = Math.atan2(hy - ey, hx - ex), nx = -Math.sin(a2), ny = Math.cos(a2);
      c.beginPath(); c.moveTo(ex + nx * 2.3, ey + ny * 2.3); c.lineTo(hx - (hx - ex) * .2 + nx * 4, hy - (hy - ey) * .2 + ny * 4); c.lineTo(hx - (hx - ex) * .2 - nx * 4, hy - (hy - ey) * .2 - ny * 4); c.lineTo(ex - nx * 2.3, ey - ny * 2.3); c.closePath();
      outFill(c, shade(A.c, dk - .05), .9); c.strokeStyle = A.t; c.lineWidth = 1.2; c.beginPath(); c.moveTo(hx - (hx - ex) * .2 + nx * 4, hy - (hy - ey) * .2 + ny * 4); c.lineTo(hx - (hx - ex) * .2 - nx * 4, hy - (hy - ey) * .2 - ny * 4); c.stroke();
    } else cap(c, ex, ey, hx, hy, aw * .9, shade(loCol, dk));
    if (style === 'plate') { gem(c, ex, ey, 1.7, shade(A.c, .15)); }
    if (style === 'leather' && !o.braceL && !o.braceR) cap(c, lerp(ex, hx, .5), lerp(ey, hy, .5), lerp(ex, hx, .85), lerp(ey, hy, .85), aw * .95, shade(A.c, -.25), true);
    // bracelet
    const br = isFront ? o.braceR : o.braceL;
    if (br) { const bx = lerp(ex, hx, .78), by = lerp(ey, hy, .78); cap(c, lerp(ex, hx, .68), lerp(ey, hy, .68), bx, by, aw * (br.s === 'scaled' ? 1.3 : 1.15), br.m);
      if (br.s === 'spiked') { c.fillStyle = shade(br.m, .3); for (const sd of [-1, 1]) { c.beginPath(); c.moveTo(bx + sd * 2.4, by - 1); c.lineTo(bx + sd * 4.4, by - .5); c.lineTo(bx + sd * 2.4, by + .6); c.fill(); } }
      if (br.s === 'beads') { c.fillStyle = br.g; for (let i = -1; i <= 1; i++) { c.beginPath(); c.arc(bx + i * 1.6, by - .3, .7, 0, 7); c.fill(); } }
      else if (br.g) gem(c, bx, by - .2, br.s === 'scaled' ? 1.2 : .9, br.g, br.glow); }
    // hand
    const handCol = style === 'plate' ? shade(A.c, -.1) : bone ? skin : skin;
    c.fillStyle = OUTL; c.beginPath(); c.arc(hx, hy, bone ? 2 : 2.7, 0, 7); c.fill();
    const hg = c.createRadialGradient(hx - .8, hy - .8, 0, hx, hy, 2.6); hg.addColorStop(0, shade(handCol, .3)); hg.addColorStop(1, shade(handCol, -.3)); c.fillStyle = hg; c.beginPath(); c.arc(hx, hy, bone ? 1.4 : 2.1, 0, 7); c.fill();
    const rg2 = isFront ? o.ringR : o.ringL;
    if (rg2) { gem(c, hx + .8, hy + .6, .85, rg2.g, !!rg2.sp); if (rg2.sp) { c.save(); c.globalCompositeOperation = 'lighter'; const pulse = .35 + Math.sin(o.idle * 4) * .15; glow(c, hx, hy, 7, hexRgb(SPECIAL_COL[rg2.sp]), pulse); c.restore(); } }
    if (isFront && o.weapon) {
      c.save(); c.translate(hx, hy); const upright = /staff|wand|bough|eternity/.test(o.weapon.k); c.rotate(-a - b2 + (o.atk >= 0 || o.cast >= 0 ? 0 : upright ? .12 : .8)); c.scale(1.12, 1.12);
      drawWeapon(c, o.weapon.k, o.weapon.c, o.weapon.glow, o.weapon.len);
      if (o.weapon.r >= 5) { c.globalCompositeOperation = 'lighter'; const L2 = o.weapon.k === 'staff' ? -12 : 22; glow(c, 0, L2 * .6, 10, o.weapon.r >= 7 ? '255,170,60' : '190,120,255', .35 + Math.sin(o.idle * 5) * .15); }
      c.restore();
    }
    if (!isFront && o.shield) { c.beginPath(); c.ellipse(hx - 1, hy - 3, 5.5, 8.5, 0, 0, 7); outFill(c, gH(c, hx - 6, hx + 4, stone ? '#6a6458' : '#6a4a2a')); c.strokeStyle = '#b8a060'; c.lineWidth = 1.2; c.beginPath(); c.ellipse(hx - 1, hy - 3, 4, 7, 0, 0, 7); c.stroke(); gem(c, hx - 1, hy - 3, 1.4, '#c9a040'); }
    // pauldron on top of the arm
    if (!bone && (style === 'plate' || style === 'chain' || style === 'leather') && face !== 'side') {
      const big = style === 'plate' ? 1 : .72; const px = sx + (isFront ? 1 : -1) * .5, py = sy - 1;
      for (let l = 0; l < (style === 'plate' ? 2 : 1); l++) { c.beginPath(); c.ellipse(px, py + l * 2.2, 5.4 * big - l * .8, 4.2 * big - l * .6, 0, Math.PI, 0); c.lineTo(px + 5.4 * big - l * .8, py + l * 2.2 + 1); c.lineTo(px - 5.4 * big + l * .8, py + l * 2.2 + 1); c.closePath(); outFill(c, gH(c, px - 5, px + 5, style === 'plate' ? A.c : style === 'chain' ? '#6a4a2e' : shade(A.c, -.1), .35, -.45), .9); }
      if (style === 'plate') { c.strokeStyle = A.t; c.lineWidth = 1; c.beginPath(); c.ellipse(px, py, 5.4, 4.2, 0, Math.PI, 0); c.stroke(); if (A.q) { c.fillStyle = shade(A.t, .1); c.beginPath(); c.moveTo(px - 1.2, py - 3.8); c.lineTo(px + (isFront ? 1.5 : -1.5), py - 8.5); c.lineTo(px + 1.5, py - 3.8); c.fill(); } }
    } else if (!bone && style === 'plate' && face === 'side' && isFront) { c.beginPath(); c.ellipse(sx, sy - .5, 4.6, 4, 0, Math.PI, 0); c.closePath(); outFill(c, gH(c, sx - 4, sx + 4, A.c, .35, -.45)); c.strokeStyle = A.t; c.lineWidth = 1; c.stroke(); }
  };
  // ---- head
  const drawHead = () => {
    const hx = hx0;
    // long hair behind
    const hairVisible = o.hair && !bone && !o.hood && !(o.helm && (o.helm.k === 'plume' || o.helm.k === 'dragon'));
    if (hairVisible && o.fem && face !== 'back') { c.beginPath(); c.moveTo(hx - 7, headY - 2); c.quadraticCurveTo(hx - 8.5, headY + 8, hx - 6 + (face === 'side' ? -2 : 0), shY + 7); c.lineTo(hx + (face === 'side' ? -1 : 6), shY + 7); c.quadraticCurveTo(hx + (face === 'side' ? 1 : 8.5), headY + 8, hx + 7, headY - 2); c.closePath(); outFill(c, gH(c, hx - 8, hx + 8, shade(o.hair, -.15))); }
    // neck
    if (!bone) { c.fillStyle = shade(skin, -.2); c.fillRect(hx - 2.1 - (face === 'side' ? 1 : 0), neckY - 1, 4.2, shY - neckY + 2.5); }
    else { c.strokeStyle = skin; c.lineWidth = 1.8; c.beginPath(); c.moveTo(hx, neckY); c.lineTo(hx, shY + 1); c.stroke(); }
    if (o.beard && face !== 'back') { c.beginPath(); c.moveTo(hx - 5, headY + 2); c.lineTo(hx + 5 + (face === 'side' ? 2 : 0), headY + 2); c.lineTo(hx + (face === 'side' ? 3 : 0), headY + 14); c.closePath(); outFill(c, o.hair || '#ddd', .8); }
    if (o.bull) {
      c.beginPath(); c.ellipse(hx, headY, 8.5, 8, 0, 0, 7); outFill(c, gH(c, hx - 8, hx + 8, skin));
      if (face !== 'back') { c.beginPath(); c.ellipse(hx + (face === 'side' ? 6.5 : 0), headY + 4.5, face === 'side' ? 5 : 6, 4.2, 0, 0, 7); outFill(c, shade(skin, -.3), .8); c.fillStyle = '#1a0a04'; c.fillRect(hx - 2 + (face === 'side' ? 7 : 0), headY + 4, 1.4, 1.4); if (face !== 'side') c.fillRect(hx + .8, headY + 4, 1.4, 1.4); c.fillStyle = '#ff5a2a'; c.fillRect(hx - 4 + (face === 'side' ? 4 : 0), headY - 2, 2.2, 2); if (face !== 'side') c.fillRect(hx + 2, headY - 2, 2.2, 2); c.save(); c.globalCompositeOperation = 'lighter'; glow(c, hx, headY - 1, 7, '255,90,40', .4); c.restore(); }
    } else {
      c.beginPath(); c.ellipse(hx, headY, bone ? 6.4 : 6.6, bone ? 6.8 : 7.2, 0, 0, 7);
      const hg = c.createRadialGradient(hx - 2.2 * LS, headY - 2.5, .5, hx, headY, 8); hg.addColorStop(0, shade(skin, .25)); hg.addColorStop(.6, skin); hg.addColorStop(1, shade(skin, -.4)); c.fillStyle = hg; c.fill(); c.strokeStyle = OUTL; c.lineWidth = 1.1; c.stroke();
      if (!bone && face !== 'back') { c.fillStyle = shade(skin, -.12); if (face === 'side') { c.beginPath(); c.ellipse(hx - 1.2, headY + .5, 1.4, 2, 0, 0, 7); c.fill(); } else { c.beginPath(); c.ellipse(hx - 6.6, headY + .4, 1.2, 1.9, 0, 0, 7); c.ellipse(hx + 6.6, headY + .4, 1.2, 1.9, 0, 0, 7); c.fill(); } }
      if (bone) { if (face !== 'back') { c.fillStyle = '#140a08'; const ex = face === 'side' ? 3 : q3 ? 1 : 0; c.beginPath(); c.ellipse(hx - 2.5 + ex, headY - .3, 1.9, 2.2, 0, 0, 7); c.ellipse(hx + 2.5 + ex, headY - .3, 1.9, 2.2, 0, 0, 7); c.fill(); c.fillRect(hx - .6 + ex, headY + 2, 1.2, 1.4); c.fillStyle = skin; c.fillRect(hx - 2.8 + ex, headY + 4.2, 5.6, 2.2); c.fillStyle = '#140a08'; for (let i = 0; i < 4; i++) c.fillRect(hx - 2.2 + ex + i * 1.4, headY + 4.4, .5, 1.8); c.save(); c.globalCompositeOperation = 'lighter'; c.fillStyle = 'rgba(255,90,60,.8)'; c.fillRect(hx - 2.9 + ex, headY - .6, .9, .9); c.fillRect(hx + 2.1 + ex, headY - .6, .9, .9); c.restore(); } }
      else if (face !== 'back') {
        const fx2 = face === 'side' ? 3.6 : q3 ? 1.4 : 0; const eyeY = headY - .2;
        const eye = (ex) => { c.fillStyle = stone ? '#2a2018' : '#f4eee4'; c.beginPath(); c.ellipse(ex, eyeY, o.fem ? 1.2 : 1.05, o.fem ? .95 : .8, 0, 0, 7); c.fill(); c.fillStyle = stone ? '#ffb040' : (o.eyes || '#2a1a10'); c.fillRect(ex - .35 + (face === 'side' ? .3 : 0), eyeY - .7, .8, 1.4); if (o.fem) { c.fillStyle = '#1a0e08'; c.fillRect(ex - 1.3, eyeY - 1.2, 2.6, .45); } };
        if (face === 'side') eye(hx + fx2); else { eye(hx - 2.5 + fx2); eye(hx + 2.5 + fx2); }
        if (o.hair && !stone) { c.fillStyle = shade(o.hair, -.2); if (face === 'side') c.fillRect(hx + fx2 - 1.2, eyeY - 2.4, 2.6, .8); else { c.fillRect(hx - 3.7 + fx2, eyeY - 2.4, 2.5, .75); c.fillRect(hx + 1.3 + fx2, eyeY - 2.4, 2.5, .75); } }
        c.fillStyle = shade(skin, -.3); if (face === 'side') { c.beginPath(); c.moveTo(hx + 6.2, headY - .5); c.lineTo(hx + 7.6, headY + 1.8); c.lineTo(hx + 6, headY + 2.2); c.fill(); } else c.fillRect(hx - .4 + fx2, headY + .6, .9, 1.8);
        c.fillStyle = o.fem ? '#b0504a' : shade(skin, -.4); c.fillRect(hx - 1.2 + fx2 + (face === 'side' ? 1.8 : 0), headY + 3.6, face === 'side' ? 1.6 : 2.4, .75);
      }
      // hair
      const helmFull = o.helm && o.helm.k !== 'cap';
      if (hairVisible && !helmFull && !o.hat) {
        c.fillStyle = o.hair; c.strokeStyle = OUTL; c.lineWidth = 1;
        if (face === 'back') { c.beginPath(); c.ellipse(hx, headY - .3, 7.1, 7.6, 0, 0, 7); outFill(c, gH(c, hx - 7, hx + 7, o.hair)); if (o.fem) { c.beginPath(); c.moveTo(hx - 6.5, headY); c.quadraticCurveTo(hx - 7, shY + 6, hx - 3 + W, shY + 9); c.lineTo(hx + 3 + W, shY + 9); c.quadraticCurveTo(hx + 7, shY + 6, hx + 6.5, headY); c.closePath(); outFill(c, gH(c, hx - 7, hx + 7, o.hair)); } }
        else {
          c.beginPath(); const fr = face === 'side' ? -1.8 : 0;
          c.moveTo(hx - 7.2 + fr, headY + (face === 'side' ? 3 : 1)); c.quadraticCurveTo(hx - 8 + fr, headY - 9.5, hx + fr * .2, headY - 8.3); c.quadraticCurveTo(hx + 7.8, headY - 8.5, hx + 7.1, headY - 1);
          for (let i = 0; i < 5; i++) { const t = i / 4; c.lineTo(hx + lerp(6.4, -5.5, t) + (face === 'side' ? 1 : 0), headY - 3.2 + (i % 2 ? 1.6 : -.4)); }
          c.closePath(); outFill(c, gH(c, hx - 8, hx + 8, o.hair, .35, -.45));
          c.strokeStyle = 'rgba(255,255,255,.18)'; c.lineWidth = .8; c.beginPath(); c.moveTo(hx - 3, headY - 7); c.quadraticCurveTo(hx, headY - 8, hx + 3, headY - 7); c.stroke();
          if (o.fem && face !== 'side') { c.beginPath(); c.moveTo(hx - 7.2, headY - 2); c.quadraticCurveTo(hx - 8.6, headY + 6, hx - 7, shY + 6); c.lineTo(hx - 5.4, shY + 5); c.quadraticCurveTo(hx - 6.2, headY + 4, hx - 5.6, headY - 1); c.closePath(); outFill(c, o.hair, .8); c.beginPath(); c.moveTo(hx + 7.2, headY - 2); c.quadraticCurveTo(hx + 8.6, headY + 6, hx + 7, shY + 6); c.lineTo(hx + 5.4, shY + 5); c.quadraticCurveTo(hx + 6.2, headY + 4, hx + 5.6, headY - 1); c.closePath(); outFill(c, o.hair, .8); }
        }
      }
    }
    if (o.ears === 1) { for (const sx of [-4, 4]) { c.beginPath(); c.moveTo(hx + sx - 3, headY - 4); c.lineTo(hx + sx, headY - 13); c.lineTo(hx + sx + 3, headY - 4); c.closePath(); outFill(c, skin, .8); c.fillStyle = '#d88a8a'; c.beginPath(); c.moveTo(hx + sx - 1.4, headY - 5); c.lineTo(hx + sx, headY - 10); c.lineTo(hx + sx + 1.4, headY - 5); c.fill(); } }
    if (o.ears === 2) { for (const sd of [-1, 1]) { c.beginPath(); c.moveTo(hx + sd * 5.5, headY - 2.5); c.lineTo(hx + sd * 15, headY - 7); c.lineTo(hx + sd * 5.5, headY + 2); c.closePath(); outFill(c, skin, .8); } }
    if (o.horns) { for (const sd of [-1, 1]) { c.lineCap = 'round'; c.strokeStyle = OUTL; c.lineWidth = 4.4; c.beginPath(); c.moveTo(hx + sd * 6.5, headY - 4); c.quadraticCurveTo(hx + sd * 17, headY - 6, hx + sd * 15, headY - 17); c.stroke(); c.strokeStyle = '#ece0c4'; c.lineWidth = 2.8; c.stroke(); } }
    // helmets
    if (o.helm) drawHelm(c, o.helm, hx, headY, face, o.idle, W);
    if (o.hat) { c.beginPath(); c.ellipse(hx, headY - 3.5, 13.5, 3.8, 0, 0, 7); outFill(c, '#c9a85a'); c.beginPath(); c.moveTo(hx - 6.5, headY - 4.5); c.lineTo(hx, headY - 15); c.lineTo(hx + 6.5, headY - 4.5); c.closePath(); outFill(c, gH(c, hx - 6, hx + 6, '#d8b86a')); c.fillStyle = '#8a3a2a'; c.fillRect(hx - 6, headY - 6, 12, 1.6); }
    if (o.wizhat) { c.beginPath(); c.ellipse(hx, headY - 4.5, 11, 3.2, 0, 0, 7); outFill(c, shade(A.c, -.2)); c.beginPath(); c.moveTo(hx - 6.5, headY - 5.5); c.quadraticCurveTo(hx + 1, headY - 14, hx + 6 + Math.sin(o.idle) * 1.5, headY - 22); c.lineTo(hx + 6.5, headY - 5.5); c.closePath(); outFill(c, gH(c, hx - 6, hx + 6, A.c)); c.fillStyle = A.t; c.fillRect(hx - 6, headY - 7.2, 12.5, 1.6); }
    if (o.hood) { c.beginPath(); c.arc(hx, headY - 1, 8.6, Math.PI * .78, Math.PI * 2.22); c.lineTo(hx + 7.5, headY + 7); c.lineTo(hx - 7.5, headY + 7); c.closePath(); outFill(c, gH(c, hx - 9, hx + 9, o.cloth || '#3a2a2a')); if (face !== 'back') { c.fillStyle = '#080303'; c.beginPath(); c.ellipse(hx + (face === 'side' ? 3 : 0), headY + 1, 4.6, 5.2, 0, 0, 7); c.fill(); c.save(); c.globalCompositeOperation = 'lighter'; c.fillStyle = '#ff4a2a'; c.fillRect(hx - 2.2 + (face === 'side' ? 3 : 0), headY, 1.4, 1.2); c.fillRect(hx + 1 + (face === 'side' ? 3 : 0), headY, 1.4, 1.2); glow(c, hx + (face === 'side' ? 3 : 0), headY + .5, 6, '255,70,30', .3); c.restore(); } }
    if (o.crown) { c.beginPath(); c.moveTo(hx - 6.5, headY - 5.5); for (let i = 0; i < 5; i++) c.lineTo(hx - 6.5 + i * 3.25, headY - 6 - (i % 2 ? 1.5 : 7)); c.lineTo(hx + 6.5, headY - 5.5); c.closePath(); outFill(c, gH(c, hx - 7, hx + 7, '#e8b830', .4, -.35), .9); gem(c, hx, headY - 7.5, 1.2, '#ff3a3a'); }
  };

  // ======== DRAW ORDER ========
  drawCape(false);
  if (face === 'back') arm(true); else arm(false);
  if (o.tail) { c.lineCap = 'round'; c.strokeStyle = OUTL; c.lineWidth = 4.6; c.beginPath(); c.moveTo(-5, hipY + 1); c.quadraticCurveTo(-17, hipY - 5 + W * 3, -15, hipY - 16); c.stroke(); c.strokeStyle = shade(skin, -.15); c.lineWidth = 3; c.stroke(); }
  drawLegs();
  drawTorso();
  drawCape(true);
  drawNeck();
  drawHead();
  if (face === 'back') arm(false); else arm(true);
  c.filter = 'none';
  c.restore();
}

function drawHelm(c, h, hx, headY, face, idle, W) {
  const k = h.k === 'helm' ? 'nasal' : h.k; const col = h.c; const back = face === 'back', side = face === 'side';
  const dome = (r, lowY) => { c.beginPath(); c.arc(hx, headY - 1, r, Math.PI, 0); c.lineTo(hx + r, lowY); c.lineTo(hx - r, lowY); c.closePath(); };
  if (k === 'cap') {
    dome(7.4, headY - .5); outFill(c, gH(c, hx - 7, hx + 7, col, .3, -.45));
    if (!back) { for (const sd of side ? [-1] : [-1, 1]) { c.beginPath(); rr(c, hx + sd * 6.8 - 1.8, headY - 1.5, 3.6, 7, 1.4); outFill(c, shade(col, -.15), .8); } }
    c.strokeStyle = 'rgba(0,0,0,.35)'; c.setLineDash([1, 1]); c.lineWidth = .7; c.beginPath(); c.moveTo(hx, headY - 8); c.lineTo(hx, headY - 1); c.stroke(); c.setLineDash([]);
    c.fillStyle = shade(col, .2); c.fillRect(hx - 7.4, headY - 1.8, 14.8, 1.4);
  } else if (k === 'nasal') {
    dome(7.6, headY + .5); outFill(c, gH(c, hx - 8, hx + 8, col, .45, -.5));
    c.fillStyle = shade(col, -.25); c.fillRect(hx - 7.8, headY - 1, 15.6, 2.2); c.strokeStyle = OUTL; c.lineWidth = .7; c.strokeRect(hx - 7.8, headY - 1, 15.6, 2.2);
    c.fillStyle = '#f4e4b0'; for (let i = -2; i <= 2; i++) { c.beginPath(); c.arc(hx + i * 3, headY + .1, .5, 0, 7); c.fill(); }
    if (!back) { const nx = side ? hx + 5.5 : hx; c.fillStyle = shade(col, -.1); c.fillRect(nx - .9, headY, 1.8, 4.6); c.strokeStyle = OUTL; c.strokeRect(nx - .9, headY, 1.8, 4.6); if (!side) for (const sd of [-1, 1]) { c.beginPath(); c.moveTo(hx + sd * 7.6, headY + 1); c.lineTo(hx + sd * 7.4, headY + 6); c.lineTo(hx + sd * 5.4, headY + 5); c.closePath(); outFill(c, shade(col, -.15), .7); } }
    c.strokeStyle = 'rgba(255,255,255,.4)'; c.lineWidth = .9; c.beginPath(); c.arc(hx, headY - 1, 5.5, Math.PI * 1.15, Math.PI * 1.5); c.stroke();
  } else if (k === 'plume') {
    c.beginPath(); c.ellipse(hx, headY, 7.8, 8.2, 0, 0, 7); outFill(c, gH(c, hx - 8, hx + 8, col, .45, -.5));
    if (!back) { c.fillStyle = '#0a0806'; if (side) c.fillRect(hx + 2, headY - 1, 6, 1.6); else { c.fillRect(hx - 5, headY - 1, 10, 1.6); c.fillRect(hx - .8, headY - 1, 1.6, 5.5); } c.fillStyle = 'rgba(0,0,0,.35)'; for (let i = 0; i < 3; i++) c.fillRect(hx - 3 + i * 3 + (side ? 4 : 0), headY + 3, .8, 2); }
    c.strokeStyle = shade(col, .5); c.lineWidth = .9; c.beginPath(); c.moveTo(hx - 7.6, headY - 2); c.quadraticCurveTo(hx, headY - 4, hx + 7.6, headY - 2); c.stroke();
    const sw2 = Math.sin(idle * 2.3) * 1.2 - W * 1.5; const pc = h.p || '#c8302a';
    c.lineCap = 'round'; c.strokeStyle = OUTL; c.lineWidth = 4.6; c.beginPath(); c.moveTo(hx + 1, headY - 7.5); c.quadraticCurveTo(hx - 2, headY - 16, hx - 10 + sw2, headY - 9 + Math.abs(sw2)); c.stroke();
    c.strokeStyle = pc; c.lineWidth = 3.2; c.stroke(); c.strokeStyle = shade(pc, .35); c.lineWidth = 1.2; c.stroke();
    c.fillStyle = '#e0c060'; c.beginPath(); c.arc(hx + 1, headY - 7.5, 1.3, 0, 7); c.fill();
  } else if (k === 'skull') {
    dome(7.8, headY + .2); outFill(c, gH(c, hx - 8, hx + 8, col, .3, -.5));
    if (!back) { const ox = side ? 3.2 : 0; c.fillStyle = '#140a08'; c.beginPath(); c.ellipse(hx - 2.8 + ox, headY - 4.2, 1.8, 1.5, 0, 0, 7); if (!side) c.ellipse(hx + 2.8, headY - 4.2, 1.8, 1.5, 0, 0, 7); c.fill(); c.fillStyle = col; c.fillRect(hx - 6 + ox * .5, headY - .2, 12, 2.2); c.fillStyle = '#140a08'; for (let i = 0; i < 6; i++) c.fillRect(hx - 5.4 + ox * .5 + i * 2, headY, .5, 2); c.save(); c.globalCompositeOperation = 'lighter'; glow(c, hx - 2.8 + ox, headY - 4.2, 4, '120,255,140', .45); if (!side) glow(c, hx + 2.8, headY - 4.2, 4, '120,255,140', .45); c.restore(); }
    for (const sd of [-1, 1]) { c.beginPath(); c.moveTo(hx + sd * 5, headY - 6); c.quadraticCurveTo(hx + sd * 10, headY - 9, hx + sd * 9, headY - 13); c.lineTo(hx + sd * 6.6, headY - 7.5); c.closePath(); outFill(c, shade(col, -.1), .7); }
  } else if (k === 'abyss') {
    dome(7.6, headY + .2); outFill(c, gH(c, hx - 8, hx + 8, col, .35, -.5));
    for (let i = 0; i < 5; i++) { const a = Math.PI * (1.1 + i * .2); const bx = hx + Math.cos(a) * 7, by = headY - 1 + Math.sin(a) * 7; c.beginPath(); c.moveTo(bx - 1.3, by); c.lineTo(hx + Math.cos(a) * 14, headY - 1 + Math.sin(a) * (i === 2 ? 17 : 13)); c.lineTo(bx + 1.3, by); c.closePath(); outFill(c, gH(c, bx - 2, bx + 2, '#4a3a5a', .4, -.4), .7); }
    if (!back) gem(c, hx + (side ? 4 : 0), headY - 2.5, 1.8, '#c060ff', true);
    c.save(); c.globalCompositeOperation = 'lighter'; glow(c, hx, headY - 8, 14, '170,80,255', .25 + Math.sin(idle * 3) * .08); c.restore();
  } else if (k === 'dragon') {
    c.beginPath(); c.ellipse(hx, headY - .5, 8, 8.3, 0, Math.PI * .95, Math.PI * 2.05); c.lineTo(hx + 7.4, headY + 5); c.lineTo(hx + 4, headY + 6.2); c.lineTo(hx + 4, headY + 1); c.lineTo(hx - 4, headY + 1); c.lineTo(hx - 4, headY + 6.2); c.lineTo(hx - 7.4, headY + 5); c.closePath();
    outFill(c, gH(c, hx - 8, hx + 8, col, .5, -.45));
    c.fillStyle = shade(col, .25); for (let i = 0; i < 4; i++) { c.beginPath(); c.moveTo(hx - 1.5 - i * 1.4, headY - 8 + i * .7); c.lineTo(hx - 3 - i * 1.6, headY - 12 + i); c.lineTo(hx - .2 - i * 1.4, headY - 8.4 + i * .7); c.fill(); }
    for (const sd of [-1, 1]) { c.lineCap = 'round'; c.strokeStyle = OUTL; c.lineWidth = 3.8; c.beginPath(); c.moveTo(hx + sd * 6.5, headY - 3); c.quadraticCurveTo(hx + sd * 16, headY - 4, hx + sd * 13 - (side ? 4 : 0), headY - 17); c.stroke(); c.strokeStyle = '#f4ead0'; c.lineWidth = 2.4; c.stroke(); }
    if (!back) gem(c, hx + (side ? 4 : 0), headY - 3.5, 1.6, '#ff3a2a', true);
  }
}

/* ---------- transformation visuals ---------- */
function drawWings(c, x, y, col, edge, t, sc) {
  c.save(); c.translate(x, y - 40 * sc); c.scale(sc, sc);
  const flap = Math.sin(t * 5) * .25;
  for (const sd of [-1, 1]) {
    c.save(); c.scale(sd, 1); c.rotate(-.15 + flap * .6);
    c.beginPath(); c.moveTo(2, 0); c.quadraticCurveTo(14, -26, 34, -30); c.lineTo(30, -18); c.quadraticCurveTo(34, -10, 30, -2); c.quadraticCurveTo(26, 4, 24, 12); c.quadraticCurveTo(16, 6, 10, 14); c.quadraticCurveTo(6, 6, 2, 8); c.closePath();
    const g = c.createLinearGradient(0, -30, 30, 10); g.addColorStop(0, shade(col, .2)); g.addColorStop(1, shade(col, -.5)); c.fillStyle = g; c.globalAlpha = .88; c.fill(); c.globalAlpha = 1;
    c.strokeStyle = edge; c.lineWidth = 1.6; c.beginPath(); c.moveTo(2, 0); c.quadraticCurveTo(14, -26, 34, -30); c.moveTo(12, -18); c.lineTo(30, -2); c.moveTo(10, -10); c.lineTo(24, 12); c.stroke();
    c.restore();
  }
  c.restore();
}
/* ---------- appearance from equipment ---------- */
/* Every piece of jewellery has its own metal, stone and shape, on the body and in its icon. */
const JEWEL = {
  bead_necklace: { m: '#7a4a2a', g: '#c89a5a', s: 'beads' }, gold_necklace: { m: '#f0c850', g: '#ffe890', s: 'chain' }, fang_necklace: { m: '#5a3a1a', g: '#f4ecd8', s: 'fang' },
  amber_necklace: { m: '#e0b048', g: '#ff9a20', s: 'chain' }, jade_necklace: { m: '#d8c068', g: '#3ac878', s: 'disc' }, bone_necklace: { m: '#4a3020', g: '#ece2c8', s: 'skull' },
  crystal_necklace: { m: '#dfe8f4', g: '#8ad8ff', s: 'shard' }, spirit_beads: { m: '#3a2a1a', g: '#6aff9a', s: 'beads' }, luck_pendant: { m: '#ffd860', g: '#ffd860', s: 'clover' }, abyss_amulet: { m: '#3a2a4a', g: '#c060ff', s: 'heart' },
  iron_bracelet: { m: '#8e949c', g: null }, silver_bracelet: { m: '#e8ecf2', g: '#ffffff' }, blackiron_bracelet: { m: '#3a3c44', g: '#ff5a3a', s: 'spiked' }, magic_bracelet: { m: '#8a6ad8', g: '#d0b0ff' },
  spirit_bracelet: { m: '#4ab870', g: '#b8ffd0', s: 'beads' }, dragon_bracelet: { m: '#f0c050', g: '#ff3a1a', s: 'scaled' }, abyss_band: { m: '#2a2036', g: '#c060ff', s: 'spiked' },
  copper_ring: { m: '#c8834e', g: '#40d0c0' }, hex_ring: { m: '#b8bec6', g: '#e0463a' }, ruby_ring: { m: '#f0c850', g: '#ff1a3a' }, jade_ring: { m: '#f0c850', g: '#30c070' },
  coral_ring: { m: '#e8ecf2', g: '#ff7a5a' }, sapphire_ring: { m: '#e8ecf2', g: '#3a6aff' }, emerald_ring: { m: '#f0c850', g: '#10d060' }, dragon_ring: { m: '#ffc040', g: '#ff8a10' },
  ring_paralysis: { m: '#3a3c44', g: '#c070ff' }, ring_revival: { m: '#ffd860', g: '#fff0a0' }, ring_protection: { m: '#e8ecf2', g: '#70b0ff' }, ring_teleport: { m: '#9aa2ae', g: '#60f0ff' }, ring_healing: { m: '#f0c850', g: '#70ff90' }, abyss_ring: { m: '#2a2036', g: '#c060ff' },
};
function jewelLook(it, isNeck) {
  if (!it) return null; const d = ITEMS[it.id]; const j = JEWEL[it.id] || { m: '#e0bc5a', g: statGem(d) };
  return { m: j.m, g: j.g, s: j.s || null, sp: d.special || null, q: d.q || 0, enh: addTotal(it) > 0, big: d.lv >= 20, glow: d.q > 0 || addTotal(it) > 0 || /magic|spirit|dragon|abyss/.test(it.id) };
}
function refineGlow(r, base) { if (r >= 7) return '#ffb040'; if (r >= 5) return '#c080ff'; if (r >= 3) return '#7ab8ff'; return base || null; }
function lookFromEquip(eq, base) {
  const w = eq.weapon, a = eq.armour, h = eq.helmet;
  const al = a ? ITEMS[a.id].look : null, wl = w ? ITEMS[w.id].look : null, hl = h ? ITEMS[h.id].look : null;
  return Object.assign({}, base, {
    armor: al ? Object.assign({}, al, { q: ITEMS[a.id].q || 0 }) : { c: '#8a7a62', t: '#6a5238', style: 'tunic' },
    helm: hl ? { c: hl.c, k: hl.k, p: hl.p } : null,
    weapon: wl ? { k: wl.k, c: (w.r || 0) >= 1 ? shade(wl.c, Math.min(.35, (w.r || 0) * .06)) : wl.c, glow: refineGlow(w.r || 0, wl.glow || (addTotal(w) > 0 ? null : null)), r: w.r || 0 } : null,
    neck: jewelLook(eq.necklace, true), braceL: jewelLook(eq.braceletL), braceR: jewelLook(eq.braceletR), ringL: jewelLook(eq.ringL), ringR: jewelLook(eq.ringR),
  });
}
