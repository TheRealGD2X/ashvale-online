/* ================= CHARACTER & MONSTER DRAWING ================= */
function rr(c, x, y, w, h, r) { c.beginPath(); c.moveTo(x + r, y); c.arcTo(x + w, y, x + w, y + h, r); c.arcTo(x + w, y + h, x, y + h, r); c.arcTo(x, y + h, x, y, r); c.arcTo(x, y, x + w, y, r); c.closePath(); }
function limb(c, x0, y0, x1, y1, w, col) { c.strokeStyle = col; c.lineWidth = w; c.lineCap = 'round'; c.beginPath(); c.moveTo(x0, y0); c.lineTo(x1, y1); c.stroke(); }

function drawWeapon(c, k, col, glowC, len) {
  // drawn along +y from the hand at (0,0); the caller rotates
  const L = len || 1;
  const blade = (bl, bw, tipFn) => { const g = c.createLinearGradient(-bw, 0, bw, 0); g.addColorStop(0, shade(col, -.4)); g.addColorStop(.45, shade(col, .45)); g.addColorStop(.55, shade(col, .15)); g.addColorStop(1, shade(col, -.3)); c.fillStyle = g; c.beginPath(); tipFn(bl, bw); c.fill(); c.strokeStyle = 'rgba(10,6,4,.7)'; c.lineWidth = .7; c.stroke(); };
  const hilt = (gc, gw) => { c.fillStyle = '#3a2412'; c.fillRect(-1.5, -6, 3, 8); c.fillStyle = '#6a4424'; for (let i = -5; i < 2; i += 2) c.fillRect(-1.5, i, 3, .7); c.fillStyle = gc || '#c9a040'; c.fillRect(-(gw || 5), 2, (gw || 5) * 2, 2.6); c.beginPath(); c.arc(0, -6.5, 1.8, 0, 7); c.fill(); };
  const straight = (bl, bw) => { c.moveTo(-bw / 2, 4.6); c.lineTo(bw / 2, 4.6); c.lineTo(bw / 2, bl - 5); c.lineTo(0, bl); c.lineTo(-bw / 2, bl - 5); c.closePath(); };
  const staffShaft = (h, sc) => { const g = c.createLinearGradient(-2, 0, 2, 0); g.addColorStop(0, shade(sc, .3)); g.addColorStop(1, shade(sc, -.4)); c.fillStyle = g; c.fillRect(-1.6, -12, 3.2, h); c.strokeStyle = 'rgba(0,0,0,.5)'; c.lineWidth = .6; c.strokeRect(-1.6, -12, 3.2, h); };
  if (glowC) { c.shadowColor = glowC; c.shadowBlur = 12; }
  switch (k) {
    case 'wood': hilt('#6a4a2a', 3.5); blade(22 * L, 4, (bl, bw) => { c.moveTo(-bw / 2, 4.6); c.lineTo(bw / 2, 4.6); c.lineTo(bw / 2, bl - 3); c.quadraticCurveTo(0, bl + 1, -bw / 2, bl - 3); c.closePath(); }); c.strokeStyle = 'rgba(60,30,10,.4)'; c.beginPath(); c.moveTo(0, 7); c.lineTo(.5, 20 * L); c.stroke(); break;
    case 'dagger': hilt('#9a9aa0', 3.5); blade(17 * L, 3.4, straight); break;
    case 'leaf': hilt('#8a5a2a', 4); blade(24 * L, 3, (bl, bw) => { c.moveTo(-bw / 2, 4.6); c.quadraticCurveTo(-bw * 1.4, bl * .6, 0, bl); c.quadraticCurveTo(bw * 1.4, bl * .6, bw / 2, 4.6); c.closePath(); }); break;
    case 'sword': hilt(); blade(25 * L, 3.2, straight); break;
    case 'long': hilt('#d8d8e0', 6.5); blade(31 * L, 3.8, straight); c.strokeStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.moveTo(0, 7); c.lineTo(0, 25 * L); c.stroke(); break;
    case 'greatsword': hilt('#8a8a90', 6); blade(35 * L, 5, straight); break;
    case 'blade': hilt(); blade(28 * L, 4, (bl, bw) => { c.moveTo(-bw / 2, 4.6); c.lineTo(bw / 2, 4.6); c.quadraticCurveTo(bw * 1.4, bl * .6, 0, bl); c.quadraticCurveTo(-bw * .3, bl * .5, -bw / 2, 4.6); c.closePath(); }); break;
    case 'curved': hilt('#c9a040', 5); blade(30 * L, 4.4, (bl, bw) => { c.moveTo(-bw / 2, 4.6); c.lineTo(bw / 2, 4.6); c.quadraticCurveTo(bw * 2.8, bl * .55, bw * 1.2, bl); c.quadraticCurveTo(bw * .6, bl * .55, -bw / 2, 4.6); c.closePath(); }); break;
    case 'serrated': hilt('#2a0a0a', 6); blade(32 * L, 5.4, (bl, bw) => { c.moveTo(-bw / 2, 4.6); c.lineTo(bw / 2, 4.6); for (let y = 8; y < bl - 4; y += 4) { c.lineTo(bw / 2 + 2, y + 2); c.lineTo(bw / 2, y + 4); } c.lineTo(0, bl); c.lineTo(-bw / 2, bl - 5); c.closePath(); }); c.fillStyle = '#ff4a2a'; c.fillRect(-.6, 8, 1.2, 20 * L); break;
    case 'dragonblade': {
      c.fillStyle = '#3a1a0a'; c.fillRect(-1.8, -7, 3.6, 9); c.fillStyle = '#e8a030'; c.beginPath(); c.moveTo(-8, 1); c.quadraticCurveTo(-4, 6, 0, 3); c.quadraticCurveTo(4, 6, 8, 1); c.lineTo(5, 5); c.lineTo(-5, 5); c.fill(); gem(c, 0, 3.5, 1.5, '#ff3a1a');
      blade(38 * L, 6, (bl, bw) => { c.moveTo(-bw / 2, 5); c.lineTo(bw / 2, 5); c.quadraticCurveTo(bw * .9, bl * .5, bw * .7, bl - 7); c.lineTo(0, bl); c.lineTo(-bw * .7, bl - 7); c.quadraticCurveTo(-bw * .9, bl * .5, -bw / 2, 5); c.closePath(); });
      c.fillStyle = '#ff6a2a'; c.beginPath(); c.moveTo(-1, 8); c.lineTo(1, 8); c.lineTo(.4, 30 * L); c.lineTo(-.4, 30 * L); c.fill(); break;
    }
    case 'axe': case 'greataxe': {
      const hl = (k === 'greataxe' ? 36 : 26) * L; c.fillStyle = '#5a3a1e'; c.fillRect(-1.6, -4, 3.2, hl); c.fillStyle = '#3a2412'; c.fillRect(-1.8, hl - 16, 3.6, 3);
      const head = (sd) => { c.beginPath(); c.moveTo(sd, hl - 13); c.quadraticCurveTo(sd * (k === 'greataxe' ? 17 : 12), hl - 10, sd * (k === 'greataxe' ? 15 : 11), hl + 3); c.quadraticCurveTo(sd * 6, hl - 2, sd, hl - 2); c.closePath(); c.fillStyle = gH(c, -12, 12, col); c.fill(); c.strokeStyle = 'rgba(10,6,4,.7)'; c.lineWidth = .7; c.stroke(); };
      head(1); if (k === 'greataxe') head(-1); break;
    }
    case 'kris': hilt('#c9a040', 4.5); blade(26 * L, 3.4, (bl, bw) => { c.moveTo(-bw / 2, 4.6); for (let i = 0; i <= 6; i++) { const y = 4.6 + (bl - 6) * i / 6; c.lineTo(bw / 2 + Math.sin(i * 1.6) * 1.8, y); } c.lineTo(0, bl); for (let i = 6; i >= 0; i--) { const y = 4.6 + (bl - 6) * i / 6; c.lineTo(-bw / 2 + Math.sin(i * 1.6) * 1.8, y); } c.closePath(); }); break;
    case 'jade': hilt('#3a8a5a', 5); blade(28 * L, 4, straight); c.fillStyle = '#c82a1a'; c.beginPath(); c.moveTo(0, -7); c.quadraticCurveTo(-4, -12, -2, -18); c.lineTo(0, -11); c.fill(); break;
    case 'moon': hilt('#dfe8ff', 5); blade(29 * L, 3.6, straight); c.strokeStyle = '#eef4ff'; c.lineWidth = 2; c.beginPath(); c.arc(0, 3.5, 6.5, Math.PI * .1, Math.PI * .9); c.stroke(); break;
    case 'reaver': hilt('#1a3a2a', 5.5); blade(31 * L, 5, (bl, bw) => { c.moveTo(-bw / 2, 4.6); c.lineTo(bw / 2, 4.6); c.lineTo(bw / 2 + 3, bl * .5); c.lineTo(bw / 2, bl * .55); c.lineTo(0, bl); c.lineTo(-bw / 2, bl - 5); c.closePath(); }); c.fillStyle = '#7aff9a'; c.fillRect(-.5, 7, 1, 20 * L); break;
    case 'fang': hilt('#c9a040', 5); blade(30 * L, 6, (bl, bw) => { c.moveTo(-bw / 2, 4.6); c.lineTo(bw / 2, 4.6); c.quadraticCurveTo(bw * .7, bl * .7, bw * 1.1, bl); c.quadraticCurveTo(-bw * .2, bl * .8, -bw / 2, 4.6); c.closePath(); }); break;
    case 'abyssblade': hilt('#6a3a9a', 7); blade(40 * L, 6.4, (bl, bw) => { c.moveTo(-bw / 2, 5); c.lineTo(bw / 2, 5); c.lineTo(bw * .9, bl * .35); c.lineTo(bw * .5, bl * .42); c.lineTo(bw * .7, bl - 8); c.lineTo(0, bl); c.lineTo(-bw * .7, bl - 8); c.lineTo(-bw * .5, bl * .42); c.lineTo(-bw * .9, bl * .35); c.closePath(); }); c.fillStyle = '#d090ff'; c.fillRect(-.6, 9, 1.2, 28 * L); break;
    case 'staff': staffShaft(40 * L, '#4a3220'); c.fillStyle = col; c.beginPath(); c.arc(0, -13, 4.5, 0, 7); c.fill(); c.fillStyle = 'rgba(255,255,255,.6)'; c.beginPath(); c.arc(-1.2, -14.5, 1.5, 0, 7); c.fill(); break;
    case 'wand': c.fillStyle = '#2a1a3a'; c.fillRect(-1.2, -2, 2.4, 21); gem(c, 0, 20, 3.2, col); break;
    case 'skullstaff': staffShaft(40 * L, '#d8ccb0'); c.fillStyle = col; c.beginPath(); c.arc(0, -15, 5, 0, 7); c.fill(); c.fillRect(-3, -12, 6, 3); c.fillStyle = '#1a0a08'; c.beginPath(); c.arc(-1.8, -15.5, 1.3, 0, 7); c.arc(1.8, -15.5, 1.3, 0, 7); c.fill(); break;
    case 'crystalstaff': staffShaft(40 * L, '#5a6a8a'); for (const [dx2, h2] of [[-2.5, 9], [0, 13], [2.5, 8]]) { c.fillStyle = col; c.beginPath(); c.moveTo(dx2 - 2, -11); c.lineTo(dx2, -11 - h2); c.lineTo(dx2 + 2, -11); c.fill(); c.fillStyle = 'rgba(255,255,255,.6)'; c.fillRect(dx2 - .4, -11 - h2 * .8, .8, h2 * .6); } break;
    case 'emberstaff': staffShaft(40 * L, '#3a2418'); c.strokeStyle = '#6a4a2a'; c.lineWidth = 1.6; c.beginPath(); c.arc(0, -16, 5, 0, 7); c.stroke(); c.fillStyle = col; c.beginPath(); c.moveTo(-3, -13); c.quadraticCurveTo(-3, -20, 0, -24); c.quadraticCurveTo(3, -20, 3, -13); c.fill(); c.fillStyle = '#ffe070'; c.beginPath(); c.arc(0, -15.5, 1.8, 0, 7); c.fill(); break;
    case 'dragonstaff': staffShaft(42 * L, '#8a5a1a'); c.fillStyle = '#e8b030'; c.beginPath(); c.moveTo(-2, -11); c.quadraticCurveTo(-9, -16, -5, -24); c.lineTo(-2, -19); c.lineTo(2, -19); c.lineTo(5, -24); c.quadraticCurveTo(9, -16, 2, -11); c.fill(); gem(c, 0, -17, 3, '#ff3a1a'); break;
    case 'abyssstaff': staffShaft(46 * L, '#2a1a3a'); c.strokeStyle = '#6a3a9a'; c.lineWidth = 1.8; for (const sd of [-1, 1]) { c.beginPath(); c.moveTo(0, -11); c.quadraticCurveTo(sd * 9, -18, sd * 3, -27); c.stroke(); } gem(c, 0, -19, 3.6, '#c060ff'); break;
    case 'abyssfang': hilt('#6a3a9a', 5.5); blade(32 * L, 5.4, (bl, bw) => { c.moveTo(-bw / 2, 4.6); c.lineTo(bw / 2, 4.6); c.quadraticCurveTo(bw * 1.6, bl * .5, 0, bl); c.quadraticCurveTo(-bw * .5, bl * .6, -bw / 2, 4.6); c.closePath(); }); c.fillStyle = '#b8ffb8'; c.fillRect(-.5, 7, 1, 22 * L); break;
    case 'worldbreaker': { c.fillStyle = '#2a1a10'; c.fillRect(-2, -8, 4, 11); c.fillStyle = '#6a3a1a'; c.beginPath(); c.moveTo(-9, 1); c.lineTo(9, 1); c.lineTo(6, 6); c.lineTo(-6, 6); c.fill();
      blade(44 * L, 9, (bl, bw) => { c.moveTo(-bw / 2, 5); c.lineTo(bw / 2, 5); c.lineTo(bw * .75, bl * .3); c.lineTo(bw * .55, bl * .5); c.lineTo(bw * .8, bl * .75); c.lineTo(0, bl); c.lineTo(-bw * .8, bl * .75); c.lineTo(-bw * .55, bl * .5); c.lineTo(-bw * .75, bl * .3); c.closePath(); });
      c.strokeStyle = '#ff8a2a'; c.lineWidth = 1.2; c.beginPath(); c.moveTo(0, 8); c.lineTo(2, 18); c.lineTo(-1.5, 28); c.lineTo(1.5, 38 * L); c.moveTo(-2, 14); c.lineTo(-3.5, 20); c.moveTo(2, 26); c.lineTo(4, 31); c.stroke(); gem(c, 0, 3.5, 2, '#ff5a10', true); break; }
    case 'eternity': { staffShaft(44 * L, '#c8d8e8'); c.strokeStyle = '#e8f4ff'; c.lineWidth = 1.6; c.beginPath(); c.arc(0, -19, 7, 0, 7); c.stroke(); for (let i = 0; i < 12; i++) { const a = i * Math.PI / 6; c.fillStyle = '#e8f4ff'; c.fillRect(Math.cos(a) * 7 - .5, -19 + Math.sin(a) * 7 - .5, 1, 1); } c.strokeStyle = '#6ae0ff'; c.lineWidth = 1; c.beginPath(); c.moveTo(0, -19); c.lineTo(0, -24); c.moveTo(0, -19); c.lineTo(4, -19); c.stroke(); gem(c, 0, -30, 2.6, '#9af0ff', true); break; }
    case 'bough': { c.strokeStyle = '#5a3a1a'; c.lineWidth = 3.4; c.lineCap = 'round'; c.beginPath(); c.moveTo(0, 28 * L); c.quadraticCurveTo(-3, 8, 1, -6); c.quadraticCurveTo(4, -14, -2, -22); c.stroke(); c.lineWidth = 1.6; c.beginPath(); c.moveTo(1, -8); c.quadraticCurveTo(8, -14, 9, -22); c.stroke();
      for (const [lx, ly] of [[-6, -20], [9, -24], [5, -14], [-4, -12], [2, -27]]) { c.fillStyle = '#4ac86a'; c.beginPath(); c.ellipse(lx, ly, 3.2, 1.6, lx * .1, 0, 7); c.fill(); } gem(c, 0, -24, 2.6, '#ffb8e8', true); break; }
    case 'club': c.fillStyle = '#6a4a2a'; c.beginPath(); c.moveTo(-1.5, -2); c.lineTo(1.5, -2); c.lineTo(4, 22); c.lineTo(-4, 22); c.fill(); c.fillStyle = '#4a3218'; c.beginPath(); c.arc(0, 21, 5, 0, 7); c.fill(); c.fillStyle = '#9a9aa0'; for (let i = 0; i < 4; i++) c.fillRect(-5 + i * 3, 17 + (i % 2) * 5, 1.4, 1.4); break;
    case 'stick': c.fillStyle = '#7a5a30'; c.fillRect(-1.2, -4, 2.4, 22); break;
    case 'hook': c.strokeStyle = '#b8c0c8'; c.lineWidth = 2; c.beginPath(); c.moveTo(0, 0); c.lineTo(0, 12); c.arc(4, 12, 4, Math.PI, 0, true); c.stroke(); break;
    case 'rake': c.fillStyle = '#6a4a2a'; c.fillRect(-1.2, -4, 2.4, 22); c.fillStyle = '#9aa2aa'; c.fillRect(-6, 18, 12, 2); for (let i = -6; i <= 6; i += 3) c.fillRect(i, 18, 1.4, 6); break;
    case 'bow': c.strokeStyle = '#6a4a2a'; c.lineWidth = 2.5; c.beginPath(); c.arc(-6, 8, 14, -1.1, 1.1); c.stroke(); c.strokeStyle = '#ddd'; c.lineWidth = .8; c.beginPath(); c.moveTo(-6 + 14 * Math.cos(-1.1), 8 + 14 * Math.sin(-1.1)); c.lineTo(-6 + 14 * Math.cos(1.1), 8 + 14 * Math.sin(1.1)); c.stroke(); break;
  }
  c.shadowBlur = 0;
}

