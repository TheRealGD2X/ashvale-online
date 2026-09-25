/* ================= ICONS ================= */
const ICONS = new Map();
function statGem(d) { if (d.special) return '#b070ff'; if (d.luck) return '#ffd040'; if (d.dc && !d.mc && !d.sc) return '#e0463a'; if (d.mc && !d.dc) return '#4a8aff'; if (d.sc && !d.dc) return '#46c86a'; if (d.mc && d.sc) return '#e8c050'; if (d.ac || d.mac) return '#c9d0d8'; return '#e0c060'; }
function itemIconCanvas(id) {
  let c = ICONS.get(id); if (c) return c;
  const d = ITEMS[id]; c = document.createElement('canvas'); c.width = c.height = 64; const x = c.getContext('2d');
  x.translate(32, 32);
  const g2 = (a, b) => { const g = x.createLinearGradient(-20, -20, 20, 20); g.addColorStop(0, a); g.addColorStop(1, b); return g; };
  if (d.q) { x.save(); x.globalCompositeOperation = 'lighter'; glow(x, 0, 0, 30, d.q === 2 ? '160,90,255' : '255,180,60', .35); x.restore(); }
  switch (d.slot) {
    case 'weapon': { const l = d.look; x.save(); x.rotate(-Math.PI * .75 + Math.PI); x.translate(0, -22); x.scale(1.45, 1.45); drawWeapon(x, l.k, l.c, l.glow, l.k === 'staff' ? .9 : 1); x.restore(); break; }
    case 'armour': { const l = d.look; x.save(); x.translate(0, 30); const lk = { skin: '#6a625a', armor: Object.assign({}, l, { q: d.q }), dir: 4, walk: 0, moving: false, idle: 0, atk: -1, cast: -1, size: 1.12 }; drawHuman(x, 0, 0, lk); x.restore(); break; }
    case 'helmet': { const l = d.look; x.save(); x.scale(2.6, 2.6); x.translate(0, 9); x.fillStyle = '#3a3430'; x.beginPath(); x.ellipse(0, -8, 6.6, 7.2, 0, 0, 7); x.fill(); drawHelm(x, l, 0, -8, 'front', 0, 0); x.restore(); break; }
    case 'necklace': case 'bracelet': case 'ring': {
      const j = jewelLook({ id }, d.slot === 'necklace');
      if (d.slot === 'necklace') { x.strokeStyle = j.m; x.lineWidth = j.s === 'beads' ? 4 : 2.5; x.beginPath(); x.arc(0, -10, 18, .25, Math.PI - .25); x.stroke(); if (j.s === 'beads') { x.fillStyle = j.g; for (let i = 0; i < 9; i++) { const a = .3 + i * (Math.PI - .6) / 8; x.beginPath(); x.arc(Math.cos(a) * 18, -10 + Math.sin(a) * 18, 2.8, 0, 7); x.fill(); } }
        x.save(); x.translate(0, 10); x.scale(3.2, 3.2);
        if (j.s === 'fang') { x.beginPath(); x.moveTo(-1.2, -1); x.quadraticCurveTo(0, 4, .6, 4.5); x.quadraticCurveTo(1.4, 1, 1.2, -1); x.closePath(); x.fillStyle = j.g; x.fill(); }
        else if (j.s === 'skull') { x.fillStyle = j.g; x.beginPath(); x.arc(0, .5, 2, 0, 7); x.fill(); x.fillStyle = '#1a0a08'; x.fillRect(-1.1, 0, .8, .8); x.fillRect(.3, 0, .8, .8); }
        else if (j.s === 'shard') { x.fillStyle = j.g; x.beginPath(); x.moveTo(0, -1.5); x.lineTo(1.4, 1.5); x.lineTo(0, 5); x.lineTo(-1.4, 1.5); x.fill(); }
        else if (j.s === 'disc') { x.fillStyle = j.g; x.beginPath(); x.arc(0, .5, 2.2, 0, 7); x.fill(); x.fillStyle = shade(j.g, -.4); x.beginPath(); x.arc(0, .5, .8, 0, 7); x.fill(); }
        else if (j.s === 'clover') { x.fillStyle = j.g; for (let i = 0; i < 4; i++) { x.beginPath(); x.arc(Math.cos(i * Math.PI / 2) * 1.4, .5 + Math.sin(i * Math.PI / 2) * 1.4, 1.1, 0, 7); x.fill(); } }
        else gem(x, 0, .5, j.s === 'heart' ? 2.4 : 1.8, j.g, j.glow);
        x.restore();
      } else if (d.slot === 'bracelet') { x.strokeStyle = j.m; x.lineWidth = j.s === 'scaled' ? 9 : 7; x.beginPath(); x.ellipse(0, 0, 18, 11, -.3, 0, 7); x.stroke(); x.strokeStyle = 'rgba(255,255,255,.35)'; x.lineWidth = 1.5; x.beginPath(); x.ellipse(0, 0, 18, 11, -.3, 3.6, 5.2); x.stroke();
        if (j.s === 'spiked') { x.fillStyle = shade(j.m, .35); for (let i = 0; i < 7; i++) { const a = i * .9; x.beginPath(); x.moveTo(Math.cos(a) * 16, Math.sin(a) * 9); x.lineTo(Math.cos(a) * 25, Math.sin(a) * 15); x.lineTo(Math.cos(a + .25) * 16, Math.sin(a + .25) * 9); x.fill(); } }
        if (j.s === 'beads') { x.fillStyle = j.g; for (let i = 0; i < 8; i++) { const a = i * .78; x.beginPath(); x.arc(Math.cos(a) * 18, Math.sin(a) * 11, 3, 0, 7); x.fill(); } }
        else if (j.g) gem(x, 2, -11, j.s === 'scaled' ? 5 : 4, j.g, j.glow);
      } else { x.strokeStyle = j.m; x.lineWidth = 5; x.beginPath(); x.ellipse(0, 7, 13, 9, 0, 0, 7); x.stroke(); x.strokeStyle = 'rgba(255,255,255,.4)'; x.lineWidth = 1.2; x.beginPath(); x.ellipse(0, 7, 13, 9, 0, 3.4, 5); x.stroke(); gem(x, 0, -5, 7, j.g, !!d.special || d.q > 0);
        if (d.special) { x.save(); x.globalCompositeOperation = 'lighter'; glow(x, 0, -5, 20, hexRgb(SPECIAL_COL[d.special]), .6); x.restore(); } }
      break;
    }
    case 'cons': {
      if (d.icon === 'scroll' || d.icon === 'scroll2') { x.fillStyle = '#e8d8a8'; x.fillRect(-14, -16, 28, 30); x.fillStyle = '#c8b078'; x.beginPath(); x.ellipse(0, -16, 16, 4, 0, 0, 7); x.ellipse(0, 14, 16, 4, 0, 0, 7); x.fill(); x.fillStyle = d.icon === 'scroll' ? '#2a5ad0' : '#8a3ad0'; x.beginPath(); x.arc(0, 0, 5, 0, 7); x.fill(); x.strokeStyle = 'rgba(80,60,30,.5)'; for (let i = -9; i < 11; i += 5) { x.beginPath(); x.moveTo(-9, i); x.lineTo(9, i); x.stroke(); } break; }
      if (d.icon === 'oil') { x.fillStyle = 'rgba(220,235,255,.3)'; x.beginPath(); x.moveTo(-6, -14); x.lineTo(6, -14); x.lineTo(14, 16); x.lineTo(-14, 16); x.closePath(); x.fill(); x.fillStyle = '#e8b830'; x.beginPath(); x.moveTo(-4, -4); x.lineTo(4, -4); x.lineTo(11, 14); x.lineTo(-11, 14); x.closePath(); x.fill(); x.fillStyle = '#6a4a2a'; x.fillRect(-5, -20, 10, 7); x.fillStyle = 'rgba(255,255,255,.5)'; x.fillRect(-8, 2, 3, 9); break; }
      const col = d.icon === 'hp' ? ['#ff5a4a', '#8a0a0a'] : d.icon === 'mp' ? ['#5a8aff', '#0a1a8a'] : ['#ffe070', '#c87a0a'];
      const sz = d.heal >= 200 || d.mana >= 200 ? 1.15 : d.heal >= 100 || d.mana >= 100 ? 1 : .85;
      x.scale(sz, sz); x.fillStyle = 'rgba(220,235,255,.25)'; x.beginPath(); x.arc(0, 6, 15, 0, 7); x.fill();
      x.fillStyle = g2(col[0], col[1]); x.beginPath(); x.arc(0, 7, 12.5, 0, 7); x.fill(); x.fillStyle = 'rgba(220,235,255,.35)'; x.fillRect(-5, -16, 10, 10); x.fillStyle = '#8a5a2a'; x.fillRect(-6, -20, 12, 6);
      x.fillStyle = 'rgba(255,255,255,.6)'; x.beginPath(); x.ellipse(-5, 2, 3, 5, .4, 0, 7); x.fill(); break;
    }
    case 'book': { const cc = CLASSES[d.cls].color; x.fillStyle = shade(cc, -.4); x.fillRect(-15, -19, 30, 38); x.fillStyle = cc; x.fillRect(-12, -19, 27, 36); x.fillStyle = '#e8dcc0'; x.fillRect(-12, 16, 27, 3); x.strokeStyle = '#ffe8a0'; x.lineWidth = 1.5; x.strokeRect(-7, -12, 17, 20); x.fillStyle = '#ffe8a0'; x.beginPath(); x.arc(1.5, -2, 4, 0, 7); x.fill(); break; }
    case 'mat': { x.fillStyle = g2('#6a6a78', '#1a1a22'); x.beginPath(); x.moveTo(-16, 8); x.lineTo(-10, -12); x.lineTo(6, -16); x.lineTo(17, -2); x.lineTo(12, 14); x.lineTo(-6, 17); x.closePath(); x.fill(); x.fillStyle = 'rgba(160,190,255,.5)'; x.beginPath(); x.moveTo(-6, -8); x.lineTo(2, -11); x.lineTo(-2, -2); x.fill(); break; }
    case 'quest': { x.strokeStyle = g2('#f4e8c8', '#8a7a5a'); x.lineWidth = 9; x.lineCap = 'round'; x.beginPath(); x.moveTo(-16, 14); x.quadraticCurveTo(10, 16, 14, -18); x.stroke(); x.strokeStyle = '#6a4a2a'; x.lineWidth = 4; x.beginPath(); x.moveTo(-14, 12); x.lineTo(-6, 13); x.stroke(); break; }
  }
  ICONS.set(id, c); return c;
}
const ICONURL = new Map();
function iconUrl(id) { let u = ICONURL.get(id); if (!u) { u = itemIconCanvas(id).toDataURL(); ICONURL.set(id, u); } return u; }
const SKICON = new Map();
function skillIconUrl(k) {
  let u = SKICON.get(k); if (u) return u;
  const c = document.createElement('canvas'); c.width = c.height = 64; const x = c.getContext('2d'); const s = SKILLS[k];
  const base = { W: ['#5a2a1a', '#1a0a06'], M: ['#1a2a5a', '#060a1a'], T: ['#1a4a2a', '#061a0a'] }[s.cls];
  const g = x.createRadialGradient(32, 26, 4, 32, 32, 44); g.addColorStop(0, base[0]); g.addColorStop(1, base[1]); x.fillStyle = g; x.fillRect(0, 0, 64, 64);
  x.translate(32, 32); x.lineCap = 'round'; x.lineJoin = 'round';
  const orb = (col, r) => { x.save(); x.globalCompositeOperation = 'lighter'; glow(x, 0, 0, r * 2.2, col, .9); x.fillStyle = '#fff'; x.beginPath(); x.arc(0, 0, r * .45, 0, 7); x.fill(); x.restore(); };
  const flame = (ox, oy, sc) => { x.save(); x.translate(ox, oy); x.scale(sc, sc); x.fillStyle = '#ff7a20'; x.beginPath(); x.moveTo(-8, 10); x.quadraticCurveTo(-10, -6, 0, -18); x.quadraticCurveTo(10, -6, 8, 10); x.fill(); x.fillStyle = '#ffe070'; x.beginPath(); x.moveTo(-4, 10); x.quadraticCurveTo(-4, 0, 0, -8); x.quadraticCurveTo(4, 0, 4, 10); x.fill(); x.restore(); };
  const sword = (a, col) => { x.save(); x.rotate(a); x.translate(0, -18); x.scale(1.2, 1.2); drawWeapon(x, 'sword', col || '#dfe6ec', null, 1.1); x.restore(); };
  switch (k) {
    case 'fencing': sword(-.6); sword(.6); break;
    case 'slaying': sword(-.8); x.save(); x.globalCompositeOperation = 'lighter'; glow(x, 8, -8, 16, '255,220,120', .9); x.restore(); break;
    case 'thrusting': sword(-Math.PI / 2 + .1); x.strokeStyle = 'rgba(200,230,255,.8)'; x.lineWidth = 2; for (let i = 0; i < 3; i++) { x.beginPath(); x.moveTo(-20, -6 + i * 6); x.lineTo(-8, -6 + i * 6); x.stroke(); } break;
    case 'halfmoon': x.strokeStyle = '#cfe6ff'; x.lineWidth = 5; x.beginPath(); x.arc(0, 4, 20, Math.PI * 1.1, Math.PI * 1.9); x.stroke(); x.strokeStyle = '#fff'; x.lineWidth = 2; x.stroke(); break;
    case 'flaming': sword(-.7, '#ffb070'); flame(6, -6, .9); break;
    case 'dash': x.strokeStyle = '#ffd890'; x.lineWidth = 5; for (let i = 0; i < 3; i++) { x.beginPath(); x.moveTo(-18 + i * 12, -12); x.lineTo(-8 + i * 12, 0); x.lineTo(-18 + i * 12, 12); x.stroke(); } break;
    case 'fireball': orb('255,120,30', 12); break;
    case 'repulsion': for (let i = 0; i < 3; i++) { x.strokeStyle = `rgba(190,220,255,${.9 - i * .25})`; x.lineWidth = 3; x.beginPath(); x.arc(0, 0, 8 + i * 8, 0, 7); x.stroke(); } break;
    case 'thunder': x.fillStyle = '#e8f0ff'; x.beginPath(); x.moveTo(4, -24); x.lineTo(-10, 2); x.lineTo(0, 2); x.lineTo(-6, 24); x.lineTo(12, -4); x.lineTo(2, -4); x.lineTo(10, -24); x.fill(); x.save(); x.globalCompositeOperation = 'lighter'; glow(x, 0, 0, 30, '120,170,255', .6); x.restore(); break;
    case 'hellfire': flame(-12, 6, .8); flame(0, 2, 1); flame(12, -2, 1.2); break;
    case 'shield': x.save(); x.globalCompositeOperation = 'lighter'; glow(x, 0, 0, 26, '100,160,255', .6); x.restore(); x.strokeStyle = '#bfe0ff'; x.lineWidth = 3; x.beginPath(); x.arc(0, 0, 20, 0, 7); x.stroke(); break;
    case 'icestorm': x.strokeStyle = '#dff4ff'; x.lineWidth = 3; for (let i = 0; i < 6; i++) { x.save(); x.rotate(i * Math.PI / 3); x.beginPath(); x.moveTo(0, 0); x.lineTo(0, -22); x.moveTo(0, -14); x.lineTo(-6, -19); x.moveTo(0, -14); x.lineTo(6, -19); x.stroke(); x.restore(); } break;
    case 'firewall': flame(-14, 8, .8); flame(0, 8, .8); flame(14, 8, .8); x.fillStyle = '#5a2a10'; x.fillRect(-24, 16, 48, 4); break;
    case 'healing': x.fillStyle = '#8cff9a'; x.fillRect(-5, -18, 10, 36); x.fillRect(-18, -5, 36, 10); x.save(); x.globalCompositeOperation = 'lighter'; glow(x, 0, 0, 24, '120,255,140', .5); x.restore(); break;
    case 'poison': x.fillStyle = '#9cff5a'; x.beginPath(); x.moveTo(0, -20); x.quadraticCurveTo(16, 4, 0, 18); x.quadraticCurveTo(-16, 4, 0, -20); x.fill(); x.fillStyle = 'rgba(255,255,255,.5)'; x.beginPath(); x.arc(-4, 4, 3, 0, 7); x.fill(); break;
    case 'soulfire': orb('255,235,130', 11); break;
    case 'skeleton': x.fillStyle = '#ece6d2'; x.beginPath(); x.arc(0, -4, 14, 0, 7); x.fill(); x.fillRect(-8, 6, 16, 10); x.fillStyle = '#111'; x.beginPath(); x.arc(-5, -4, 4, 0, 7); x.arc(5, -4, 4, 0, 7); x.fill(); x.fillRect(-5, 9, 2, 6); x.fillRect(-1, 9, 2, 6); x.fillRect(3, 9, 2, 6); break;
    case 'soulshield': x.fillStyle = '#e8c060'; x.beginPath(); x.moveTo(0, -20); x.lineTo(16, -12); x.quadraticCurveTo(14, 10, 0, 20); x.quadraticCurveTo(-14, 10, -16, -12); x.closePath(); x.fill(); x.fillStyle = '#7a5a1a'; x.fillRect(-2, -10, 4, 20); x.fillRect(-8, -3, 16, 4); break;
    case 'massheal': x.strokeStyle = '#8cff9a'; x.lineWidth = 3; x.beginPath(); x.arc(0, 0, 20, 0, 7); x.stroke(); x.fillStyle = '#8cff9a'; x.fillRect(-3, -12, 6, 24); x.fillRect(-12, -3, 24, 6); break;
    case 'hound': flame(0, 4, 1.3); x.fillStyle = '#2a0a00'; x.beginPath(); x.arc(-4, 0, 2, 0, 7); x.arc(4, 0, 2, 0, 7); x.fill(); break;
  }
  x.setTransform(1, 0, 0, 1, 0, 0); x.strokeStyle = 'rgba(227,194,127,.35)'; x.strokeRect(.5, .5, 63, 63);
  u = c.toDataURL(); SKICON.set(k, u); return u;
}


