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
  <canvas id="tcv" width="1040" height="300" style="width:min(520px,100%);height:auto"></canvas>
  <h1 class="title">Ashvale Online</h1><div class="tagline">A single-player MMORPG</div>
  <div class="panel frame">
    <div class="small muted" style="letter-spacing:.12em;text-transform:uppercase;margin-bottom:6px">Server</div>
    <div class="server"><span>Ashvale-1</span><span class="busy">Busy, ${fmt(S.online)} online</span></div>
    <div class="server" style="opacity:.5"><span>Varn PvP</span><span>Full</span></div>
    <div class="small muted" style="letter-spacing:.12em;text-transform:uppercase;margin:14px 0 6px">Character</div>
    ${save ? `<div class="server" style="align-items:center"><span><b style="font-family:var(--display);font-weight:400;font-size:17px;color:var(--bronze-hi)">${esc(save.name)}</b> <span class="muted">Level ${save.lv} ${CLASSES[save.cls].name}${save.guild ? ', ' + esc(save.guild.name) : ''}</span></span><button class="btn gold" id="enter" style="padding:6px 18px;font-size:14px">Enter world</button></div>
    <div class="small muted" style="margin-top:8px">${UI.cloud ? 'Saved to your account.' : 'Saved in this browser.'} <a href="#" id="loadfile" class="lnkfile">Load a character from a file</a></div>` : `<button class="btn gold" id="create" style="padding:8px 22px;font-size:14px;width:100%">Create character</button>
    <div class="small muted" style="margin-top:8px;text-align:center">Have a save file? <a href="#" id="loadfile" class="lnkfile">Load a character from a file</a></div>`}
  </div></div>`;
  const tc = $('#tcv').getContext('2d');
  // three heroes in their best gear, drawn with the real sprites (code-drawn figures until they load)
  const heroes = [
    { e: STAGE.hero({ cls: 'W', name: 'Title W', variant: 'plate_gold', weapon: 'dragonblade', helm: { k: 'dragon' }, cape: '#7a1414', glow: '#ff5a1a', dir: 3 }), x: 170, pose: 'attack', every: 6.5 },
    { e: STAGE.hero({ cls: 'M', name: 'Title M', variant: 'robe_arcane', weapon: 'crystalstaff', hair: '#e8e8e8', head: 'mage', cape: '#120f38', dir: 4 }), x: 260, pose: 'cast', every: 5.2 },
    { e: STAGE.hero({ cls: 'T', name: 'Title T', variant: 'tao_spirit', weapon: 'bough', fem: true, hair: '#6a3a1a', head: 'rogue', dir: 5 }), x: 350, pose: 'raise', every: 7.4 },
  ];
  const oldLook = [
    { dir: 3, armor: { c: '#7a2020', t: '#ffcc55' }, plate: 1, helm: { c: '#c9a040', k: 'horned' }, weapon: { k: 'blade', c: '#ff7a3c', glow: '#ff5a1a' }, hair: '#2a1a0a' },
    { dir: 4, armor: { c: '#1d1b52', t: '#ffcc55', robe: 1 }, weapon: { k: 'staff', c: '#ffd257', glow: '#ffb020' }, hair: '#e8e8e8', fem: 1 },
    { dir: 5, armor: { c: '#e8e2d0', t: '#3fae6a', robe: 1 }, weapon: { k: 'blade', c: '#ffe07a', glow: '#ffc030' }, hair: '#6a3a1a' }];
  const drawT = () => { if (ov.hidden || !$('#tcv')) return; tc.clearRect(0, 0, 1040, 300); tc.save(); tc.scale(2, 2);
    const t = performance.now() / 1000;
    heroes.forEach((h, i) => {
      const y = 128 + (i === 1 ? 4 : 0); STAGE.floor(tc, h.x, y, 46);
      const pt = (t + i * 1.7) % h.every; STAGE.pose(h.e, pt < .6 ? h.pose : 'idle', pt < .6 ? pt : t + i);
      if (!STAGE.draw(tc, h.e, h.x, y, 1.45)) drawHuman(tc, h.x, y, Object.assign({ walk: 0, idle: t + i, atk: -1, cast: -1, size: 1.35 }, oldLook[i]));
    });
    tc.restore(); requestAnimationFrame(drawT); };
  drawT();
  if ($('#loadfile')) $('#loadfile').onclick = ev => { ev.preventDefault(); SAVEFILE.pick(P => showTitle(P)); };
  if (save) $('#enter').onclick = () => { au(); startGame(save); };
  else $('#create').onclick = () => showCreate();
}
function showCreate() {
  const ov = $('#ov');
  const st = { cls: 'W', fem: false, head: 'knight', hair: '#3a2414', skin: '#e0b48a' };
  const hairs = ['#1a1414', '#3a2414', '#6a3a1a', '#a0522d', '#c8903a', '#e0c070', '#e8e8e8', '#7a2a2a', '#3a4a8a', '#5a3a7a'];
  const skins = ['#f0c8a0', '#e0b48a', '#c8966a', '#a8764a', '#7a5234'];
  const HEADS = { m: [['knight', 'Short hair'], ['barbarian', 'Shaved & bearded'], ['mage', 'Sage']], f: [['rogue', 'Bob']] };
  ov.innerHTML = `<div class="panel frame create">
  <h2 style="font-family:var(--display);font-weight:400;color:var(--bronze-hi);margin:0 0 4px;font-size:26px">Create your hero</h2><div class="small muted">Choose carefully. Your class decides how you fight for the rest of your life in Ashvale.</div>
  <div class="cgrid">
    <div class="stagebox"><canvas id="stagecv" width="640" height="760"></canvas><div class="turnhint">Drag to turn</div></div>
    <div class="cform">
      <div class="classes">${Object.entries(CLASSES).map(([k, c]) => `<div class="cls ${k === st.cls ? 'sel' : ''}" data-c="${k}" role="button" tabindex="0"><canvas width="120" height="130" style="width:60px;height:65px"></canvas><b style="color:${c.color}">${c.name}</b><p>${c.blurb}</p></div>`).join('')}</div>
      <div class="crow"><div class="small muted">Body</div><div class="chips" id="bodychips"><button class="btn chip sel" data-f="0">Male</button><button class="btn chip" data-f="1">Female</button></div></div>
      <div class="crow"><div class="small muted">Look</div><div class="chips" id="headchips"></div></div>
      <div class="crow"><div class="small muted">Hair</div><div class="swatches" id="hairsw">${hairs.map(h => `<i data-h="${h}" style="background:${h}" class="${h === st.hair ? 'sel' : ''}"></i>`).join('')}</div></div>
      <div class="crow"><div class="small muted">Skin</div><div class="swatches" id="skinsw">${skins.map(h => `<i data-s="${h}" style="background:${h}" class="${h === st.skin ? 'sel' : ''}"></i>`).join('')}</div></div>
      <div class="crow"><label class="small muted" for="cname">Name</label><input class="txt" id="cname" maxlength="14" placeholder="Your name" autocomplete="off"></div>
      <div class="row" style="margin-top:14px"><button class="btn" id="back" style="padding:7px 16px">Back</button><span class="small" id="cerr" style="color:#ff7a6a"></span><button class="btn gold" id="go" style="padding:8px 22px;font-size:14px">Enter Ashvale</button></div>
    </div>
  </div></div>`;
  const cards = ov.querySelectorAll('.cls'), scv = $('#stagecv'), sc = scv.getContext('2d');
  const heroOf = (cls, dir) => STAGE.hero({ cls, fem: st.fem, head: st.head, hair: st.hair, skin: st.skin, dir, name: 'Stage' + cls });
  let hero = heroOf(st.cls, 4);
  const refresh = () => { hero = heroOf(st.cls, hero.dir); STAGE.preload(st.cls); };
  const headChips = () => {
    const list = HEADS[st.fem ? 'f' : 'm']; if (!list.some(h => h[0] === st.head)) st.head = list[0][0];
    $('#headchips').innerHTML = list.map(([k, n]) => `<button class="btn chip ${k === st.head ? 'sel' : ''}" data-h="${k}">${n}</button>`).join('');
    $('#headchips').querySelectorAll('.chip').forEach(b => b.onclick = () => { st.head = b.dataset.h; headChips(); refresh(); sfx('click'); });
  };
  headChips(); ['W', 'M', 'T'].forEach(STAGE.preload);
  // the turntable: turns on its own, or follows the mouse while dragged
  let drag = null, lastDrag = -9, raf, poseT = 0;
  scv.addEventListener('pointerdown', e => { drag = { x: e.clientX, dir: hero.dir }; scv.setPointerCapture(e.pointerId); });
  scv.addEventListener('pointermove', e => { if (!drag) return; hero.dir = ((drag.dir - Math.round((e.clientX - drag.x) / 28)) % 8 + 8) % 8; lastDrag = performance.now() / 1000; });
  scv.addEventListener('pointerup', () => { drag = null; });
  const POSE = { W: 'attack', M: 'cast', T: 'raise' };
  const draw = () => {
    if (!document.body.contains(scv)) return; const t = performance.now() / 1000;
    sc.clearRect(0, 0, 640, 760); sc.save(); sc.scale(2, 2);
    const glow = sc.createRadialGradient(160, 190, 10, 160, 190, 190); glow.addColorStop(0, 'rgba(255,190,110,.14)'); glow.addColorStop(1, 'rgba(0,0,0,0)'); sc.fillStyle = glow; sc.fillRect(0, 0, 320, 380);
    STAGE.floor(sc, 160, 318, 120);
    if (!drag && t - lastDrag > 3) hero.dir = (4 + Math.floor((t - lastDrag) / 1.3)) % 8;
    const pt = t % 6.5; STAGE.pose(hero, pt < .6 ? POSE[st.cls] : 'idle', pt < .6 ? pt : t);
    if (!STAGE.draw(sc, hero, 160, 318, 3.1)) drawHuman(sc, 160, 318, { dir: hero.dir, walk: 0, idle: t, atk: -1, cast: -1, hair: st.hair, fem: st.fem, skin: st.skin, armor: { c: '#7a5b3a', t: '#a07a4a' }, size: 3.2 });
    sc.restore();
    cards.forEach(cd => { const c = cd.querySelector('canvas').getContext('2d'), k = cd.dataset.c; c.clearRect(0, 0, 120, 130);
      const e = cd._e || (cd._e = heroOf(k, 4)); STAGE.pose(e, 'idle', t + k.charCodeAt(0));
      if (!STAGE.draw(c, e, 60, 118, 1.25)) { c.save(); c.scale(1.65, 1.65); drawHuman(c, 36, 72, { dir: 4, walk: 0, idle: t, atk: -1, cast: -1, hair: st.hair, fem: st.fem, skin: st.skin, armor: { c: '#7a5b3a', t: '#a07a4a' } }); c.restore(); } });
    raf = requestAnimationFrame(draw);
  };
  draw();
  const pickCard = cd => { st.cls = cd.dataset.c; cards.forEach(c2 => c2.classList.toggle('sel', c2 === cd)); refresh(); sfx('click'); };
  cards.forEach(cd => { cd.onclick = () => pickCard(cd); cd.onkeydown = e => { if (e.key === 'Enter' || e.key === ' ') pickCard(cd); }; });
  $('#bodychips').querySelectorAll('.chip').forEach(b => b.onclick = () => { st.fem = b.dataset.f === '1'; $('#bodychips').querySelectorAll('.chip').forEach(x => x.classList.toggle('sel', x === b)); headChips(); cards.forEach(c => c._e = null); refresh(); sfx('click'); });
  $('#hairsw').querySelectorAll('i').forEach(s => s.onclick = () => { st.hair = s.dataset.h; $('#hairsw').querySelectorAll('i').forEach(x => x.classList.toggle('sel', x === s)); cards.forEach(c => c._e = null); refresh(); });
  $('#skinsw').querySelectorAll('i').forEach(s => s.onclick = () => { st.skin = s.dataset.s; $('#skinsw').querySelectorAll('i').forEach(x => x.classList.toggle('sel', x === s)); cards.forEach(c => c._e = null); refresh(); });
  $('#back').onclick = () => { cancelAnimationFrame(raf); showTitle(null); };
  const go = () => { const n = $('#cname').value.trim().replace(/[^A-Za-z0-9_]/g, ''); if (n.length < 3) { $('#cerr').textContent = 'Names need 3 to 14 letters or numbers.'; return; } if (BOT_NAMES.includes(n)) { $('#cerr').textContent = 'That name is taken on this server.'; return; }
    cancelAnimationFrame(raf); au();
    const P = newProfile(n, st.cls, st.fem, st.hair); P.head = st.head; P.skin = st.skin;   // appearance: see CHANGELOG [need] G.newCharacter({head, skin})
    startGame(P); };
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