/* drawHuman lives in js3b_human.js */
function drawQuad(c, x, y, o) {
  const s = o.size || 1; c.save(); c.translate(x, y);
  c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(0, 0, 17 * s, 5 * s, 0, 0, 7); c.fill();
  if (o.fall) c.rotate(o.fall * .3);
  c.scale(s * (o.faceL ? -1 : 1), s);
  if (o.flash) c.filter = 'brightness(2.2)';
  const w = o.moving ? Math.sin(o.walk * Math.PI * 2) : 0; const col = o.col;
  const lunge = o.atk >= 0 ? Math.sin(o.atk * Math.PI) * 5 : 0;
  c.translate(lunge, 0);
  for (const [lx, ph, dk] of [[-9, 1, -.3], [7, -1, -.3], [-7, -1, 0], [9, 1, 0]]) limb(c, lx, -12, lx + w * 4 * ph, -1, 3.5, shade(col, dk - .15));
  const g = c.createLinearGradient(0, -24, 0, -8); g.addColorStop(0, shade(col, .2)); g.addColorStop(1, shade(col, -.3));
  c.fillStyle = g; c.beginPath(); c.ellipse(0, -15, 15, 8, 0, 0, 7); c.fill();
  if (o.tusks) { c.fillStyle = shade(col, -.35); for (let i = -10; i < 8; i += 3) c.fillRect(i, -24, 2, 4); }
  // head
  c.fillStyle = shade(col, .05); c.beginPath(); c.ellipse(15, -19 + (o.atk >= 0 ? 3 : 0), 7, 5.5, .3, 0, 7); c.fill();
  c.beginPath(); c.ellipse(21, -16 + (o.atk >= 0 ? 3 : 0), 4, 3.5, .2, 0, 7); c.fill();
  c.fillStyle = '#111'; c.fillRect(16, -22, 1.8, 1.8);
  if (o.tusks) { c.fillStyle = '#f0e8d0'; c.beginPath(); c.moveTo(21, -15); c.quadraticCurveTo(27, -16, 26, -22); c.lineTo(23, -16); c.fill(); }
  if (o.antlers) { c.strokeStyle = '#d8c8a0'; c.lineWidth = 1.6; c.beginPath(); c.moveTo(13, -23); c.lineTo(10, -33); c.lineTo(6, -36); c.moveTo(10, -30); c.lineTo(14, -35); c.moveTo(15, -23); c.lineTo(17, -32); c.lineTo(21, -35); c.stroke(); c.fillStyle = '#f4ecd8'; for (let i = 0; i < 4; i++) c.fillRect(-8 + i * 4, -19 + (i % 2) * 2, 2, 2); }
  c.fillStyle = shade(col, -.2); c.beginPath(); c.moveTo(11, -24); c.lineTo(12, -28); c.lineTo(14, -23); c.fill();
  c.filter = 'none'; c.restore();
}
function drawHen(c, x, y, o) {
  const s = o.size || 1; c.save(); c.translate(x, y);
  c.fillStyle = 'rgba(0,0,0,.25)'; c.beginPath(); c.ellipse(0, 0, 8 * s, 3 * s, 0, 0, 7); c.fill();
  if (o.fall) c.rotate(o.fall * 1.4);
  c.scale(s * (o.faceL ? -1 : 1), s); if (o.flash) c.filter = 'brightness(2)';
  const w = o.moving ? Math.sin(o.walk * Math.PI * 4) : 0; const peck = o.atk >= 0 ? Math.sin(o.atk * Math.PI) * 5 : 0;
  limb(c, -2, -5, -2 + w * 2, 0, 1.4, '#d8a030'); limb(c, 2, -5, 2 - w * 2, 0, 1.4, '#d8a030');
  c.fillStyle = o.col; c.beginPath(); c.ellipse(0, -9, 8, 6, -.2, 0, 7); c.fill(); c.fillStyle = shade(o.col, -.12); c.beginPath(); c.ellipse(-7, -12, 4, 5, -.6, 0, 7); c.fill();
  c.fillStyle = shade(o.col, -.2); c.beginPath(); c.ellipse(-1, -9, 5, 3, -.3, 0, 7); c.fill();
  c.fillStyle = o.col; c.beginPath(); c.arc(6 + peck * .6, -15 + peck, 4, 0, 7); c.fill();
  c.fillStyle = '#d82a2a'; c.fillRect(5 + peck * .6, -21 + peck, 3, 3); c.fillRect(9 + peck * .6, -13 + peck, 2, 3);
  c.fillStyle = '#e8a020'; c.beginPath(); c.moveTo(9 + peck * .6, -16 + peck); c.lineTo(13 + peck * .6, -14.5 + peck); c.lineTo(9 + peck * .6, -13 + peck); c.fill();
  c.fillStyle = '#111'; c.fillRect(6.5 + peck * .6, -16.5 + peck, 1.5, 1.5);
  c.filter = 'none'; c.restore();
}
function drawWorm(c, x, y, o) {
  const s = o.size || 1; c.save(); c.translate(x, y); c.scale(s * (o.faceL ? -1 : 1), s); if (o.flash) c.filter = 'brightness(2)';
  c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(0, 0, 16, 4, 0, 0, 7); c.fill();
  const t = o.walk * Math.PI * 2 + o.idle;
  const rear = o.atk >= 0 ? Math.sin(o.atk * Math.PI) * 10 : 0;
  for (let i = 5; i >= 0; i--) { const px = -12 + i * 5, py = -5 - Math.abs(Math.sin(t + i * .8)) * 3 - (i > 3 ? rear * (i - 3) / 2 : 0); c.fillStyle = i % 2 ? o.col : shade(o.col, -.12); c.beginPath(); c.ellipse(px, py, 5.5 - (5 - i) * .3, 5 - (5 - i) * .3, 0, 0, 7); c.fill(); }
  c.fillStyle = '#3a1a10'; c.beginPath(); c.arc(15, -7 - rear, 2.5, 0, 7); c.fill();
  c.filter = 'none'; c.restore();
}
function drawFlyer(c, x, y, o) {
  const s = o.size || 1; c.save(); c.translate(x, y);
  c.fillStyle = 'rgba(0,0,0,.2)'; c.beginPath(); c.ellipse(0, 0, 10 * s, 3 * s, 0, 0, 7); c.fill();
  const hover = -26 - Math.sin(o.idle * 3) * 3 + (o.fall ? o.fall * 24 : 0);
  c.translate(0, hover); c.scale(s * (o.faceL ? -1 : 1), s); if (o.flash) c.filter = 'brightness(2)';
  const f = Math.sin(o.idle * 22) ;
  c.fillStyle = o.wing;
  for (const sd of [-1, 1]) { c.beginPath(); c.moveTo(0, 0); if (o.moth) { c.ellipse(sd * 9, -2 - f * 4, 10, 6 + f * 3, sd * .4, 0, 7); } else { c.lineTo(sd * 8, -6 - f * 8); c.lineTo(sd * 18, -2 - f * 10); c.lineTo(sd * 14, 3); c.lineTo(sd * 8, 1); } c.fill(); }
  if (o.moth) { c.fillStyle = 'rgba(255,240,200,.35)'; for (const sd of [-1, 1]) { c.beginPath(); c.arc(sd * 10, -3 - f * 4, 3, 0, 7); c.fill(); } }
  c.fillStyle = o.col; c.beginPath(); c.ellipse(0, 0, 5, 6, 0, 0, 7); c.fill();
  c.fillStyle = o.moth ? '#1a1a1a' : '#ff3a3a'; c.fillRect(-2.5, -3, 1.6, 1.6); c.fillRect(1, -3, 1.6, 1.6);
  if (!o.moth) { c.fillStyle = o.col; c.beginPath(); c.moveTo(-4, -4); c.lineTo(-3, -9); c.lineTo(-1, -5); c.moveTo(4, -4); c.lineTo(3, -9); c.lineTo(1, -5); c.fill(); }
  c.filter = 'none'; c.restore();
}
function drawSpider(c, x, y, o) {
  const s = o.size || 1; c.save(); c.translate(x, y); c.scale(s * (o.faceL ? -1 : 1), s); if (o.flash) c.filter = 'brightness(2)';
  c.fillStyle = 'rgba(0,0,0,.3)'; c.beginPath(); c.ellipse(0, 0, 18, 5, 0, 0, 7); c.fill();
  if (o.fall) c.scale(1, 1 - o.fall * .5);
  const w = (o.moving ? o.walk : o.idle * .1) * Math.PI * 4;
  for (let i = 0; i < 4; i++) for (const sd of [-1, 1]) {
    const bx = -2 + i * 3, ph = Math.sin(w + i * 1.3 + (sd > 0 ? 0 : Math.PI)) * 3;
    c.strokeStyle = shade(o.col, -.2); c.lineWidth = 1.8; c.beginPath(); c.moveTo(bx, -8); c.lineTo(bx + sd * 6 + (i - 1.5) * 4, -15 + ph * .5); c.lineTo(bx + sd * 4 + (i - 1.5) * 7 + ph, -1); c.stroke();
  }
  c.fillStyle = o.col; c.beginPath(); c.ellipse(-6, -10, 9, 7, 0, 0, 7); c.fill(); c.fillStyle = o.mark; c.beginPath(); c.moveTo(-6, -15); c.lineTo(-3, -10); c.lineTo(-6, -6); c.lineTo(-9, -10); c.fill();
  c.fillStyle = shade(o.col, .1); c.beginPath(); c.ellipse(5, -9, 5, 4.5, 0, 0, 7); c.fill();
  c.fillStyle = '#ff3a2a'; c.fillRect(7, -11, 1.5, 1.5); c.fillRect(9, -10, 1.5, 1.5);
  c.filter = 'none'; c.restore();
}
function drawSnake(c, x, y, o) {
  const s = o.size || 1; c.save(); c.translate(x, y); c.scale(s * (o.faceL ? -1 : 1), s); if (o.flash) c.filter = 'brightness(2)';
  c.fillStyle = 'rgba(0,0,0,.25)'; c.beginPath(); c.ellipse(0, 0, 18, 4, 0, 0, 7); c.fill();
  const t = o.walk * Math.PI * 2 + o.idle * 2; const rear = o.atk >= 0 ? Math.sin(o.atk * Math.PI) : 0;
  c.strokeStyle = o.col; c.lineWidth = 6; c.lineCap = 'round'; c.beginPath();
  for (let i = 0; i <= 12; i++) { const px = -18 + i * 2.6, py = -4 + Math.sin(t + i * .7) * 3 * (1 - i / 14); i ? c.lineTo(px, py) : c.moveTo(px, py); }
  c.stroke();
  c.lineWidth = 5; c.beginPath(); c.moveTo(13, -4); c.quadraticCurveTo(15, -14 - rear * 6, 19 + rear * 6, -18 - rear * 4); c.stroke();
  c.fillStyle = o.col; c.beginPath(); c.ellipse(21 + rear * 6, -19 - rear * 4, 5, 3.5, 0, 0, 7); c.fill();
  c.fillStyle = '#ffd030'; c.fillRect(22 + rear * 6, -21 - rear * 4, 1.6, 1.6);
  c.strokeStyle = '#d02020'; c.lineWidth = 1; c.beginPath(); c.moveTo(26 + rear * 6, -19 - rear * 4); c.lineTo(29 + rear * 7, -18 - rear * 4); c.stroke();
  c.filter = 'none'; c.restore();
}
function drawSummonHound(c, x, y, o) {
  const q = { ...o, col: '#c84a1a', size: 1.1 }; drawQuad(c, x, y, q);
  c.save(); c.globalCompositeOperation = 'lighter'; const g = c.createRadialGradient(x, y - 18, 2, x, y - 18, 26); g.addColorStop(0, 'rgba(255,120,40,.35)'); g.addColorStop(1, 'rgba(255,60,0,0)'); c.fillStyle = g; c.fillRect(x - 30, y - 45, 60, 50); c.restore();
}