/* ================= UI ================= */
const $ = s => document.querySelector(s);
const UI = { chatDirty: true, invDirty: true, charDirty: true, skillsDirty: true, questDirty: true, partyDirty: true, wins: {}, mode: null, drag: null, t: 0, dollT: 0 };
window.UI = UI;
const TOAST_LAB = { level: 'Level up', rare: 'Rare item found', legend: 'Legendary item found', raid: 'Abyssal raid treasure', mythic: 'MYTHIC ITEM FOUND', skill: 'Skill mastery', boss: 'A world boss has appeared', guild: 'Guild', refine: 'Refinement succeeded' };
UI.toast = (text, cls) => {
  cls = cls || 'zone';
  if (cls === 'legend') { const d = Object.values(ITEMS).find(x => x.raid && String(text).startsWith(x.name)); if (d) cls = 'raid'; }
  const box = $('#toasts'); while (box.children.length > 3) box.firstChild.remove();
  if (cls === 'zone') for (const o of box.querySelectorAll('.toast.zone')) o.remove();
  const d = document.createElement('div'); d.className = 'toast ' + cls; d.setAttribute('role', 'status');
  const lab = TOAST_LAB[cls]; d.innerHTML = (lab ? `<small>${lab}</small>` : '') + `<b>${esc(text)}</b>`;
  box.appendChild(d); setTimeout(() => d.remove(), cls === 'level' ? 3700 : cls === 'boss' ? 4300 : 3100);
};

function makeWin(id, title, x, y, render, w) {
  if (UI.wins[id]) { const W0 = UI.wins[id]; W0.render = render; W0.title = title; W0.el.querySelector('h3').textContent = title; W0.el.style.zIndex = ++UI.z; W0.render(W0.body); return W0; }
  const el = document.createElement('div'); el.className = 'win frame orn'; if (w) el.style.width = w + 'px';
  el.innerHTML = `<div class="wh"><h3>${esc(title)}</h3><button class="x" title="Close (Esc)" aria-label="Close"></button></div><div class="wb"></div>`;
  $('#wins').appendChild(el);
  const W = { el, body: el.querySelector('.wb'), render, id };
  UI.wins[id] = W; UI.z = (UI.z || 10) + 1; el.style.zIndex = UI.z;
  const px = clamp(x, 8, Math.max(8, S.vw - (w || 300) - 8)), py = clamp(y, 8, Math.max(8, S.vh - S.hudH - 140));
  el.style.left = px + 'px'; el.style.top = py + 'px';
  el.querySelector('.x').onclick = () => { closeWin(id); sfx('click'); };
  el.addEventListener('pointerdown', () => { el.style.zIndex = ++UI.z; });
  const h = el.querySelector('.wh');
  h.addEventListener('pointerdown', ev => { if (ev.target.classList.contains('x')) return; const r = el.getBoundingClientRect(), ar = APP.getBoundingClientRect(); const ox = ev.clientX - r.left, oy = ev.clientY - r.top; const mv = e2 => { el.style.left = clamp(e2.clientX - ar.left - ox, 0, S.vw - 60) + 'px'; el.style.top = clamp(e2.clientY - ar.top - oy, 0, S.vh - 40) + 'px'; }; const up = () => { window.removeEventListener('pointermove', mv); window.removeEventListener('pointerup', up); }; window.addEventListener('pointermove', mv); window.addEventListener('pointerup', up); });
  render(W.body); return W;
}
function closeWin(id) { const w = UI.wins[id]; if (!w) return; w.el.remove(); delete UI.wins[id]; if (id === 'shop' || id === 'storage' || id === 'smith') { UI.mode = null; UI.invDirty = true; } if (id === 'char') UI.dollCv = null; hideTip(); }
function toggleWin(id) { if (UI.wins[id]) closeWin(id); else openWin(id); sfx('paper'); }
function openWin(id) {
  const vw = S.vw;
  switch (id) {
    case 'inv': makeWin('inv', 'Bag', vw - 366, Math.max(56, Math.min(318, S.vh - S.hudH - 330)), renderInv, 350); break;
    case 'char': makeWin('char', S.P.name, 20, 56, renderChar, 378); break;
    case 'skills': makeWin('skills', 'Skills', 410, 60, renderSkills, 372); break;
    case 'quest': makeWin('quest', 'Quests', 410, 80, renderQuest, 350); break;
    case 'guild': makeWin('guild', 'Guild', 420, 70, renderGuild, 350); break;
    case 'map': makeWin('map', S.map.name, Math.max(10, vw / 2 - 282), 36, renderMap, 564); break;
    case 'opts': makeWin('opts', 'Menu', Math.max(10, vw / 2 - 170), 80, renderOpts, 340); break;
  }
}
function refreshWin(id) { const w = UI.wins[id]; if (w) w.render(w.body); }

/* ---------- slot html ---------- */
function rarCls(it) { const d = ITEMS[it.id]; return d.q === 3 ? 'q-myth' : d.raid ? 'q-raid' : d.q === 2 ? 'q-leg' : d.q === 1 ? 'q-rare' : addTotal(it) > 0 ? 'q-add' : ''; }
function slotHtml(it, attrs, extra, style, cls) {
  const st = (style || '') + (it ? `background-image:url(${iconUrl(it.id)});` : '');
  return `<div class="slot ${cls || ''} ${it ? rarCls(it) : ''}" ${attrs || ''}${st ? ` style="${st}"` : ''}>${it && it.n > 1 ? `<span class="c">${it.n}</span>` : ''}${extra || ''}</div>`;
}
function renderInv(b) {
  const P = S.P;
  let h = `<div class="grid inv">`; for (let i = 0; i < 40; i++) h += slotHtml(P.inv[i], `data-inv="${i}"`); h += '</div>';
  const hint = UI.mode === 'shop' ? 'Right-click an item to sell it.' : UI.mode === 'storage' ? 'Right-click an item to store it.' : 'Right-click to use or equip. Drag potions to the belt.';
  h += `<div class="winfoot"><span class="hint">${hint}</span><span class="gold"><i class="coin"></i>${fmt(P.gold)}</span></div>`;
  b.innerHTML = h;
}

/* ---------- character ---------- */
const DOLL = { weapon: [10, 18], armour: [10, 90], braceletL: [10, 196], ringL: [10, 268], helmet: [292, 18], necklace: [292, 90], braceletR: [292, 196], ringR: [292, 268] };
const EQLAB = { weapon: 'Weapon', armour: 'Armour', helmet: 'Helmet', necklace: 'Necklace', braceletL: 'Bracelet', braceletR: 'Bracelet', ringL: 'Ring', ringR: 'Ring' };
function charStatsHtml() {
  const P = S.P, p = S.player, st = p.st; const r = a => `${a[0]}-${a[1]}`;
  const row = (k, v, col) => `<div><span>${k}</span><b${col ? ` style="color:${col}"` : ''}>${v}</b></div>`;
  return row('HP', `${Math.round(p.hp)}/${p.maxhp}`, '#ff9a8a') + row('MP', `${Math.round(p.mp)}/${p.maxmp}`, '#9ab8ff') + row('DC', r(st.dc)) + row('AC', r(st.ac)) + row('MC', r(st.mc)) + row('MAC', r(st.mac)) + row('SC', r(st.sc)) + row('Accuracy', st.acc) + row('Luck', st.luck) + row('Agility', st.agi) + row('PK points', P.pk, P.pk >= 200 ? '#ff6a5a' : P.pk >= 100 ? '#ffe04a' : '') + row('Kills', fmt(P.kills || 0));
}
function renderChar(b) {
  const P = S.P, c = CLASSES[P.cls];
  let h = `<div class="doll"><canvas id="dollcv" width="692" height="668"></canvas>`;
  for (const sl of EQUIP_SLOTS) { const [x, y] = DOLL[sl]; const it = P.equip[sl]; h += slotHtml(it, `data-eq="${sl}"`, it ? '' : `<span class="eql">${EQLAB[sl]}</span>`, `left:${x}px;top:${y}px;`, 'eq-' + sl.replace(/[LR]$/, '')); }
  h += `</div><div class="charhd"><b style="color:${c.color}">${c.name}</b><span>Level ${P.lv}${P.guild ? ' &middot; ' + esc(P.guild.name) : ''}</span></div>`;
  UI.lastCStats = charStatsHtml(); h += `<div class="stats" id="cstats">${UI.lastCStats}</div>`;
  b.innerHTML = h; UI.dollCv = b.querySelector('#dollcv'); drawDoll();
}
function drawDoll() {
  const cvd = UI.dollCv; if (!cvd || !cvd.isConnected || !S.P) return; const c = cvd.getContext('2d');
  c.setTransform(1, 0, 0, 1, 0, 0); c.clearRect(0, 0, cvd.width, cvd.height); c.setTransform(2, 0, 0, 2, 0, 0);
  const cx = 173, fy = 240, t = calm() ? 0 : S.time;
  // light shaft
  const lg = c.createLinearGradient(0, 0, 0, fy + 20); lg.addColorStop(0, 'rgba(255,220,150,0)'); lg.addColorStop(1, 'rgba(255,215,140,.09)');
  c.fillStyle = lg; c.beginPath(); c.moveTo(cx - 34, 0); c.lineTo(cx + 34, 0); c.lineTo(cx + 86, fy + 20); c.lineTo(cx - 86, fy + 20); c.fill();
  // pedestal: runic circle
  c.save(); c.translate(cx, fy + 2); c.scale(1, .27);
  const g = c.createRadialGradient(0, 0, 4, 0, 0, 96); g.addColorStop(0, 'rgba(255,210,130,.42)'); g.addColorStop(.55, 'rgba(168,130,74,.14)'); g.addColorStop(1, 'rgba(0,0,0,0)');
  c.fillStyle = g; c.beginPath(); c.arc(0, 0, 96, 0, 7); c.fill();
  c.strokeStyle = 'rgba(233,200,120,.6)'; c.lineWidth = 2.4; c.beginPath(); c.arc(0, 0, 68, 0, 7); c.stroke();
  c.strokeStyle = 'rgba(212,175,100,.28)'; c.lineWidth = 1.6; c.beginPath(); c.arc(0, 0, 82, 0, 7); c.stroke();
  for (let i = 0; i < 28; i++) { const a = i / 28 * Math.PI * 2 + t * .12; c.fillStyle = i % 4 ? 'rgba(247,223,158,.3)' : 'rgba(255,240,200,.75)'; c.fillRect(Math.cos(a) * 75 - 1.5, Math.sin(a) * 75 - 1.5, 3, 3); }
  c.restore();
  c.save(); c.translate(cx - 4, fy); c.scale(3.4, 3.4);
  drawHuman(c, 0, 0, Object.assign(playerLook(), { dir: 4, walk: 0, moving: false, idle: t, atk: -1, cast: -1 }));
  c.restore();
}

