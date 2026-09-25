/* ================= SESSION START, TITLE & CREATION, MAIN LOOP, BOOT ================= */
function startGame(P) {
  S.P = P; P.inv = (P.inv || []).concat(Array(40).fill(null)).slice(0, 40); P.storage = (P.storage || []).concat(Array(40).fill(null)).slice(0, 40);
  P.visited = P.visited || { ashvale: 1 }; P.toggles = P.toggles || {}; P.keys = P.keys || Array(8).fill(null);
  S.bossNext = P.bossNext || {}; S.castle = P.castle || null; AU.on = P.sound !== false; loadAudioPrefs(P);
  for (const k in P.skills) P.skills[k].cd = 0;
  $('#ov').hidden = true; S.running = true; S.dead = false; S.player = null; S.party = []; S.pet = null; CHAT.length = 0;
  let map = P.map || 'ashvale'; const m = getMap(map); let x = P.x, y = P.y;
  if (!inb(m, x, y) || m.b[idx(m, x, y)] || !m.reach[idx(m, x, y)]) { x = m.start.x; y = m.start.y; }
  resize(); UI.firstMap = true;
  changeMap(map, x, y);
  sys(`Welcome to Ashvale Online, ${P.name}.`);
  if (!P.intro) { P.intro = 1; setTimeoutGame(1.2, () => { sys('Speak to Elder Rowan by the fountain for your first task. Press H for controls.'); UI.toast('Ashvale Province'); }); }
  chat('shout', pick(['welcome newbie!', 'hi ' + P.name, 'another one lol', 'gl hf']), pick(BOT_NAMES));
  saveGame();
}

/* ================= TITLE & CREATION ================= */
function showTitle(save) {
  const ov = $('#ov'); ov.hidden = false; ov.style.background = '';
  save = save || localLoad();
  ov.innerHTML = `<div style="display:flex;flex-direction:column;align-items:center;padding-block:28px;width:100%">
  <canvas id="tcv" width="1040" height="220" style="width:min(520px,100%);height:auto"></canvas>
  <h1 class="title">Ashvale Online</h1><div class="tagline">A single-player MMORPG</div>
  <div class="panel frame">
    <div class="small muted" style="letter-spacing:.12em;text-transform:uppercase;margin-bottom:6px">Server</div>
    <div class="server"><span>Ashvale-1</span><span class="busy">Busy, ${fmt(S.online)} online</span></div>
    <div class="server" style="opacity:.5"><span>Varn PvP</span><span>Full</span></div>
    <div class="small muted" style="letter-spacing:.12em;text-transform:uppercase;margin:14px 0 6px">Character</div>
    ${save ? `<div class="server" style="align-items:center"><span><b style="font-family:var(--display);font-weight:400;font-size:17px;color:var(--bronze-hi)">${esc(save.name)}</b> <span class="muted">Level ${save.lv} ${CLASSES[save.cls].name}${save.guild ? ', ' + esc(save.guild.name) : ''}</span></span><button class="btn gold" id="enter" style="padding:6px 18px;font-size:14px">Enter world</button></div>
    <div class="small muted" style="margin-top:8px">${UI.cloud ? 'Saved to your account.' : 'Saved in this browser.'}</div>` : `<button class="btn gold" id="create" style="padding:8px 22px;font-size:14px;width:100%">Create character</button>`}
  </div></div>`;
  const tc = $('#tcv').getContext('2d');
  const drawT = () => { if (ov.hidden || !$('#tcv')) return; tc.clearRect(0, 0, 1040, 220); tc.save(); tc.scale(2, 2);
    const t = performance.now() / 1000;
    drawHuman(tc, 170, 100, { dir: 3, walk: 0, idle: t, atk: -1, cast: -1, armor: { c: '#7a2020', t: '#ffcc55' }, plate: 1, helm: { c: '#c9a040', k: 'horned' }, weapon: { k: 'blade', c: '#ff7a3c', glow: '#ff5a1a' }, hair: '#2a1a0a', size: 1.35 });
    drawHuman(tc, 260, 104, { dir: 4, walk: 0, idle: t + 1, atk: -1, cast: Math.sin(t) > .6 ? (t % 1) : -1, armor: { c: '#1d1b52', t: '#ffcc55', robe: 1 }, weapon: { k: 'staff', c: '#ffd257', glow: '#ffb020' }, hair: '#e8e8e8', fem: 1, size: 1.35 });
    drawHuman(tc, 350, 100, { dir: 5, walk: 0, idle: t + 2, atk: -1, cast: -1, armor: { c: '#e8e2d0', t: '#3fae6a', robe: 1 }, weapon: { k: 'blade', c: '#ffe07a', glow: '#ffc030' }, hair: '#6a3a1a', size: 1.35 });
    tc.restore(); requestAnimationFrame(drawT); };
  drawT();
  if (save) $('#enter').onclick = () => { au(); startGame(save); };
  else $('#create').onclick = () => showCreate();
}
function showCreate() {
  const ov = $('#ov'); let cls = 'W', fem = false, hair = '#2a1a0a';
  const hairs = ['#2a1a0a', '#6a3a1a', '#d8b060', '#1a1a1a', '#a02a1a', '#e8e8e8', '#4a2a6a'];
  ov.innerHTML = `<div class="panel frame" style="margin-top:0;width:min(640px,100%)">
  <h2 style="font-family:var(--display);font-weight:400;color:var(--bronze-hi);margin:0 0 4px;font-size:26px">Create your hero</h2><div class="small muted">Choose carefully. Your class decides how you fight for the rest of your life in Ashvale.</div>
  <div class="classes">${Object.entries(CLASSES).map(([k, c]) => `<div class="cls ${k === cls ? 'sel' : ''}" data-c="${k}" role="button" tabindex="0"><canvas width="160" height="170" style="width:80px;height:85px"></canvas><b style="color:${c.color}">${c.name}</b><p>${c.blurb}</p></div>`).join('')}</div>
  <div class="row" style="flex-wrap:wrap;gap:12px"><div style="flex:1;min-width:200px"><label class="small muted" for="cname">Name</label><input class="txt" id="cname" maxlength="14" placeholder="Your name" autocomplete="off"></div>
  <div><div class="small muted">Body</div><div style="display:flex;gap:4px"><button class="btn" id="gm" style="padding:5px 10px">Male</button><button class="btn" id="gf" style="padding:5px 10px">Female</button></div></div>
  <div><div class="small muted">Hair</div><div class="swatches">${hairs.map(h => `<i data-h="${h}" style="background:${h}" class="${h === hair ? 'sel' : ''}"></i>`).join('')}</div></div></div>
  <div class="row" style="margin-top:14px"><button class="btn" id="back" style="padding:7px 16px">Back</button><span class="small" id="cerr" style="color:#ff7a6a"></span><button class="btn gold" id="go" style="padding:8px 22px;font-size:14px">Enter Ashvale</button></div></div>`;
  const cards = ov.querySelectorAll('.cls');
  const look = k => ({ W: { armor: { c: '#7a5b3a', t: '#a07a4a' }, weapon: { k: 'sword', c: '#c7ccd2' } }, M: { armor: { c: '#3b3f8a', t: '#c9a6ff', robe: 1 }, weapon: { k: 'wand', c: '#7a5ad0' } }, T: { armor: { c: '#2f6a4a', t: '#e4d7a0', robe: 1 }, weapon: { k: 'sword', c: '#6fbf73' } } }[k]);
  let raf;
  const draw = () => { if (!document.body.contains(cards[0])) return; const t = performance.now() / 1000; cards.forEach(cd => { const c = cd.querySelector('canvas').getContext('2d'); c.clearRect(0, 0, 160, 170); c.save(); c.scale(2.2, 2.2); const k = cd.dataset.c; drawHuman(c, 36, 72, Object.assign(look(k), { dir: 4, walk: t * 1.2 % 1, moving: k === cls, idle: t, atk: k === cls && (t % 2.4) < .6 ? (t % 2.4) / .6 : -1, cast: -1, hair, fem, skin: '#e0b48a' })); c.restore(); }); raf = requestAnimationFrame(draw); };
  draw();
  cards.forEach(cd => cd.onclick = () => { cls = cd.dataset.c; cards.forEach(c2 => c2.classList.toggle('sel', c2 === cd)); sfx('click'); });
  ov.querySelectorAll('.swatches i').forEach(s => s.onclick = () => { hair = s.dataset.h; ov.querySelectorAll('.swatches i').forEach(x => x.classList.toggle('sel', x === s)); });
  $('#gm').onclick = () => { fem = false; }; $('#gf').onclick = () => { fem = true; };
  $('#back').onclick = () => { cancelAnimationFrame(raf); showTitle(null); };
  const go = () => { const n = $('#cname').value.trim().replace(/[^A-Za-z0-9_]/g, ''); if (n.length < 3) { $('#cerr').textContent = 'Names need 3 to 14 letters or numbers.'; return; } if (BOT_NAMES.includes(n)) { $('#cerr').textContent = 'That name is taken on this server.'; return; } cancelAnimationFrame(raf); au(); startGame(newProfile(n, cls, fem, hair)); };
  $('#go').onclick = go; $('#cname').addEventListener('keydown', e => { e.stopPropagation(); if (e.key === 'Enter') go(); });
  setTimeout(() => $('#cname') && $('#cname').focus(), 50);
}