/* ================= PARTICLES & EFFECTS ================= */
const FX = [], PARTS = [], FLOATS = [];
function part(x, y, o) { if (PARTS.length > 1400) return; PARTS.push(Object.assign({ x, y, vx: 0, vy: 0, life: 1, max: 1, size: 3, col: '255,200,120', add: 1, grav: 0, shrink: 1 }, o)); }
function burst(x, y, n, col, spd, life, size, grav, up) {
  for (let i = 0; i < n; i++) { const a = R() * Math.PI * 2, v = spd * (.3 + R() * .7); part(x, y, { vx: Math.cos(a) * v, vy: Math.sin(a) * v * .6 - (up || 0), life: life * (.6 + R() * .6), max: life, size: size * (.6 + R() * .6), col, grav: grav || 0 }); }
}
function fx(type, x, y, o) { const e = Object.assign({ type, x, y, t: 0, dur: 1 }, o); FX.push(e); return e; }
function floatText(x, y, text, col, big) { FLOATS.push({ x: x + (R() - .5) * 10, y, text, col, t: 0, big }); }

function drawBolt(c, x0, y0, x1, y1, w, col, jag) {
  const segs = 10; c.beginPath(); c.moveTo(x0, y0);
  for (let i = 1; i < segs; i++) { const t = i / segs; c.lineTo(lerp(x0, x1, t) + (R() - .5) * jag, lerp(y0, y1, t) + (R() - .5) * jag * .3); }
  c.lineTo(x1, y1); c.strokeStyle = col; c.lineWidth = w; c.stroke();
}
function glow(c, x, y, r, col, a) { const g = c.createRadialGradient(x, y, 0, x, y, r); g.addColorStop(0, `rgba(${col},${a})`); g.addColorStop(1, `rgba(${col},0)`); c.fillStyle = g; c.fillRect(x - r, y - r, r * 2, r * 2); }