/* ---------- skills / quests / guild ---------- */
function renderSkills(b) {
  const P = S.P; const ks = Object.keys(SKILLS).filter(k => SKILLS[k].cls === P.cls);
  let h = '';
  for (const k of ks) {
    const s = SKILLS[k], sk = P.skills[k];
    if (!sk) { h += `<div class="skrow" style="opacity:.42"><div class="slot" style="background-image:url(${skillIconUrl(k)});filter:grayscale(1)"></div><div><div class="nm"><b>${s.name}</b><span class="small muted">Book &middot; level ${s.lv}</span></div><div class="small muted">${s.desc}</div></div></div>`; continue; }
    const need = sk.rank < 3 ? s.train[sk.rank] : 0, pct = sk.rank < 3 ? sk.pts / need * 100 : 100;
    const lvReq = sk.rank < 3 && P.lv < s.lv + sk.rank * 3 ? ` <span class="small" style="color:#e0806a">(rank ${sk.rank + 1} needs level ${s.lv + sk.rank * 3})</span>` : '';
    h += `<div class="skrow"><div class="slot ${P.toggles[k] ? 'on' : ''}" data-cast="${k}" style="background-image:url(${skillIconUrl(k)})"></div><div><div class="nm"><b>${s.name}</b><span class="pips">${[1, 2, 3].map(i => `<i class="${sk.rank >= i ? 'on' : ''}"></i>`).join('')}</span></div>
    <div class="small muted">${s.desc}${s.mp ? ` <span style="color:#9ab8ff">${s.mp} MP</span>` : ''}${lvReq}</div>
    <div class="trainbar"><i style="width:${pct}%"></i></div>
    ${s.kind !== 'passive' ? `<div class="keys">${[0, 1, 2, 3, 4, 5, 6, 7].map(i => `<button data-bind="${k}:${i}" class="${P.keys[i] === k ? 'on' : ''}" aria-label="Bind to key ${i + 1}">${i + 1}</button>`).join('')}</div>` : ''}</div></div>`;
  }
  b.innerHTML = `<div class="scroll">${h}</div><div class="hint" style="margin-top:8px">Skills rank up to 3 with use. Buy new books from Sage Orrin in town.</div>`;
}
function questHtml() {
  const P = S.P, q = QUESTS[P.q];
  if (!q) return `<b>All tasks complete</b><div class="qp">Ashvale owes you everything.</div>`;
  if (!P.qa) return `<b>${q.name}</b><div class="qp">${P.lv < q.lv ? `Reach level ${q.lv}, then speak to` : 'Speak to'} Elder Rowan in town.</div>`;
  const tgt = MON[q.need];
  if (P.qn >= q.n) return `<b>${q.name}</b><div class="done">Complete. Return to Elder Rowan.</div>`;
  return `<b>${q.name}</b><div class="qp">${tgt.name}: ${P.qn} / ${q.n}</div>`;
}
function renderQuest(b) {
  const P = S.P, q = QUESTS[P.q];
  let h = `<div id="qbody" style="font-size:13px">${questHtml().replace('<b>', '<b style="font-family:var(--display);font-size:16px;color:var(--gold-hi);font-weight:700;letter-spacing:.04em;display:block;margin-bottom:3px">')}</div>`;
  if (q && P.qa) { const pct = Math.min(100, P.qn / q.n * 100); h += `<div class="meter" style="margin:8px 0 2px;height:14px"><i style="width:${pct}%"></i><span style="line-height:14px">${P.qn} / ${q.n}</span></div>`; }
  if (q) h += `<p class="npc-line" style="margin:10px 0 8px">“${q.text}”</p><div class="rule"></div><div class="small" style="line-height:1.6"><span class="muted" style="letter-spacing:.14em;text-transform:uppercase;font-size:10.5px">Rewards</span><br><span style="color:#9fe0a8">${fmt(q.xp)} experience</span> &middot; <i class="coin"></i> <span style="color:#f3d27a">${fmt(q.gold)}</span>${q.items.map(([id, n]) => ` &middot; <span style="color:${itemColor({ id })}">${ITEMS[id].name}${n > 1 ? ' x' + n : ''}</span>`).join('')}</div>`;
  h += `<div class="hint" style="margin-top:10px">Completed ${P.q} of ${QUESTS.length} tasks</div>`;
  b.innerHTML = h;
}
function renderGuild(b) {
  const P = S.P, g = P.guild;
  if (!g) { b.innerHTML = `<p class="npc-line" style="margin-top:0">You are not in a guild. Guild Master Kael in Ashvale can help you join one, or found your own with a Warlord's Horn.</p>`; return; }
  const mem = g.members.slice().sort((a, b2) => b2.on - a.on || b2.lv - a.lv);
  b.innerHTML = `<div class="row"><b style="font-family:var(--display);font-weight:700;font-size:18px;letter-spacing:.04em;color:${S.castle === g.name ? '#ffd24a' : 'var(--gold-hi)'}">${esc(g.name)}</b><span class="muted small">${g.own ? 'Leader' : 'Member'}</span></div>
  ${S.castle === g.name ? '<div class="small" style="color:#ffd24a">Holds Castle Varn: +10% experience</div>' : ''}
  <p class="npc-line" style="margin:6px 0 8px">“${esc(g.notice)}”</p>
  <div class="small muted">${mem.filter(m => m.on).length + 1} online, ${mem.length + 1} members. Chat with <kbd>!~</kbd> before your message.</div>
  <div class="rule"></div>
  <div class="scroll" style="max-height:220px"><div class="gm"><span>${esc(P.name)} (you)</span><span class="on">Lv ${P.lv} ${CLASSES[P.cls].name}</span></div>${mem.map(m => `<div class="gm"><span>${esc(m.name)}</span><span class="${m.on ? 'on' : 'off'}">Lv ${m.lv} ${CLASSES[m.cls].name}</span></div>`).join('')}</div>
  <div class="row" style="margin-top:10px"><span></span><button class="btn danger" id="gleave">${UI.leaveConfirm ? 'Click again to leave' : 'Leave guild'}</button></div>`;
  b.querySelector('#gleave').onclick = () => { if (!UI.leaveConfirm) { UI.leaveConfirm = true; renderGuild(b); return; } UI.leaveConfirm = false; sys(`You left ${P.guild.name}.`); P.guild = null; renderGuild(b); };
}
const MAPINFO = { ashvale: { lv: '1-14', cost: 0 }, mine: { lv: '9-22', cost: 300 }, mirewood: { lv: '16-30', cost: 900 }, temple: { lv: '25-40', cost: 2500 }, sanctum: { lv: '30+ raid', cost: 0 } };
const MAPNAMES = { ashvale: 'Ashvale Province', mine: 'Hollow Mine', mirewood: 'Mirewood Forest', temple: 'Sunken Temple of Khar', sanctum: 'Abyssal Sanctum' };
function renderMap(b) {
  const m = S.map; const W = 530, sc = Math.min(W / m.w, 380 / m.h); const Wc = Math.round(m.w * sc), H = Math.round(m.h * sc);
  const ids = Object.keys(GEN).filter(id => MAPINFO[id] && (id !== 'sanctum' || S.P.visited[id]));
  b.innerHTML = `<div class="mapfr" style="width:${Wc}px;margin:3px auto"><canvas id="bigmap" width="${Wc * 2}" height="${H * 2}" style="width:${Wc}px;height:${H}px;display:block;background:#000"></canvas></div>
  <div class="legend"><span><i style="background:#fff"></i>You</span><span><i style="background:#ffe070"></i>NPC</span><span><i style="background:#6ab0ff"></i>Portal</span><span><i style="background:#ff4a2a"></i>Boss</span><span><i style="background:#6ad0ff"></i>Group</span></div>
  <div class="zones">${ids.map(id => `<span class="${id === m.id ? 'here' : S.P.visited[id] ? '' : 'unk'}">${S.P.visited[id] ? '' : '? '}${S.maps[id] ? S.maps[id].name : MAPNAMES[id]}<em>Lv ${MAPINFO[id].lv}</em></span>`).join('')}</div><div id="bosslist" style="margin-top:8px"></div>`;
  UI.bigmap = { cv: b.querySelector('#bigmap'), sc }; drawBigMap();
}
function drawBigMap() {
  const bm = UI.bigmap; if (!bm || !UI.wins.map || !bm.cv.isConnected) return; const c = bm.cv.getContext('2d'), m = S.map, sc = bm.sc * 2;
  c.imageSmoothingEnabled = false; c.drawImage(m.mini, 0, 0, m.w * sc, m.h * sc);
  if (m.dark > .5) { c.fillStyle = 'rgba(0,0,0,.2)'; c.fillRect(0, 0, bm.cv.width, bm.cv.height); }
  for (const q of m.portals) { const x = (q.x0 + q.x1 + 1) / 2 * sc, y = (q.y0 + q.y1 + 1) / 2 * sc; c.save(); c.globalCompositeOperation = 'lighter'; glow(c, x, y, 18, '90,160,255', .7); c.restore(); c.fillStyle = '#8ac4ff'; c.beginPath(); c.arc(x, y, 6, 0, 7); c.fill(); textOut(c, q.label, clamp(x, 80, bm.cv.width - 80), y - 14, '#b8d8ff', '700 20px "Alegreya Sans", sans-serif'); }
  for (const e of S.ents) { if (e.dead) continue; if (e.kind === 'npc') { c.fillStyle = '#000'; c.fillRect(e.x * sc - 4, e.y * sc - 4, 8, 8); c.fillStyle = '#ffe070'; c.fillRect(e.x * sc - 3, e.y * sc - 3, 6, 6); } if (e.kind === 'bot') { c.fillStyle = e.party ? '#6ad0ff' : e.red ? '#ff4a3a' : '#d8d0c0'; c.fillRect(e.x * sc - 2, e.y * sc - 2, 4, 4); } }
  let bl = '';
  for (const bo of m.bosses) { const d = MON[bo.mon]; const k = m.id + ':' + bo.mon; const alive = S.ents.some(e => e.kind === 'mon' && e.def.id === bo.mon && !e.dead); const x = bo.x * sc, y = bo.y * sc;
    if (alive) { c.save(); c.globalCompositeOperation = 'lighter'; glow(c, x, y, 26, '255,70,30', .6); c.restore(); }
    c.strokeStyle = alive ? '#ff4a2a' : '#7a6a5a'; c.lineWidth = 3; c.beginPath(); c.arc(x, y, 12, 0, 7); c.stroke(); textOut(c, d.name, x, y - 20, alive ? '#ffb04a' : '#9a8a7a', '700 20px "Alegreya Sans", sans-serif');
    const rem = S.bossNext[k] ? Math.max(0, (S.bossNext[k] - Date.now()) / 1000) : 0; bl += `<div><span>${d.name} <span class="muted">Lv ${d.lv}</span></span>${alive ? '<span class="al">Alive</span>' : `<span class="muted">Returns in ${Math.floor(rem / 60)}:${String(Math.floor(rem % 60)).padStart(2, '0')}</span>`}</div>`; }
  const p = S.player; c.save(); c.globalCompositeOperation = 'lighter'; glow(c, p.x * sc, p.y * sc, 22, '255,255,255', .5); c.restore(); c.fillStyle = '#fff'; c.strokeStyle = '#000'; c.lineWidth = 2; c.beginPath(); c.arc(p.x * sc, p.y * sc, 6, 0, 7); c.fill(); c.stroke();
  const bll = document.getElementById('bosslist'); if (bll && bll._h !== bl) { bll._h = bl; bll.innerHTML = bl; }
}
function renderOpts(b) {
  b.innerHTML = `<div class="opts" style="margin-top:0;padding-top:0;align-items:stretch;gap:6px">
  <div class="audio-set">${[['master', 'Master'], ['music', 'Music'], ['amb', 'Ambience'], ['sfx', 'Effects']].map(([k, l]) => `<label class="aud"><span>${l}</span><input type="range" min="0" max="100" value="${Math.round(AU.vol[k] * 100)}" data-vol="${k}" id="vol-${k}" aria-label="${l} volume"><b>${Math.round(AU.vol[k] * 100)}</b></label>`).join('')}
  <div class="aud-row"><button class="btn" id="o-sound">${AU.on ? 'Mute all' : 'Unmute'}</button><button class="btn" id="o-steps">Footsteps: ${AU.steps ? 'On' : 'Off'}</button></div></div>
  <button class="btn" id="o-save">Save now</button>
  <button class="btn" id="o-help">Controls</button>
  <button class="btn danger" id="o-del">${UI.delConfirm ? 'Click again to delete this character forever' : 'Delete character'}</button></div>
  <div class="hint" style="margin-top:10px">${UI.cloud ? 'Progress saves to your account and this browser.' : 'Progress saves in this browser.'} Last saved ${UI.lastSave ? new Date(UI.lastSave).toLocaleTimeString() : 'never'}.</div>`;
  b.querySelector('#o-sound').onclick = () => { AU.on = !AU.on; applyVolumes(); saveAudioPrefs(S.P); renderOpts(b); };
  b.querySelector('#o-steps').onclick = () => { AU.steps = !AU.steps; saveAudioPrefs(S.P); renderOpts(b); };
  b.querySelectorAll('[data-vol]').forEach(r => r.oninput = () => { AU.vol[r.dataset.vol] = r.value / 100; r.nextElementSibling.textContent = r.value; applyVolumes(); saveAudioPrefs(S.P); if (r.dataset.vol === 'sfx') sfx('gold'); });
  b.querySelector('#o-save').onclick = () => { saveGame(true); renderOpts(b); };
  b.querySelector('#o-help').onclick = () => { closeWin('opts'); showHelp(); };
  b.querySelector('#o-del').onclick = () => { if (!UI.delConfirm) { UI.delConfirm = true; renderOpts(b); return; } UI.delConfirm = false; deleteSave(); };
}
function showHelp() {
  makeWin('help', 'Controls', Math.max(10, S.vw / 2 - 220), 50, b => { b.innerHTML = `<div class="help">
  <div><kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd> walk. Or <kbd>left click</kbd> to walk, attack, talk and pick up; hold to keep walking.</div>
  <div><kbd>1</kbd>–<kbd>8</kbd> cast skills at the monster under your cursor or your target. <kbd>Space</kbd> targets the nearest monster, <kbd>Tab</kbd> cycles targets.</div>
  <div><kbd>Q</kbd> drinks a health potion, <kbd>E</kbd> a mana potion. Drag potions onto the first two belt slots to choose which.</div>
  <div><kbd>R</kbd> Mythic power. <kbd>T</kbd> Teleport Ring.</div>
  <div><kbd>C</kbd> character <kbd>I</kbd> bag <kbd>K</kbd> skills <kbd>J</kbd> quests <kbd>G</kbd> guild <kbd>M</kbd> map <kbd>O</kbd> menu</div>
  <div><kbd>Enter</kbd> chat. Start with <kbd>!</kbd> to shout, <kbd>!~</kbd> for guild, <kbd>!!</kbd> for group, <kbd>/Name</kbd> to whisper. Players answer, and if you ask for help, someone may come.</div>
  <div><kbd>Ctrl</kbd> + click, or the PK button, attacks other players. Murder turns your name red and the guards will hunt you.</div></div>`; }, 440);
}