/* ================= MAIN LOOP ================= */
let lastT = performance.now(), saveT = 0;
function frame(now) {
  const dt = Math.min(.05, (now - lastT) / 1000); lastT = now;
  try { audioTick(dt); } catch (e) { }
  if (S.running && S.player) {
    S.ctrl = !!(S.ctrlHeld || S.pkMode);
    try {
      if (!S.dead) S.P.playT = (S.P.playT || 0) + dt;
      update(dt * VIEW.timeScale(dt));
      S.hover = pickHover();
      cv.className = S.hover ? (S.hover.kind === 'npc' ? 'talk' : isEnemy(S.player, S.hover) || S.hover.kind === 'mon' ? 'atk' : '') : '';
      render(); UI.hudTick(dt);
    } catch (err) { console.error(err); }
    saveT += dt; if (saveT > 20) { saveT = 0; saveGame(); }
  }
  requestAnimationFrame(frame);
}
document.addEventListener('visibilitychange', () => { if (document.hidden && S.running) { saveGame(); if (CLOUD.db && CLOUD.uid && S.P) CLOUD.db.doc('data/users/' + CLOUD.uid + '/save').set({ json: serialize(), ts: Date.now() }).catch(() => { }); } });
window.addEventListener('pagehide', () => { if (S.running) saveGame(); });

function boot(data) {
  buildBars(); resize();
  if (data && data.save) { try { startGame(JSON.parse(data.save)); } catch (e) { showTitle(null); } }
  else showTitle(null);
  requestAnimationFrame(frame);
  cloudInit();
}
try { if (window.claude && window.claude.hot && window.claude.hot.snapshot) window.claude.hot.snapshot(() => ({ save: S.running ? serialize() : null })); } catch (e) { }
if (window.claude && window.claude.hot && window.claude.hot.ready) window.claude.hot.ready(boot); else boot(window.claude && window.claude.hot && window.claude.hot.data || {});