function updateFX(dt) {
  for (let i = FX.length - 1; i >= 0; i--) { const e = FX[i]; e.t += dt; if (e.update) e.update(e, dt); if (e.t >= e.dur) FX.splice(i, 1); }
  for (let i = PARTS.length - 1; i >= 0; i--) { const p = PARTS[i]; p.life -= dt; if (p.life <= 0) { PARTS.splice(i, 1); continue; } p.x += p.vx * dt; p.y += p.vy * dt; p.vy += p.grav * dt; p.vx *= .98; }
  for (let i = FLOATS.length - 1; i >= 0; i--) { const f = FLOATS[i]; f.t += dt; if (f.t > 1.1) FLOATS.splice(i, 1); }
}
function drawFXLayer(c, below) {
  for (const e of FX) { if (!!e.below !== below) continue; const t = e.t / e.dur; drawEffect(c, e, t); }
}
function drawEffect(c, e, t) {
  c.save();
  switch (e.type) {
    case 'slash': {
      c.globalCompositeOperation = 'lighter'; c.translate(e.x, e.y - 18); c.rotate(e.ang || 0);
      c.strokeStyle = `rgba(${e.col || '255,255,255'},${1 - t})`; c.lineWidth = 4 * (1 - t) + 1; c.beginPath(); c.arc(0, 0, 16 + t * 6, -1.2 + t * .6, .9 + t * .6); c.stroke(); break;
    }
    case 'halfmoon': {
      c.globalCompositeOperation = 'lighter'; c.translate(e.x, e.y - 14); c.scale(1, .6); const a0 = (e.ang || 0) - 1.9, a1 = (e.ang || 0) + 1.9;
      for (let k = 0; k < 3; k++) { c.strokeStyle = `rgba(${k ? '160,210,255' : '255,255,255'},${(1 - t) * (1 - k * .25)})`; c.lineWidth = 8 - k * 2; c.beginPath(); c.arc(0, 0, 40 + k * 8 + t * 20, a0 + t * .5, a1 + t * .5); c.stroke(); }
      break;
    }
    case 'ring': {
      c.globalCompositeOperation = 'lighter'; c.translate(e.x, e.y); c.scale(1, .55);
      c.strokeStyle = `rgba(${e.col},${1 - t})`; c.lineWidth = (e.w || 5) * (1 - t) + 1; c.beginPath(); c.arc(0, 0, (e.r0 || 5) + t * (e.r || 60), 0, 7); c.stroke(); break;
    }
    case 'thunder': {
      c.globalCompositeOperation = 'lighter';
      if (t < .5) { for (let k = 0; k < 2 + (e.rank || 0); k++) { drawBolt(c, e.x + (R() - .5) * 40, e.y - 420, e.x, e.y - 10, 5 - k, 'rgba(160,200,255,.9)', 40); drawBolt(c, e.x + (R() - .5) * 20, e.y - 420, e.x, e.y - 10, 2, 'rgba(255,255,255,1)', 26); } }
      glow(c, e.x, e.y - 12, 60 + (e.rank || 0) * 12, '150,190,255', .9 * (1 - t)); break;
    }
    case 'flash': { c.globalCompositeOperation = 'lighter'; glow(c, e.x, e.y, e.r || 50, e.col, (e.a || .8) * (1 - t)); break; }
    case 'fireground': {
      c.globalCompositeOperation = 'lighter';
      const a = t < .1 ? t / .1 : t > .8 ? (1 - t) / .2 : 1;
      glow(c, e.x, e.y - 8, 34, '255,120,30', .55 * a);
      if (R() < .9) part(e.x + (R() - .5) * 36, e.y - 2 + (R() - .5) * 18, { vy: -40 - R() * 50, vx: (R() - .5) * 10, life: .5, max: .5, size: 5 + R() * 4, col: R() < .5 ? '255,150,40' : '255,80,20' });
      break;
    }
    case 'ice': {
      c.globalCompositeOperation = 'lighter'; glow(c, e.x, e.y - 10, 90, '140,200,255', .5 * (1 - t));
      if (t < .7) for (let k = 0; k < 3; k++) { const px = e.x + (R() - .5) * 130, py = e.y + (R() - .5) * 80; part(px, py - 120, { vy: 420, vx: -40, life: .28, max: .28, size: 4, col: '200,235,255' }); }
      break;
    }
    case 'pillar': {
      c.globalCompositeOperation = 'lighter'; const a = Math.sin(t * Math.PI);
      const g = c.createLinearGradient(e.x - 26, 0, e.x + 26, 0); g.addColorStop(0, `rgba(${e.col},0)`); g.addColorStop(.5, `rgba(${e.col},${.75 * a})`); g.addColorStop(1, `rgba(${e.col},0)`);
      c.fillStyle = g; c.fillRect(e.x - 26, e.y - 260, 52, 262); glow(c, e.x, e.y - 20, 70, e.col, .6 * a); break;
    }
    case 'shieldpop': { c.globalCompositeOperation = 'lighter'; c.strokeStyle = `rgba(${e.col},${1 - t})`; c.lineWidth = 3; c.beginPath(); c.ellipse(e.x, e.y - 22, 22 + t * 12, 30 + t * 14, 0, 0, 7); c.stroke(); break; }
    case 'smoke': { const a = 1 - t; for (let k = 0; k < 6; k++) { c.fillStyle = `rgba(${e.col || '90,40,120'},${.3 * a})`; c.beginPath(); c.arc(e.x + Math.sin(k * 2 + t * 3) * 14, e.y - 10 - k * 8 - t * 20, 12 + t * 10, 0, 7); c.fill(); } break; }
    case 'telegraph': { c.fillStyle = `rgba(255,60,30,${.25 + .2 * Math.sin(t * 30)})`; c.beginPath(); c.ellipse(e.x, e.y, e.r * t + 10, (e.r * t + 10) * .55, 0, 0, 7); c.fill(); c.strokeStyle = 'rgba(255,120,60,.8)'; c.lineWidth = 2; c.beginPath(); c.ellipse(e.x, e.y, e.r, e.r * .55, 0, 0, 7); c.stroke(); break; }
    case 'portal': {
      c.globalCompositeOperation = 'lighter'; c.translate(e.x, e.y); c.scale(1, .5); const tt = performance.now() / 1000;
      for (let k = 0; k < 3; k++) { c.strokeStyle = `rgba(${e.col || '120,180,255'},${.35 - k * .08})`; c.lineWidth = 3; c.beginPath(); c.arc(0, 0, 16 + k * 7 + Math.sin(tt * 3 + k) * 2, tt * (k + 1), tt * (k + 1) + 4.5); c.stroke(); }
      break;
    }
  }
  c.restore();
}
function drawParticles(c) {
  c.save();
  for (const p of PARTS) {
    const a = Math.max(0, p.life / p.max); c.globalCompositeOperation = p.add ? 'lighter' : 'source-over';
    c.fillStyle = `rgba(${p.col},${a})`; const s = p.shrink ? p.size * (.3 + a * .7) : p.size;
    if (p.sq) c.fillRect(p.x - s / 2, p.y - s / 2, s, s); else { c.beginPath(); c.arc(p.x, p.y, s, 0, 7); c.fill(); }
  }
  c.restore();
}
function drawFloats(c) {
  c.save(); c.textAlign = 'center'; c.lineJoin = 'round';
  for (const f of FLOATS) {
    const t = f.t, y = f.y - 30 - t * 34 - (f.big ? 10 : 0), a = t < .8 ? 1 : 1 - (t - .8) / .3;
    const sc = f.big ? (t < .12 ? 1 + (0.12 - t) * 6 : 1) : 1;
    c.font = `${f.big ? 800 : 700} ${Math.round((f.big ? 19 : 14) * sc)}px "Alegreya Sans", system-ui, sans-serif`;
    c.globalAlpha = Math.max(0, a); c.strokeStyle = 'rgba(0,0,0,.85)'; c.lineWidth = 3.5; c.strokeText(f.text, f.x, y); c.fillStyle = f.col; c.fillText(f.text, f.x, y);
  }
  c.restore();
}
/* projectile visuals */
function drawProjectile(c, p) {
  c.save(); const x = p.x, y = p.y - 22;
  switch (p.kind) {
    case 'fireball': { c.globalCompositeOperation = 'lighter'; const r = 7 + p.rank * 2; glow(c, x, y, r * 3.2, '255,120,30', .7); c.fillStyle = '#fff3c0'; c.beginPath(); c.arc(x, y, r * .55, 0, 7); c.fill(); part(x, y, { vx: (R() - .5) * 30, vy: (R() - .5) * 30 - 10, life: .35, max: .35, size: r * .7, col: R() < .5 ? '255,140,40' : '255,70,20' }); break; }
    case 'soulfire': { c.globalCompositeOperation = 'lighter'; const r = 6 + p.rank * 1.5; glow(c, x, y, r * 3.5, '255,240,140', .6); c.fillStyle = '#fff'; c.beginPath(); c.arc(x, y, r * .5, 0, 7); c.fill(); part(x, y, { vx: (R() - .5) * 20, vy: (R() - .5) * 20, life: .4, max: .4, size: 3, col: '255,230,120' }); break; }
    case 'poison': { c.globalCompositeOperation = 'lighter'; glow(c, x, y, 18, '120,255,80', .6); part(x, y, { vx: (R() - .5) * 20, vy: -10, life: .4, max: .4, size: 3, col: '140,255,100' }); break; }
    case 'heal': { c.globalCompositeOperation = 'lighter'; glow(c, x, y, 16, '140,255,160', .7); break; }
    case 'arrow': { c.translate(x, y); c.rotate(p.ang); c.strokeStyle = '#d8c8a0'; c.lineWidth = 2; c.beginPath(); c.moveTo(-12, 0); c.lineTo(8, 0); c.stroke(); c.fillStyle = '#bbb'; c.beginPath(); c.moveTo(12, 0); c.lineTo(6, -3); c.lineTo(6, 3); c.fill(); break; }
    case 'axe': { c.translate(x, y); c.rotate(p.t * 18); drawWeapon(c, 'axe', '#9aa2aa', null, .5); break; }
    case 'spit': { c.globalCompositeOperation = 'lighter'; glow(c, x, y, 12, '160,255,60', .8); c.fillStyle = '#d0ff80'; c.beginPath(); c.arc(x, y, 3, 0, 7); c.fill(); break; }
    case 'green': { c.globalCompositeOperation = 'lighter'; glow(c, x, y, 16, '80,255,160', .8); part(x, y, { life: .3, max: .3, size: 4, col: '80,255,160' }); break; }
    case 'fire': { c.globalCompositeOperation = 'lighter'; glow(c, x, y, 20, '255,90,30', .8); part(x, y, { life: .3, max: .3, size: 5, col: '255,110,30' }); break; }
    case 'houndfire': { c.globalCompositeOperation = 'lighter'; glow(c, x, y, 22, '255,120,30', .8); part(x, y, { life: .3, max: .3, size: 6, col: '255,150,40' }); break; }
  }
  c.restore();
}