/* ---------- NPC ---------- */
function npcPortrait(n) { const c = document.createElement('canvas'); c.width = 184; c.height = 184; const x = c.getContext('2d'); x.scale(4.6, 4.6); drawHuman(x, 20, 70, Object.assign({}, n.look, { dir: 4, walk: 0, moving: false, idle: 0, atk: -1, cast: -1 })); return c; }
UI.openNPC = (n) => {
  const def = n.def; closeWin('shop'); closeWin('storage'); closeWin('smith'); closeWin('tele');
  makeWin('npc', S.map.name, Math.max(10, S.vw / 2 - 380), 70, b => renderNPC(b, n), 440);
  sfx('click');
};
function npcHead(b, n, line) {
  b.innerHTML = `<div class="npc-head"><div class="npcp" id="npcp"></div><div style="min-width:0;flex:1"><div class="npc-nm">${esc(n.def.name)}</div>${n.def.title ? `<div class="npc-ti">${esc(n.def.title)}</div>` : '<div class="npc-ti">Elder of Ashvale</div>'}<div class="npc-line">“${line}”</div></div></div><div class="opts" id="npco"></div>`;
  b.querySelector('#npcp').appendChild(npcPortrait(n)); return b.querySelector('#npco');
}
function opt(o, label, fn, cls) { const bt = document.createElement('button'); bt.className = 'lnk ' + (cls === 'gold' ? 'key' : cls || ''); if (label === 'Goodbye') bt.classList.add('bye'); bt.innerHTML = label; bt.onclick = () => { if (bt.disabled) return; sfx('click'); fn(); }; o.appendChild(bt); return bt; }
function renderNPC(b, n) {
  const def = n.def, P = S.P;
  if (def.role === 'quest') {
    const q = QUESTS[P.q];
    let line = def.line;
    if (!q) line = 'You have done more for Ashvale than any hero before you. Rest a while.';
    else if (!P.qa) line = P.lv < q.lv ? `Come back when you are stronger. Level ${q.lv} at least.` : q.text;
    else if (P.qn < q.n) line = `${q.text} (${P.qn}/${q.n})`;
    else line = 'You have done it! Here, take this with my thanks.';
    const o = npcHead(b, n, line);
    if (q && !P.qa && P.lv >= q.lv) opt(o, `Accept: ${q.name} <small>${fmt(q.xp)} xp, ${fmt(q.gold)} gold</small>`, () => { P.qa = true; P.qn = 0; sys(`Quest accepted: ${q.name}.`); renderNPC(b, n); UI.questDirty = true; }, 'gold');
    if (q && P.qa && P.qn >= q.n) opt(o, 'Claim reward', () => { for (const [id, k] of q.items) { const it = makeItem(id, k); if (!invAdd(it)) dropItem(S.player.x, S.player.y, it); } P.gold += q.gold; gainXP(q.xp); sys(`Quest complete: ${q.name}. +${fmt(q.gold)} gold.`); sfx('rare'); P.q++; P.qa = false; P.qn = 0; UI.invDirty = UI.questDirty = true; renderNPC(b, n); }, 'gold');
    opt(o, 'Goodbye', () => closeWin('npc'));
  } else if (def.role === 'shop' || def.role === 'books') {
    const o = npcHead(b, n, def.line);
    opt(o, 'Buy and sell', () => openShop(n));
    opt(o, 'Goodbye', () => closeWin('npc'));
  } else if (def.role === 'smith') { const o = npcHead(b, n, def.line); opt(o, 'Refine my weapon', () => openSmith()); opt(o, 'Sell items', () => openShop(n)); opt(o, 'Goodbye', () => closeWin('npc')); }
  else if (def.role === 'storage') { const o = npcHead(b, n, def.line); opt(o, 'Open storage', () => openStorage()); opt(o, 'Goodbye', () => closeWin('npc')); }
  else if (def.role === 'teleport') {
    const o = npcHead(b, n, def.line);
    for (const id of ['mine', 'mirewood', 'temple']) { const name = MAPNAMES[id]; const cost = MAPINFO[id].cost; const ok = P.visited[id];
      const bt = opt(o, `${name} <small>${ok ? fmt(cost) + ' gold' : 'not yet discovered'}</small>`, () => { if (!ok) return; if (P.gold < cost) { sys('Not enough gold.'); sfx('error'); return; } P.gold -= cost; closeWin('npc'); const m = getMap(id); changeMap(id, m.start.x, m.start.y); }); if (!ok) bt.disabled = true; }
    opt(o, `Abyssal Sanctum <small>raid, group of 3+, level 30+</small>`, () => { if (enterRaid()) closeWin('npc'); }, 'gold');
    opt(o, `Raid finder <small>recruit players for the Sanctum</small>`, () => { raidFinder(); closeWin('npc'); });
    opt(o, 'Goodbye', () => closeWin('npc'));
  } else if (def.role === 'guild') {
    const o = npcHead(b, n, P.guild ? `Fight well for ${P.guild.name}.` : def.line);
    if (!P.guild) {
      for (const g of GUILDS) opt(o, `Apply to ${g.name} <small>level ${g.minLv}+</small>`, () => { if (P.lv < g.minLv) { sys(`${g.name} only accepts level ${g.minLv}+.`); sfx('error'); return; } closeWin('npc'); sys(`You applied to ${g.name}...`); setTimeoutGame(2, () => { joinGuild(g.name, g.notice, false); }); });
      const hasHorn = invCount('warlord_horn') > 0;
      opt(o, `Found a guild <small>Warlord's Horn + 20,000 gold${hasHorn ? '' : ' (no horn)'}</small>`, () => { if (!hasHorn) { sys("You need a Warlord's Horn. Slay the Goblin Warlord in Mirewood."); sfx('error'); return; } if (P.gold < 20000) { sys('You need 20,000 gold.'); sfx('error'); return; } foundGuildPrompt(b, n); });
    }
    opt(o, 'Goodbye', () => closeWin('npc'));
  }
}
function foundGuildPrompt(b, n) {
  b.innerHTML = `<p class="npc-line" style="margin-top:0">Name your guild. Choose well; songs will be sung of it.</p><input class="txt" id="gname" maxlength="16" placeholder="Guild name" aria-label="Guild name"><div class="row" style="margin-top:10px"><button class="btn" id="gc">Back</button><button class="btn gold" id="gok">Found guild</button></div>`;
  const inp = b.querySelector('#gname'); inp.focus();
  inp.addEventListener('keydown', e => e.stopPropagation());
  b.querySelector('#gc').onclick = () => renderNPC(b, n);
  b.querySelector('#gok').onclick = () => { const nm = inp.value.trim().replace(/[<>]/g, ''); if (nm.length < 3) { inp.style.boxShadow = '0 0 0 1px #c2281f'; return; } S.P.gold -= 20000; invTake('warlord_horn', 1); joinGuild(nm, 'Welcome. Hunt hard, share loot.', true); closeWin('npc'); UI.invDirty = true; };
}
function joinGuild(name, notice, own) {
  const P = S.P; const members = [];
  const n = own ? rnd(1, 3) : rnd(14, 32);
  for (let i = 0; i < n; i++) { const nm = pick(BOT_NAMES); if (members.some(m => m.name === nm) || nm === P.name) continue; members.push({ name: nm, lv: rnd(5, 40), cls: pick(['W', 'M', 'T']), on: R() < .45 }); }
  P.guild = { name, notice, own, members };
  sys(own ? `You founded the guild ${name}!` : `${name} accepted you. Welcome!`); sfx('rare'); UI.toast(name, 'guild');
  if (!own) setTimeoutGame(2, () => chat('guild', pick(['welcome!', 'hi new member', 'wb', 'welcome ' + P.name]), pick(members.filter(m => m.on).concat(members)).name));
  refreshWin('guild');
}
function shopStock(n) { if (n.def.role === 'books') return Object.keys(SKILLS).filter(k => SKILLS[k].cls === S.P.cls).map(k => 'book_' + k); return n.def.stock || []; }
function openShop(n) {
  UI.mode = 'shop'; closeWin('npc');
  const stock = shopStock(n);
  makeWin('shop', n.def.name + (n.def.title ? ', ' + n.def.title : ''), Math.max(10, S.vw / 2 - 420), 70, b => {
    b.innerHTML = `<div class="shoplist">${stock.map(id => { const d = ITEMS[id]; const bad = canEquipish(d); return `<div class="shopitem ${bad ? 'bad' : ''}" data-buy="${id}"><div class="slot ${rarCls({ id })}" style="background-image:url(${iconUrl(id)})"></div><div style="min-width:0;flex:1"><div class="nm" style="${bad ? '' : `color:${itemColor({ id })}`}">${d.name}</div><div class="pr"><i class="coin"></i>${fmt(d.price)}${d.lv > 1 ? `<span class="rq">Lv ${d.lv}</span>` : ''}</div></div></div>`; }).join('') || '<div class="muted">Nothing for sale. Right-click items in your bag to sell.</div>'}</div>
    <div class="winfoot"><span class="hint">Click to buy${n.def.id === 'potions' ? ', Shift-click buys 10' : ''}. Right-click bag items to sell.</span><span class="gold"><i class="coin"></i>${fmt(S.P.gold)}</span></div>`;
  }, 440);
  if (!UI.wins.inv) openWin('inv'); else refreshWin('inv');
}
function canEquipish(d) { const P = S.P; if (d.cls && d.cls !== P.cls) return true; if (d.lv && P.lv < d.lv) return true; if (d.slot === 'book' && P.skills[d.skill]) return true; return false; }
function buy(id, many) {
  const d = ITEMS[id], P = S.P; const n = many && d.slot === 'cons' ? 10 : 1; const cost = d.price * n;
  if (P.gold < cost) { sys('Not enough gold.'); sfx('error'); return; }
  const it = makeItem(id, n); delete it.add; if (!invAdd(it)) { sys('Your bag is full.'); sfx('error'); return; }
  P.gold -= cost; sfx('gold'); chat('xp', `Bought ${d.name}${n > 1 ? ' x' + n : ''} for ${fmt(cost)} gold`); UI.invDirty = true;
}
function sell(i) {
  const P = S.P, it = P.inv[i]; if (!it) return; const d = ITEMS[it.id]; if (d.slot === 'quest') { sys('Nobody will buy that here.'); return; }
  const pr = sellPrice(it); P.inv[i] = null; P.gold += pr; sfx('gold'); chat('xp', `Sold ${itemName(it)}${it.n > 1 ? ' x' + it.n : ''} for ${fmt(pr)} gold`); UI.invDirty = true;
}
function openStorage() {
  UI.mode = 'storage'; closeWin('npc');
  makeWin('storage', 'Storage', Math.max(10, S.vw / 2 - 420), 80, b => { let h = '<div class="grid inv">'; for (let i = 0; i < 40; i++) h += slotHtml(S.P.storage[i], `data-sto="${i}"`); b.innerHTML = h + '</div><div class="winfoot"><span class="hint">Click an item to take it. Right-click items in your bag to store them.</span></div>'; }, 350);
  if (!UI.wins.inv) openWin('inv'); else refreshWin('inv');
}
function openSmith() {
  UI.mode = 'smith'; closeWin('npc');
  makeWin('smith', 'Grom, Blacksmith', Math.max(10, S.vw / 2 - 200), 90, b => {
    const P = S.P, w = P.equip.weapon; const ore = invCount('black_ore');
    if (!w) { b.innerHTML = '<p class="npc-line" style="margin-top:0">“Equip the weapon you want me to work on.”</p>'; return; }
    const r = w.r || 0, cost = 600 * (r + 1) * (r + 1), ch = Math.max(.15, .85 - r * .12);
    b.innerHTML = `<div class="row" style="justify-content:flex-start;gap:12px">${slotHtml(w, 'data-eq="weapon"', '', 'width:48px;height:48px;')}<div><div style="color:${itemColor(w)};font-weight:800;font-size:15px">${esc(itemName(w))}</div><div class="small muted">Refine +${r} → +${r + 1}: adds 1 to your weapon's top damage${ITEMS[w.id].mc || ITEMS[w.id].sc ? ' and spell power' : ''}.</div></div></div>
    <div class="stats" style="grid-template-columns:1fr;margin-top:10px"><div><span>Success chance</span><b style="color:${ch >= .6 ? '#9fe0a8' : ch >= .35 ? '#ffe08a' : '#ff8a7a'}">${Math.round(ch * 100)}%</b></div><div><span>Black Iron Ore</span><b style="color:${ore ? '' : '#ff8a7a'}">${ore} / 1</b></div><div><span>Fee</span><b style="color:#f3d27a">${fmt(cost)} gold</b></div></div>
    <div class="row" style="margin-top:12px"><span class="hint">A failed attempt consumes the ore and fee.</span><button class="btn gold" id="refine" style="padding:6px 18px" ${r >= 7 ? 'disabled' : ''}>${r >= 7 ? 'Maximum' : 'Refine'}</button></div>`;
    const bt = b.querySelector('#refine'); if (bt) bt.onclick = () => {
      if (ore < 1) { sys('You need Black Iron Ore. It drops in the Hollow Mine.'); sfx('error'); return; } if (P.gold < cost) { sys('Not enough gold.'); sfx('error'); return; }
      invTake('black_ore', 1); P.gold -= cost; sfx('hit');
      if (R() < ch) { w.r = r + 1; computeStats(); sys(`Success! ${itemName(w)}.`); sfx('rare'); UI.toast(itemName(w), 'refine'); fx('pillar', epx(S.player), epy(S.player), { dur: 1, col: '140,200,255' }); }
      else { sys('The metal cracks and cools. The refinement failed.'); sfx('error'); }
      UI.invDirty = UI.charDirty = true; refreshWin('smith');
    };
  }, 380);
}
UI.invitePrompt = (bot) => { const el = $('#invite'); el.classList.add('show'); $('#invtext').innerHTML = `<b style="color:#bfe0ff;font-size:15px">${esc(bot.name)}</b> <span class="muted">Lv ${bot.lv} ${CLASSES[bot.cls].name}</span><div class="small" style="margin-top:3px;color:#d8cfb8">invites you to join a group.</div>`; UI.pendingInvite = bot; sfx('whisper'); clearTimeout(UI.invT); UI.invT = setTimeout(() => { el.classList.remove('show'); }, 15000); };
$('#invy').onclick = () => { const b = UI.pendingInvite; $('#invite').classList.remove('show'); if (b && !b.dead && S.ents.includes(b)) joinParty(b); };
$('#invn').onclick = () => { $('#invite').classList.remove('show'); if (UI.pendingInvite) whisperFrom(UI.pendingInvite.name, 'ok np'); };
UI.showDeath = (src) => {
  const ov = $('#ov'); ov.hidden = false; ov.style.background = 'radial-gradient(ellipse at 50% 45%,rgba(70,4,0,.5),rgba(0,0,0,.86))';
  ov.innerHTML = `<div class="deathbox"><h2>You have died</h2><p>${src && src.name ? 'Slain by <b style="color:#ff9a7a">' + esc(src.name) + '</b>. ' : ''}Your spirit drifts back toward Ashvale.</p><button class="btn gold" id="rev" style="padding:9px 30px;font-size:14px;letter-spacing:.06em">Return to Ashvale</button></div>`;
  $('#rev').onclick = () => { ov.hidden = true; revive(); };
};
UI.onMapChange = () => { $('#mapname').textContent = S.map.name; $('#mmname').textContent = S.map.name; if (UI.wins.map) { UI.wins.map.el.querySelector('h3').textContent = S.map.name; refreshWin('map'); } S.buildAll = true; closeWin('npc'); closeWin('shop'); closeWin('storage'); closeWin('smith'); UI.partyDirty = true; if (UI.firstMap !== false) UI.firstMap = false; else UI.toast(S.map.name); };

