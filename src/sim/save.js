/* ================= SAVE / LOAD ================= */
const SAVE_KEY = 'ashvale_online_v1';
const CLOUD = { db: null, uid: null, ready: false };
function serialize() {
  const P = S.P, p = S.player; if (!P) return null;
  if (p) { P.hp = Math.round(p.hp); P.mp = Math.round(p.mp); P.x = p.x; P.y = p.y; P.map = S.map.id; }
  P.bossNext = S.bossNext; P.castle = S.castle; P.ts = Date.now(); P.sound = AU.on; saveAudioPrefs(P);
  return JSON.stringify(P);
}
function localLoad() { try { const s = localStorage.getItem(SAVE_KEY); return s ? JSON.parse(s) : null; } catch (e) { return null; } }
function saveGame(manual) {
  if (!S.P || S.dead) return; const j = serialize(); if (!j) return;
  try { localStorage.setItem(SAVE_KEY, j); } catch (e) { }
  UI.lastSave = Date.now();
  if (CLOUD.db && CLOUD.uid && (manual || !UI.lastCloud || Date.now() - UI.lastCloud > 45000)) {
    UI.lastCloud = Date.now();
    CLOUD.db.doc('data/users/' + CLOUD.uid + '/save').set({ json: j, ts: Date.now() }).catch(() => { });
  }
  if (manual) sys('Game saved.');
}
function deleteSave() {
  try { localStorage.removeItem(SAVE_KEY); } catch (e) { }
  if (CLOUD.db && CLOUD.uid) CLOUD.db.doc('data/users/' + CLOUD.uid + '/save').delete().catch(() => { });
  S.running = false; S.P = null; S.player = null; for (const id of Object.keys(UI.wins)) closeWin(id); showTitle(null);
}
async function cloudInit() {
  try {
    if (!window.claude || !window.claude.use) return;
    const [db, user] = await Promise.all([window.claude.use('db'), window.claude.use('user')]);
    if (!db || !user) return; const uid = await user.id(); if (!uid) return;
    CLOUD.db = db; CLOUD.uid = uid; UI.cloud = true;
    const snap = await db.doc('data/users/' + uid + '/save').get();
    const data = snap && snap.exists ? (typeof snap.data === 'function' ? snap.data() : snap.data) : null;
    if (data && data.json) { const cloudP = JSON.parse(data.json); const loc = localLoad(); if (!loc || (cloudP.ts || 0) > (loc.ts || 0)) { try { localStorage.setItem(SAVE_KEY, data.json); } catch (e) { } if (!S.running) showTitle(cloudP); } }
  } catch (e) { }
}

/* ================= NEW CHARACTER ================= */
function newProfile(name, cls, fem, hair) {
  const P = { v: 1, name, cls, fem, hair, skin: '#e0b48a', lv: 1, xp: 0, gold: 150, inv: Array(40).fill(null), equip: {}, skills: {}, keys: Array(8).fill(null), belt: ['hp_s', 'mp_s', 'hp_m', 'mp_m', 'sun_potion', 'town_scroll'], storage: Array(40).fill(null), toggles: {}, q: 0, qn: 0, qa: false, map: 'ashvale', x: 76, y: 63, hp: 0, mp: 0, visited: { ashvale: 1 }, pk: 0, guild: null, kills: 0, playT: 0, bossNext: {}, ts: Date.now(), created: Date.now() };
  P.equip.weapon = { id: cls === 'W' ? 'wooden_sword' : cls === 'M' ? 'wooden_sword' : 'wooden_sword', u: '1' };
  P.equip.armour = { id: 'light_armour', u: '2' };
  P.inv[0] = { id: 'hp_s', n: 8, u: '3' }; P.inv[1] = { id: 'mp_s', n: 6, u: '4' }; P.inv[2] = { id: 'town_scroll', n: 1, u: '5' };
  const first = { W: 'fencing', M: 'fireball', T: 'healing' }[cls]; P.skills[first] = { rank: 0, pts: 0, cd: 0 };
  if (cls !== 'W') P.keys[0] = first;
  return P;
}