/* ---------- tooltip ---------- */
const tip = $('#tip');
const STLAB = { dc: 'DC', mc: 'MC', sc: 'SC', ac: 'AC', mac: 'MAC' };
function rarInfo(it) { const d = ITEMS[it.id]; if (d.q === 3) return ['r-myth', 'Mythic']; if (d.raid) return ['r-raid', 'Raid Legendary']; if (d.q === 2) return ['r-leg', 'Legendary']; if (d.q === 1) return ['r-rare', 'Rare']; if (addTotal(it) > 0) return ['r-add', 'Enhanced']; return ['', '']; }
function itemTip(it, o) {
  o = o || {}; const d = ITEMS[it.id], P = S.P, a = it.add || {}; const [rc, rl] = rarInfo(it);
  const typ = d.slot === 'book' ? `Skill Book, ${CLASSES[d.cls] ? CLASSES[d.cls].name : ''}` : SLOTNAME[d.slot] || '';
  let h = o.equipped ? '<div class="eqd">Equipped</div>' : '';
  h += `<div class="th"><div class="ti" style="background-image:url(${iconUrl(it.id)})"></div><div><div class="tn" style="color:${itemColor(it)}">${esc(itemName(it))}${it.n > 1 ? ` <span class="muted" style="font-weight:600;font-size:13px">x${it.n}</span>` : ''}</div><div class="tt">${rl ? rl + ' ' : ''}${typ}</div></div></div>`;
  let s = '';
  for (const k of ['dc', 'mc', 'sc', 'ac', 'mac']) {
    const ref = it.r && (k === 'dc' || ((k === 'mc' || k === 'sc') && d[k])) ? it.r : 0; const ad = (a[k] || 0) + ref;
    if (!d[k] && !ad) continue; const lo = d[k] ? d[k][0] : 0, hi = (d[k] ? d[k][1] : 0) + ad;
    s += `<div class="st"><span>${STLAB[k]}</span><b>${lo}-${hi}</b>${ad ? ` <i class="add">(+${ad})</i>` : ''}</div>`;
  }
  if (d.acc || a.acc) s += `<div class="st"><span>Accuracy</span><b>+${(d.acc || 0) + (a.acc || 0)}</b>${a.acc ? ` <i class="add">(+${a.acc})</i>` : ''}</div>`;
  if (d.luck || a.luck) s += `<div class="st"><span>Luck</span><b>+${(d.luck || 0) + (a.luck || 0)}</b>${a.luck ? ` <i class="add">(+${a.luck})</i>` : ''}</div>`;
  if (d.spd) s += `<div class="st"><span>Speed</span><b>+${d.spd}</b></div>`; if (d.hp) s += `<div class="st"><span>Max HP</span><b>+${d.hp}</b></div>`;
  if (d.heal) s += `<div style="color:#ff9a8a">Restores ${d.heal} HP${d.instant ? ' instantly' : ''}</div>`; if (d.mana) s += `<div style="color:#9ab8ff">Restores ${d.mana} MP</div>`;
  if (d.scroll) s += `<div>${d.scroll === 'town' ? 'Returns you to Ashvale.' : 'Teleports you to a random place on this map.'}</div>`;
  h += s;
  if (d.sdesc) h += `<div class="sp">✦ ${d.sdesc}</div>`;
  if (d.slot === 'book') h += `<div class="ds">Teaches <b style="color:#bfe0ff;font-style:normal">${SKILLS[d.skill].name}</b>. ${SKILLS[d.skill].desc}</div>`;
  if (d.desc) h += `<div class="ds">${d.desc}</div>`;
  if (it.l) h += `<div class="st"><span>${it.l > 0 ? 'Blessed luck' : 'Cursed'}</span><b style="color:${it.l > 0 ? '#ffd860' : '#ff6a5a'}">${it.l > 0 ? '+' : ''}${it.l}</b></div>`;
  if (d.use) { const cd = (S.P.mcd && S.P.mcd[d.use.id]) || 0; h += `<div class="myth"><b>Use (R): ${d.use.name}</b> ${d.use.text}<div class="muted" style="font-size:11.5px;margin-top:2px">${d.use.cd}s recharge${cd > 0 ? `, ready in ${Math.ceil(cd)}s` : ''}</div></div>`; }
  if (d.raid) { const n = EQUIP_SLOTS.filter(sl => S.P.equip[sl] && ITEMS[S.P.equip[sl].id].raid).length; h += `<div class="raidl">Abyssal Sanctum raid set (${n}/6 worn)</div>` + setBonusText(S.P.cls).map(b2 => `<div class="${n >= b2.n ? 'setb on' : 'setb'}"><b>(${b2.n}) ${b2.name}:</b> ${b2.text}</div>`).join(''); }
  let rq = '';
  if (d.cls) rq += `<div class="${d.cls !== P.cls ? 'bad' : 'ok'}">${CLASSES[d.cls].name} only</div>`;
  if (d.lv > 1) rq += `<div class="${P.lv < d.lv ? 'bad' : 'ok'}">Requires level ${d.lv}</div>`;
  if (d.slot === 'book' && P.skills[d.skill]) rq += `<div class="bad">Already learned</div>`;
  h += `<div class="tsep"></div>${rq}<div class="pr"><i class="coin"></i>${o.buy ? 'Costs ' + fmt(d.price) : UI.mode === 'shop' ? 'Sells for ' + fmt(sellPrice(it)) : 'Value ' + fmt(sellPrice(it))}</div>`;
  if (o.hint) h += `<div class="hint" style="margin-top:4px">${o.hint}</div>`;
  return [h, rc];
}
function skillTip(k) {
  const s = SKILLS[k], sk = S.P.skills[k]; const kind = { passive: 'Passive', toggle: 'Toggle', target: 'Targeted spell', self: 'Self', ground: 'Area spell', summon: 'Summon', buff: 'Buff', heal: 'Heal' }[s.kind] || '';
  return `<div class="th"><div class="ti" style="background-image:url(${skillIconUrl(k)});background-size:cover"></div><div><div class="tn" style="color:#bfe0ff">${s.name}</div><div class="tt">${kind} &middot; Rank ${sk ? sk.rank : 0} of 3</div></div></div><div style="color:#d8cfb8">${s.desc}</div><div class="tsep"></div>${s.mp ? `<div class="st"><span>Mana</span><b style="color:#9ab8ff">${s.mp} MP</b></div>` : ''}${s.cd ? `<div class="st"><span>Cooldown</span><b>${s.cd}s</b></div>` : ''}${s.range ? `<div class="st"><span>Range</span><b>${s.range}</b></div>` : ''}${!sk ? `<div class="bad">Not learned. Requires level ${s.lv}</div>` : ''}`;
}
function showTip(html, x, y, cls, anchor) {
  if (tip._h !== html) { tip._h = html; tip.innerHTML = html; } const cn = 'frame orn ' + (cls || ''); if (tip.className !== cn) tip.className = cn; tip.style.display = 'block';
  const r = APP.getBoundingClientRect(); const w = tip.offsetWidth, h = tip.offsetHeight; let tx = x - r.left + 18, ty = y - r.top + 14;
  if (anchor) { tx = anchor.left + anchor.width / 2 - w / 2 - r.left; ty = anchor.top - r.top - h - 10; if (tx + w > S.vw - 6) tx = S.vw - 6 - w; }
  else { if (tx + w > S.vw - 6) tx = x - r.left - w - 14; if (ty + h > S.vh - 6) ty = y - r.top - h - 10; }
  tip.style.left = Math.max(4, tx) + 'px'; tip.style.top = Math.max(4, ty) + 'px';
}
function hideTip() { if (tip.style.display !== 'none') tip.style.display = 'none'; }
function simpleTip(t) {
  const P = S.P; const [lab, key] = t.dataset.tip.split('|');
  let h = `<div class="tn" style="font-size:13.5px;color:var(--gold-hi)">${lab}${key ? `<span class="hk">${key}</span>` : ''}</div>`;
  if (P && t.classList.contains('xp')) h += `<div class="tt" style="margin-top:2px">${P.lv >= MAXLV ? 'Maximum level' : `${fmt(Math.floor(P.xp))} / ${fmt(xpNeed(P.lv))}`}</div>`;
  if (P && t.classList.contains('wt')) h += `<div class="tt" style="margin-top:2px">${P.inv.filter(Boolean).length} of 40 bag slots used</div>`;
  if (t.id === 'pkbtn') h += `<div class="tt" style="margin-top:2px">${S.pkMode ? 'On: clicks attack other players' : 'Off'}</div>`;
  return h;
}
document.addEventListener('pointermove', e => {
  const t = e.target.closest ? e.target.closest('[data-inv],[data-eq],[data-sto],[data-buy],[data-belt],[data-sk],[data-cast],[data-tip]') : null;
  if (!t) { hideTip(); return; }
  if (t.dataset.tip) { showTip(simpleTip(t), e.clientX, e.clientY, 'mini', t.closest('#hud') ? t.getBoundingClientRect() : null); return; }
  const P = S.P; if (!P) return; let it = null, eq = false;
  if (t.dataset.inv != null) it = P.inv[+t.dataset.inv]; else if (t.dataset.eq) { it = P.equip[t.dataset.eq]; eq = true; } else if (t.dataset.sto != null) it = P.storage[+t.dataset.sto];
  else if (t.dataset.buy) { const [h, rc] = itemTip({ id: t.dataset.buy }, { buy: true }); showTip(h, e.clientX, e.clientY, rc); return; }
  else if (t.dataset.belt != null) { const id = P.belt[+t.dataset.belt]; if (id) { const [h, rc] = itemTip({ id, n: invCount(id) }, { hint: `Hotkey ${+t.dataset.belt + 1}. Right-click to clear this slot.` }); showTip(h, e.clientX, e.clientY, rc); return; } }
  else if (t.dataset.sk != null || t.dataset.cast) { const k = t.dataset.cast || P.keys[+t.dataset.sk]; if (k) { showTip(skillTip(k), e.clientX, e.clientY); return; } }
  if (it) { const [h, rc] = itemTip(it, { equipped: eq }); showTip(h, e.clientX, e.clientY, rc); } else hideTip();
});
/* ---------- item interactions ---------- */
function invAction(i) {
  const P = S.P; const it = P.inv[i]; if (!it) return;
  if (UI.mode === 'shop') { sell(i); return; }
  if (UI.mode === 'storage') { const j = P.storage.findIndex(x => !x); if (j < 0) { sys('Storage is full.'); return; } P.storage[j] = it; P.inv[i] = null; UI.invDirty = true; refreshWin('storage'); sfx('pickup'); return; }
  useItem(i); UI.invDirty = true;
}
document.addEventListener('contextmenu', e => { if (e.target.closest('#app')) e.preventDefault(); });
$('#wins').addEventListener('pointerdown', e => {
  const P = S.P; const t = e.target.closest('[data-inv],[data-eq],[data-sto],[data-buy],[data-bind],[data-cast]'); if (!t) return;
  if (t.dataset.bind) { const [k, i] = t.dataset.bind.split(':'); const ix = +i; for (let j = 0; j < 8; j++) if (P.keys[j] === k) P.keys[j] = null; P.keys[ix] = k; UI.skillsDirty = true; sfx('click'); return; }
  if (t.dataset.cast) { castSkill(t.dataset.cast); return; }
  if (t.dataset.buy) { buy(t.dataset.buy, e.shiftKey); if (UI.wins.shop) refreshWin('shop'); return; }
  if (t.dataset.sto != null) { const i = +t.dataset.sto, it = P.storage[i]; if (it && invAdd(it)) { P.storage[i] = null; refreshWin('storage'); UI.invDirty = true; sfx('pickup'); } return; }
  if (t.dataset.eq) { if (e.button === 2 || e.detail >= 2) unequip(t.dataset.eq); return; }
  if (t.dataset.inv != null) {
    const i = +t.dataset.inv; if (!P.inv[i]) return;
    if (e.button === 2) { invAction(i); return; }
    if (e.detail >= 2) { invAction(i); return; }
    startDrag(i, e);
  }
});
function startDrag(i, e) {
  const it = S.P.inv[i]; let ghost = null; const sx = e.clientX, sy = e.clientY;
  const mv = ev => { if (!ghost && Math.hypot(ev.clientX - sx, ev.clientY - sy) > 6) { ghost = document.createElement('div'); ghost.className = 'slot ' + rarCls(it); ghost.style.cssText = `position:fixed;pointer-events:none;z-index:99;opacity:.9;transform:scale(1.1);background-image:url(${iconUrl(it.id)})`; document.body.appendChild(ghost); hideTip(); } if (ghost) { ghost.style.left = ev.clientX - 18 + 'px'; ghost.style.top = ev.clientY - 18 + 'px'; } };
  const up = ev => {
    window.removeEventListener('pointermove', mv); window.removeEventListener('pointerup', up); if (!ghost) return; ghost.remove();
    const el = document.elementFromPoint(ev.clientX, ev.clientY); const P = S.P; if (!el) return;
    const belt = el.closest('[data-belt]'), inv = el.closest('[data-inv]'), eq = el.closest('[data-eq]');
    if (belt) { if (ITEMS[it.id].slot === 'cons') { P.belt[+belt.dataset.belt] = it.id; UI.beltDirty = true; sfx('click'); } return; }
    if (inv) { const j = +inv.dataset.inv; if (j !== i) { [P.inv[i], P.inv[j]] = [P.inv[j], P.inv[i]]; UI.invDirty = true; } return; }
    if (eq) { useItem(i); return; }
    if (el === cv) { P.inv[i] = null; dropItem(S.player.x, S.player.y, it); sys(`You dropped ${itemName(it)}.`); UI.invDirty = true; }
  };
  window.addEventListener('pointermove', mv); window.addEventListener('pointerup', up);
}

/* ---------- HUD ---------- */
function buildBars() {
  let h = ''; for (let i = 0; i < 8; i++) h += `<div class="slot" data-sk="${i}"><span class="k">${i + 1}</span><div class="cd" style="--p:0%"></div><span class="cdt"></span></div>`; $('#skbar').innerHTML = h;
  h = ''; for (let i = 0; i < 6; i++) h += `<div class="slot" data-belt="${i}"><span class="k">${['Q', 'E', '', '', '', ''][i]}</span><span class="c"></span></div>`; $('#belt').innerHTML = h;
  $('#skbar').addEventListener('pointerdown', e => { const t = e.target.closest('[data-sk]'); if (!t) return; const i = +t.dataset.sk; if (e.button === 2) { S.P.keys[i] = null; UI.skillsDirty = true; return; } const k = S.P.keys[i]; if (k) castSkill(k); });
  $('#belt').addEventListener('pointerdown', e => { const t = e.target.closest('[data-belt]'); if (!t) return; const i = +t.dataset.belt; if (e.button === 2) { S.P.belt[i] = null; UI.beltDirty = true; return; } useBelt(i); });
  document.querySelectorAll('#btns [data-w]').forEach(b => b.onclick = e => { toggleWin(b.dataset.w); if (e.detail) b.blur(); });
  $('#pkbtn').onclick = e => { S.pkMode = !S.pkMode; $('#pkbtn').classList.toggle('on', S.pkMode); sys(S.pkMode ? 'PK mode on. Clicking other players will attack them.' : 'PK mode off.'); if (e.detail) $('#pkbtn').blur(); };
  document.querySelectorAll('[data-chat]').forEach(b => b.onclick = e => { const a = b.dataset.chat; if (e.detail) b.blur();
    if (a === 'up') chatlog.scrollTop -= 42; else if (a === 'down') chatlog.scrollTop += 42; else if (a === 'end') chatlog.scrollTop = chatlog.scrollHeight; else if (S.running) openChat(a === '/' ? '/' : a + ' '); });
}
function useBelt(i) { const id = S.P.belt[i]; if (!id) return; const k = S.P.inv.findIndex(x => x && x.id === id); if (k < 0) { sys(`You have no ${ITEMS[id].name}.`); sfx('error'); return; } useItem(k); UI.beltDirty = true; }

/* ---------- HP / MP orb with dragon-wing frame ---------- */
const orbC = $('#orb').getContext('2d');
const RMQ = window.matchMedia ? matchMedia('(prefers-reduced-motion: reduce)') : null; const calm = () => !!(RMQ && RMQ.matches);
const ORB = { W: 204, H: 156, cx: 102, cy: 92, r: 47, h: null, m: null };
function metal(c, x0, y0, x1, y1, stops) { const g = c.createLinearGradient(x0, y0, x1, y1); stops.forEach((s, i) => g.addColorStop(i / (stops.length - 1), s)); return g; }
const GOLD = ['#fff6d4', '#e8c472', '#9a6c26', '#e2bc6a', '#5a3c10'], STEEL = ['#f4f6fa', '#b8bec8', '#646a74', '#aab0ba', '#2e3238'];
function buildOrbFrame() {
  const cvs = document.createElement('canvas'); cvs.width = ORB.W * 2; cvs.height = ORB.H * 2; const c = cvs.getContext('2d'); c.scale(2, 2);
  const { cx, cy, r } = ORB; const R0 = r + 4;
  const tips = [[-98, -58], [-94, -24], [-84, 6], [-66, 30]], ctl = [[-76, -42], [-72, -10], [-60, 12], [-47, 24]], A = [-31, -41], B = [-42, 33], root = [-46, -8];
  c.lineJoin = 'round'; c.lineCap = 'round';
  for (const s of [1, -1]) {
    c.save(); c.translate(cx, cy); c.scale(s, 1);
    // wing silhouette (gold)
    const path = () => { c.beginPath(); c.moveTo(A[0], A[1]); c.bezierCurveTo(-46, -60, -72, -68, tips[0][0], tips[0][1]); for (let i = 0; i < 4; i++) { const nx = i < 3 ? tips[i + 1] : B; c.quadraticCurveTo(ctl[i][0], ctl[i][1], nx[0], nx[1]); } c.arc(0, 0, R0, Math.atan2(B[1], B[0]), Math.atan2(A[1], A[0]) + Math.PI * 2 * (Math.atan2(A[1], A[0]) < Math.atan2(B[1], B[0]) ? 1 : 0)); c.closePath(); };
    c.shadowColor = 'rgba(0,0,0,.7)'; c.shadowBlur = 6; c.shadowOffsetY = 2; path(); c.fillStyle = metal(c, -98, -60, -40, 30, GOLD); c.fill(); c.shadowBlur = 0; c.shadowOffsetY = 0;
    c.strokeStyle = '#1a1004'; c.lineWidth = 1.4; c.stroke();
    // silver membranes between the bones
    for (let i = 0; i < 4; i++) {
      const t0 = tips[i], t1 = i < 3 ? tips[i + 1] : B, k = .84; const p0 = [root[0] + (t0[0] - root[0]) * k, root[1] + (t0[1] - root[1]) * k], p1 = [root[0] + (t1[0] - root[0]) * k, root[1] + (t1[1] - root[1]) * k];
      const cc = [ctl[i][0] * .9 + root[0] * .1 + 2, ctl[i][1] * .9 + root[1] * .1];
      c.beginPath(); c.moveTo(root[0] + 3, root[1]); c.lineTo(p0[0], p0[1]); c.quadraticCurveTo(cc[0], cc[1], p1[0], p1[1]); c.closePath();
      c.fillStyle = metal(c, p0[0], p0[1], root[0], root[1] + 20, STEEL); c.globalAlpha = .88; c.fill(); c.globalAlpha = 1;
      c.strokeStyle = 'rgba(20,14,6,.7)'; c.lineWidth = .8; c.stroke();
      // engraved line inside membrane
      c.strokeStyle = 'rgba(255,255,255,.35)'; c.lineWidth = .6; c.beginPath(); c.moveTo(root[0] - 4, root[1] + 1); c.quadraticCurveTo((p0[0] + p1[0]) / 2 + 8, (p0[1] + p1[1]) / 2, (p0[0] + p1[0]) / 2 + 3, (p0[1] + p1[1]) / 2 + 2); c.stroke();
    }
    // gold bones
    for (const tp of tips.concat([B])) { c.strokeStyle = '#1a1004'; c.lineWidth = 3.6; c.beginPath(); c.moveTo(root[0], root[1]); c.lineTo(tp[0], tp[1]); c.stroke(); c.strokeStyle = metal(c, root[0], root[1], tp[0], tp[1], ['#fff0c0', '#d4a850', '#8a5e1c']); c.lineWidth = 2.2; c.stroke(); }
    // leading edge (arm bone)
    c.beginPath(); c.moveTo(A[0], A[1]); c.bezierCurveTo(-46, -60, -72, -68, tips[0][0], tips[0][1]);
    c.strokeStyle = '#1a1004'; c.lineWidth = 5.5; c.stroke(); c.strokeStyle = metal(c, -30, -40, -98, -58, ['#fff8dc', '#f0cc78', '#a07028', '#e8c070']); c.lineWidth = 3.8; c.stroke();
    c.strokeStyle = 'rgba(255,255,240,.8)'; c.lineWidth = .8; c.beginPath(); c.moveTo(A[0] - 2, A[1] - 2); c.bezierCurveTo(-47, -62, -72, -69.5, -94, -61); c.stroke();
    // tip claw
    c.fillStyle = '#fff0c0'; c.strokeStyle = '#1a1004'; c.lineWidth = 1; c.beginPath(); c.moveTo(-96, -60); c.lineTo(-106, -64); c.lineTo(-97, -55); c.closePath(); c.fill(); c.stroke();
    // root knuckle
    c.fillStyle = metal(c, root[0] - 5, root[1] - 5, root[0] + 5, root[1] + 5, GOLD); c.beginPath(); c.arc(root[0], root[1], 4.6, 0, 7); c.fill(); c.stroke();
    c.fillStyle = '#c02a1a'; c.beginPath(); c.arc(root[0], root[1], 2, 0, 7); c.fill();
    c.restore();
  }
  c.save(); c.translate(cx, cy);
  // bezel ring
  c.lineWidth = 10; c.strokeStyle = metal(c, -r, -r, r, r, ['#fff6d4', '#e0bb68', '#8a5e1c', '#f0d080', '#a07028', '#4a3008']); c.beginPath(); c.arc(0, 0, r + 5, 0, 7); c.stroke();
  c.strokeStyle = '#140c02'; c.lineWidth = 1.3; c.beginPath(); c.arc(0, 0, r + .4, 0, 7); c.stroke(); c.beginPath(); c.arc(0, 0, r + 10, 0, 7); c.stroke();
  c.strokeStyle = 'rgba(255,245,210,.65)'; c.lineWidth = .9; c.beginPath(); c.arc(0, 0, r + 8.6, Math.PI * 1.05, Math.PI * 1.6); c.stroke();
  c.strokeStyle = 'rgba(40,24,4,.55)'; c.lineWidth = .8; c.beginPath(); c.arc(0, 0, r + 5, 0, 7); c.stroke();
  for (let i = 0; i < 16; i++) { const a = i / 16 * Math.PI * 2 + Math.PI / 16; const x = Math.cos(a) * (r + 5), y = Math.sin(a) * (r + 5); c.fillStyle = '#2a1a06'; c.beginPath(); c.arc(x, y, 1.9, 0, 7); c.fill(); c.fillStyle = i % 2 ? '#fff0c0' : '#dfe4ea'; c.beginPath(); c.arc(x - .4, y - .4, 1.1, 0, 7); c.fill(); }
  // crest with ruby
  c.beginPath(); c.moveTo(-15, -r - 5); c.bezierCurveTo(-10, -r - 12, -5, -r - 16, 0, -r - 28); c.bezierCurveTo(5, -r - 16, 10, -r - 12, 15, -r - 5); c.closePath();
  c.fillStyle = metal(c, -14, -r - 28, 14, -r, GOLD); c.fill(); c.strokeStyle = '#1a1004'; c.lineWidth = 1.2; c.stroke();
  c.strokeStyle = 'rgba(255,248,220,.7)'; c.lineWidth = .7; c.beginPath(); c.moveTo(-9, -r - 8); c.quadraticCurveTo(-4, -r - 15, 0, -r - 24); c.stroke();
  const gy = -r - 12; c.fillStyle = '#1a0402'; c.beginPath(); c.ellipse(0, gy, 5.2, 6.2, 0, 0, 7); c.fill();
  let g = c.createRadialGradient(-1.5, gy - 2, .5, 0, gy, 6); g.addColorStop(0, '#ffe0d8'); g.addColorStop(.3, '#ff3a24'); g.addColorStop(1, '#5a0402'); c.fillStyle = g; c.beginPath(); c.ellipse(0, gy, 4.2, 5.2, 0, 0, 7); c.fill();
  // bottom clasp
  c.beginPath(); c.moveTo(-18, r + 6); c.quadraticCurveTo(0, r + 20, 18, r + 6); c.lineTo(10, r + 3); c.quadraticCurveTo(0, r + 10, -10, r + 3); c.closePath(); c.fillStyle = metal(c, 0, r, 0, r + 16, GOLD); c.fill(); c.strokeStyle = '#1a1004'; c.lineWidth = 1; c.stroke();
  c.restore();
  return cvs;
}
function drawOrb(dt) {
  const p = S.player, c = orbC, { cx, cy, r } = ORB; if (!ORB.frame) ORB.frame = buildOrbFrame();
  const hpF = clamp(p.hp / p.maxhp, 0, 1), mpF = p.maxmp ? clamp(p.mp / p.maxmp, 0, 1) : 0, k = Math.min(1, (dt || .016) * 7);
  ORB.h = ORB.h == null ? hpF : ORB.h + (hpF - ORB.h) * k; ORB.m = ORB.m == null ? mpF : ORB.m + (mpF - ORB.m) * k;
  const t = calm() ? 0 : S.time;
  c.setTransform(1, 0, 0, 1, 0, 0); c.clearRect(0, 0, ORB.W * 2, ORB.H * 2); c.setTransform(2, 0, 0, 2, 0, 0);
  c.save(); c.beginPath(); c.arc(cx, cy, r, 0, 7); c.clip();
  c.fillStyle = '#12080a'; c.fillRect(cx - r, cy - r, r, 2 * r); c.fillStyle = '#05071a'; c.fillRect(cx, cy - r, r, 2 * r);
  const liquid = (x0, x1, f, cols, ph) => {
    if (f <= .002) return; const top = cy + r - f * 2 * r; const wave = x => top + Math.sin(x * .11 + t * 2.3 + ph) * 1.7 + Math.sin(x * .047 - t * 1.3 + ph) * 1.2;
    const g = c.createLinearGradient(0, top - 3, 0, cy + r); g.addColorStop(0, cols[0]); g.addColorStop(.3, cols[1]); g.addColorStop(1, cols[2]);
    c.fillStyle = g; c.beginPath(); c.moveTo(x0, cy + r + 1); for (let x = x0; x <= x1 + .1; x += 2) c.lineTo(x, wave(x)); c.lineTo(x1, cy + r + 1); c.closePath(); c.fill();
    c.strokeStyle = 'rgba(255,255,255,.4)'; c.lineWidth = .9; c.beginPath(); for (let x = x0; x <= x1 + .1; x += 2) { if (x === x0) c.moveTo(x, wave(x) + .6); else c.lineTo(x, wave(x) + .6); } c.stroke();
    const hh = f * 2 * r; if (hh > 8 && t) { c.fillStyle = 'rgba(255,255,255,.22)'; for (let i = 0; i < 4; i++) { const bx = x0 + 7 + ((i * 11 + ph * 7) % (x1 - x0 - 14)); const by = cy + r - ((t * (7 + i * 3) + i * 23) % hh); c.beginPath(); c.arc(bx + Math.sin(t * 3 + i) * 1.5, by, .9 + (i % 2) * .6, 0, 7); c.fill(); } }
  };
  liquid(cx - r, cx, ORB.h, ['#ff8a64', '#d41a10', '#4a0302'], 0);
  liquid(cx, cx + r, ORB.m, ['#8ab8ff', '#2448d8', '#060c4a'], 1.7);
  c.fillStyle = 'rgba(0,0,0,.85)'; c.fillRect(cx - 1, cy - r, 2, 2 * r); c.fillStyle = 'rgba(255,230,180,.25)'; c.fillRect(cx - .3, cy - r, .6, 2 * r);
  let g = c.createRadialGradient(cx, cy, r * .5, cx, cy, r); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(0,0,0,.6)'); c.fillStyle = g; c.fillRect(cx - r, cy - r, 2 * r, 2 * r);
  c.save(); c.translate(cx - r * .3, cy - r * .48); c.rotate(-.45); c.scale(1, .55); g = c.createRadialGradient(0, 0, 0, 0, 0, r * .52); g.addColorStop(0, 'rgba(255,255,255,.6)'); g.addColorStop(.55, 'rgba(255,255,255,.14)'); g.addColorStop(1, 'rgba(255,255,255,0)'); c.fillStyle = g; c.beginPath(); c.arc(0, 0, r * .52, 0, 7); c.fill(); c.restore();
  c.fillStyle = 'rgba(255,255,255,.85)'; c.beginPath(); c.arc(cx - r * .42, cy - r * .5, 1.6, 0, 7); c.fill();
  c.strokeStyle = 'rgba(255,255,255,.18)'; c.lineWidth = 1.5; c.beginPath(); c.arc(cx, cy, r - 4, Math.PI * .15, Math.PI * .5); c.stroke();
  c.restore();
  c.setTransform(1, 0, 0, 1, 0, 0); c.drawImage(ORB.frame, 0, 0);
  if (hpF < .3 && hpF > 0) { c.setTransform(2, 0, 0, 2, 0, 0); c.strokeStyle = `rgba(255,50,30,${.45 + Math.sin(t * 7) * .35})`; c.lineWidth = 3; c.shadowColor = '#ff2a10'; c.shadowBlur = 14; c.beginPath(); c.arc(cx, cy, r + 5, Math.PI * .5, Math.PI * 1.5); c.stroke(); c.shadowBlur = 0; }
}

/* ---------- minimap ---------- */
const mmC = $('#mmc').getContext('2d'); const MMS = 328;
function drawMini() {
  const m = S.map, p = S.player, c = mmC; const span = 60, sc = MMS / span;
  c.fillStyle = '#000'; c.fillRect(0, 0, MMS, MMS); c.imageSmoothingEnabled = false;
  const sx = p.x - span / 2, sy = p.y - span / 2; c.drawImage(m.mini, sx, sy, span, span, 0, 0, MMS, MMS);
  if (m.dark > .5) { c.fillStyle = 'rgba(0,0,0,.25)'; c.fillRect(0, 0, MMS, MMS); }
  for (const q of m.portals) { const x = ((q.x0 + q.x1 + 1) / 2 - sx) * sc, y = ((q.y0 + q.y1 + 1) / 2 - sy) * sc; if (x < -8 || y < -8 || x > MMS + 8 || y > MMS + 8) continue; c.save(); c.globalCompositeOperation = 'lighter'; glow(c, x, y, 14, '90,160,255', .8); c.restore(); c.fillStyle = '#9ad0ff'; c.beginPath(); c.arc(x, y, 4, 0, 7); c.fill(); }
  for (const e of S.ents) { if (e.dead || e === p) continue; const x = (e.x + .5 - sx) * sc, y = (e.y + .5 - sy) * sc; if (x < 0 || y < 0 || x > MMS || y > MMS) continue;
    const boss = e.kind === 'mon' && e.def.boss;
    const col = e.kind === 'mon' ? (boss ? '#ff9a2a' : '#e8402e') : e.kind === 'npc' ? '#ffe070' : e.kind === 'bot' ? (e.party ? '#6ad0ff' : e.red ? '#ff3a2a' : '#ece4d4') : e.kind === 'pet' ? '#6ae07a' : '#8a8a8a';
    const s = boss ? 10 : e.kind === 'npc' ? 7 : 6; c.fillStyle = '#000'; c.fillRect(x - s / 2 - 1, y - s / 2 - 1, s + 2, s + 2); c.fillStyle = col; c.fillRect(x - s / 2, y - s / 2, s, s);
    if (boss) { c.strokeStyle = `rgba(255,120,40,${.5 + Math.sin(S.time * 5) * .4})`; c.lineWidth = 2; c.beginPath(); c.arc(x, y, 10, 0, 7); c.stroke(); } }
  const px = (p.x + .5 - sx) * sc, py = (p.y + .5 - sy) * sc, a = Math.atan2(DY[p.dir], DX[p.dir]);
  c.save(); c.translate(px, py); c.rotate(a); c.beginPath(); c.moveTo(9, 0); c.lineTo(-6, -6); c.lineTo(-3, 0); c.lineTo(-6, 6); c.closePath(); c.fillStyle = '#fff'; c.fill(); c.strokeStyle = '#000'; c.lineWidth = 2; c.stroke(); c.restore();
}

/* ---------- chat ---------- */
const chatlog = $('#chatlog');
const ALERT_RE = /not enough|cannot|can't|you have been slain|you must|you need|is full|failed|no target|rejects|nobody will|you have no|you dropped|murder|recharging|only accepts|not in a|destroyed|taken on|dropped/i;
const GOOD_RE = /^level up|reached rank|you learned|quest complete|^success|joined your group|accepted you|you founded|flares|new skill|you have defeated|holds castle|quest accepted|game saved/i;
function chatLine(l) {
  const n = l.from ? esc(l.from) : '', t = esc(l.text);
  switch (l.ch) {
    case 'shout': return l.from === 'System' ? `<div class="c-shout sysx"><span>${t}</span></div>` : `<div class="c-shout"><span>(!) ${n ? n + ': ' : ''}${t}</span></div>`;
    case 'say': return `<div class="c-say"><b>${n}</b>: ${t}</div>`;
    case 'guild': return `<div class="c-guild">[Guild] ${n}: ${t}</div>`;
    case 'party': return `<div class="c-party">[Group] ${n}: ${t}</div>`;
    case 'whisper': return `<div class="c-whisper">${n} whispers: ${t}</div>`;
    case 'whisperTo': return `<div class="c-whisper">To ${n}: ${t}</div>`;
    case 'loot': return `<div class="c-loot"><span style="color:${esc(l.from || '#e9e4d6')}">${t}</span></div>`;
    case 'xp': return `<div class="c-xp">${t}</div>`;
    default: return ALERT_RE.test(l.text) ? `<div class="c-alert"><span>${t}</span></div>` : GOOD_RE.test(l.text) ? `<div class="c-notice"><span>${t}</span></div>` : `<div class="c-sys">${t}</div>`;
  }
}

/* ---------- per-frame HUD ---------- */
const HE = {}; const he = id => HE[id] || (HE[id] = document.getElementById(id));
function setT(id, v) { const e = he(id); v = String(v); if (e._v !== v) { e._v = v; e.textContent = v; } }
function setWd(id, pct) { const e = he(id); const v = clamp(pct, 0, 100).toFixed(1) + '%'; if (e._w !== v) { e._w = v; e.style.width = v; } }
let WBTNS = null;
UI.hudTick = (dt) => {
  const p = S.player, P = S.P; if (!p) return;
  drawOrb(dt);
  setT('hpn', Math.max(0, Math.round(p.hp)) + '/' + p.maxhp); setT('mpn', Math.round(p.mp) + '/' + p.maxmp);
  UI.t += dt;
  // skill bar cooldowns
  const sks = he('skbar').children;
  for (let i = 0; i < 8 && i < sks.length; i++) {
    const k = P.keys[i], el = sks[i]; if (el.dataset.k !== (k || '')) { el.dataset.k = k || ''; el.style.backgroundImage = k ? `url(${skillIconUrl(k)})` : ''; el.classList.toggle('empty', !k); }
    const cdEl = el._cd || (el._cd = el.querySelector('.cd')), cdT = el._cdt || (el._cdt = el.querySelector('.cdt')); let v = 0, left = 0;
    if (k) { const s = SKILLS[k], sk = P.skills[k]; const real = sk && sk.cd > 0 && s.cd; v = clamp(real ? sk.cd / s.cd : S.gcd > 0 && s.kind !== 'toggle' ? S.gcd / .75 : 0, 0, 1); left = real ? sk.cd : 0; const on = !!P.toggles[k], nm = p.mp < s.mp; if (el._on !== on) { el._on = on; el.classList.toggle('on', on); } if (el._nm !== nm) { el._nm = nm; el.classList.toggle('nomp', nm); } }
    else if (el._on || el._nm) { el._on = el._nm = false; el.classList.remove('on', 'nomp'); }
    // radial sweep (WoW-style), countdown text over 1.5 s, and a flash when it comes off cooldown
    const sv = (v * 100).toFixed(1) + '%'; if (cdEl._s !== sv) { if (cdEl._s && cdEl._s !== '0.0%' && sv === '0.0%') { el.classList.remove('ready'); void el.offsetWidth; el.classList.add('ready'); } cdEl._s = sv; cdEl.style.setProperty('--p', sv); }
    const tt = left > 1.5 ? (left < 10 ? left.toFixed(1) : Math.ceil(left) + '') : ''; if (cdT._t !== tt) { cdT._t = tt; cdT.textContent = tt; }
  }
  if (UI.wins.char && UI.dollCv) { UI.dollT += dt; if (UI.dollT > .045) { UI.dollT = 0; drawDoll(); } }
  if (UI.t < .15 && !UI.chatDirty) return; UI.t = 0;
  // slower updates
  const bl = he('belt').children;
  for (let i = 0; i < 6 && i < bl.length; i++) { const id = P.belt[i], el = bl[i]; if (el.dataset.id !== (id || '')) { el.dataset.id = id || ''; el.style.backgroundImage = id ? `url("${iconUrl(id)}")` : ''; } const cnt = id ? invCount(id) : 0; const ct = id ? String(cnt) : ''; const cEl = el._c || (el._c = el.querySelector('.c')); if (cEl._v !== ct) { cEl._v = ct; cEl.textContent = ct; } const em = !id || !cnt; if (el._em !== em) { el._em = em; el.classList.toggle('empty', em); } }
  setT('lvl', 'Lv ' + P.lv); setT('stname', P.name); setT('stlv', 'Lv ' + P.lv);
  const need = xpNeed(P.lv); const pct = P.lv >= MAXLV ? 100 : P.xp / need * 100;
  setT('xppct', P.lv >= MAXLV ? 'MAX' : pct.toFixed(2) + '%'); setWd('xpb', pct); setT('goldn', fmt(P.gold));
  let used = 0; for (const x of P.inv) if (x) used++; setT('wtn', used + '/40'); setWd('wtb', used / 40 * 100);
  const wc = used >= 36 ? 'meter wt full' : used >= 28 ? 'meter wt mid' : 'meter wt'; const wm = he('wtm'); if (wm.className !== wc) wm.className = wc;
  const xy = `${p.x}:${p.y}`; setT('coords', xy); setT('mmxy', xy);
  const dp = dayPhase(); const hh = Math.floor(dp.hour), mm = Math.floor((dp.hour % 1) * 60);
  setT('tod', S.map.outdoor ? (dp.night > .5 ? 'Night' : dp.night > .1 ? 'Dusk' : 'Day') : 'Underground'); setT('online', fmt(S.online) + ' online');
  setT('clock', `${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}`);
  drawMini(); if (UI.wins.map) drawBigMap();
  if (!WBTNS) WBTNS = [...document.querySelectorAll('#btns [data-w]')];
  for (const b of WBTNS) { const on = !!UI.wins[b.dataset.w]; if (b._on !== on) { b._on = on; b.classList.toggle('on', on); } }
  // target
  const t = (p.target && !p.target.dead) ? p.target : (S.hover && S.hover.kind === 'mon' ? S.hover : null); const tf = he('target');
  if (t && (t.kind === 'mon' || t.kind === 'bot')) {
    if (tf.hidden) tf.hidden = false; const boss = !!(t.def && t.def.boss); if (tf._b !== boss) { tf._b = boss; tf.classList.toggle('boss', boss); }
    setT('tname', t.name); const col = boss ? '#ffb04a' : t.red ? '#ff6a5a' : '#ece6d6'; const tn = he('tname'); if (tn._c !== col) { tn._c = col; tn.style.color = col; }
    setT('tlv', t.kind === 'mon' ? `Level ${t.def.lv}${t.def.undead ? ' · Undead' : ''}${boss ? ' · Boss' : ''}` : `Level ${t.lv} ${CLASSES[t.cls].name}${t.guild ? ' · ' + t.guild : ''}`); setWd('thp', t.hp / t.maxhp * 100);
  } else if (!tf.hidden) tf.hidden = true;
  // buffs
  const BUFFICON = { lich: 'skeleton', dragon: 'hound', sanct: 'massheal' }; const bf = []; for (const k in p.buffs) { const ik = BUFFICON[k] || k; if (!SKILLS[ik]) continue; bf.push(`<div class="buff${BUFFICON[k] ? ' myth' : ''}" style="background-image:url(${skillIconUrl(ik)})"><span>${Math.ceil(p.buffs[k].t)}</span></div>`); }
  if (p.poison) bf.push(`<div class="buff" style="background-image:url(${skillIconUrl('poison')})"><span>${Math.ceil(p.poison.t)}</span></div>`);
  if (P.pk >= 100) bf.push(`<div class="buff" style="background:#1a0a06;display:grid;place-items:center;font-weight:800;color:${P.pk >= 200 ? '#ff6a5a' : '#ffe04a'};font-size:11px">PK</div>`);
  const bh = bf.join(''); if (bh !== UI.lastBuffs) { he('buffs').innerHTML = bh; UI.lastBuffs = bh; }
  // party
  const ph = S.party.map(b => `<div class="pm frame"><div class="n"><span>${esc(b.name)}</span><span class="muted">${b.lv} ${b.cls}</span></div><div class="bar"><i style="width:${Math.round(b.hp / b.maxhp * 100)}%;background:linear-gradient(180deg,#8ae07a,#2a9a3a 50%,#0e4a16)"></i></div></div>`).join('') + (S.pet && !S.pet.dead ? `<div class="pm frame"><div class="n"><span style="color:#b8f0c0">${S.pet.petType === 'hound' ? 'Spirit Hound' : 'Skeleton'}</span><span class="muted">${S.pet.lv}</span></div><div class="bar"><i style="width:${Math.round(S.pet.hp / S.pet.maxhp * 100)}%;background:linear-gradient(180deg,#8ae07a,#2a9a3a 50%,#0e4a16)"></i></div></div>` : '');
  if (ph !== UI.lastParty) { he('party').innerHTML = ph; UI.lastParty = ph; }
  const qh = questHtml(); if (qh !== UI.lastQ) { he('qt').innerHTML = qh; UI.lastQ = qh; }
  if (UI.chatDirty) {
    UI.chatDirty = false;
    for (let i = CHAT.length - 1; i >= 0 && !CHAT[i]._s; i--) { const l = CHAT[i]; l._s = 1; if (l.ch === 'shout' && l.from === 'System' && / has appeared/.test(l.text) && S.time - l.t < 3) UI.toast(l.text.replace(/ has appeared.*/, ''), 'boss'); }
    const atBottom = chatlog.scrollHeight - chatlog.scrollTop - chatlog.clientHeight < 30; chatlog.innerHTML = CHAT.slice(-80).map(chatLine).join(''); if (atBottom) chatlog.scrollTop = chatlog.scrollHeight;
  }
  if (UI.invDirty) { UI.invDirty = false; refreshWin('inv'); if (UI.wins.smith) refreshWin('smith'); if (UI.wins.shop) { const g = UI.wins.shop.body.querySelector('.winfoot .gold'); if (g) g.innerHTML = `<i class="coin"></i>${fmt(P.gold)}`; } }
  if (UI.charDirty) { UI.charDirty = false; refreshWin('char'); }
  else if (UI.wins.char) { const s = charStatsHtml(); if (s !== UI.lastCStats) { UI.lastCStats = s; const el = document.getElementById('cstats'); if (el) el.innerHTML = s; } }
  if (UI.skillsDirty) { UI.skillsDirty = false; refreshWin('skills'); }
  if (UI.questDirty) { UI.questDirty = false; refreshWin('quest'); }
};

/* ---------- context menu ---------- */
const ctxEl = $('#ctx');
function showCtx(b, x, y) {
  const r = APP.getBoundingClientRect();
  ctxEl.innerHTML = `<div class="t">${esc(b.name)}</div><div class="s">Level ${b.lv} ${CLASSES[b.cls].name}${b.guild ? ` &middot; &lt;${esc(b.guild)}&gt;` : ''}</div>
  ${b.party ? '<div class="i" data-a="kick">Remove from group</div>' : '<div class="i" data-a="inv">Invite to group</div>'}<div class="i" data-a="trade">Trade</div><div class="i" data-a="wh">Whisper</div><div class="i red" data-a="pk">Attack</div>`;
  ctxEl.style.display = 'block'; const place = () => { ctxEl.style.left = Math.max(4, Math.min(x - r.left + 4, S.vw - ctxEl.offsetWidth - 6)) + 'px'; ctxEl.style.top = Math.max(4, Math.min(y - r.top + 4, S.vh - ctxEl.offsetHeight - 6)) + 'px'; }; place(); queueMicrotask(place);
  ctxEl.onclick = e => { const a = e.target.dataset.a; if (!a) return; ctxEl.style.display = 'none';
    if (a === 'inv') { sys(`You invited ${b.name} to your group.`); inviteBot(b); }
    if (a === 'kick') { leaveParty(b); b.mode = 'hunt'; }
    if (a === 'trade' && window.openTrade) openTrade(b);
    if (a === 'wh') openChat('/' + b.name + ' ');
    if (a === 'pk') { S.forcePK = b; S.player.target = b; } };
}
document.addEventListener('pointerdown', e => { if (!e.target.closest('#ctx')) ctxEl.style.display = 'none'; }, true);

/* ---------- chat input ---------- */
const chatin = $('#chatin');
function updCh() { const v = chatin.value; const [c, l] = v.startsWith('!~') ? ['guild', 'Guild'] : v.startsWith('!!') ? ['party', 'Group'] : v.startsWith('!') ? ['shout', 'Shout'] : v.startsWith('/') ? ['whisper', 'Whisper'] : ['', 'Say']; const e = he('chch'); if (e.className !== c) e.className = c; if (e.textContent !== l) e.textContent = l; }
function openChat(pre) { chatin.classList.add('on'); chatin.value = pre || ''; chatin.focus(); updCh(); }
function sendChat() {
  const v = chatin.value.trim(); chatin.value = ''; chatin.classList.remove('on'); chatin.blur(); updCh(); if (!v || !S.running) return; const P = S.P, p = S.player;
  if (v.startsWith('!~')) { if (!P.guild) { sys('You are not in a guild.'); return; } chat('guild', v.slice(2).trim(), P.name); const on = P.guild.members.filter(m => m.on); if (on.length && R() < .6) setTimeoutGame(2 + R() * 4, () => chat('guild', replyFor(v) || pick(['lol', 'yep', 'ok', 'sure', 'nice']), pick(on).name)); return; }
  if (v.startsWith('!!')) { if (!S.party.length) { sys('You are not in a group.'); return; } chat('party', v.slice(2).trim(), P.name); setTimeoutGame(1.5 + R() * 3, () => { if (S.party.length) chat('party', replyFor(v) || pick(['ok', 'kk', 'on it', 'sure']), pick(S.party).name); }); return; }
  if (v.startsWith('!')) { chat('shout', v.slice(1).trim(), P.name); if (R() < .4) setTimeoutGame(3 + R() * 6, () => chat('shout', replyFor(v) || pick(['lol', 'who cares', 'pm me', 'same', '^^']), pick(BOT_NAMES))); return; }
  if (v.startsWith('/')) { const sp = v.indexOf(' '); const to = sp > 0 ? v.slice(1, sp) : v.slice(1); const msg = sp > 0 ? v.slice(sp + 1) : ''; if (!msg) return; chat('whisperTo', msg, to); if (R() < .75) setTimeoutGame(2 + R() * 5, () => whisperFrom(to, replyFor(msg) || pick(['?', 'hi', 'busy atm', 'sure', 'lol', 'what?']))); return; }
  chat('say', v, P.name); say(p, v);
  const near = S.ents.filter(e => e.kind === 'bot' && !e.dead && cheb(e.x, e.y, p.x, p.y) < 10);
  if (near.length && R() < .7) { const b = pick(near); setTimeoutGame(1.5 + R() * 3, () => { if (!b.dead) botSay(b, replyFor(v) || pick(['?', 'lol', 'hi', 'ok', 'huh'])); }); }
}
function replyFor(v) { const l = v.toLowerCase(); for (const k in REPLIES) if (l.includes(k)) return pick(REPLIES[k]); return null; }
chatin.addEventListener('keydown', e => { e.stopPropagation(); if (e.key === 'Enter') sendChat(); if (e.key === 'Escape') { chatin.value = ''; chatin.classList.remove('on'); chatin.blur(); updCh(); } });
chatin.addEventListener('input', updCh);

/* ---------- title / creation helpers (markup lives in js7) ---------- */
new MutationObserver(() => { const gm = document.getElementById('gm'), gf = document.getElementById('gf'); if (gm && gf && !gm.classList.contains('sel') && !gf.classList.contains('sel')) gm.classList.add('sel'); }).observe($('#ov'), { childList: true });
document.addEventListener('click', e => { const t = e.target.closest && e.target.closest('#gm,#gf'); if (!t) return; for (const b of document.querySelectorAll('#gm,#gf')) b.classList.toggle('sel', b === t); });

/* ---------- canvas input ---------- */
function mousePos(e) { const r = cv.getBoundingClientRect(); S.mouse.x = e.clientX - r.left; S.mouse.y = e.clientY - r.top; }
cv.addEventListener('pointermove', e => { mousePos(e); });
cv.addEventListener('pointerdown', e => {
  au(); if (AU.ctx && AU.ctx.state === 'suspended') AU.ctx.resume();
  if (document.activeElement === chatin && !chatin.value) chatin.blur();
  if (!S.running || S.dead) return; mousePos(e); const h = pickHover(); S.hover = h; const p = S.player;
  cv.setPointerCapture && cv.setPointerCapture(e.pointerId);
  S.mouse.down = true; S.mouse.mode = 'none';
  if (e.button === 2 || e.button === 1) { p.target = null; p.talkTo = null; S.mouse.mode = 'move'; p.dest = null; return; }
  if (h && h.kind === 'npc') { p.talkTo = h; p.target = null; p.path = findPath(p, h.x, h.y, 1); return; }
  if (h && h.kind === 'bot' && !isEnemy(p, h)) { showCtx(h, e.clientX, e.clientY); return; }
  if (h && (isEnemy(p, h) || h.kind === 'mon')) { p.target = h; p.talkTo = null; p.path = null; p.pathT = 0; return; }
  const d = S.drops.find(d2 => d2.x === S.mouse.tx && d2.y === S.mouse.ty);
  if (d) { p.target = null; p.talkTo = null; p.path = findPath(p, d.x, d.y, 0); return; }
  p.target = null; p.talkTo = null; p.pending = null; S.mouse.mode = 'move'; p.dest = null; S.forcePK = null;
  if (!inb(S.map, S.mouse.tx, S.mouse.ty)) return;
  fx('ring', S.mouse.tx * TW + 24, S.mouse.ty * TH + 18, { dur: .35, col: '227,194,127', r: 14, r0: 4, w: 2, below: 1 });
});
window.addEventListener('pointerup', () => { S.mouse.down = false; S.mouse.mode = 'none'; });
window.addEventListener('keydown', e => {
  if (!S.running) return;
  if (e.key === 'Control') S.ctrlHeld = true;
  if (document.activeElement && document.activeElement.tagName === 'INPUT') return;
  const k = e.key;
  if (/^F[1-8]$/.test(k)) { e.preventDefault(); const sk = S.P.keys[+k.slice(1) - 1]; if (sk) castSkill(sk); return; }
  if (k >= '1' && k <= '8') { const sk = S.P.keys[+k - 1]; if (sk) castSkill(sk); return; }
  const lk = k.toLowerCase();
  if (lk.length === 1 && 'wasd'.includes(lk) && !e.ctrlKey && !e.metaKey) { e.preventDefault(); S.keys = S.keys || {}; S.keys[lk] = true; return; }
  if (lk === 'q' && !e.ctrlKey) { quaff('hp'); return; }
  if (lk === 'e' && !e.ctrlKey) { quaff('mp'); return; }
  if (k === ' ') { e.preventDefault(); const p = S.player; if (!p.target || p.target.dead) { let best = null, bd = 99; for (const m of S.ents) if (m.kind === 'mon' && !m.dead) { const d = cheb(m.x, m.y, p.x, p.y); if (d < bd) { bd = d; best = m; } } if (best && bd < 10) p.target = best; } return; }
  if (k === 'Enter') { e.preventDefault(); openChat(); return; }
  if (k === 'Escape') { if (ctxEl.style.display === 'block') { ctxEl.style.display = 'none'; return; } const ids = Object.keys(UI.wins); if (ids.length) { let top = null, z = -1; for (const id of ids) { const zz = +UI.wins[id].el.style.zIndex; if (zz > z) { z = zz; top = id; } } closeWin(top); } else openWin('opts'); return; }
  if (k === 'Tab') { e.preventDefault(); const p = S.player; let best = null, bd = 99; for (const m of S.ents) if (m.kind === 'mon' && !m.dead && m !== p.target) { const d = cheb(m.x, m.y, p.x, p.y); if (d < bd) { bd = d; best = m; } } if (best && bd < 12) p.target = best; return; }
  if (e.ctrlKey || e.metaKey || e.altKey) return;
  const map = { c: 'char', i: 'inv', b: 'inv', k: 'skills', j: 'quest', l: 'quest', g: 'guild', m: 'map', o: 'opts' };
  if (map[k.toLowerCase()]) { toggleWin(map[k.toLowerCase()]); return; }
  if (k.toLowerCase() === 'r') { useMythic(); return; }
  if (k.toLowerCase() === 't') { if (S.player.st.special.teleport) { if ((S.P.tpCd || 0) > 0) { sys('The ring is recharging.'); return; } S.P.tpCd = 10; randomTeleport(); } return; }
  if (k.toLowerCase() === 'h') showHelp();
});
window.addEventListener('keyup', e => { if (e.key === 'Control') S.ctrlHeld = false; const lk = e.key.toLowerCase(); if (S.keys && lk.length === 1 && 'wasd'.includes(lk)) S.keys[lk] = false; });
window.addEventListener('blur', () => { S.ctrlHeld = false; S.mouse.down = false; S.keys = {}; });
