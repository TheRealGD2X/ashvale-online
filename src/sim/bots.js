/* ================= BOT LIFE (realistic fake players) — overrides & extensions =================
   Loaded after js4_game.js, before js5/js6/js7 (all in one script tag).
   Overrides by declaration: populateBots, spawnFieldBot, worldTick.
   Wrapped by assignment: makeBot, botAI, botSay, whisperFrom, chat, killEnt, botLeave, dropItem,
   inviteBot, joinParty, leaveParty, and (guarded, runtime only) js6's replyFor / showCtx.
   Globals exposed: openTrade(bot), botTradeUI(bot, offer), BOTLIFE (debug handle).
*/
const BOTMAX = 20;
const BL = {
  recent: [], hush: {}, own: 0, force: 0, pend: {}, pers: {}, gid: 1, night: null, seenRed: new Set(), greeted: new Set(),
  t: { sec: 1, shout: 6, say: 9, ping: 30, pop: 4, pk: 25, guild: 30, party: 40, grp: 5 },
  nextPing: 70,
};

/* ---------- small utils ---------- */
function blAlive(b) { return !!b && !b.dead && !b.gone && S.ents.indexOf(b) >= 0; }
function blNear(e, r) { const p = S.player; return !!p && !!e && cheb(e.x, e.y, p.x, p.y) <= r; }
function blBots(f) { const out = []; for (const e of S.ents) if (e.kind === 'bot' && !e.dead && !e.gone && (!f || f(e))) out.push(e); return out; }
function blBotCount() { let n = 0; for (const e of S.ents) if (e.kind === 'bot' && !e.dead) n++; return n; }
function blLoad(w, ch) { while (BL.recent.length && BL.recent[0][0] < S.time - 90) BL.recent.shift(); const t0 = S.time - (w || 12); let n = 0; for (let i = BL.recent.length - 1; i >= 0 && BL.recent[i][0] > t0; i--) if (!ch || BL.recent[i][1] === ch) n++; return n; }
function blQuiet(max, w, ch) { return blLoad(w || 12, ch) < (max || 3); }
function pickW(list) { let t = 0; for (const x of list) t += x[1]; let r = R() * t; for (const x of list) { r -= x[1]; if (r <= 0) return x[0]; } return list[0][0]; }
function blShuffle(a) { for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(R() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; }
function blFreeName() { const used = usedNames(); const c = BOT_NAMES.filter(n => !used.has(n) && (!S.P || n !== S.P.name)); return c.length ? pick(c) : pick(BOT_NAMES); }
function blBotByName(n) { if (!n) return null; const l = String(n).toLowerCase(); return S.ents.find(e => e.kind === 'bot' && !e.dead && !e.gone && e.name.toLowerCase() === l) || null; }
function fmtK(n) { n = Math.round(n); if (n >= 1e6) return (n / 1e6).toFixed(n >= 1e7 ? 0 : 1).replace(/\.0$/, '') + 'm'; if (n >= 1000) return (n / 1000).toFixed(n >= 10000 ? 0 : 1).replace(/\.0$/, '') + 'k'; return String(n); }
function blRound(n) { if (n >= 10000) return Math.round(n / 500) * 500; if (n >= 1000) return Math.round(n / 50) * 50; if (n >= 100) return Math.round(n / 10) * 10; return Math.max(1, Math.round(n)); }
function blNpc(id) { return S.ents.find(e => e.kind === 'npc' && e.def && e.def.id === id) || null; }
function blFace(e, t) { if (!t) return; const d = dirTo(e.x, e.y, t.x, t.y); e.dir = d; if (DX[d]) e.faceL = DX[d] < 0; }
function blCurve() { const h = typeof dayPhase === 'function' && S.P ? dayPhase().hour : 20; return .5 + .5 * Math.cos((h - 21.5) / 24 * Math.PI * 2); }

/* ---------- personalities & MMO typing ---------- */
const BL_ABBR = [[/\byou\b/gi, 'u'], [/\byour\b/gi, 'ur'], [/\bare\b/gi, 'r'], [/\bplease\b/gi, 'pls'], [/\bthanks\b/gi, 'thx'], [/\bpeople\b/gi, 'ppl'], [/\banyone\b/gi, 'any1'], [/\blevel\b/gi, 'lvl'], [/\bgroup\b/gi, 'grp'], [/\bbecause\b/gi, 'cuz'], [/\bright now\b/gi, 'rn'], [/\bwant to\b/gi, 'wanna'], [/\bgoing to\b/gi, 'gonna'], [/\bi don'?t know\b/gi, 'idk'], [/\bto be honest\b/gi, 'tbh'], [/\bokay\b/gi, 'ok'], [/\bthough\b/gi, 'tho'], [/\bsomeone\b/gi, 'some1']];
function blPers(name) {
  name = name || '?'; let p = BL.pers[name];
  if (!p) { const st = pick(['lazy', 'lazy', 'lazy', 'clean', 'hyper', 'terse']); p = BL.pers[name] = { st, typo: st === 'clean' ? .01 : .02 + R() * .07, emo: st === 'hyper' ? .25 : st === 'terse' ? .02 : .07 }; }
  return p;
}
function blTypo(w) { const i = rnd(1, w.length - 2), r = R(); if (r < .45) return w.slice(0, i) + w[i + 1] + w[i] + w.slice(i + 2); if (r < .75) return w.slice(0, i) + w.slice(i + 1); return w.slice(0, i) + w[i] + w.slice(i); }
/* who: bot entity, a name string, or null (random stranger) */
function blStyle(who, s) {
  if (!s) return s; s = String(s);
  if (/^[?!.…]+$/.test(s)) return s;
  const p = blPers(who && typeof who === 'object' ? who.name : who || pick(BOT_NAMES)); BL.lastTypo = null;
  if (R() < p.typo) { const w = s.split(' '); const c = []; w.forEach((x, i) => { if (/^[a-z]{5,}$/.test(x)) c.push(i); }); if (c.length) { const i = pick(c); const o = w[i]; w[i] = blTypo(w[i]); if (w[i] !== o) BL.lastTypo = o; s = w.join(' '); } }
  if (p.st === 'clean') { s = s.charAt(0).toUpperCase() + s.slice(1); if (!/[.!?)]$/.test(s) && R() < .45) s += '.'; return s; }
  const ap = p.st === 'hyper' ? .9 : p.st === 'terse' ? .85 : .6;
  for (const [re, rep] of BL_ABBR) if (R() < ap) s = s.replace(re, rep);
  if (p.st === 'hyper' && R() < .12) s = s.toUpperCase(); else s = s.toLowerCase();
  s = s.replace(/\.$/, '');
  if (p.st === 'hyper' && R() < .3 && !/[?]$/.test(s)) s = s.replace(/!+$/, '') + '!!';
  if (R() < p.emo && !/(lol|xd|:\)|:d|\^\^|:p|lmao)/i.test(s)) s += ' ' + pick(p.st === 'hyper' ? ['xD', 'lol', ':D', 'lmao', 'xD'] : ['lol', ':)', '^^', ':/', 'xd', ':p']);
  return s;
}

/* ---------- world knowledge ---------- */
const BL_MAPMONS = { ashvale: ['hen', 'deer', 'scarecrow', 'wildcat', 'wildcat_brute', 'boar', 'old_tusk'], mine: ['cave_bat', 'maggot', 'skeleton', 'axe_skeleton', 'zombie', 'bone_fighter', 'rot_zombie', 'bone_king'], mirewood: ['goblin', 'goblin_fighter', 'goblin_shaman', 'spider', 'black_boar', 'snake', 'goblin_brute', 'goblin_warlord'], temple: ['moth', 'temple_archer', 'stone_guardian', 'cultist', 'khar_elite', 'minotaur'], sanctum: ['abyss_knight', 'wraith', 'lich_acolyte', 'colossus', 'vaal'] };
const BL_MONMAP = {}; for (const k in BL_MAPMONS) for (const id of BL_MAPMONS[k]) BL_MONMAP[id] = k;
const BL_MAPSH = { ashvale: ['ashvale', 'fields', 'ashvale'], mine: ['mine', 'Hollow Mine', 'hm', 'mine'], mirewood: ['mirewood', 'mw', 'Mirewood', 'forest'], temple: ['temple', 'khar', 'Temple'], sanctum: ['sanctum', 'raid'] };
const BL_MAPNAME = { ashvale: 'Ashvale Province', mine: 'Hollow Mine', mirewood: 'Mirewood Forest', temple: 'Sunken Temple of Khar', sanctum: 'Abyssal Sanctum' };
function mapSh(id) { return pick(BL_MAPSH[id] || ['here']); }
const BL_CLS = { W: ['war', 'warr', 'war', 'warrior'], M: ['wiz', 'wizard', 'wiz', 'mage'], T: ['tao', 'taoist', 'tao'] };
function clsSh(c) { return pick(BL_CLS[c] || ['?']); }
const BL_MONSH = { hen: 'hens', deer: 'deer', scarecrow: 'scarecrows', wildcat: 'cats', wildcat_brute: 'brutes', boar: 'boars', old_tusk: 'tusk', cave_bat: 'bats', maggot: 'maggots', skeleton: 'skeles', axe_skeleton: 'axe skeles', zombie: 'zombies', bone_fighter: 'bone fighters', rot_zombie: 'rotters', bone_king: 'bk', goblin: 'gobs', goblin_fighter: 'gob fighters', goblin_shaman: 'shamans', spider: 'spiders', black_boar: 'black boars', snake: 'vipers', goblin_brute: 'brutes', goblin_warlord: 'warlord', moth: 'moths', temple_archer: 'archers', stone_guardian: 'guardians', cultist: 'cultists', khar_elite: 'elites', minotaur: 'mino' };
function monSh(id) { return BL_MONSH[id] || (MON[id] ? MON[id].name.toLowerCase() : id); }
const BL_LANDMARKS = {
  ashvale: [[23, 21, 'mine entrance'], [76, 42, 'north gate'], [76, 76, 'south gate'], [57, 60, 'west gate'], [95, 59, 'east gate'], [77, 86, 'the farms'], [128, 16, 'tusk spawn'], [32, 92, 'the lake'], [120, 95, 'cat fields'], [108, 40, 'deer meadow'], [105, 60, 'hen field'], [140, 57, 'mirewood road'], [30, 108, 'brute camp']],
  mine: [[9, 10, 'mine entrance'], [50, 45, 'mine middle'], [84, 76, 'bk room'], [20, 78, 'south tunnels'], [88, 12, 'north tunnels']],
  mirewood: [[4, 55, 'mw entrance'], [40, 45, 'first clearing'], [55, 15, 'north clearing'], [30, 90, 'south clearing'], [90, 20, 'NE clearing'], [108, 88, 'warlord camp'], [130, 50, 'temple gate'], [80, 60, 'crossroads']],
  temple: [[8, 50, 'temple stairs'], [98, 50, 'mino room']],
  sanctum: [[8, 30, 'raid entrance']],
};
function blLandmark(mapId, x, y) {
  const L = BL_LANDMARKS[mapId] || []; let best = null, bd = 1e9;
  for (const [lx, ly, n] of L) { const d = cheb(x, y, lx, ly); if (d < bd) { bd = d; best = n; } }
  if (best && bd < 22) return R() < .5 ? best : 'near ' + best;
  const m = S.maps[mapId] || S.map; const dir = (y < m.h / 3 ? 'north' : y > m.h * 2 / 3 ? 'south' : '') + (x < m.w / 3 ? 'west' : x > m.w * 2 / 3 ? 'east' : '');
  return (dir || 'middle of') + ' ' + mapSh(mapId);
}
const BL_BOSSMAP = { old_tusk: 'ashvale', bone_king: 'mine', goblin_warlord: 'mirewood', minotaur: 'temple' };
function blBossStatus(bid) {
  const k = BL_BOSSMAP[bid] + ':' + bid; const nx = S.bossNext && S.bossNext[k];
  if (nx && nx > Date.now()) { const min = Math.max(1, Math.ceil((nx - Date.now()) / 60000)); return pick([`respawns in like ${min} min`, `${min} min till it's back`, `just died, ${min} min`]); }
  if (S.map.id === BL_BOSSMAP[bid] && S.ents.some(e => e.kind === 'mon' && !e.dead && e.def.id === bid)) return pick(['its up, go go', 'up rn', 'yes, at the usual spot']);
  return pick(['dunno, go check', 'was up 10 min ago', 'some1 killed it i think', 'no idea']);
}
let BL_INAMES = null;
function blItemIn(text) {
  if (!BL_INAMES) {
    const L = Object.values(ITEMS).map(d => [d.name.toLowerCase(), d.id]).concat([['rev ring', 'ring_revival'], ['para ring', 'ring_paralysis'], ['tele ring', 'ring_teleport'], ['prot ring', 'ring_protection'], ['heal ring', 'ring_healing'], ['sun pot', 'sun_potion'], ['black iron', 'black_ore'], ['ore', 'black_ore'], ['horn', 'warlord_horn']]);
    L.sort((a, b) => b[0].length - a[0].length);
    BL_INAMES = L.map(([n, id]) => [new RegExp('\\b' + n.replace(/[.*+?^${}()|[\]\\']/g, '\\$&') + 's?\\b'), id]);
  }
  const l = String(text).toLowerCase(); for (const [re, id] of BL_INAMES) if (re.test(l)) return id; return null;
}
function blDropSrc(id) { const out = []; for (const m of Object.values(MON)) if ((m.drops || []).some(([i]) => i === id) || (m.loot && m.loot.pool.includes(id))) out.push(m); return out; }
const BL_GEAR = ['weapon', 'armour', 'helmet', 'necklace', 'bracelet', 'ring'];

/* ================= WRAPPERS / OVERRIDES OF js4 ================= */
const _blMakeBot = makeBot;
makeBot = function (x, y, o) {
  const e = _blMakeBot(x, y, o);
  if (e.guild === undefined) e.guild = R() < .5 ? pick(GUILDS).name : null;
  e.pers = blPers(e.name); e.born = S.time; if (!e.life) e.life = 240 + R() * 900;
  return e;
};
const _blBotSay = botSay;
botSay = function (e, text) {
  if (!e || !text || text === BL_SIL) return;
  if (!S.player) return say(e, text);
  if (cheb(e.x, e.y, S.player.x, S.player.y) < 16 && (BL.force || S.time < (BL.forceUntil || 0) || (blQuiet(2, 10, 'say') && blQuiet(4, 12)))) _blBotSay(e, text); else say(e, text);
};
function blSayF(b, text) { BL.force = 1; try { botSay(b, text); } finally { BL.force = 0; } }
const _blWhisperFrom = whisperFrom;
whisperFrom = function (name, text) {
  if (text === BL_SIL) return;
  if (!BL.own && name && BL.hush[String(name).toLowerCase()] > S.time) return; /* our contextual reply replaces the generic one */
  _blWhisperFrom(name, text);
};
function blWhisper(who, text) { blTell(who, 'whisper', text); }

const _blChat = chat;
chat = function (ch, text, from) {
  if (text === BL_SIL) return;
  _blChat(ch, text, from);
  try { blOnChat(ch, text, from); } catch (err) { console.error(err); }
};
const _blKillEnt = killEnt;
killEnt = function (e, src) {
  const was = e.dead; _blKillEnt(e, src);
  if (!was) { try { blOnKill(e, src); } catch (err) { console.error(err); } }
};
const _blBotLeave = botLeave;
botLeave = function (e, how) {
  _blBotLeave(e, how); blGroupRemove(e);
  if (TR.cur && TR.cur.bot === e) blTradeClose('gone');
};
const _blDropItem = dropItem;
dropItem = function (x, y, it, gold) {
  const d = _blDropItem(x, y, it, gold);
  try { if (it && ITEMS[it.id].q && S.player && cheb(x, y, S.player.x, S.player.y) < 14) { const near = blBots(b => blNear(b, 12) && !b.afk && !b.party); if (near.length && R() < .7) { const b = pick(near); setTimeoutGame(.8 + R(), () => { if (blAlive(b)) blSayF(b, blStyle(b, pick(['!!!', 'omg', 'what dropped??', 'no way', 'gz!!', 'shiny']))); }); } } } catch (err) { }
  return d;
};
const _blInviteBot = inviteBot;
inviteBot = function (b) {
  if (!b || S.party.includes(b)) return;
  if (S.party.length >= 4) return _blInviteBot(b);
  const key = b.name.toLowerCase(), pd = BL.pend[key];
  if (b.afk) return; /* afk players never answer */
  { const hm = BL.mem[b.name.toLowerCase()]; const ho = hm && hm.off; if (ho && !ho.cancel && ho.state !== 'done' && S.time - ho.t < 200) { ho.accepted = true; ho.bot = b; b.helpOff = ho; if (blNear(b, 14) || ho.state === 'arrived' || ho.state === 'invited') setTimeoutGame(1 + R(), () => { if (blAlive(b)) joinParty(b); }); else { blTellAt(b, 'whisper', pick(['omw', 'coming, 1 sec']), 1.5); ho.going = false; blHelpGo(b, b.name, ho); } return; } }
  if (b.act && b.act.k === 'vendor') { setTimeoutGame(1.5, () => blWhisper(b, pick(['selling atm sry', 'cant, busy vending', 'no thx, shop open']))); return; }
  if (b.grp) {
    const g = b.grp;
    if (g.leader !== b) { setTimeoutGame(1.2 + R(), () => blWhisper(b, pick([`im in ${g.leader.name}'s grp, ask them`, 'already grouped sry', `ask ${g.leader.name}`]))); return; }
    if (S.party.length + g.members.length > 4) { setTimeoutGame(1.5, () => blWhisper(b, pick(['we r ' + g.members.length + ', no room in ur grp', 'too many of us lol']))); return; }
    setTimeoutGame(1.5 + R(), () => { if (blAlive(b)) { blWhisper(b, pick(['sure, bringing my grp', 'ok we all join', 'k'])); joinParty(b); } });
    return;
  }
  if (pd && (pd.kind === 'lfg' || pd.kind === 'lfmjoin')) { delete BL.pend[key]; setTimeoutGame(1 + R(), () => { if (blAlive(b)) joinParty(b); }); return; }
  const P = S.P; if (b.fq && P.qa && QUESTS[P.q] && QUESTS[P.q].need === b.fq.need && !b.red) { setTimeoutGame(1 + R(), () => { if (blAlive(b)) { blWhisper(b, 'yes! same quest'); joinParty(b); } }); return; }
  _blInviteBot(b);
};
const _blJoinParty = joinParty;
joinParty = function (b) {
  if (!b || S.party.includes(b) || S.party.length >= 4) return;
  const g = b.grp; let others = [];
  if (g) { if (g.leader === b) others = g.members.filter(m => m !== b); for (const m of g.members.slice()) blGroupRemove(m); }
  b.act = null; b.plan = null; b.afk = false; b.shop = null; b.wtb = null; b.route = null; b.come = null; b.holdT = 0;
  delete BL.pend[b.name.toLowerCase()];
  _blJoinParty(b);
  if (b.helpOff && !b.helpOff.cancel) { const off = b.helpOff; off.state = 'joined'; off.joinT = S.time; b.partyUntil = S.time + blHelpStay(off); b.assistUntil = 0; }
  others.forEach((m, i) => setTimeoutGame(.8 + i * .9, () => { if (blAlive(m) && !m.party && S.party.length < 4) { m.act = null; m.plan = null; m.route = null; _blJoinParty(m); } }));
};
const _blLeaveParty = leaveParty;
leaveParty = function (b, silent) { _blLeaveParty(b, silent); if (b && b.helpOff) { b.helpOff.state = 'done'; b.helpOff = null; } if (b && !b.dead && !b.gone) { b.huntC = [b.x, b.y]; b.mode = 'hunt'; } };

/* guarded runtime overrides of js6 helpers (js6 is not edited) */
try { if (typeof replyFor === 'function') replyFor = function (v) { return BL_SIL; }; } catch (err) { } /* js6 canned replies are dropped; the conversation layer answers */
try {
  if (typeof showCtx === 'function' && !/openTrade/.test(String(showCtx))) {
    const _blShowCtx = showCtx;
    showCtx = function (b, x, y) {
      _blShowCtx(b, x, y);
      try {
        const ctx = document.getElementById('ctx'); if (!ctx || ctx.querySelector('[data-a="trade"]')) return;
        const it = document.createElement('div'); it.className = 'i'; it.dataset.a = 'trade'; it.textContent = 'Trade';
        const ref = ctx.querySelector('[data-a="wh"]'); ctx.insertBefore(it, ref || null);
        it.addEventListener('click', () => { ctx.style.display = 'none'; openTrade(b); });
      } catch (err) { }
    };
  }
} catch (err) { }
Object.assign(REPLIES, { wts: ['how much?', 'pc?', 'what stats?'], wtb: ['what u need?', 'check the vendors in town'], lfg: ['what lvl?', 'inv me'], brb: ['k', 'ok'], afk: ['k'], gn: ['gn', 'night'], gm: ['gm', 'morning'], bot: ['lol what', 'im real lol'], pk: ['where?', 'report him'] });

/* ================= BOT GROUPS ================= */
function blMakeGroup(L, arr) {
  const g = { id: BL.gid++, leader: L, members: [L].concat(arr), fq: L.fq || (arr[0] && arr[0].fq) || null, chatAt: S.time + 4 + R() * 8, lfmAt: S.time + 20 + R() * 40 };
  for (const m of g.members) { m.grp = g; m.fq = g.fq; if (L.huntC) m.huntC = L.huntC; m.dest = null; }
  return g;
}
function blGroupAdd(g, b) { if (!g || b.grp) return; b.grp = g; g.members.push(b); b.fq = g.fq; b.huntC = g.leader.huntC; b.target = null; b.dest = null; }
function blGroupRemove(e) {
  const g = e && e.grp; if (!g) return; e.grp = null;
  g.members = g.members.filter(m => m !== e);
  if (e.fq && e.fq === g.fq) e.fq = Object.assign({}, g.fq);
  if (g.members.length <= 1) { for (const m of g.members) m.grp = null; g.members = []; return; }
  if (g.leader === e) g.leader = g.members[0];
}
function blGroups() { const s = new Set(); for (const e of S.ents) if (e.kind === 'bot' && e.grp && !e.dead) s.add(e.grp); return [...s]; }

/* ================= BOT QUESTS ================= */
function blPickQuest(lv, mapId) {
  const c = [];
  QUESTS.forEach((q, i) => { if (q.lv <= lv && lv <= q.lv + 9 && (!mapId || BL_MONMAP[q.need] === mapId)) c.push([i, (MON[q.need] && MON[q.need].boss ? .5 : 1) + (q.lv >= lv - 4 ? 2 : 0)]); });
  return c.length ? pickW(c) : null;
}
function blAssignQuest(b, qi) {
  if (qi == null || !QUESTS[qi]) { b.fq = null; return; }
  const q = QUESTS[qi]; const boss = MON[q.need] && MON[q.need].boss;
  b.fq = { qi, need: q.need, N: q.n, n: boss ? 0 : rnd(0, Math.floor(q.n * .5)), done: false };
}
function blProgressLine(b) {
  const fq = b.fq; if (!fq) return pick(SAYS); const ms = monSh(fq.need);
  if (MON[fq.need] && MON[fq.need].boss) return pick([`waiting for ${ms}`, `${ms} where r u`, `camping ${ms} lol`, `need ppl for ${ms}`]);
  return pick([`${ms} ${fq.n}/${fq.N}`, `${fq.n}/${fq.N}`, `${fq.N - fq.n} more ${ms}`, `${fq.n} of ${fq.N} ${ms}`, `where r all the ${ms}`, `${ms} spawn so slow`, `${fq.N - fq.n} to go`]);
}
function blQuestCredit(b, monId) {
  const fq = b.fq; if (!fq || fq.done || fq.need !== monId) return;
  fq.n++;
  if (fq.n >= fq.N) { blQuestDone(b); return; }
  if (R() < .3) { const sp = b.grp ? pick(b.grp.members.filter(m => !m.dead)) || b : b; if (blNear(sp, 16)) botSay(sp, blStyle(sp, blProgressLine(sp))); }
}
function blQuestDone(b) {
  const fq = b.fq; if (!fq || fq.done) return; fq.done = true;
  const q = QUESTS[fq.qi]; const g = b.grp; const L = g ? g.leader : b; const mem = g ? g.members.slice() : [b];
  const shout = [`finally done with ${q.name}!`, `${q.name} done :)`, `${q.name} done, only took forever`, `done with ${monSh(q.need)} finally`];
  const local = ['done!', 'quest done', `${fq.N}/${fq.N} :)`, 'finally', 'done, back to town', 'ty all'];
  if (R() < .35 && S.time > (BL.doneShoutT || 0) && blQuiet(2, 12, 'shout')) { BL.doneShoutT = S.time + 75; chat('shout', blStyle(b, pick(shout)), b.name); } else if (blNear(b, 16)) botSay(b, blStyle(b, pick(local)));
  for (const m of mem) if (R() < .3 && m.lv < 40) { const who = m; setTimeoutGame(1 + R() * 3, () => { if (!blAlive(who)) return; who.lv++; who.maxhp = Math.round(baseStats(who.cls, who.lv).hp * 1.25); who.hp = who.maxhp; if (blNear(who, 18)) { fx('pillar', epx(who), epy(who), { dur: 1.3, col: '255,210,110' }); fx('ring', epx(who), epy(who), { dur: .9, col: '255,220,140', r: 60, w: 4 }); } if (blNear(who, 14) && R() < .7) blSayF(who, blStyle(who, pick(['ding!', 'ding ' + who.lv, 'lvl ' + who.lv + ' finally', 'ding :D']))); }); }
  setTimeoutGame(4 + R() * 4, () => {
    if (!blAlive(L)) return;
    const nq = blPickQuest(L.lv, S.map.id);
    if (nq != null && R() < .6) {
      blAssignQuest(L, nq); L.fq.n = 0; if (L.grp) { L.grp.fq = L.fq; for (const m of L.grp.members) m.fq = L.fq; }
      const hc = blHuntSpot(L.fq.need, L.lv, S.map); if (hc) for (const m of (L.grp ? L.grp.members : [L])) m.huntC = hc;
      if (blNear(L, 16)) botSay(L, blStyle(L, pick([`next: ${QUESTS[nq].name}`, `lets do ${monSh(QUESTS[nq].need)} next`, 'next quest'])));
      return;
    }
    blHeadHome(L);
  });
}
/* after a quest: walk back to town on ashvale, otherwise scroll out */
function blHeadHome(L) {
  const mem = L.grp ? L.grp.members.slice() : [L];
  if (S.map.id === 'ashvale' && cheb(L.x, L.y, 76, 59) < 60) {
    for (const m of mem) { const r = blRouteTo(m, 'town'); m.route = r.route; m.travelEnd = r.end; m.mode = 'travel'; m.target = null; m.wpT = S.time; }
    for (const m of mem) blGroupRemove(m);
    return;
  }
  mem.forEach((m, i) => setTimeoutGame(i * (.6 + R()), () => { if (blAlive(m)) botLeave(m, 'teleport'); }));
}

/* ================= POPULATION ================= */
const BL_GATES = [{ n: 'N', in: [76, 48], gate: [76, 46], out: [76, 42] }, { n: 'S', in: [76, 70], gate: [76, 72], out: [76, 76] }, { n: 'W', in: [64, 59], gate: [62, 59], out: [58, 60] }, { n: 'E', in: [88, 59], gate: [90, 59], out: [94, 59] }];
const BL_VSPOTS = [[67, 59], [68, 64], [84, 64], [85, 59], [72, 64], [80, 64], [68, 55], [84, 55], [71, 61], [81, 61], [67, 66], [85, 66]];
function blHuntSpot(monId, lv, m, farFromPlayer) {
  m = m || S.map; const lists = [];
  const monOk = id => monId ? id === monId : (MON[id] && !MON[id].boss && MON[id].lv <= lv + 2 && MON[id].lv >= lv - 9);
  if (monId && MON[monId] && MON[monId].boss) { const b = (m.bosses || []).find(x => x.mon === monId); if (b) { const s = randomFree(m, b.x, b.y, 5, (x, y) => cheb(x, y, b.x, b.y) >= 2); if (s) return s; } }
  for (const sp of m.spawns || []) { const ids = sp.mon ? [sp.mon] : (sp.mons || []); if (ids.some(monOk) && sp.cand && sp.cand.length) lists.push(sp.cand); }
  for (const z of m.zones || []) if ((z.mons || []).some(monOk) && z.cand && z.cand.length) lists.push(z.cand);
  if (!lists.length) return null;
  for (let i = 0; i < 20; i++) {
    const c = pick(lists); const k = rnd(0, c.length / 2 - 1) * 2; const x = c[k], y = c[k + 1];
    if (!inb(m, x, y) || m.b[idx(m, x, y)] || (m.safe && x > m.safe.x0 - 2 && x < m.safe.x1 + 2 && y > m.safe.y0 - 2 && y < m.safe.y1 + 2)) continue;
    if (farFromPlayer && S.player && cheb(x, y, S.player.x, S.player.y) < farFromPlayer && i < 16) continue;
    return [x, y];
  }
  return null;
}
function spawnFieldBot(announce, o) {
  o = o || {}; const cfg = BOT_CFG[S.map.id], m = S.map; if (!cfg || blBotCount() >= BOTMAX) return null;
  let lv = o.lv || rnd(cfg.lv[0], cfg.lv[1]);
  const red = !o.noRed && (m.id !== 'ashvale' ? R() < .1 : R() < .03);
  if (red) lv = clamp(Math.max(lv, S.P.lv + rnd(-2, 4)), 1, 40);
  const qi = red ? null : blPickQuest(lv, m.id); const need = qi != null ? QUESTS[qi].need : null;
  let s = null;
  if (announce && S.player && R() < .18) s = randomFree(m, S.player.x, S.player.y, 7, (x, y) => !inSafe(x, y) && cheb(x, y, S.player.x, S.player.y) >= 3);
  const far = announce ? 16 : 7;
  if (!s) s = blHuntSpot(need, lv, m, far) || blHuntSpot(null, lv, m, far);
  if (!s) s = randomFree(m, rnd(5, m.w - 5), rnd(5, m.h - 5), 4, (x, y) => !inSafe(x, y) && (!S.player || cheb(x, y, S.player.x, S.player.y) > 10));
  if (!s) return null;
  const mo = { lv, red, mode: 'hunt' }; if (o.cls) mo.cls = o.cls; if (red) mo.guild = null;
  const b = makeBot(s[0], s[1], mo);
  if (red) b.pk = 200;
  b.huntC = s.slice(); blAssignQuest(b, qi);
  if (announce && blNear(b, 14)) { fx('pillar', epx(b), epy(b), { dur: .8, col: '140,180,255' }); if (blNear(b, 10)) sfx('portal'); }
  return b;
}
function spawnFieldGroup(n, announce) {
  const L = spawnFieldBot(announce, { noRed: true }); if (!L) return 0;
  const cfg = BOT_CFG[S.map.id]; const guild = L.guild || (R() < .6 ? pick(GUILDS).name : null); L.guild = guild;
  let hasT = L.cls === 'T'; const mem = [];
  for (let i = 1; i < n && blBotCount() < BOTMAX; i++) {
    const s = randomFree(S.map, L.x, L.y, 2) || nearFree(S.map, L.x, L.y);
    const cls = !hasT && i === n - 1 && R() < .8 ? 'T' : pick(['W', 'W', 'M', 'T']); if (cls === 'T') hasT = true;
    const b = makeBot(s[0], s[1], { lv: clamp(L.lv + rnd(-3, 3), 1, 40), cls, guild, mode: 'hunt' });
    b.huntC = L.huntC; mem.push(b);
    if (announce && blNear(b, 14)) fx('pillar', epx(b), epy(b), { dur: .8, col: '140,180,255' });
  }
  if (!mem.length) return 1;
  blMakeGroup(L, mem); return 1 + mem.length;
}
function blVendorSpot() {
  const m = S.map; const used = new Set(blBots(b => b.vspot).map(b => b.vspot.join(',')));
  const c = BL_VSPOTS.filter(s => !used.has(s.join(',')) && !m.b[idx(m, s[0], s[1])] && !S.occ[idx(m, s[0], s[1])]);
  return c.length ? pick(c).slice() : randomFree(m, 76, 62, 8, (x, y) => inSafe(x, y));
}
function blTownLv() { const P = S.P; return R() < .55 ? clamp(P.lv + rnd(-5, 6), 2, 40) : rnd(3, 38); }
function spawnTownBot(role, arrive) {
  const m = S.map; if (m.id !== 'ashvale' || blBotCount() >= BOTMAX) return null;
  role = role || pickW([['quester', .34], ['shopper', .26], ['social', .16], ['afk', .1], ['vendor', .07], ['leaver', .07]]);
  if (role === 'vendor' && blBots(b => b.role === 'vendor').length >= 4) role = 'shopper';
  let s = null, gate = null;
  const how = arrive ? (R() < .6 ? 'tp' : 'gate') : null;
  if (role === 'vendor') s = blVendorSpot();
  else if (how === 'gate') { gate = pick(BL_GATES); s = randomFree(m, gate.out[0], gate.out[1], 2, (x, y) => !inSafe(x, y)); if (s && S.player && cheb(s[0], s[1], S.player.x, S.player.y) < 8) s = null; }
  if (!s) s = randomFree(m, 76, 60, 11, (x, y) => inSafe(x, y));
  if (!s) return null;
  const b = makeBot(s[0], s[1], { lv: role === 'vendor' ? rnd(18, 40) : blTownLv(), mode: 'town' });
  b.role = role; b.act = null; b.plan = blPlanFor(role, b);
  if (role === 'vendor') b.vspot = s.slice();
  if (role === 'quester' || role === 'leaver' || role === 'shopper') blAssignQuest(b, blPickQuest(b.lv, null));
  if (gate) { b.mode = 'travel'; b.route = [gate.gate.slice(), gate.in.slice()]; b.travelEnd = 'town'; b.wpT = S.time; }
  else if (how === 'tp' && blNear(b, 16)) { fx('pillar', epx(b), epy(b), { dur: .8, col: '140,180,255' }); if (blNear(b, 10)) sfx('portal'); }
  return b;
}
function blPlanFor(role, b) {
  switch (role) {
    case 'quester': return (R() < .4 ? ['shop'] : []).concat(['elder', 'leave']);
    case 'shopper': return ['shop'].concat(R() < .5 ? ['shop'] : []).concat(pick([['elder', 'leave'], ['leave'], ['logout'], ['wander', 'logout']]));
    case 'social': return ['wander', 'chat', 'wander'].concat(pick([['shop', 'logout'], ['logout'], ['elder', 'leave'], ['chat', 'leave']]));
    case 'afk': return ['afk'].concat(pick([['logout'], ['wander', 'leave'], ['shop', 'logout']]));
    case 'vendor': return ['vendor', 'logout'];
    case 'returner': return ['elder'].concat(R() < .5 ? ['shop'] : []).concat(pick([['leave'], ['logout'], ['wander', 'logout']]));
    default: return ['leave'];
  }
}
function populateBots() {
  const cfg = BOT_CFG[S.map.id]; if (!cfg) return; const v = blCurve();
  if (cfg.town) { const n = Math.round(cfg.town * (.7 + .5 * v)); const nv = rnd(2, 3); for (let i = 0; i < n; i++) spawnTownBot(i < nv ? 'vendor' : null, false); }
  if (cfg.field) { const n = Math.round(cfg.field * (.8 + .5 * v)); let made = 0, guard = 0; while (made < n && blBotCount() < BOTMAX - 2 && guard++ < 30) { if (R() < .4 && n - made >= 2) made += spawnFieldGroup(rnd(2, 3), false) || 1; else { spawnFieldBot(false); made++; } } }
}
function blWrapUp(b) {
  b.wrapping = true;
  if (b.mode === 'town') { b.plan = ['logout']; if (!b.act || b.act.k !== 'vendor' || R() < .5) b.act = null; return; }
  const g = b.grp;
  if (g && g.leader === b) { if (blNear(b, 16)) botSay(b, blStyle(b, pick(['gtg guys', 'last pull, then i log', 'ty for grp, gtg']))); g.members.forEach((m, i) => setTimeoutGame(2 + i * (.8 + R()), () => { if (blAlive(m)) { if (m !== b && blNear(m, 16) && R() < .5) botSay(m, blStyle(m, pick(['cya', 'ty', 'gn', 'me too']))); botLeave(m, 'teleport'); } })); return; }
  if (g) return; /* followers leave with their leader */
  if (blNear(b, 14) && R() < .5) botSay(b, blStyle(b, pick(['gtg', 'cya', 'bed time', 'logging, gn'])));
  setTimeoutGame(1.2 + R(), () => { if (blAlive(b)) botLeave(b, 'teleport'); });
}
function blPopTick() {
  const cfg = BOT_CFG[S.map.id]; if (!cfg || !S.player) return; const v = blCurve();
  const bots = blBots(b => !b.party);
  for (const b of bots) if (!b.wrapping && S.time - (b.born || 0) > (b.life || 600) && !b.come && !(TR.cur && TR.cur.bot === b) && !(b.grp && b.grp.leader !== b)) blWrapUp(b);
  for (const b of bots) if (b.fq && !b.fq.done && b.mode === 'hunt' && !blNear(b, 22) && (!b.grp || b.grp.leader === b) && R() < .05) { b.fq.n++; if (b.fq.n >= b.fq.N) blQuestDone(b); }
  const town = bots.filter(b => b.mode === 'town' || (b.mode === 'travel' && b.travelEnd === 'town'));
  const field = bots.filter(b => !town.includes(b));
  if (cfg.town) { const want = Math.round(cfg.town * (.7 + .5 * v)); if (town.length < want && R() < .55) spawnTownBot(null, true); }
  if (cfg.field) {
    const want = Math.round(cfg.field * (.8 + .5 * v));
    const def = want - field.length;
    if (def > 0 && R() < (def >= 3 ? .9 : .5)) { if (R() < .3) spawnFieldGroup(rnd(2, 3), true); else spawnFieldBot(true); if (def >= 4) spawnFieldBot(true); }
    else if (field.length > want + 2 && R() < .3) { const c = field.filter(b => !blNear(b, 14) && !b.grp && b.mode === 'hunt'); if (c.length) botLeave(pick(c)); }
  }
}

/* ================= BOT AI ================= */
function blGoTo(e, x, y, stop) {
  if (cheb(e.x, e.y, x, y) <= stop) { e.lastMoveT = S.time; return true; }
  const k = e.x + ',' + e.y;
  if (e.lastK !== k) { e.lastK = k; e.lastMoveT = S.time; }
  else if (S.time - (e.lastMoveT || S.time) > 2.5) {
    e.lastMoveT = S.time; e.path = null; e.stuckN = (e.stuckN || 0) + 1;
    if (cheb(e.x, e.y, x, y) <= stop + 2 || e.stuckN > 4) { e.stuckN = 0; return true; }
    stepToward(e, x + rnd(-2, 2), y + rnd(-2, 2), e.spd);
    return false;
  }
  botMove(e, x, y, stop); return false;
}
const _blBotAI = botAI;
botAI = function (e, dt) {
  if (e.stunT > 0 || e.atk >= 0 || e.cast >= 0 || e.mt < 1) return;
  if (e.party) { blPartyExtras(e); return _blBotAI(e, dt); }
  if (e.come && blComeAI(e)) return;
  if (e.holdT > S.time) return;
  if (e.assistUntil > S.time) { if (e.mode !== 'hunt') e.mode = 'hunt'; if (blAssistAI(e)) return; if (e.target) return _blBotAI(e, dt); }
  if (e.mode === 'town') return blTownAI(e, dt);
  if (e.mode === 'travel') { if (e.target && !e.target.dead && e.target.target === e) return _blBotAI(e, dt); return blTravelAI(e); }
  if (e.hp < e.maxhp * .2 && S.time > (e.sunAt || 0) && R() < .7) { e.sunAt = S.time + 20 + R() * 15; const h = Math.round(e.maxhp * .45); e.hp = Math.min(e.maxhp, e.hp + h); if (blNear(e, 18)) { burst(epx(e), epy(e) - 20, 12, '255,220,120', 60, .6, 2.5, -30); floatText(epx(e), epy(e) - 36, '+' + h, 'rgba(140,255,160,.8)'); } }
  if (e.hp < e.maxhp * .2 && !e.saidLow && R() < .5) { e.saidLow = true; if (blNear(e, 14)) botSay(e, blStyle(e, pick(['help!!', 'omg', 'nooo', 'run', 'heal pls', '!!!']))); }
  if (e.hp > e.maxhp * .6) e.saidLow = false;
  if (e.grp) {
    if (blGroupHeal(e)) return;
    if (e.grp && e.grp.leader !== e) { if (blFollower(e)) return; }
    else if (e.grp && !e.target) { const lag = e.grp.members.some(m => m !== e && cheb(m.x, m.y, e.x, e.y) > 7); if (lag && S.time - (e.waitT || 0) < 8) return; if (!lag) e.waitT = S.time; }
  }
  if (e.target && blBossProtected(e.target)) e.target = null;
  if (!e.target && e.thinkT <= 0 && !e.red) blHuntPick(e);
  _blBotAI(e, dt);
  if (e.target && blBossProtected(e.target)) { e.target = null; e.thinkT = 1; }
};
/* bosses respawn on real-time timers: bots leave a boss alone while the player's active quest needs it */
function blBossProtected(m) { if (!m || m.kind !== 'mon' || !m.def.boss) return false; const P = S.P, q = QUESTS[P.q]; return !!(q && P.qa && P.qn < q.n && q.need === m.def.id); }
function blHuntPick(e) {
  const need = e.fq && !e.fq.done ? e.fq.need : null;
  if (need) {
    const boss = MON[need] && MON[need].boss; const canBoss = !boss || e.grp || e.lv >= MON[need].lv - 2;
    let best = null, bd = 12;
    if (canBoss) for (const m of S.ents) { if (m.kind !== 'mon' || m.dead || m.def.id !== need || blBossProtected(m)) continue; const d = cheb(m.x, m.y, e.x, e.y); if (d < bd && !(m.target === S.player && R() < .8)) { bd = d; best = m; } }
    if (best) { e.target = best; e.thinkT = .6 + R() * .6; return; }
  }
  const hc = e.huntC;
  if (hc && cheb(e.x, e.y, hc[0], hc[1]) > 15) { e.dest = randomFree(S.map, hc[0], hc[1], 5) || hc.slice(); e.thinkT = 2 + R() * 2; }
}
function blFollower(e) {
  const g = e.grp, L = g.leader;
  if (!L || L.dead || L.gone) { blGroupRemove(e); return false; }
  const d = cheb(e.x, e.y, L.x, L.y);
  if (d > 20 && !blNear(e, 20) && !blNear(L, 20)) { const s = nearFree(S.map, L.x, L.y); teleportEnt(e, s[0], s[1]); return true; }
  if (L.target && !L.target.dead && L.target.kind === 'mon' && !blBossProtected(L.target) && d < 14 && (!e.target || e.target.dead || e.target.kind !== 'mon')) e.target = L.target;
  if (e.target && !e.target.dead && d > 11 && e.target !== L.target) e.target = null;
  if (!e.target || e.target.dead) {
    e.target = null;
    if (d > 3) { e.dest = null; botMove(e, L.x, L.y, 2); return true; }
    if (!e.dest && R() < .02) { const s = randomFree(S.map, L.x, L.y, 2); if (s) e.dest = s; }
    if (e.dest) { if (cheb(e.x, e.y, e.dest[0], e.dest[1]) === 0) e.dest = null; else botMove(e, e.dest[0], e.dest[1], 0); }
    return true;
  }
  return false;
}
function blGroupHeal(e) {
  if (e.cls !== 'T' || S.time < (e.healAt || 0)) return false;
  let best = null, bf = .6;
  for (const m of e.grp.members) { if (m.dead || m.gone) continue; const f = m.hp / m.maxhp; if (f < bf && cheb(m.x, m.y, e.x, e.y) <= 7) { bf = f; best = m; } }
  if (!best) return false;
  e.healAt = S.time + 2.5 + R() * 1.5; e.cast = 0; e.castDur = .45; if (best !== e) blFace(e, best);
  const amt = Math.round(e.lv * 1.8 + 10 + R() * e.lv * .5);
  setTimeoutGame(.3, () => { if (best.dead || best.gone) return; best.hp = Math.min(best.maxhp, best.hp + amt); healFx(best, amt); if (blNear(best, 12)) sfx('heal'); });
  if (bf < .3 && R() < .3 && blNear(e, 16)) botSay(e, blStyle(e, pick(['healing', 'got u', 'heal inc', 'careful!', 'stop pulling lol'])));
  return true;
}
function blPartyExtras(e) {
  if (e.cls !== 'T' || S.time < (e.healAt || 0) || !S.player || S.player.hp < S.player.maxhp * .6) return;
  let best = null, bf = .5;
  for (const m of S.party) if (m !== e && !m.dead && cheb(m.x, m.y, e.x, e.y) <= 7 && m.hp / m.maxhp < bf) { bf = m.hp / m.maxhp; best = m; }
  if (!best) return;
  e.healAt = S.time + 3; const amt = Math.round(e.lv * 1.6 + 10);
  setTimeoutGame(.3, () => { if (!best.dead) { best.hp = Math.min(best.maxhp, best.hp + amt); healFx(best, amt); sfx('heal'); } });
}
function blPortalTo(e, x, y) { const s = randomFree(S.map, x, y, 3, (a, b) => cheb(a, b, x, y) >= 1) || nearFree(S.map, x + 1, y); fx('pillar', epx(e), epy(e), { dur: .5, col: '140,180,255' }); teleportEnt(e, s[0], s[1]); e.path = null; fx('pillar', epx(e), epy(e), { dur: .8, col: '140,180,255' }); if (blNear(e, 14)) sfx('portal'); }
function blComeAI(e) {
  const c = e.come, p = S.player;
  if (!p || S.dead || S.time > c.until) { e.come = null; if (blAlive(e)) blWhisper(e, pick(c.help ? ['cant find u, nvm', 'nvm, gtg sry', 'where did u go? nvm'] : ['nvm, gtg', 'cant find u, nvm', 'nvm'])); if (e.helpOff) { e.helpOff.state = 'done'; e.helpOff = null; } return false; }
  if (c.help && S.ents.some(m => m.kind === 'mon' && !m.dead && m.target === e && cheb(m.x, m.y, e.x, e.y) < 6)) return false; /* fight back, then carry on */
  e.target = null;
  if (c.at) { /* boss help: go to the boss and wait there for the player */
    const d = cheb(e.x, e.y, c.at[0], c.at[1]);
    if (blNear(e, 12)) { c.at = null; return true; }
    if (d <= 3) { if (!c.camp) { c.camp = S.time; blTell(e, 'whisper', pick([`at ${monSh(e.helpOff ? e.helpOff.boss : '')}, where r u?`, 'im at the boss spot, waiting', `here at ${monSh(e.helpOff ? e.helpOff.boss : '')}`])); } return true; }
    if (d > 45 && S.time - c.t0 > 4) { blPortalTo(e, c.at[0], c.at[1]); return true; }
    blGoTo(e, c.at[0], c.at[1], 2); return true;
  }
  const d = cheb(e.x, e.y, p.x, p.y);
  if (d <= 3) { e.come = null; e.path = null; blFace(e, p); const f = c.fn; setTimeoutGame(.4, f); return true; }
  const far = c.help ? 45 : 24, late = c.help ? 28 : 14;
  if ((d > far && S.time - c.t0 > 3) || (S.time - c.t0 > late && d > 8)) { blPortalTo(e, p.x, p.y); return true; }
  blGoTo(e, p.x, p.y, 2); return true;
}

/* ---------- town life ---------- */
const BL_CHATPAIRS = [['hi', 'hey'], ['nice armour', 'ty :)'], ['u going mine?', 'later maybe', 'k'], ['wanna duo?', 'sure after pots', 'k'], ['how much is a Coral Ring?', 'like 6k'], ['did u see bk drop?', 'no what dropped'], ['brb food', 'k'], ['im so broke lol', 'same'], ['whats ur guild?', 'no guild atm'], ['lf tao', 'ask in shout'], ['lol', 'lol'], ['u selling?', 'nah'], ['hows mirewood?', 'full of pkers lol'], ['gz on lvl', 'ty!'], ['got any pots?', 'no sry'], ['yo', 'o/'], ['this server is so full', 'ikr'], ['ready?', 'sec, buying pots', 'k']];
function blTSay(b, text) { if (blAlive(b)) botSay(b, blStyle(b, text)); }
function blTownAI(e, dt) {
  if (!e.act) { const k = e.plan && e.plan.length ? e.plan.shift() : pick(['logout', 'leave']); e.act = { k, ph: 0, t0: S.time }; }
  const a = e.act; const m = S.map;
  switch (a.k) {
    case 'elder': {
      if (a.ph === 0) {
        if (!a.spot) { a.npc = blNpc('elder'); const n = a.npc; a.spot = n ? (randomFree(m, n.x, n.y + 1, 2, (x, y) => cheb(x, y, n.x, n.y) <= 2 && cheb(x, y, n.x, n.y) >= 1) || [n.x, n.y + 2]) : [73, 59]; }
        if (blGoTo(e, a.spot[0], a.spot[1], 0) || S.time > a.t0 + 40) { a.ph = 1; a.until = S.time + 3 + R() * 4; blFace(e, a.npc); say(e, e.fq && e.fq.done ? '?' : pick(['!', '?', '...', '!'])); }
      } else if (S.time > a.until) {
        if (!e.fq || e.fq.done) blAssignQuest(e, blPickQuest(e.lv, null));
        if (e.fq && R() < .35 && blNear(e, 14)) { const q = QUESTS[e.fq.qi]; blTSay(e, pick([`${monSh(q.need)} again?`, `${q.n} ${monSh(q.need)}... ok`, 'ty elder', `${q.name} time`, 'ugh', 'k'])); }
        e.act = null;
      }
      return;
    }
    case 'shop': {
      if (a.ph === 0) {
        if (!a.spot) { const shops = S.ents.filter(n => n.kind === 'npc' && n.def && ['shop', 'books', 'smith', 'storage'].includes(n.def.role)); a.npc = shops.length ? pick(shops) : null; if (!a.npc) { e.act = null; return; } a.spot = randomFree(m, a.npc.x, a.npc.y + 1, 1, (x, y) => y > a.npc.y) || [a.npc.x, a.npc.y + 1]; }
        if (blGoTo(e, a.spot[0], a.spot[1], 0) || S.time > a.t0 + 40) { a.ph = 1; a.until = S.time + 3 + R() * 6; blFace(e, a.npc); if (R() < .25) say(e, pick(a.npc.def.id === 'potions' ? ['pots...', 'so expensive', 'x50 hp pots'] : a.npc.def.id === 'smith' ? ['+3 pls', 'plz dont break', '...'] : ['hmm', '...', 'too expensive lol', 'broke'])); }
      } else if (S.time > a.until) {
        if (a.npc.def.id === 'smith' && R() < .5 && blNear(e, 14)) blTSay(e, pick(['yes +' + rnd(2, 5) + '!!', 'broke my ore again', 'failed lol', 'grom hates me']));
        e.act = null;
      }
      return;
    }
    case 'vendor': {
      if (a.ph === 0) {
        if (!e.vspot) e.vspot = blVendorSpot() || [e.x, e.y];
        if (blGoTo(e, e.vspot[0], e.vspot[1], 0) || S.time > a.t0 + 30) { a.ph = 1; a.until = S.time + 150 + R() * 300; a.nextB = S.time + 1 + R() * 3; e.dir = 4; if (!e.shop && !e.wtb) blStockVendor(e); }
      } else {
        if (S.time > a.nextB) { a.nextB = S.time + 9 + R() * 10; if (!e.shop && !e.wtb) blStockVendor(e); const t = blVendorLine(e); if (blNear(e, 16) && R() < .1) botSay(e, t); else say(e, t); }
        if (S.time > a.until) { if (blNear(e, 14) && R() < .5) blTSay(e, pick(['closing shop', 'sold out, cya', 'gn all'])); e.act = null; }
      }
      return;
    }
    case 'afk': {
      if (a.ph === 0) {
        if (!a.spot) a.spot = randomFree(m, 76, 60, 11, (x, y) => inSafe(x, y) && !S.occ[idx(m, x, y)]) || [e.x, e.y];
        if (blGoTo(e, a.spot[0], a.spot[1], 0) || S.time > a.t0 + 30) { a.ph = 1; e.afk = true; a.until = S.time + 60 + R() * 200; a.nextB = S.time + 2; }
      } else {
        if (S.time > a.nextB) { a.nextB = S.time + 18 + R() * 20; say(e, pick(['afk', 'afk', 'zzz', 'brb', 'afk 5 min'])); }
        if (S.time > a.until) { e.afk = false; if (R() < .5) say(e, pick(['back', 'b', 're'])); e.act = null; }
      }
      return;
    }
    case 'wander': {
      if (a.ph === 0) { if (!a.spot) a.spot = randomFree(m, e.x, e.y, 6, (x, y) => inSafe(x, y)) || [e.x, e.y]; if (blGoTo(e, a.spot[0], a.spot[1], 0) || S.time > a.t0 + 20) { a.ph = 1; a.until = S.time + 2 + R() * 5; } }
      else if (S.time > a.until) e.act = null;
      return;
    }
    case 'chat': {
      if (a.ph === 0) {
        if (!a.o) { const c = blBots(o => o !== e && o.mode === 'town' && !o.afk && !(o.act && o.act.k === 'vendor') && cheb(o.x, o.y, e.x, e.y) < 14); a.o = c.length ? pick(c) : null; if (!a.o) { e.act = null; return; } }
        if (!blAlive(a.o)) { e.act = null; return; }
        if (blGoTo(e, a.o.x, a.o.y, 1) || S.time > a.t0 + 20) {
          a.ph = 1; a.until = S.time + 9; const o = a.o; blFace(e, o); o.holdT = S.time + 8; blFace(o, e);
          const pr = pick(BL_CHATPAIRS); blTSay(e, pr[0]);
          setTimeoutGame(2 + R() * 2, () => blTSay(o, pr[1] === 'lvl' ? String(o.lv) : pr[1]));
          if (pr[2]) setTimeoutGame(5 + R() * 2, () => blTSay(e, pr[2]));
        }
      } else if (S.time > a.until) e.act = null;
      return;
    }
    case 'leave': {
      if (blNear(e, 14) && R() < .25) blTSay(e, pick(['cya', 'off to hunt', 'bb', 'lets go']));
      const r = blRouteTo(e, 'hunt'); e.route = r.route; e.travelEnd = r.end; e.mode = 'travel'; e.act = null; e.wpT = S.time;
      return;
    }
    case 'logout': default: {
      if (a.ph === 0) { a.ph = 1; a.until = S.time + 1.5 + R(); if (blNear(e, 14) && R() < .4) blTSay(e, pick(['cya', 'gn', 'bb', 'logging', 'gtg', 'night all'])); }
      else if (S.time > a.until) botLeave(e, 'teleport');
      return;
    }
  }
}
/* routes out of (or back into) Ashvale town */
function blRouteTo(e, kind) {
  if (kind === 'town') {
    let g = BL_GATES[0], bd = 1e9; for (const G of BL_GATES) { const d = cheb(e.x, e.y, G.out[0], G.out[1]); if (d < bd) { bd = d; g = G; } }
    return { route: [g.out.slice(), g.gate.slice(), g.in.slice()], end: 'town' };
  }
  const fq = e.fq; const dest = fq ? BL_MONMAP[fq.need] : (e.lv < 12 ? 'ashvale' : e.lv < 20 ? 'mine' : e.lv < 28 ? 'mirewood' : 'temple');
  if (dest === 'ashvale' && S.map.id === 'ashvale') {
    const hc = (fq && blHuntSpot(fq.need, e.lv, S.map)) || blHuntSpot(null, e.lv, S.map);
    if (hc) { let g = BL_GATES[0], bd = 1e9; for (const G of BL_GATES) { const d = cheb(hc[0], hc[1], G.out[0], G.out[1]); if (d < bd) { bd = d; g = G; } } e.huntC = hc; return { route: [g.in.slice(), g.gate.slice(), g.out.slice(), hc.slice()], end: 'hunt' }; }
  }
  if (dest === 'mine') return { route: [[76, 48], [76, 46], [76, 42], [76, 36], [76, 30], [62, 27], [48, 24], [34, 22], [24, 20], [23, 19]], end: 'portal' };
  return { route: [[88, 59], [90, 59], [94, 59], [105, 58], [118, 58], [130, 57], [142, 57], [148, 57]], end: 'portal' };
}
function blTravelAI(e) {
  const r = e.route;
  if (!r || !r.length) { blFinishTravel(e); return; }
  if (e.travelEnd === 'portal' && !inSafe(e.x, e.y) && !blNear(e, 22) && cheb(e.x, e.y, 76, 59) > 16) { blVanish(e); return; }
  const w = r[0];
  if (blGoTo(e, w[0], w[1], r.length === 1 ? 0 : 1) || S.time - (e.wpT || 0) > 30) { r.shift(); e.path = null; e.wpT = S.time; }
}
function blVanish(e) { e.gone = true; e.dead = true; e.deadT = 99; blGroupRemove(e); if (TR.cur && TR.cur.bot === e) blTradeClose('gone'); }
function blFinishTravel(e) {
  const end = e.travelEnd; e.route = null; e.travelEnd = null;
  if (end === 'portal') { blVanish(e); return; }
  if (end === 'town') { e.mode = 'town'; e.role = 'returner'; e.plan = blPlanFor('returner', e); e.act = null; e.huntC = null; e.born = S.time; e.life = 200 + R() * 300; e.wrapping = false; return; }
  e.mode = 'hunt'; e.thinkT = 0; if (!e.huntC) e.huntC = [e.x, e.y];
}

/* ================= CHAT: reactions to the world ================= */
function blOnChat(ch, text, from) {
  const P = S.P; if (!P || !S.player) return;
  if (from && from !== P.name && from !== 'System' && (ch === 'say' || ch === 'shout' || ch === 'whisper' || ch === 'guild' || ch === 'party')) BL.recent.push([S.time, ch]);
  if (ch === 'whisperTo') { blOnWhisperTo(text, from); return; }
  if (ch === 'sys') { blOnSys(text); return; }
  if (ch === 'shout' && from === 'System') { blOnSystemShout(text); return; }
  if (ch === 'loot') { if (from === '#ffc94a' || from === '#c58cff') blReactRare(String(text).replace(/^Picked up /, '').replace(/ x\d+$/, '')); return; }
  if (from === P.name && (ch === 'say' || ch === 'shout' || ch === 'guild' || ch === 'party')) { if (ch === 'say') BL.forceUntil = S.time + 8; blOnPlayerChat(ch, text); }
}
function blOnSys(t) {
  let m;
  if ((m = /^Level up! You are now level (\d+)/.exec(t))) blReactLevel(+m[1]);
  else if ((m = /^You have been slain(?: by (.+?))?\. You lost/.exec(t))) blReactDeath(m[1]);
  else if ((m = /^You murdered (\S+)\./.exec(t))) blReactMurder(m[1]);
  else if ((m = /^You have defeated (\S+)\./.exec(t))) { const nm = m[1]; if (R() < .5) setTimeoutGame(3 + R() * 4, () => chat('shout', blStyle(null, pick([`ty ${S.P.name} for killing ${nm}`, `${nm} finally dead lol`, `gj ${S.P.name}`])), blFreeName())); }
  else if ((m = /^Quest accepted: (.+)\.$/.exec(t))) { const q = QUESTS[S.P.q]; if (q && R() < .45) { const c = blBots(b => b.fq && b.fq.need === q.need && !b.party && !b.red && (!b.grp || b.grp.leader === b)); if (c.length && S.party.length < 4) { const b = pick(c); setTimeoutGame(8 + R() * 20, () => { if (!blAlive(b) || S.time < BL.nextPing - 30) return; BL.nextPing = S.time + 60; blWhisper(b, pick([`doing ${monSh(q.need)} too? wanna grp, kills share`, `u on ${q.name}? lets duo`, `saw u took ${q.name}, grp?`])); BL.pend[b.name.toLowerCase()] = { kind: 'lfg', t: S.time }; }); } } }
  else if (/^Your guild holds Castle Varn/.test(t)) { const G = S.P.guild; if (G) { const on = G.members.filter(x => x.on); for (let i = 0; i < Math.min(3, on.length); i++) setTimeoutGame(1 + i * 1.5 + R(), () => chat('guild', blStyle(on[i].name, pick(['GG!!', 'we did it', 'castle is ours', 'gg all', 'VARN!!', 'lets gooo'])), on[i].name)); } }
}
function blReactLevel(n) {
  const P = S.P; const near = blShuffle(blBots(b => blNear(b, 13) && !b.afk && !b.party));
  const k = Math.min(near.length, n % 10 === 0 ? 3 : (R() < .55 ? 1 : 0) + (R() < .2 ? 1 : 0));
  for (let i = 0; i < k; i++) { const b = near[i]; setTimeoutGame(1 + i * 1.6 + R() * 2, () => { if (blAlive(b)) blSayF(b, blStyle(b, pick(['gz', 'grats', 'gz!!', `gz ${n}`, 'gratz', 'gz :)', 'nice']))); }); }
  if (P.guild && R() < .7) setTimeoutGame(2 + R() * 4, () => { const on = P.guild ? P.guild.members.filter(x => x.on) : []; if (on.length) { const w = pick(on); chat('guild', blStyle(w.name, pick(['gz!', `gz ${P.name}`, `gz on ${n}`, 'grats', 'gz gz', `${n} already? nice`])), w.name); } });
  if (S.party.length && R() < .75) setTimeoutGame(1.5 + R() * 3, () => { const b = pick(S.party); if (b) chat('party', blStyle(b, pick(['gz!', 'gz', 'grats', `${n} nice`, 'ding!'])), b.name); });
  if (n >= 20 && n % 10 === 0 && R() < .5) setTimeoutGame(4 + R() * 6, () => chat('shout', blStyle(null, pick([`gz ${P.name} on ${n}!`, `grats ${P.name} lvl ${n}`])), blFreeName()));
}
function blReactDeath(kn) {
  const near = blBots(b => blNear(b, 12) && !b.afk && !b.party); const kb = kn ? blBotByName(kn) : null;
  if (near.length && R() < .6) { const b = pick(near); setTimeoutGame(1.5 + R() * 2, () => { if (blAlive(b)) blSayF(b, blStyle(b, pick(kb ? ['lol pker', 'report him', 'run next time', 'guards cant help u out here'] : ['rip', 'F', 'lol', 'u ok?', 'rip :(', 'that mob hits hard', 'need a tao next time']))); }); }
  if (S.party.length) setTimeoutGame(1 + R() * 2, () => { const b = pick(S.party); if (b) chat('party', blStyle(b, pick(['rip', 'noo', 'we wait for u', 'lol rip', 'come back', 'sry couldnt heal in time'])), b.name); });
  if (kb && (kb.red || kb.pkOn) && R() < .7) { const lm = blLandmark(S.map.id, kb.x, kb.y); setTimeoutGame(3 + R() * 4, () => chat('shout', blStyle(null, pick([`${kb.name} is pking at ${lm}!!`, `red name ${kb.name} ${lm}, stay away`, `careful ${lm}, ${kb.name} is red`])), blFreeName())); }
}
function blReactMurder(victim) {
  const P = S.P, lm = blLandmark(S.map.id, S.player.x, S.player.y);
  setTimeoutGame(3 + R() * 4, () => chat('shout', blStyle(victim, pick([`wtf ${P.name} just pked me at ${lm}`, `${P.name} is pking ${lm}!!`, `red name ${P.name} ${lm}, careful`])), victim));
  const near = blBots(b => blNear(b, 10) && !b.red && !b.party); if (near.length && R() < .6) { const b = pick(near); setTimeoutGame(1 + R(), () => { if (blAlive(b)) blSayF(b, blStyle(b, pick(['omg pker', 'run!!', 'wtf', 'guards!', 'not cool']))); }); }
}
function blOnSystemShout(t) {
  let m;
  if ((m = /^(.+) has appeared in (.+)!$/.exec(t))) blReactBossSpawn(m[1], m[2]);
  else if ((m = /^(.+) has been slain by (.+)!$/.exec(t))) blReactBossKill(m[1], m[2]);
  else if (/siege of Castle Varn has begun/.test(t)) { setTimeoutGame(2 + R() * 3, () => chat('shout', blStyle(null, pick(['SIEGE!!', 'go go go', 'everyone to varn', 'crimson dawn gonna lose again lol'])), blFreeName())); }
  else if ((m = /^(.+) has conquered Castle Varn!$/.exec(t))) { const g = m[1]; setTimeoutGame(2 + R() * 4, () => chat('shout', blStyle(null, pick([`gg ${g}`, 'gg', `${g} again?? lol`, 'rigged', `gz ${g}`])), blFreeName())); }
}
function blReactBossSpawn(name, mapName) {
  const id = Object.keys(MON).find(k => MON[k].name === name); if (!id) return; const sh = monSh(id);
  const a = blFreeName();
  setTimeoutGame(2 + R() * 4, () => chat('shout', blStyle(a, pick([`${sh} up!!`, `where is ${sh}?`, `omw ${sh}`, `grp for ${sh}?`, 'finally', `anyone want to kill ${sh}? ${rnd(15, 38)} ${clsSh(pick(['W', 'M', 'T']))}`])), a));
  if (R() < .5) { const b = blFreeName(); setTimeoutGame(7 + R() * 5, () => chat('shout', blStyle(b, pick(['its at the usual spot', 'already dead probably lol', 'ks incoming', `${sh} is mine, back off`, 'going'])), b)); }
  if (mapName === S.map.name) { const bs = (S.map.bosses || []).find(x => x.mon === id); if (bs) for (const b of blBots(b => b.mode === 'hunt' && !b.party && !b.red && (!b.grp || b.grp.leader === b) && (b.lv >= MON[id].lv - 6 || (b.fq && b.fq.need === id)))) if (R() < .5 || (b.fq && b.fq.need === id)) { b.huntC = [bs.x, bs.y]; b.target = null; b.thinkT = 0; } }
}
function blReactBossKill(name, who) {
  const P = S.P; const id = Object.keys(MON).find(k => MON[k].name === name); const sh = id ? monSh(id) : name.toLowerCase();
  for (const b of blBots(x => x.helpOff && !x.party && x.helpOff.boss === id && x.helpOff.state !== 'done')) { const off = b.helpOff; off.state = 'done'; b.come = null; b.helpOff = null; b.assistUntil = 0; if (who !== P.name) blTellAt(b, 'whisper', pick([`${monSh(id)} just died lol, some1 got it`, `rip, ${who} killed it`, `${monSh(id)} is dead, wait for respawn?`]), 2 + R() * 3); }
  if (who === P.name || S.party.some(b => b.name === who)) S.party.filter(b => b.helpOff && b.helpOff.boss === id).forEach((b, i) => { setTimeoutGame(2 + i * 1.5 + R() * 2, () => { if (b.party) chat('party', blStyle(b, pick(['gz on the kill', 'gg', 'ez', 'gz!!', 'nice'])), b.name); }); setTimeoutGame(10 + i * 2 + R() * 8, () => blHelpLeave(b, pick(['np, gtg gl!', 'np, cya', 'gl with ur quest', 'np :)']))); });
  if (who === P.name) {
    const near = blBots(b => blNear(b, 16) && !b.party);
    if (near.length) { const b = pick(near); setTimeoutGame(1.5 + R() * 2, () => { if (blAlive(b)) blSayF(b, blStyle(b, pick(['gz', 'what dropped?', 'ugh i wanted that', 'nice kill', 'gz, ks tho lol']))); }); }
    if (R() < .6) { const n = blFreeName(); setTimeoutGame(4 + R() * 4, () => chat('shout', blStyle(n, pick([`gz ${P.name}`, `what dropped ${P.name}?`, `${P.name} killed ${sh}?? nice`, 'gz'])), n)); }
    if (S.party.length) setTimeoutGame(1 + R(), () => { const b = pick(S.party); if (b) chat('party', blStyle(b, pick(['GG!!', 'gg', 'nice!!', 'what dropped', 'ez'])), b.name); });
    if (P.guild && R() < .6) setTimeoutGame(3 + R() * 3, () => { const on = P.guild ? P.guild.members.filter(x => x.on) : []; if (on.length) { const w = pick(on); chat('guild', blStyle(w.name, pick(['gz!!! what dropped', `gz on ${sh}`, 'nice'])), w.name); } });
    for (const b of blBots(b => b.fq && b.fq.need === id && !b.fq.done && blNear(b, 20))) if (R() < .4) { const bb = b; setTimeoutGame(2 + R() * 3, () => { if (blAlive(bb)) botSay(bb, blStyle(bb, pick(['ugh now i wait for respawn', 'missed it', 'rip my quest', 'gz, see u in ' + Math.round((MON[id].respawn || 300) / 60) + ' min lol']))); }); }
  } else {
    const kb = blBotByName(who);
    if (kb && R() < .5) setTimeoutGame(1.5, () => { if (blAlive(kb)) chat('shout', blStyle(kb, pick(['gg', `${sh} down`, 'got it!!', 'ez'])), kb.name); });
    else if (R() < .4) { const n = blFreeName(); setTimeoutGame(3 + R() * 3, () => chat('shout', blStyle(n, pick([`gz ${who}`, `ugh ${who} got it again`, 'gz'])), n)); }
    if (kb && kb.grp) for (const m of kb.grp.members) if (m.fq && m.fq.need === id) { blQuestDone(m); break; }
  }
}
function blReactRare(name) {
  const near = blBots(b => blNear(b, 12) && !b.afk && !b.party);
  if (near.length && R() < .8) { const b = pick(near); setTimeoutGame(1.2 + R() * 1.5, () => { if (blAlive(b)) blSayF(b, blStyle(b, pick(['omg', 'gz!!', 'nice drop', `wts ${name}? lol`, 'lucky', 'no way', 'gz, what stats?']))); }); }
  if (S.party.length && R() < .7) setTimeoutGame(1.5 + R(), () => { const b = pick(S.party); if (b) chat('party', blStyle(b, pick(['gz!!', 'nice!', 'lucky', 'omg'])), b.name); });
  if (R() < .45) setTimeoutGame(20 + R() * 40, () => {
    const it = S.P.inv.find(x => x && itemName(x) === name); if (!it || S.time < BL.nextPing - 40) return;
    const bot = blPickTrader(it) || null; const nm = bot ? bot.name : blFreeName();
    const o = blBuyOffer(bot, it); if (!o) return; o.price = blRound(Math.min(o.base * 2.6, o.base * (1.9 + R() * .6)));
    BL.nextPing = S.time + 60 + R() * 60;
    blWhisper(bot || nm, pick([`heard u got ${itemName(it)}, ${fmtK(o.price)}?`, `wtb ur ${itemName(it)} ${fmtK(o.price)}`, `selling that ${itemName(it)}? ill pay ${fmtK(o.price)}`]));
    BL.pend[nm.toLowerCase()] = { kind: 'wtb', offer: o, t: S.time };
  });
}

function blOnKill(e, src) {
  if (e.kind === 'mon') { if (src && src.kind === 'bot') blQuestCredit(src, e.def.id); return; }
  if (e.kind !== 'bot') return;
  const g = e.grp; const mates = g ? g.members.filter(m => m !== e) : []; blGroupRemove(e);
  if (TR.cur && TR.cur.bot === e) blTradeClose('gone');
  if (src && src.kind === 'bot' && (src.red || src.pkOn)) {
    const lm = blLandmark(S.map.id, e.x, e.y), nm = e.name, kn = src.name;
    setTimeoutGame(3 + R() * 4, () => { if (blQuiet(5, 10)) chat('shout', blStyle(nm, pick([`wtf ${kn} just pked me at ${lm}`, `${kn} is pking at ${lm}!!`, `red name ${kn} ${lm}, careful`])), nm); });
    return;
  }
  if (src && src.kind === 'mon' && blNear(e, 14)) {
    const nm = e.name;
    if (R() < .5) setTimeoutGame(.8, () => chat('say', blStyle(nm, pick(['lag!!', 'wtf', 'noooo', 'gg', 'rip me', 'omg that hurt', 'brb corpse run', 'why'])), nm));
    const o = mates.length ? pick(mates) : pick(blBots(b => b !== e && blNear(b, 12) && !b.party));
    if (o && R() < (mates.length ? .7 : .3)) setTimeoutGame(2 + R() * 2, () => { if (blAlive(o)) botSay(o, blStyle(o, pick(mates.length ? [`rip ${nm}`, 'noo', 'lol rip', 'res? jk', 'i told u not to pull that'] : ['lol', 'rip', 'F']))); });
  }
}

/* ---------- player chat intents ---------- */
function blOnPlayerChat(ch, text) {
  if (blConvPre(ch, text, null)) return;
  blOnPlayerIntent(ch, text);
}
function blOnPlayerIntent(ch, text) {
  const l = String(text).toLowerCase(); const P = S.P;
  const id = blItemIn(l);
  if (/\b(lfg|lf group|lf grp|looking for (a )?(group|grp|party)|any ?1 (want to |wanna )?(group|grp)|need (a )?(group|grp|party))\b/.test(l)) return blRespondLfg(ch);
  if (/\b(lfm|lf\dm|need (a )?(heal|healer|heals|tao|taoist|tank|war|warrior|wiz|wizard|dps))\b/.test(l)) return blRespondLfm(ch);
  if (id && /\b(wts|selling|sell|s>)\b/.test(l)) return blRespondWts(id);
  if (id && /\b(wtb|buying|buy|b>)\b/.test(l)) return blRespondWtb(id);
  if (/\bding\b/.test(l) || (id && /\b(got|dropped|drop|finally|looted)\b/.test(l) && !/\?/.test(l))) { const near = ch === 'say' ? blBots(b => blNear(b, 12) && !b.afk && !b.party) : []; const n = near.length ? pick(near) : null; setTimeoutGame(2 + R() * 3, () => { const t = pick(['gz', 'grats', 'gz!!', 'nice', 'gz :)']); if (n && blAlive(n)) blSayF(n, blStyle(n, t)); else if (ch === 'shout') chat('shout', blStyle(null, t), blFreeName()); }); return; }
  if (ch === 'say' && /\btrade\b/.test(l)) { const near = blBots(b => blNear(b, 8) && !b.red && !b.afk && !b.party); if (near.length) { const b = pick(near); setTimeoutGame(2 + R() * 2, () => { if (blAlive(b)) blReqTrade(b, null, null); }); } }
  if (ch === 'say' && P.pk >= 200) { const near = blBots(b => blNear(b, 10) && !b.red && !b.party); if (near.length && R() < .5) { const b = pick(near); blTellAt(b, 'say', pick(['dont talk to me pker', 'go away', 'lol no']), 2 + R() * 2); return; } }
  if (ch === 'say' && /\btrade\b/.test(l)) return;
  blConvReply(ch, text, null);
}
function blRespondLfg(ch) {
  const P = S.P; if (S.party.length >= 4) return;
  const c = blBots(b => !b.party && !b.red && !b.afk && b.mode !== 'town' && Math.abs(b.lv - P.lv) <= 7 && (!b.grp || (b.grp.leader === b && b.grp.members.length + S.party.length <= 4)) && (ch !== 'say' || blNear(b, 14)));
  if (!c.length) { if (ch === 'shout' && R() < .5) { const n = blFreeName(); setTimeoutGame(4 + R() * 5, () => chat('shout', blStyle(n, pick(['what lvl?', 'which map?', 'try mine, lots of ppl there'])), n)); } return; }
  const b = pick(c);
  setTimeoutGame(3 + R() * 4, () => {
    if (!blAlive(b) || b.party) return;
    blWhisper(b, b.grp ? pick([`we have ${b.grp.members.length}, join us? doing ${b.fq ? monSh(b.fq.need) : mapSh(S.map.id)}`, 'join our grp? sent inv']) : pick([`sent u inv, ${b.lv} ${clsSh(b.cls)}`, 'grp? sent inv', `inv sent, doing ${b.fq ? monSh(b.fq.need) : mapSh(S.map.id)}`]));
    setTimeoutGame(1.2, () => { if (blAlive(b) && !b.party && window.UI && UI.invitePrompt && S.party.length < 4) UI.invitePrompt(b); });
  });
}
function blRespondLfm(ch) {
  const P = S.P; if (S.party.length >= 4) return;
  const c = blShuffle(blBots(b => !b.party && !b.red && !b.afk && !b.grp && b.mode !== 'town' && Math.abs(b.lv - P.lv) <= 8));
  const k = Math.min(c.length, 1 + (R() < .4 ? 1 : 0));
  for (let i = 0; i < k; i++) { const b = c[i]; setTimeoutGame(3 + i * 3 + R() * 4, () => { if (!blAlive(b) || b.party) return; blWhisper(b, pick([`inv ${b.lv} ${clsSh(b.cls)}`, `can i join? ${b.lv} ${clsSh(b.cls)}`, `x ${b.lv} ${clsSh(b.cls)}`, `me! ${clsSh(b.cls)} ${b.lv}`, `${b.lv} ${clsSh(b.cls)} here, inv pls`])); BL.pend[b.name.toLowerCase()] = { kind: 'lfmjoin', t: S.time }; }); }
  if (!k && ch === 'shout' && R() < .6) { const n = blFreeName(); const lv = clamp(P.lv + rnd(-3, 3), 1, 40), cls = pick(['W', 'M', 'T']); setTimeoutGame(4 + R() * 4, () => { blWhisper(n, `inv ${lv} ${clsSh(cls)}`); BL.pend[n.toLowerCase()] = { kind: 'lfmjoin', t: S.time, lv, cls }; }); }
}
function blRespondWts(id) {
  const it = S.P.inv.find(x => x && x.id === id); if (!it) return;
  const bot = blPickTrader(it); const nm = bot ? bot.name : blFreeName(); const o = blBuyOffer(bot, it); if (!o) return;
  setTimeoutGame(3 + R() * 5, () => { blWhisper(bot || nm, pick([`${fmtK(o.price)} for ur ${itemName(it)}?`, `how much for ${itemName(it)}? i can do ${fmtK(o.price)}`, `ill take it, ${fmtK(o.price)}`])); BL.pend[nm.toLowerCase()] = { kind: 'wtb', offer: o, t: S.time }; });
}
function blRespondWtb(id) {
  const d = ITEMS[id]; const bot = blPickTrader(null); const nm = bot ? bot.name : blFreeName();
  if (d.raid || d.slot === 'quest' || d.slot === 'book') { if (R() < .5) setTimeoutGame(4 + R() * 4, () => blWhisper(bot || nm, pick([`lol nobody sells ${d.name}`, 'good luck with that', 'raid only item lol']))); return; }
  const it = makeItem(id, d.slot === 'cons' ? 5 : d.slot === 'mat' ? rnd(1, 3) : undefined); const base = sellPrice(it);
  const o = { mode: 'sell', item: it, base, price: blRound(base * (d.q ? 2.5 + R() * 1.0 : 1.5 + R() * .9)), haggles: 0, annoy: 0 };
  setTimeoutGame(4 + R() * 6, () => { blWhisper(bot || nm, pick([`got ${d.name}, ${fmtK(o.price)}`, `i have one, ${fmtK(o.price)}?`, `${d.name} ${fmtK(o.price)}, want?`])); BL.pend[nm.toLowerCase()] = { kind: 'wts', offer: o, t: S.time }; });
}

/* ---------- player whispers to bots ---------- */
function blParsePrice(l) { const m = /(\d+(?:[.,]\d+)?)\s*(k|m)?\b/.exec(l); if (!m) return null; let n = parseFloat(m[1].replace(',', '.')); if (m[2] === 'k') n *= 1000; else if (m[2] === 'm') n *= 1e6; return n >= 10 ? Math.round(n) : null; }
function blCanon(n) { const b = blBotByName(n); if (b) return b.name; const l = String(n).toLowerCase(); return BOT_NAMES.find(x => x.toLowerCase() === l) || (S.P.guild && (S.P.guild.members.find(m => m.name.toLowerCase() === l) || {}).name) || n; }
function blOnWhisperTo(msg, to) {
  if (!to) return; to = blCanon(to); const key = String(to).toLowerCase(); BL.hush[key] = S.time + 14;
  const l = String(msg).toLowerCase().trim(); const b = blBotByName(to); const pd = BL.pend[key];
  const YES = /^(y|ya|ye|yes|yea|yeah|yep|yup|sure|ok|okay|k|kk|deal|pls|plz|please|send|go|alright|fine|why not|inv|invite|come|trade)\b/.test(l) || /\b(sure|deal)\b/.test(l);
  const NO = /\b(no|nah|nope|pass|not interested|nty|no thx|no thanks)\b/.test(l) || l === 'n';
  const PRICE = /(how much|price|\bpc\b|cost)/.test(l); const num = blParsePrice(l);
  const dl = 2 + R() * 3;
  if (b && b.afk) { if (R() < .6) setTimeoutGame(20 + R() * 30, () => { if (blAlive(b)) blWhisper(b, pick(['sry was afk', 'back, what?', 'was afk'])); }); return; }
  if (blConvPre('whisper', msg, to)) return;
  if (pd && S.time - pd.t < 300) {
    const o = pd.offer;
    if (pd.kind === 'lfg') { if (YES) { delete BL.pend[key]; setTimeoutGame(dl, () => { if (blAlive(b) && !b.party && window.UI && UI.invitePrompt && S.party.length < 4) { blWhisper(b, 'sent'); UI.invitePrompt(b); } else blWhisper(to, 'nvm, found a grp sry'); }); return; } if (NO) { delete BL.pend[key]; setTimeoutGame(dl, () => blWhisper(b || to, pick(['ok np', 'k', 'np']))); return; } }
    if (pd.kind === 'lfmjoin') { if (YES) { delete BL.pend[key]; setTimeoutGame(dl, () => blJoinFromAfar(b, to, pd)); return; } if (NO) { delete BL.pend[key]; setTimeoutGame(dl, () => blWhisper(b || to, pick(['ok', 'k np', ':(']))); return; } }
    if (pd.kind === 'guild') { if (YES) { delete BL.pend[key]; setTimeoutGame(dl, () => { blWhisper(to, 'sent! welcome'); if (typeof joinGuild === 'function' && !S.P.guild) setTimeoutGame(1.5, () => joinGuild(pd.g.name, pd.g.notice, false)); }); return; } if (NO) { delete BL.pend[key]; setTimeoutGame(dl, () => blWhisper(to, pick(['ok, offer stands', 'np', 'k']))); return; } }
    if ((pd.kind === 'wtb' || pd.kind === 'wts') && o) {
      if (PRICE && !num) { setTimeoutGame(dl, () => blWhisper(b || to, pick([`${fmtK(o.price)}`, `${fmtK(o.price)}, good price`, `${fmtK(o.price)} like i said`]))); return; }
      if (num) {
        if (o.mode === 'sell') { if (num >= o.price * .85) { o.price = Math.max(num, blRound(o.base * 1.15)); delete BL.pend[key]; setTimeoutGame(dl, () => { blWhisper(b || to, pick([`ok ${fmtK(o.price)}, deal`, 'fine, deal', 'k deal, omw'])); blComeTrade(b, to, o); }); } else if (num >= o.price * .6) { o.price = blRound(Math.max((o.price + num) / 2, o.base * 1.15)); pd.t = S.time; setTimeoutGame(dl, () => blWhisper(b || to, pick([`meet in the middle, ${fmtK(o.price)}?`, `${fmtK(o.price)} lowest`]))); } else setTimeoutGame(dl, () => blWhisper(b || to, pick(['lol no', 'not that low', `${fmtK(o.price)} or nothing`]))); }
        else { if (num <= o.price * 1.15) { o.price = Math.min(num, blRound(o.base * 2.75)); delete BL.pend[key]; setTimeoutGame(dl, () => { blWhisper(b || to, pick([`ok ${fmtK(o.price)}`, 'deal', 'k deal, omw'])); blComeTrade(b, to, o); }); } else setTimeoutGame(dl, () => blWhisper(b || to, pick(['too much', `${fmtK(o.price)} max`, 'lol no']))); }
        return;
      }
      if (YES) { delete BL.pend[key]; setTimeoutGame(dl, () => { blWhisper(b || to, pick(['omw', 'k 1 sec', 'coming', 'where r u? omw'])); blComeTrade(b, to, o); }); return; }
      if (NO) { delete BL.pend[key]; setTimeoutGame(dl, () => { if (o.mode === 'sell' && R() < .35) { o.price = blRound(Math.max(o.base * 1.15, o.price * .85)); BL.pend[key] = { kind: pd.kind, offer: o, t: S.time }; blWhisper(b || to, `${fmtK(o.price)}? last offer`); } else blWhisper(b || to, pick(['ok np', 'ur loss', 'k', 'np, pm me if u change ur mind'])); }); return; }
    }
  }
  if (b && /\b(trade|wts|wtb|sell|buy|selling|buying)\b/.test(l) && !b.red) { setTimeoutGame(dl, () => { if (!blAlive(b)) return; blWhisper(b, pick(['sure, 1 sec', 'k omw', 'ok', 'what u got?'])); blComeTrade(b, to, null); }); return; }
  if (b && /\b(inv|invite|group|grp|party|join)\b/.test(l) && !b.red && !b.party) {
    setTimeoutGame(dl, () => { if (!blAlive(b)) return; const ok = !b.grp && b.act == null && Math.abs(b.lv - S.P.lv) <= 10 && R() < .7 || (b.grp && b.grp.leader === b && R() < .6);
      if (ok && S.party.length < 4 && window.UI && UI.invitePrompt) { blWhisper(b, pick(['sure, sent', 'k sent inv', 'ok'])); UI.invitePrompt(b); } else blWhisper(b, pick(['no thx', 'solo atm', 'maybe later', b.grp ? 'grp is full sry' : 'busy atm'])); });
    return;
  }
  blConvReply('whisper', msg, to);
}
function blMaterialize(name, o) {
  const p = S.player; if (!p || blBotCount() >= BOTMAX + 2) return null;
  const s = randomFree(S.map, p.x, p.y, 3, (x, y) => cheb(x, y, p.x, p.y) >= 2) || nearFree(S.map, p.x + 2, p.y); o = o || {};
  const mo = { lv: o.lv || clamp(S.P.lv + rnd(-4, 6), 1, 40), mode: inSafe(s[0], s[1]) ? 'town' : 'hunt' }; if (o.cls) mo.cls = o.cls;
  const b = makeBot(s[0], s[1], mo); b.name = name; b.pers = blPers(name); b.huntC = [s[0], s[1]]; b.plan = ['wander', 'logout']; b.role = 'visitor'; b.life = 120 + R() * 120;
  fx('pillar', epx(b), epy(b), { dur: .8, col: '140,180,255' }); sfx('portal');
  return b;
}
function blJoinFromAfar(b, name, pd) {
  if (S.party.length >= 4) { blWhisper(b || name, 'nvm ur full'); return; }
  if (!b) { b = blMaterialize(name, { lv: pd.lv, cls: pd.cls }); if (!b) return; }
  if (!blNear(b, 16)) { const p = S.player; const s = randomFree(S.map, p.x, p.y, 3) || nearFree(S.map, p.x, p.y); fx('pillar', epx(b), epy(b), { dur: .5, col: '140,180,255' }); teleportEnt(b, s[0], s[1]); fx('pillar', epx(b), epy(b), { dur: .8, col: '140,180,255' }); }
  joinParty(b);
}
function blComeTrade(b, name, offer) {
  if (!b || !blAlive(b)) { b = blMaterialize(name); if (!b) return; }
  b.come = { until: S.time + 50, t0: S.time, fn: () => { if (blAlive(b)) botTradeUI(b, offer && blOfferValid(offer) ? offer : null); } };
  if (b.mode === 'travel') { b.mode = 'hunt'; b.route = null; }
  if (b.grp && b.grp.leader !== b) blGroupRemove(b);
}

/* ---------- smart keyword replies (replaces js6 replyFor at runtime) ---------- */
function blSmartReply(v, b) {
  const l = String(v || '').toLowerCase(); const Rr = arr => blStyle(b || null, pick(arr));
  if (/\b(gz|grats|gratz|congrats)\b/.test(l)) return Rr(['ty', 'thx :)', 'ty ty', 'thanks']);
  if (/\b(ty|thx|thanks|thank you|tyvm)\b/.test(l)) return Rr(['np', 'no prob', 'anytime', 'yw']);
  if (/\b(hi|hey|hello|yo|sup|hiya)\b|o\//.test(l)) return Rr(['hey', 'hi!', 'yo', 'sup', 'hello', 'o/']);
  if (/\bwhere\b|how do i get/.test(l)) {
    if (/mine/.test(l)) return Rr(['north west of town, follow the road', 'nw of ashvale, big cave', 'up the north road then west']);
    if (/mirewood|forest|\bmw\b/.test(l)) return Rr(['east exit of ashvale', 'go east from town', 'follow the east road']);
    if (/temple|khar/.test(l)) return Rr(['far east side of mirewood', 'end of mirewood, go east']);
    if (/elder|rowan|quest/.test(l)) return Rr(['by the fountain in town', 'Elder Rowan, middle of town']);
    if (/\bore\b|black iron/.test(l)) return Rr(['mine, skeles and zombies drop it', 'hollow mine']);
    if (/pot|potion/.test(l)) return Rr(['Wen in town sells them', 'top right house in town']);
    if (/book|skill/.test(l)) return Rr(['Sage Orrin, bottom left house', 'bookseller in town']);
    const id = blItemIn(l); if (id) { const src = blDropSrc(id); if (src.length) { const m = pick(src); return Rr([`${m.name} drops it`, `${monSh(m.id)} in ${mapSh(BL_MONMAP[m.id])}`, `${m.name} i think`]); } return Rr(['shop in town i think', 'no idea', 'buy it in town']); }
  }
  const bid = /tusk/.test(l) ? 'old_tusk' : /bone ?king|\bbk\b/.test(l) ? 'bone_king' : /warlord/.test(l) ? 'goblin_warlord' : /\bmino|minotaur/.test(l) ? 'minotaur' : null;
  if (bid) return blStyle(b, blBossStatus(bid));
  if (/\b(lvl|level)\b/.test(l) && /\?/.test(l)) return Rr(b ? [`${b.lv}`, `im ${b.lv}`, `${b.lv} ${clsSh(b.cls)}`] : ['like 12+', 'depends on class', '15ish']);
  if (/\b(inv|invite|group|grp|party|join)\b/.test(l)) return Rr(['sure, invite me', 'full atm sorry', 'what lvl?', 'k', 'maybe later']);
  if (/\b(wts|selling|sell)\b/.test(l)) return Rr(['how much?', 'what stats?', 'pass', 'pc?']);
  if (/\b(wtb|buying|buy)\b/.test(l)) return Rr(['what u need?', 'might have one, pm me', 'check the vendors in town']);
  if (/\b(pk|pker|red name|pked)\b/.test(l)) return Rr(['where?', 'report him', 'lol pkers', 'guards wont help outside town']);
  if (/\bhelp\b/.test(l)) return Rr(['what do u need?', 'go to Elder Rowan in town', 'sure where r u?']);
  if (/\b(lol|lmao|haha|xd)\b/.test(l)) return Rr(['lol', 'haha', 'xD', 'lmao']);
  if (/\bgg\b/.test(l)) return Rr(['gg', 'gg wp']);
  if (/\b(bot|bots|botting|npc)\b/.test(l)) return Rr(['?', 'lol what', 'no u', 'im real lol', 'beep boop']);
  if (/\?\s*$/.test(l)) return Rr(['dunno', 'no idea sry', 'idk', 'ask in shout', 'not sure']);
  for (const k in REPLIES) if (l.includes(k)) return blStyle(b, pick(REPLIES[k]));
  return null;
}

/* ================= CONVERSATION & HELP =================
   js6's canned auto-replies are silenced (replyFor returns BL_SIL, which the chat/botSay/whisper wrappers drop);
   every answer to the player comes from here, with memory per bot name. */
const BL_SIL = '\u0001';
const BL_RUDE = /\b(noob|nub|n00b|stfu|shut up|idiot|stupid|moron|loser|trash|dumb|ugly|f+u+c+k\w*|fk off|f off|kys|scrub|useless)\b/;
const BL_THX = /\b(ty|tyvm|tysm|thx|thnx|thanks|thank you|thank u|cheers)\b/;
const BL_YES = /^(y|ya|ye|yes|yea|yeah|yep|yup|sure|ok|okay|k|kk|pls|plz|please|go|alright|come|inv|invite|ofc|deal|yes pls|yes please|ok pls)\b/;
const BL_NO = /^(no|nah|nope|n|nvm|nevermind|never mind|im ok|i'?m ok|im fine|i'?m fine|im good|i'?m good|all good|its ok|it'?s fine|dont|don'?t|no need)\b|\b(nvm|never ?mind|no thanks|no thx|nty|dont need)\b/;
const BL_MONWHERE = { hen: 'east of town, hen field', deer: 'north east meadow', scarecrow: 'at the farms south of town', wildcat: 'south east of town, some west too', wildcat_brute: 'far south west', boar: 'north east, near tusk', old_tusk: 'far north east corner of ashvale', cave_bat: 'mine entrance', maggot: 'mine entrance', skeleton: 'mine, first tunnels', axe_skeleton: 'middle of the mine', zombie: 'middle of the mine', bone_fighter: 'deep mine', rot_zombie: 'deep mine', bone_king: 'deepest room of the mine, bottom right', goblin: 'mirewood, right at the entrance', goblin_fighter: 'mirewood entrance', goblin_shaman: 'middle of mirewood', spider: 'deeper in mirewood', black_boar: 'middle of mirewood', snake: 'middle of mirewood', goblin_brute: 'east mirewood', goblin_warlord: 'mirewood, big camp south east', moth: 'temple entrance', temple_archer: 'temple, first halls', stone_guardian: 'inner temple', cultist: 'inner temple', khar_elite: 'deep temple', minotaur: 'temple boss room, far east' };
const BL_NPCWHERE = [[/\b(elder|rowan)\b/, 'Elder Rowan is by the fountain in town'], [/\b(lys|gatekeeper|teleporter)\b/, 'Lys, right next to the fountain'], [/\b(kael|guild ?master)\b/, 'Kael, bottom right house in town'], [/\b(borin|weapon ?smith|weapon shop)\b/, 'Borin, top left house in town'], [/\b(hilda|armou?rer|armou?r shop)\b/, 'Hilda, top left, 2nd house'], [/\b(mira|jewell?er)\b/, 'Mira, top right, 2nd house'], [/\b(wen|pots?|potions?|apothecary)\b/, 'Wen sells pots, top right house in town'], [/\b(orrin|books?|skill ?books?|sage)\b/, 'Sage Orrin, bottom left house'], [/\b(grom|blacksmith|smith)\b/, 'Grom, bottom left, 2nd house'], [/\b(tam|storage|bank)\b/, 'Tam, bottom right, 2nd house']];
const BL_MAPWHERE = { ashvale: 'town is the walled bit in the middle of ashvale', mine: 'north west of town, north road then west', mirewood: 'east exit of ashvale, follow the road east', temple: 'through mirewood, far east side', sanctum: 'talk to Lys, need lvl 30 + a grp' };
const BL_MAPLV = { ashvale: 'lvl 1-14', mine: 'like 10-22', mirewood: '16-30', temple: '25+ with a grp', sanctum: '30+, raid grp' };
BL.mem = {}; BL.helpAsks = []; BL.lastTypo = null;
function blMem(name) { const k = String(name).toLowerCase(); return BL.mem[k] || (BL.mem[k] = { mood: 0, topic: null, off: null, lastT: -99, said: [] }); }
function blTrait(name) { const p = blPers(name); if (!p.help) p.help = pickW([['helpful', .25], ['situational', .5], ['selfish', .25]]); return p.help; }
function blLvSpot(lv) { return lv < 4 ? 'hens and deer near town' : lv < 7 ? 'scarecrows at the farms south of town' : lv < 11 ? 'cats south east of town' : lv < 16 ? 'the mine, skeles' : lv < 20 ? 'deeper mine or mirewood entrance' : lv < 26 ? 'mirewood' : lv < 30 ? 'temple entrance' : 'inner temple, or sanctum w/ a grp'; }
function blMapIn(l) { return /\bmine\b|hollow|\bhm\b/.test(l) ? 'mine' : /mirewood|forest|\bmw\b/.test(l) ? 'mirewood' : /temple|khar/.test(l) ? 'temple' : /sanctum|\braid\b/.test(l) ? 'sanctum' : /\btown\b|ashvale/.test(l) ? 'ashvale' : null; }
function blBossIn(l) { return /tusk/.test(l) ? 'old_tusk' : /bone ?king|\bbk\b/.test(l) ? 'bone_king' : /warlord/.test(l) ? 'goblin_warlord' : /\bmino(taur)?\b/.test(l) ? 'minotaur' : null; }
function blMonIn(l) { for (const id in MON) { const m = MON[id]; if (m.boss || BL_MONMAP[id] === 'sanctum') continue; if (l.includes(m.name.toLowerCase()) || (BL_MONSH[id] && new RegExp('\\b' + BL_MONSH[id] + '\\b').test(l))) return id; } return null; }
function blDirTo(x, y) { const p = S.player; const dx = x - p.x, dy = y - p.y; const ns = dy < -8 ? 'north' : dy > 8 ? 'south' : '', ew = dx < -8 ? 'west' : dx > 8 ? 'east' : ''; return (ns + (ns && ew ? ' ' : '') + ew) || 'right here'; }
function blDelay(t) { return 1.8 + R() * 2.5 + Math.min(4, String(t).length / 12); }

/* ---------- output: styled, with the odd typo fixed by a "*word" follow-up ---------- */
function blPost(b, name, ch, s) {
  if (ch === 'say') { if (b && blAlive(b) && blNear(b, 15)) { blSayF(b, s); return; } ch = 'whisper'; }
  if (ch === 'party' && !(b && b.party)) ch = 'whisper';
  if (ch === 'whisper') { BL.own = 1; try { _blWhisperFrom(name, s); } finally { BL.own = 0; } return; }
  chat(ch, s, name);
}
function blTell(who, ch, text) {
  if (!who || !text) return; const b = typeof who === 'object' ? who : null; const name = b ? b.name : String(who);
  if (b && !blAlive(b) && !b.party) return;
  const s = blStyle(b || name, text); const ty = BL.lastTypo;
  blPost(b, name, ch, s); blMem(name).lastT = S.time;
  if (ty && R() < .5) setTimeoutGame(1.2 + R() * 1.6, () => blPost(b, name, ch, '*' + ty));
}
function blTellAt(who, ch, text, t) { setTimeoutGame(t, () => blTell(who, ch, text)); }
function blTellLater(who, ch, text) { blTellAt(who, ch, text, blDelay(text)); }

/* ---------- who is listening ---------- */
function blAddressed(ch, l) {
  if (ch !== 'say' && ch !== 'shout') return null;
  for (const b of S.ents) { if (b.kind !== 'bot' || b.dead || b.gone) continue; if (ch === 'say' && !blNear(b, 25)) continue; if (new RegExp('\\b' + b.name.toLowerCase().replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\b').test(l)) return b; }
  return null;
}
function blRecentPartners(ch) { const out = []; for (const k in BL.mem) { const m = BL.mem[k]; if (S.time - m.lastT > 45) continue; const b = blBotByName(k); if (ch === 'say' ? (b && blNear(b, 15) && !b.afk) : ch === 'party' ? (b && b.party) : true) out.push(b ? b.name : k); } return out; }
function blListeners(ch, toName) {
  const P = S.P, out = []; const add = (b, name, lv, cls, guild) => { if (!out.some(o => o.name === name)) out.push({ b, name, lv, cls, guild, d: b ? cheb(b.x, b.y, S.player.x, S.player.y) : 999 }); };
  if (ch === 'whisper') { const b = blBotByName(toName); if (b) add(b, b.name, b.lv, b.cls, b.guild); else { const gm = P.guild && P.guild.members.find(m => m.name.toLowerCase() === String(toName).toLowerCase()); add(null, toName, gm ? gm.lv : clamp(P.lv + rnd(-5, 8), 1, 40), gm ? gm.cls : pick(['W', 'M', 'T']), gm ? P.guild.name : null); } return out; }
  if (ch === 'guild') { if (!P.guild) return out; for (const m of P.guild.members) if (m.on) { const b = blBotByName(m.name); if (!(b && b.party)) add(b, m.name, b ? b.lv : m.lv, b ? b.cls : m.cls, P.guild.name); } for (const b of blBots(x => x.guild === P.guild.name && !x.party)) add(b, b.name, b.lv, b.cls, b.guild); return out; }
  for (const b of blBots(x => !x.party)) { if (ch === 'say' && !blNear(b, 13)) continue; add(b, b.name, b.lv, b.cls, b.guild); }
  if (ch === 'shout') { const n = rnd(2, 4); for (let i = 0; i < n; i++) add(null, blFreeName(), clamp(P.lv + rnd(-6, 12), 1, 40), pick(['W', 'W', 'M', 'T']), R() < .5 ? pick(GUILDS).name : null); }
  return out;
}

/* ---------- asking for help ---------- */
function blHelpIntent(l) {
  if (/\b(lfm|lfg|lf\dm|wts|wtb)\b/.test(l)) return null;
  if (!(/\b(help|halp|hlp|sos|dying|stuck|lost|carry|rescue)\b|save me|heal (me|pls|plz)|heals? (pls|plz)|need heals?|low hp|can (some ?1|some ?one|any ?1|any ?one|u|you|ya|somebody) help|need (a )?hand|gonna die/.test(l))) return null;
  const boss = blBossIn(l), mon = blMonIn(l); let kind = 'general';
  if (/dying|low hp|save me|heal|gonna die|rescue|\bsos\b/.test(l)) kind = 'heal';
  else if (/\bcarry\b/.test(l)) kind = 'carry';
  else if (/\bstuck\b/.test(l)) kind = 'stuck';
  else if (/\blost\b/.test(l)) kind = 'lost';
  else if (boss) kind = 'boss';
  else if (mon || /\bkill\b/.test(l)) kind = 'kill';
  else if (/\bquest\b/.test(l)) kind = 'quest';
  return { kind, boss, mon };
}
function blHelpChance(o, ch, h) {
  const P = S.P, b = o.b, tr = blTrait(o.name), mem = blMem(o.name);
  if (P.pk >= 200) return 0;
  let pr = tr === 'helpful' ? .6 : tr === 'situational' ? .22 : .04;
  if (P.pk >= 100) pr *= .3;
  pr *= { say: 1.3, shout: .35, guild: 1.1, whisper: 1.7 }[ch] || 1;
  if (P.guild && o.guild === P.guild.name) pr *= 2.3;
  if (b) {
    if (b.afk || b.red || b.pkOn || b.wrapping || (TR.cur && TR.cur.bot === b) || (b.helpOff && b.helpOff.state !== 'done')) return 0;
    if (b.act && b.act.k === 'vendor') pr *= .15; if (b.target && !b.target.dead && b.target.kind === 'mon') pr *= h.kind === 'heal' ? .8 : .45; if (b.grp) pr *= .4; if (b.mode === 'travel') pr *= .7;
    if (o.d < 15) pr *= 1.25; else if (o.d > 60) pr *= .7;
  }
  const need = h.kind === 'boss' ? MON[h.boss].lv - 4 : h.kind === 'kill' && h.mon ? MON[h.mon].lv - 2 : P.lv - 3;
  if (h.kind !== 'lost' && h.kind !== 'stuck') { if (o.lv < need) pr *= .12; else if (o.lv >= P.lv + 10) pr *= 1.2; }
  if (h.kind === 'heal') { pr *= o.cls === 'T' ? 1.8 : .7; if (S.player.hp > S.player.maxhp * .85) pr *= .3; }
  if (h.kind === 'carry') pr *= .35;
  pr *= 1 + .25 * clamp(mem.mood, -3, 3);
  if (BL.helpSpam >= 2) pr *= .25;
  return clamp(pr, 0, .95);
}
function blOnHelp(ch, h, toName) {
  const P = S.P, p = S.player;
  const key = ch === 'whisper' ? 'w:' + String(toName).toLowerCase() : ch === 'say' || ch === 'shout' ? 'pub' : ch;
  BL.helpAsks = BL.helpAsks.filter(a => S.time - a[0] < 75); const spam = BL.helpAsks.filter(a => a[1] === key).length; BL.helpAsks.push([S.time, key]); BL.helpSpam = spam;
  if ((h.kind === 'general' || h.kind === 'kill') && p.target && !p.target.dead && p.target.kind === 'mon' && p.target.def.boss) { h.kind = 'boss'; h.boss = p.target.def.id; }
  const urgent = h.kind === 'heal';
  /* your group mates always react */
  if (S.party.length && (ch === 'party' || ch === 'say')) {
    S.party.forEach((b, i) => { if (b.dead || (i > 0 && R() < .5) || (ch === 'say' && R() < .4)) return; const t = 1.5 + i * 1.8 + R() * 2.5;
      if (b.cls === 'T' && p.hp < p.maxhp * .8) { blTellAt(b, 'party', pick(['healing', 'got u', 'heal inc', 'hold on']), t); setTimeoutGame(t, () => blHealPlayer(b, 2)); }
      else blTellAt(b, 'party', pick(h.kind === 'boss' ? ['on it', 'lets go', 'focus the boss'] : ['on it', 'where?', 'coming', 'omw', 'what is it?']), t); });
    if (ch === 'party') return;
  }
  const L = blListeners(ch, toName);
  if (spam >= 2) {
    const act = blBots(b => b.helpOff && !b.party && ['offered', 'coming', 'arrived', 'invited'].includes(b.helpOff.state))[0];
    if (act) { const st = act.helpOff.state; blTellAt(act, blNear(act, 15) ? 'say' : 'whisper', pick(st === 'coming' ? ['omw, chill', 'coming!', 'im coming relax'] : st === 'offered' ? ['i said i can help lol', 'inv me then', 'im here, inv'] : ['im right here lol', 'inv me then', 'accept the inv lol']), 2 + R() * 3); if (R() < .5) blMem(act.name).mood -= .5; return; }
    const o = L.length ? pick(L) : null; if (o && R() < .7) blTellAt(o.b || o.name, ch === 'whisper' ? 'whisper' : ch, pick(['u asked already', 'lol', 'patience', 'chill', 'we heard u', 'spam more lol', 'someone will come, relax']), 3 + R() * 4);
    for (const x of L) if (x.b && blNear(x.b, 13)) blMem(x.name).mood -= .5;
    if (R() < .85) return;
  }
  const maxOff = ch === 'whisper' ? 1 : urgent && ch === 'say' ? pickW([[1, .65], [2, .35]]) : pickW([[0, .22], [1, .52], [2, .26]]);
  let offers = 0, snark = 0, t = urgent ? 1.5 : 3;
  const order = blShuffle(L.slice()).sort((a, b) => blHelpChance(b, ch, h) - blHelpChance(a, ch, h) + (R() - .5) * .3);
  for (const o of order) {
    const c = blHelpChance(o, ch, h);
    if (offers < maxOff && R() < c) { offers++; blHelpOffer(o, ch, h, t + R() * (urgent ? 2 : 5)); t += 3 + R() * 4; continue; }
    const sp = ch === 'shout' ? .1 : ch === 'say' ? .22 : ch === 'guild' ? .3 : .75;
    if (snark < 1 && R() < sp) { snark++; blHelpDecline(o, ch, h, 4 + R() * 8); }
  }
}
function blHelpOffer(o, ch, h, dl) {
  const P = S.P, name = o.name, mem = blMem(name); const bs = h.boss ? monSh(h.boss) : null; const q = QUESTS[P.q];
  let lines;
  switch (h.kind) {
    case 'boss': lines = [`i can help w/ ${bs}, inv`, `${bs}? im ${o.lv}, i can come`, `omw to ${bs}`, 'omw', `need a ${clsSh(o.cls)} for ${bs}?`]; break;
    case 'heal': lines = o.cls === 'T' ? ['omw with heals', 'hold on, coming', 'coming!!', 'where r u? ill heal'] : ['pot up! omw', 'hang on, omw', 'run to me', 'omw']; break;
    case 'kill': lines = [`i can help w/ ${h.mon ? monSh(h.mon) : 'that'}`, 'omw', 'sure, where r u?', 'i can help, inv me']; break;
    case 'carry': lines = ['how much u paying lol', 'sure, im bored', 'what lvl r u?']; break;
    case 'stuck': lines = ['where r u stuck?', 'omw', 'use a random tp scroll, or ill come']; break;
    case 'quest': lines = P.qa && q ? [`${q.name}? i can help`, `${monSh(q.need)}? omw`, 'what quest?'] : ['what quest?', 'which one?', 'sure what quest']; break;
    case 'lost': { mem.topic = { lost: 1 }; mem.lastT = S.time; const t2 = blLostLine(); blTellAt(o.b || name, ch === 'shout' ? 'whisper' : ch, t2, dl); return; }
    default: lines = ['i can help, where r u?', 'what do u need?', 'omw', 'sure, what lvl?', 'i can help, inv me', 'whats up?'];
  }
  const line = pick(lines); const proactive = h.kind === 'boss' || /\bomw\b|coming|hold on|hang on|run to me/.test(line);
  const rch = ch === 'shout' ? (o.b && blNear(o.b, 14) ? 'say' : R() < .75 ? 'whisper' : 'shout') : ch === 'guild' ? 'guild' : ch;
  const off = { kind: h.kind, boss: h.boss, mon: h.mon, t: S.time + dl, ch, rch, state: 'offered', accepted: false, lv: o.lv, cls: o.cls, name, bot: o.b, askedQ: /\?/.test(line) };
  mem.off = off; mem.topic = { help: 1, boss: h.boss, mon: h.mon }; mem.lastT = S.time + dl;
  if (o.b) o.b.helpOff = off;
  setTimeoutGame(dl, () => {
    if (off.cancel) return;
    blTell(o.b && blAlive(o.b) ? o.b : name, rch, line);
    if (h.kind === 'heal' && o.b && blAlive(o.b)) { if (o.cls === 'T' && blNear(o.b, 10)) blHealPlayer(o.b, 2); else if (blNear(o.b, 9)) o.b.assistUntil = S.time + 20; }
    if (proactive) blHelpGo(o.b, name, off);
  });
}
function blHelpDecline(o, ch, h, dl) {
  const b = o.b, P = S.P; let L;
  if (P.pk >= 100) L = ['lol no pker', 'no', 'help urself pker', 'nope'];
  else if (h.kind === 'heal' && S.player.hp > S.player.maxhp * .85) L = ['ur full hp lol', '?', 'u look fine'];
  else if (b && b.target && !b.target.dead && b.target.kind === 'mon') L = ['busy sry', 'cant, fighting', 'sec, busy'];
  else if (b && (b.grp || (b.act && b.act.k === 'vendor'))) L = ['in a grp sry', 'busy sry', 'cant rn'];
  else if (h.kind === 'boss' && o.lv < MON[h.boss].lv - 4) L = [`too low for ${monSh(h.boss)} sry`, `lol im ${o.lv}`, `${monSh(h.boss)} would kill me`];
  else if (h.kind === 'carry') L = ['lol no', 'carry urself', 'how much? jk no', 'no'];
  else if (h.kind === 'stuck') L = ['use a random tp scroll', 'town scroll?', 'relog lol'];
  else if (h.kind === 'lost') L = [blLostLine(), 'open ur map (M) lol'];
  else if (blTrait(o.name) === 'selfish') L = ['lol no', 'ask in shout', 'no', 'do it urself', 'git gud', 'nah'];
  else L = ['busy sry', 'cant rn', 'ask in shout', 'use pots', 'go with a grp', 'ask ur guild', h.kind === 'boss' ? `${monSh(h.boss)} needs a grp, try shout` : 'sry doing my quest'];
  blTellAt(b || o.name, ch === 'shout' ? (R() < .7 ? 'shout' : 'whisper') : ch, pick(L), dl);
}
function blLostLine() {
  const P = S.P, q = QUESTS[P.q], m = S.map.id;
  if (m !== 'ashvale') return pick(['use a town scroll', `exit is ${blLandmark(m, S.map.start.x, S.map.start.y)}`, 'town scroll, then ask Elder Rowan']);
  if (P.qa && q && BL_MONWHERE[q.need] && R() < .5) return pick([`for ${q.name}? ${monSh(q.need)} are ${BL_MONWHERE[q.need]}`, `${monSh(q.need)} are ${BL_MONWHERE[q.need]}`]);
  if (inSafe(S.player.x, S.player.y)) return pick(['ur in town lol', 'open ur map (M)', 'Elder Rowan by the fountain gives quests']);
  return pick([`town is ${blDirTo(76, 59)} of u`, `go ${blDirTo(76, 59)}, u'll hit town`, 'open ur map (M) lol']);
}
function blHealPlayer(b, n) {
  const p = S.player; if (!blAlive(b) || !p || S.dead || cheb(b.x, b.y, p.x, p.y) > 9) return;
  b.cast = 0; b.castDur = .45; blFace(b, p); const amt = Math.round(b.lv * 1.8 + 12);
  setTimeoutGame(.3, () => { if (!S.dead && blAlive(b)) { p.hp = Math.min(p.maxhp, p.hp + amt); healFx(p, amt); sfx('heal'); } });
  if (n > 1) setTimeoutGame(2.4 + R(), () => { if (p.hp < p.maxhp * .8) blHealPlayer(b, n - 1); });
}
/* follow-through: walk (or portal) to the player, then group up */
function blHelpGo(b, name, off) {
  if (off.cancel || off.going) return; off.going = true; off.state = 'coming';
  const p = S.player;
  if (b && blAlive(b)) {
    if (b.party) { off.state = 'joined'; return; }
    b.helpOff = off; off.bot = b; b.act = null; b.plan = []; b.route = null; b.mode = 'hunt'; b.huntC = [b.x, b.y]; b.target = null; b.holdT = 0; b.afk = false; if (b.grp) blGroupRemove(b);
    b.wrapping = false; b.life = Math.max(b.life || 0, S.time - (b.born || 0) + 500);
    let at = null; if (off.boss && BL_BOSSMAP[off.boss] === S.map.id) { const bs = (S.map.bosses || []).find(x => x.mon === off.boss); if (bs && cheb(p.x, p.y, bs.x, bs.y) > 20) at = [bs.x, bs.y]; }
    b.come = { until: S.time + (at ? 220 : 100), t0: S.time, help: true, at, fn: () => blHelpArrive(b) };
    return;
  }
  setTimeoutGame(8 + R() * 10, () => { if (off.cancel || S.dead) return; const nb = blMaterialize(name, { lv: off.lv, cls: off.cls }); if (!nb) return; nb.mode = 'hunt'; nb.plan = []; nb.life = 900; nb.helpOff = off; off.bot = nb; if (R() < .5) blTell(nb, 'say', pick(['tp to u', 'used a scroll lol', 'here'])); setTimeoutGame(1.5, () => blHelpArrive(nb)); });
}
function blHelpArrive(b) {
  const off = b.helpOff; if (!off || off.cancel || !blAlive(b)) return;
  const p = S.player; blFace(b, p); off.state = 'arrived'; off.arriveT = S.time; b.assistUntil = S.time + 45;
  if (off.kind === 'heal' && b.cls === 'T') blHealPlayer(b, 2);
  blTell(b, 'say', off.kind === 'boss' ? pick([`here, rdy for ${monSh(off.boss)}?`, 'here', 'ok im here', 'lets go']) : off.kind === 'heal' ? (b.cls === 'T' ? pick(['healing u', 'here, got u']) : pick(['here, u ok?', 'here'])) : pick(['here', 'im here', 'ok here, what do u need?', 'here, inv me', 'which one?']));
  if (b.party) return;
  if (S.party.length >= 4) { blTellAt(b, 'say', 'ur grp is full, ill just help', 2.5); b.assistUntil = S.time + 90 + R() * 60; return; }
  if (off.accepted) { setTimeoutGame(1.2 + R(), () => { if (blAlive(b) && !b.party && S.party.length < 4) joinParty(b); }); return; }
  setTimeoutGame(2 + R() * 2, () => { if (!blAlive(b) || b.party || off.cancel || S.party.length >= 4) return; if (window.UI && UI.invitePrompt) { UI.invitePrompt(b); off.state = 'invited'; off.inviteT = S.time; if (R() < .5) blTell(b, 'whisper', pick(['sent inv', 'inv sent', 'accept inv'])); } });
}
function blHelpLeave(b, line) {
  if (!b || !b.party) return; chat('party', blStyle(b, line), b.name);
  const off = b.helpOff; if (off) off.state = 'done'; b.helpOff = null; leaveParty(b);
  if (R() < .5) setTimeoutGame(1 + R() * 2, () => { if (blAlive(b)) botLeave(b, 'teleport'); });
}
function blHelpStay(off) { return off.kind === 'boss' ? 480 + R() * 240 : off.kind === 'heal' ? 70 + R() * 80 : off.kind === 'carry' ? 240 + R() * 300 : 120 + R() * 200; }
function blAssistAI(e) {
  const p = S.player; if (S.dead || !p) return false;
  if (e.target && (e.target.dead || e.target.kind !== 'mon')) e.target = null;
  const pt = p.target;
  if (pt && !pt.dead && pt.kind === 'mon' && !blBossProtected(pt) && cheb(pt.x, pt.y, p.x, p.y) < 12) e.target = pt;
  else if (!e.target) for (const m of S.ents) if (m.kind === 'mon' && !m.dead && m.target === p && cheb(m.x, m.y, p.x, p.y) < 8) { e.target = m; break; }
  if (e.cls === 'T' && p.hp < p.maxhp * .55 && S.time > (e.healAt || 0) && blNear(e, 9)) { e.healAt = S.time + 3; blHealPlayer(e, 1); return true; }
  if (!e.target) { if (cheb(e.x, e.y, p.x, p.y) > 3) botMove(e, p.x, p.y, 2); return true; }
  return false;
}
function blHelpTick() {
  const p = S.player; if (!p) return;
  for (const b of S.ents) {
    if (b.kind !== 'bot' || b.dead || !b.helpOff) continue; const off = b.helpOff;
    if (off.cancel || off.state === 'done') { if (!b.party) b.helpOff = null; continue; }
    if (!b.party && (off.state === 'arrived' || off.state === 'invited') && S.time - off.arriveT > 40) { off.state = 'done'; if (R() < .6) blTell(b, 'whisper', pick(['k nvm', 'ok, gl then', 'nvm, gl'])); b.assistUntil = 0; b.helpOff = null; continue; }
    if (!b.party && off.state === 'offered' && S.time - off.t > 75) { off.state = 'done'; b.helpOff = null; continue; }
    if (b.party && off.kind === 'heal' && off.joinT && S.time - off.joinT > 60 && p.hp > p.maxhp * .9 && !S.ents.some(m => m.kind === 'mon' && !m.dead && m.target === p)) blHelpLeave(b, pick(['u good now? gtg, gl', 'gl!', 'stay safe lol, cya']));
  }
}
function blFindOffer(ch, name) {
  const ok = o => o && !o.cancel && o.state !== 'done' && S.time - o.t < 150;
  if (name) { const m = BL.mem[String(name).toLowerCase()]; return m && ok(m.off) ? m.off : null; }
  let best = null;
  for (const k in BL.mem) { const o = BL.mem[k].off; if (!ok(o)) continue;
    const near = o.bot && blAlive(o.bot) && blNear(o.bot, 15);
    const fits = ch === 'say' ? (near || o.ch === 'say') : ch === 'party' ? (o.bot && o.bot.party) : ch === 'guild' ? o.ch === 'guild' : ch === 'shout' ? o.ch === 'shout' : false;
    if (fits && (!best || o.t > best.t)) best = o; }
  return best;
}
function blAcceptOffer(off) {
  off.accepted = true; const b = off.bot && blAlive(off.bot) ? off.bot : null; const who = b || off.name; const rch = off.rch === 'shout' ? 'whisper' : off.rch;
  if (off.state === 'offered') { blTellLater(who, rch, pick(['k omw', 'omw', 'coming', 'ok 1 sec, omw'])); setTimeoutGame(2.5, () => blHelpGo(b, off.name, off)); }
  else if (off.state === 'coming') { if (R() < .4) blTellLater(who, rch, pick(['omw', 'almost there', 'coming'])); }
  else if ((off.state === 'arrived' || off.state === 'invited') && b && !b.party) { setTimeoutGame(1.2 + R(), () => { if (blAlive(b) && !b.party && S.party.length < 4) joinParty(b); }); }
}
function blCancelOffer(off) {
  off.cancel = true; off.state = 'done'; const b = off.bot; if (b) { b.come = null; b.helpOff = null; b.assistUntil = 0; }
  blTellLater(b && blAlive(b) ? b : off.name, off.rch === 'shout' ? 'whisper' : off.rch, pick(['ok np', 'k', 'ok gl', 'np', 'k gl']));
}

/* ---------- entry points ---------- */
function blConvPre(ch, text, toName) {
  const l = String(text).toLowerCase().trim(); if (!l) return false;
  const addr = toName ? null : blAddressed(ch, l);
  const targets = toName ? [toName] : addr ? [addr.name] : blRecentPartners(ch);
  if (BL_RUDE.test(l)) {
    let who = targets.length ? targets[0] : null;
    if (!who && ch === 'say') { const n = blBots(b => blNear(b, 10) && !b.afk && !b.party); if (n.length && R() < .4) who = pick(n).name; }
    for (const n of targets) { const m = blMem(n); m.mood -= 1.5; if (m.off && m.off.state !== 'done' && m.off.state !== 'joined') { m.off.cancel = true; m.off.state = 'done'; const b = m.off.bot; if (b) { b.come = null; b.helpOff = null; b.assistUntil = 0; } } }
    if (who && R() < .7) { const b = blBotByName(who); blTellLater(b || who, ch === 'shout' ? 'shout' : ch, pick(['rude', 'ok then', 'lol calm down', 'wow', 'whatever', 'bye then', 'nvm then'])); }
    return true;
  }
  const h = blHelpIntent(l);
  if (h) { blOnHelp(ch, h, toName || (addr && addr.name)); return true; }
  const off = blFindOffer(ch, toName || (addr && addr.name));
  if (off) {
    if (BL_NO.test(l)) { blCancelOffer(off); return true; }
    if (BL_YES.test(l) || /\b(inv|invite|come|pls|please|yes)\b/.test(l)) { blAcceptOffer(off); return true; }
    if (/^where\b|where r u|where are you/.test(l) && off.bot && blAlive(off.bot)) { blTellLater(off.bot, off.rch === 'shout' ? 'whisper' : off.rch, pick([`${blLandmark(S.map.id, off.bot.x, off.bot.y)}, omw`, 'omw to u', 'coming to u'])); if (off.state === 'offered') blAcceptOffer(off); return true; }
    if (off.state === 'offered' && off.askedQ && !BL_THX.test(l)) { blAcceptOffer(off); return true; }
  }
  if (BL_THX.test(l) && targets.length) {
    const n = targets[0]; const b = blBotByName(n); const m = blMem(n); m.mood += 1;
    blTellLater(b || n, ch === 'shout' ? 'whisper' : ch, pick(['np', 'yw', 'anytime', 'np gl', 'np :)']));
    if (b && b.party && b.helpOff && b.helpOff.joinT && S.time - b.helpOff.joinT > 25 && R() < .5) setTimeoutGame(7 + R() * 6, () => blHelpLeave(b, pick(['np, gtg gl!', 'np, cya', 'gl!'])));
    return true;
  }
  return false;
}
function blAnswer(l, r, mem) {
  const P = S.P, b = r.b, q = QUESTS[P.q], tp = mem.topic; const setT = t => { mem.topic = t; };
  if (tp && /^(where\??|where is it\??|where r they\??|where are they\??|where exactly\??|where do they spawn\??)$/.test(l)) {
    if (tp.boss || tp.mon) return BL_MONWHERE[tp.boss || tp.mon] || 'dunno exactly';
    if (tp.map) return BL_MAPWHERE[tp.map]; if (tp.item) { const s = blDropSrc(tp.item); return s.length ? `${pick(s).name}, ${BL_MONWHERE[s[0].id] || ''}` : 'shop in town'; }
    if (b) return blLandmark(S.map.id, b.x, b.y);
  }
  if (tp && tp.item && /^(how much|price|pc|worth)\??$/.test(l)) { const v = sellPrice({ id: tp.item }) * (ITEMS[tp.item].q ? 2.8 : 1.8); return `${fmtK(blRound(v))}ish`; }
  if (tp && /^(what lvl|what level|lvl|level)\??$/.test(l)) { if (tp.map) return BL_MAPLV[tp.map]; if (tp.boss) return `${MON[tp.boss].lv}+ with a grp`; if (tp.mon) return `${MON[tp.mon].lv}ish`; }
  if (/\b(u|you|ya) (there|here|around|on|online|alive|afk)\b|^(there|hello|hey)\?+$/.test(l)) return pick(['ya', 'yes?', 'here', 'sup', 'wat', 'yea whats up']);
  if (/how (are|r) (u|you|ya)|how('?s| is) it going|how u doing|what'?s up|wassup/.test(l)) return pick(['good u?', 'tired lol', `grinding ${b && b.fq ? monSh(b.fq.need) : 'as usual'}`, 'fine, u?', 'not bad']);
  if (/\b(gz|grats|gratz|congrats)\b/.test(l)) return pick(['ty', 'thx :)', 'ty ty']);
  if (/\b(hi|hey|hello|yo|hiya|heya|sup)\b|o\//.test(l)) return pick(['hey', 'hi!', 'yo', 'hello', 'o/', `hi ${P.name}`]);
  const mp = blMapIn(l), boss = blBossIn(l), mon = blMonIn(l), item = blItemIn(l);
  if (/where (should|can|do|would) i (lvl|level|hunt|grind|go|farm|xp)|good (spot|place) (to|for) (lvl|level|xp|hunt|grind)|where to (lvl|level|grind|hunt)|best (spot|place)/.test(l)) { const m = /\b(\d{1,2})\b/.exec(l); const lv = m ? +m[1] : P.lv; return `at ${lv}? ${blLvSpot(lv)}`; }
  if (/\bwhere\b|how (do|can) i (get|go)|how to get|which way|how do i find/.test(l)) {
    if (!mp && !boss) for (const [re, ans] of BL_NPCWHERE) if (re.test(l)) return ans;
    if (boss) { setT({ boss }); return R() < .5 ? BL_MONWHERE[boss] : `${BL_MONWHERE[boss]}, ${blBossStatus(boss)}`; }
    if (mon) { setT({ mon }); return BL_MONWHERE[mon] ? pick([BL_MONWHERE[mon], `${monSh(mon)}? ${BL_MONWHERE[mon]}`]) : 'no idea'; }
    if (item) { setT({ item }); const src = blDropSrc(item); if (src.length) { const m = pick(src); return pick([`${m.name} drops it`, `${monSh(m.id)} in ${mapSh(BL_MONMAP[m.id])}`, `${m.name}, ${BL_MONWHERE[m.id] || mapSh(BL_MONMAP[m.id])}`]); } return pick(['shop in town i think', 'buy it in town']); }
    if (mp) { setT({ map: mp }); return BL_MAPWHERE[mp]; }
    if (/\b(quests?|elder)\b/.test(l)) return 'Elder Rowan by the fountain';
    if (/\b(u|you)\b/.test(l) && b) return blLandmark(S.map.id, b.x, b.y);
  }
  if (item && /what drops|drops? (from|where)|(get|find) (a |an )?/.test(l)) { setT({ item }); const src = blDropSrc(item); if (src.length) { const m = pick(src); return `${m.name}, ${BL_MONWHERE[m.id] || mapSh(BL_MONMAP[m.id])}`; } return 'buy it in town'; }
  if (boss && /\b(up|alive|spawn|respawn|timer|when|dead|back)\b/.test(l)) { setT({ boss }); return blBossStatus(boss); }
  if (/\b(lvl|level)\b/.test(l)) { if (mp) { setT({ map: mp }); return BL_MAPLV[mp]; } if (boss) { setT({ boss }); return `${MON[boss].lv}+ and bring a grp`; } if (/\b(ur|your|u|you)\b/.test(l) && b) return pick([`${b.lv}`, `${b.lv} ${clsSh(b.cls)}`, `im ${b.lv}`]); }
  if (/\bguilds?\b/.test(l)) {
    if (/(what|which) guild|ur guild|your guild|(u|you) in a guild/.test(l)) return b && b.guild ? pick([`${b.guild}`, `im in ${b.guild}`, `${b.guild}, u want in?`]) : 'no guild atm';
    if (/(make|create|found|start|own)/.test(l)) return pick(["u need a Warlord's Horn + 20k, then talk to Kael", 'kill the goblin warlord for the horn, then Kael']);
    return pick(['talk to Kael in town, u can apply there', 'Kael, bottom right house, apply to one', 'guildies get 10% xp if ur guild holds varn']);
  }
  if (/what (should|do) i do|what quest|next quest|what now/.test(l) && q) return P.qa ? `${q.name}, ${monSh(q.need)} are ${BL_MONWHERE[q.need] || 'around'}` : 'talk to Elder Rowan, he gives quests';
  if (/\b(refine|refining|upgrade)\b/.test(l)) return pick(['Grom in town, needs Black Iron Ore', 'ore from the mine, then Grom']);
  if (/\bclass\b/.test(l)) return /\b(ur|your|u|you)\b/.test(l) && b ? CLASSES[b.cls].name.toLowerCase() : pick(['tao, can solo everything', 'war for pvp', 'wiz for xp obv']);
  if (/(how much|price|worth|\bpc\b)/.test(l) && item) { setT({ item }); const v = sellPrice({ id: item }) * (ITEMS[item].q ? 2.8 : 1.8); return `${fmtK(blRound(v))}ish`; }
  if (/\b(bot|bots|botting|npc|ai)\b/.test(l)) return pick(['?', 'lol what', 'no u', 'im real lol', 'beep boop']);
  if (/\b(lol|lmao|haha|xd|rofl)\b/.test(l)) return pick(['lol', 'haha', 'xD']);
  if (/\bgg\b/.test(l)) return pick(['gg', 'gg wp']);
  if (/\b(pk|pker|red name|pked)\b/.test(l)) return pick(['where?', 'report him', 'lol pkers', 'guards wont help outside town']);
  if (/\b(bye|cya|gn|gtg|later)\b/.test(l)) return pick(['cya', 'bye', 'gn', 'later']);
  if (/\?\s*$/.test(l)) return pick(['dunno', 'no idea sry', 'idk', 'ask in shout', 'not sure']);
  for (const k in REPLIES) if (new RegExp('\\b' + k + '\\b').test(l)) return pick(REPLIES[k]);
  return null;
}
function blConvReply(ch, text, toName) {
  const l = String(text).toLowerCase().trim(); const P = S.P; if (!l) return;
  const isQ = /\?\s*$|^(where|what|how|when|who|which|is|are|can|does|do|any ?1|anyone|u|you)\b/.test(l), greet = /\b(hi|hey|hello|yo|sup|hiya)\b|o\//.test(l);
  const RB = b => ({ b, name: b.name, lv: b.lv, cls: b.cls, guild: b.guild });
  let r = null, pr = 0;
  if (ch === 'whisper') { const b = blBotByName(toName); r = b ? RB(b) : { b: null, name: toName, lv: clamp(P.lv + rnd(-5, 8), 1, 40), cls: pick(['W', 'M', 'T']) }; pr = .85; }
  else if (ch === 'party') { const c = S.party.filter(b => !b.dead); if (!c.length) return; r = RB(pick(c)); pr = isQ ? .85 : .5; }
  else if (ch === 'guild') { const on = P.guild ? P.guild.members.filter(m => m.on) : []; if (!on.length) return; const m = pick(on); r = { b: blBotByName(m.name), name: m.name, lv: m.lv, cls: m.cls, guild: P.guild.name }; pr = isQ ? .75 : greet ? .7 : .35; }
  else {
    const addr = blAddressed(ch, l);
    if (addr) { r = RB(addr); pr = addr.afk ? 0 : .9; if (addr.afk && R() < .3) blTellAt(addr, 'whisper', pick(['sry was afk', 'back, what?']), 25 + R() * 25); }
    else if (ch === 'say') { const rec = blRecentPartners('say').map(n => blBotByName(n)).filter(Boolean); const near = rec.length ? rec : blBots(b => blNear(b, 12) && !b.afk && !b.party); if (!near.length) return; r = RB(pick(near)); pr = rec.length ? .7 : isQ ? .6 : greet ? .5 : .2; }
    else { const c = blBots(b => !b.party && !b.afk); r = c.length && R() < .5 ? RB(pick(c)) : { b: null, name: blFreeName(), lv: rnd(5, 38), cls: pick(['W', 'M', 'T']) }; pr = isQ ? .55 : greet ? .3 : .12; }
  }
  if (!r) return; const mem = blMem(r.name);
  const rch = ch === 'shout' && r.b && blNear(r.b, 14) && R() < .5 ? 'say' : ch;
  const same = mem.said.filter(x => x[1] === l && S.time - x[0] < 25).length; mem.said.push([S.time, l]); if (mem.said.length > 6) mem.said.shift();
  if (same) { mem.mood -= .5; if (R() < .5) blTellLater(r.b || r.name, rch, pick(['?', 'u said that', 'lol', 'ok?', 'i heard u'])); return; }
  if (mem.mood <= -3) pr *= .2; else if (mem.mood <= -1.5) pr *= .6;
  if (R() >= pr) return;
  let ans = blAnswer(l, r, mem);
  if (!ans && /^(y|ya|yes|yea|yeah|yep|yup|ok|okay|k|kk|sure|no|nah|nope|n|pls|plz|where\??)( (pls|plz|please|sure|ok|thx|ty|then))?\W*$/.test(l)) { if ((ch === 'whisper' || ch === 'party') && R() < .6) ans = pick(['?', 'what?', 'huh', 'yes what?']); else return; }
  if (!ans) { if (ch === 'whisper' || ch === 'party') ans = pick(['?', 'lol', 'ya', 'k', 'true', 'hm', 'what?', 'same']); else if (ch === 'guild') ans = pick(['lol', 'ya', 'nice', 'same']); else if (R() < .4) ans = pick(['lol', '?', 'k', 'same', 'true']); else return; }
  mem.lastT = S.time; blTellLater(r.b || r.name, rch, ans);
}

/* ================= CHAT DIRECTOR ================= */
function blLfgLine(b) {
  const mp = mapSh(S.map.id), c = clsSh(b.cls), fq = b.fq, q = fq && QUESTS[fq.qi], ms = fq ? monSh(fq.need) : null;
  const L = [`LFG ${mp} lvl ${b.lv} ${c}`, `lvl ${b.lv} ${c} LFG ${mp}`, `any group for ${mp}? ${b.lv} ${c}`, `${b.lv} ${c} looking for group`];
  if (b.cls !== 'T') L.push(`need heals for ${mp} lol`, `any taoist want to duo ${mp}?`); else L.push(`${b.lv} tao LFG, can heal`, `taoist LF party ${mp}, got pots`);
  if (b.cls === 'W') L.push(`${b.lv} war LFG, i tank`); if (b.cls === 'M') L.push(`wiz ${b.lv} LFG ${mp}, need a tank`);
  if (q) { L.push(`LFG ${q.name} lvl ${b.lv} ${c}`, `anyone doing ${ms}? share kills`); if (MON[fq.need].boss) L.push(`LF2M ${MON[fq.need].name}, ${b.lv} ${c}`, `need ppl for ${ms}, cant solo it`); }
  return pick(L);
}
function blLfmLine(g) {
  const n = g.members.length, mp = mapSh(S.map.id), fq = g.fq, hasT = g.members.some(m => m.cls === 'T');
  const role = !hasT ? pick(['tao', 'healer', 'taoist']) : pick(['dps', 'wiz', 'war', 'any class']);
  const minLv = Math.max(1, Math.min(...g.members.map(m => m.lv)) - 3);
  const lvs = minLv >= 5 ? ` ${minLv}+` : '';
  const L = [`LFM ${mp} need ${role}${lvs}`, `${n}/5 ${mp} LF1M ${role}`, `LF${5 - n}M ${mp}${lvs ? ',' + lvs + ' pls' : ''}`];
  if (fq) L.push(`LFM ${QUESTS[fq.qi].name}, need ${role}`, `${monSh(fq.need)} grp need 1 more ${role}`);
  return pick(L);
}
function blTryJoinLfg(a) {
  const c = blBots(b => b !== a && !b.grp && !b.party && !b.red && b.mode === 'hunt' && Math.abs(b.lv - a.lv) <= 6 && !b.come);
  if (!c.length) return; const b = pick(c);
  setTimeoutGame(3 + R() * 5, () => {
    if (!blAlive(a) || !blAlive(b) || b.grp || b.party || a.party || (a.grp && a.grp.leader !== a)) return;
    chat('shout', blStyle(b, pick([`${a.name} inv`, 'x', `${a.name} pm`, `inv me ${b.lv} ${clsSh(b.cls)}`, `${a.name} me!`])), b.name);
    if (a.grp) { if (a.grp.members.length < 4) blGroupAdd(a.grp, b); } else blMakeGroup(a, [b]);
  });
}
function blMarketLine() {
  const pool = Object.values(ITEMS).filter(d => !d.raid && d.slot !== 'quest' && (BL_GEAR.includes(d.slot) || d.slot === 'book' || d.id === 'black_ore' || d.id === 'sun_potion'));
  const d = pick(pool); const v = sellPrice({ id: d.id }); const p = fmtK(blRound(v * (d.q ? 2.4 + R() : 1.4 + R() * .9)));
  const d2 = pick(pool.filter(x => x.slot === d.slot)) || pick(pool);
  const nm = x => x.slot === 'book' ? SKILLS[x.skill].name + ' book' : x.name; const dn = nm(d), d2n = nm(d2);
  return pickW([[`WTS ${dn} ${p}`, 3], [`S> ${dn} ${p}, pm`, 2], [`selling ${dn}, pm offers`, 2], [`WTB ${dn} paying ${p}`, 2], [`B> ${dn}`, 1], [`WTT ${dn} for ${d2n}`, d.slot === 'book' ? 0 : 1], [`selling ${rnd(5, 20)} sun pots, ${fmtK(rnd(2, 6) * 500)}`, .7], [`WTB Black Iron Ore ${rnd(4, 7) * 100} each`, .7], [`WTS ${dn} +${rnd(1, 3)} ${pick(['dc', 'ac', 'acc', 'mc', 'sc'])}, ${p}`, BL_GEAR.includes(d.slot) ? 1 : 0]]);
}
function blShout() {
  const k = pickW([['lfg', 22], ['lfm', 10], ['market', 22], ['qa', 20], ['meta', 12], ['quest', 7], ['recruit', 5], ['bothelp', 6]]);
  if (k === 'bothelp') { blBotHelp(); return; }
  const sm = S.map.id;
  if (k === 'lfg') {
    const c = blBots(b => b.mode === 'hunt' && !b.grp && !b.party && !b.red && !b.come);
    if (c.length) { const a = pick(c); chat('shout', blStyle(a, blLfgLine(a)), a.name); if (R() < .5) blTryJoinLfg(a); return; }
    const n = blFreeName(), mp = pick(['mine', 'mirewood', 'temple']), lv = { mine: rnd(10, 22), mirewood: rnd(16, 30), temple: rnd(25, 40) }[mp], cl = pick(['W', 'M', 'T']);
    chat('shout', blStyle(n, pick([`LFG ${mapSh(mp)} lvl ${lv} ${clsSh(cl)}`, `${lv} ${clsSh(cl)} LFG ${mapSh(mp)}`, `any grp for ${mapSh(mp)}? ${lv} ${clsSh(cl)}`])), n); return;
  }
  if (k === 'lfm') {
    const gs = blGroups().filter(g => g.members.length < 4 && !g.leader.party);
    if (gs.length) { const g = pick(gs); chat('shout', blStyle(g.leader, blLfmLine(g)), g.leader.name); if (R() < .35) { const L = g.leader; const c = blBots(b => !b.grp && !b.party && !b.red && b.mode === 'hunt' && Math.abs(b.lv - L.lv) <= 6); if (c.length) { const b = pick(c); setTimeoutGame(4 + R() * 4, () => { if (blAlive(b) && blAlive(L) && L.grp && !b.grp && L.grp.members.length < 4) { chat('shout', blStyle(b, pick(['x', `inv ${b.lv} ${clsSh(b.cls)}`, `${L.name} me`])), b.name); blGroupAdd(L.grp, b); } }); } } return; }
    const n = blFreeName(); chat('shout', blStyle(n, pick([`LFM ${pick(['bk', 'warlord', 'mino', 'tusk'])} need ${pick(['tao', 'tank', '2 dps'])}`, `LF1M ${mapSh(pick(['mine', 'mirewood', 'temple']))} ${pick(['tao', 'wiz', 'war'])}`])), n); return;
  }
  if (k === 'market') { const n = blFreeName(); chat('shout', blStyle(n, blMarketLine()), n); return; }
  if (k === 'qa') { blConvo(); return; }
  if (k === 'quest') {
    const c = blBots(b => b.fq && !b.fq.done && b.mode === 'hunt' && !b.party);
    if (c.length) { const b = pick(c); const q = QUESTS[b.fq.qi]; chat('shout', blStyle(b, pick([`${q.name} is so annoying`, `why does ${q.name} need ${q.n} ${monSh(q.need)} lol`, `where do ${monSh(q.need)} spawn?`, `anyone else doing ${q.name}?`, `${monSh(q.need)} ${b.fq.n}/${b.fq.N}, this takes forever`])), b.name); return; }
  }
  if (k === 'recruit') { const g = pick(GUILDS); const n = blFreeName(); chat('shout', blStyle(n, pick([`${g.name} recruiting lvl ${g.minLv}+, pm me`, `${g.name} looking for active players ${g.minLv}+`, `join ${g.name}! ${g.notice.split('.')[0].toLowerCase()}`])), n); return; }
  const n = blFreeName();
  const meta = SHOUTS.concat(['server lagging?', 'anyone else dc?', 'gm on?', `${sm === 'mine' ? 'mine' : 'mirewood'} is packed today`, 'so many pkers lately', 'this game needs more maps', 'anyone seen a Dragon Staff drop ever?', `${S.online} online, nice`, 'brb dinner', 'what time is siege?', BL.night ? 'night grind ftw' : 'morning ashvale']);
  chat('shout', blStyle(n, pick(meta)), n);
}
function blBotHelp() {
  const c = blBots(b => b.mode === 'hunt' && !b.party && !b.red && !b.come);
  const a = c.length ? pick(c) : null; const an = a ? a.name : blFreeName(); const lm = a ? blLandmark(S.map.id, a.x, a.y) : mapSh(pick(['mine', 'mirewood', 'temple']));
  const boss = a && a.fq && MON[a.fq.need] && MON[a.fq.need].boss ? a.fq.need : pick(Object.keys(BL_BOSSMAP));
  chat('shout', blStyle(an, pick([`can some1 help me with ${monSh(boss)}?`, `need help at ${lm}, keep dying`, `any tao? need heals at ${lm}`, 'anyone help me with my quest?', `help, stuck at ${lm} lol`])), an);
  if (R() < .6) {
    const hc = a ? blBots(b => b !== a && b.mode === 'hunt' && !b.party && !b.red && !b.grp && b.lv >= a.lv - 3) : []; const h = hc.length ? pick(hc) : null; const hn = h ? h.name : blFreeName();
    setTimeoutGame(4 + R() * 7, () => {
      chat('shout', blStyle(hn, pick([`${an} omw`, 'omw', `${an} where r u?`, `what lvl ${an}?`, 'coming'])), hn);
      if (h && a && blAlive(h) && blAlive(a) && !h.grp && !a.party) { if (a.grp) { if (a.grp.members.length < 4) blGroupAdd(a.grp, h); } else blMakeGroup(a, [h]); if (R() < .6) setTimeoutGame(15 + R() * 15, () => { if (blAlive(a)) chat('shout', blStyle(an, pick(['ty!!', `ty ${hn}`, 'thx, got help'])), an); }); }
    });
  } else if (R() < .5) { const n = blFreeName(); setTimeoutGame(5 + R() * 6, () => chat('shout', blStyle(n, pick(['ask ur guild', 'lol', 'git gud', 'use pots', 'busy sry'])), n)); }
}
function blConvo() {
  const gens = [
    () => { const pool = Object.values(ITEMS).filter(d => !d.raid && BL_GEAR.includes(d.slot) && blDropSrc(d.id).length); const d = pick(pool); const src = blDropSrc(d.id); const m = pick(src); return { q: pick([`where does ${d.name} drop?`, `anyone know what drops ${d.name}?`, `${d.name} drop where?`]), a: pick([`${m.name} in ${BL_MAPNAME[BL_MONMAP[m.id]] || 'somewhere'}`, `${monSh(m.id)}, ${mapSh(BL_MONMAP[m.id])}`, `${m.name} but its rare af`]), f: pick(['ty', 'thx', 'ah ok', 'ty!']) }; },
    () => { const bid = pick(Object.keys(BL_BOSSMAP)); return { q: pick([`is ${monSh(bid)} up?`, `${MON[bid].name} up?`, `anyone killed ${monSh(bid)} yet?`]), a: blBossStatus(bid), f: pick(['k', 'ty', 'ugh', null]) }; },
    () => { const mp = pick(['mine', 'mirewood', 'temple']); return { q: pick([`what lvl for ${mapSh(mp)}?`, `is ${mapSh(mp)} ok at lvl ${rnd(8, 30)}?`]), a: { mine: pick(['like 12+', '12+, 15 if ur a wiz', 'go at 11 w/ a tao']), mirewood: pick(['18+', '20 to be safe, spiders hurt', '16 with a grp']), temple: pick(['26+ with a grp', 'dont go solo lol', '28 at least']) }[mp], f: pick(['ty', 'ok', 'thx']) }; },
    () => { const mp = pick(['mine', 'mirewood', 'temple', 'sanctum']); return { q: `how do i get to ${mapSh(mp)}?`, a: { mine: 'north west of town, follow the road', mirewood: 'east exit of ashvale', temple: 'through mirewood, far east', sanctum: 'talk to Lys, need lvl 30 + a grp' }[mp], f: pick(['ty', 'thx!', null]) }; },
    () => { const k = pick(Object.keys(SKILLS).filter(k => SKILLS[k].lv > 1)); const s = SKILLS[k]; return { q: `where do i get ${s.name}?`, a: pick([`Sage Orrin sells the book, lvl ${s.lv}`, `book shop in town, need ${s.lv}`]), f: 'ty' }; },
    () => { const d = pick(Object.values(ITEMS).filter(d => !d.raid && BL_GEAR.includes(d.slot) && d.lv >= 10)); const v = sellPrice({ id: d.id }) * (d.q ? 2.8 : 1.8); return { q: pick([`pc ${d.name}?`, `how much is ${d.name} worth?`, `price check ${d.name}`]), a: pick([`${fmtK(blRound(v))}ish`, `like ${fmtK(blRound(v))}`, `${fmtK(blRound(v * .8))}-${fmtK(blRound(v * 1.2))}`, 'depends on stats']), f: pick(['ty', 'hmm ok', null]) }; },
    () => ({ q: pick(['whats the best class?', 'war or tao?', 'which class is best for solo?']), a: pick(['tao, can solo everything', 'war for pvp', 'wiz for xp obv', 'all of them r ok lol', 'tao easy mode']), f: pick(['lol', 'k', 'hmm', null]) }),
    () => { const g = pick(GUILDS); return { q: pick(['any guild recruiting?', 'looking for a guild, lvl ' + rnd(8, 30)]), a: pick([`${g.name} is, lvl ${g.minLv}+`, `we are! ${g.name}, pm me`, `try ${g.name}`]), f: pick(['ty', 'pm', null]) }; },
    () => ({ q: pick(['where do i farm ore?', 'best place for black iron ore?']), a: pick(['mine, skeles and zombies drop it', 'mine, deeper = more ore']), f: 'ty' }),
    () => ({ q: pick(['is refining worth it?', 'whats the max refine?']), a: pick(['up to +3 yes', 'only if u have spare ore', 'i broke 5 ore on +4 lol never again', '+7 max, good luck']), f: pick(['rip', 'lol', 'ok', null]) }),
    () => ({ q: pick(['lag?', 'is the server lagging?', 'anyone else lagging?']), a: pick(['yeah', 'fine for me', 'always lol', 'yep']), f: null }),
    () => ({ q: pick(['when is siege?', 'who holds varn?']), a: `${S.castle || 'nobody'} holds varn rn`, f: pick(['ty', null]) }),
    () => ({ q: pick(['where do i get quests?', 'new here, what do i do?']), a: pick(['Elder Rowan by the fountain', 'talk to the elder in town', 'welcome! go see Elder Rowan']), f: pick(['ty!', 'thx', null]) }),
    () => ({ q: 'how do i get to mirewood fast?', a: 'Lys teleports u if uve been there before', f: 'oh ty' }),
    () => ({ q: pick(['what does revival ring do?', 'rev ring worth it?']), a: pick(['revives u on death, 5 min cd', 'yes its the best ring']), f: null }),
  ];
  const qa = pick(gens)(); const a = blFreeName(); let b = blFreeName(); if (b === a) b = pick(BOT_NAMES);
  chat('shout', blStyle(a, qa.q), a);
  setTimeoutGame(3 + R() * 5, () => { chat('shout', blStyle(b, qa.a), b); if (qa.f && R() < .6) setTimeoutGame(2 + R() * 3, () => chat('shout', blStyle(a, qa.f), a)); });
}
function blLocalSay() {
  const p = S.player; if (!p) return; const P = S.P;
  const near = blBots(b => cheb(b.x, b.y, p.x, p.y) <= 12 && !b.party && !b.afk && !(b.act && b.act.k === 'vendor') && b.mode !== 'travel');
  if (!near.length) return; const b = pick(near); const pq = P.qa && QUESTS[P.q];
  let t;
  if (!BL.greeted.has(b.name) && R() < .3) { BL.greeted.add(b.name); t = pick(['hi', 'o/', 'yo', 'hey', 'hi ' + P.name]); }
  else if (P.pk >= 200 && !b.red) t = pick(['omg pker', 'run!!', 'guards!', 'red name...']);
  else if (pq && b.fq && b.fq.need === pq.need && R() < .6) t = pick([`u doing ${monSh(pq.need)} too?`, 'we can share, plenty for both', `${monSh(pq.need)} spawn is so slow`, 'ks much? lol jk', 'wanna grp? same quest']);
  else if (b.fq && b.mode === 'hunt' && R() < .5) t = blProgressLine(b);
  else if (b.mode === 'town') t = pick(['hi', 'anyone selling pots?', `LF ${mapSh(pick(['mine', 'mirewood']))} grp`, 'wb', 'lag...', 'so many ppl today', 'anyone want to duo?', 'how do i get to mirewood?', 'gz', 'hey', `any1 got a spare ${pick(['Bronze Helmet', 'Leather Cap', 'Iron Bracelet'])}?`, 'nice weapon ' + P.name]);
  else t = pick(SAYS.concat(['this spawn is dead', 'lol', 'anyone got a town scroll?', 'mana break', 'so much xp here', 'pots running low', 'ks...', 'nice']));
  botSay(b, blStyle(b, t));
}
function blGroupTick() {
  for (const g of blGroups()) {
    if (S.time < g.chatAt || !blNear(g.leader, 22)) continue;
    g.chatAt = S.time + 10 + R() * 18; if (R() < .6) blGroupChat(g);
  }
}
function blGroupChat(g) {
  const ms = g.members.filter(m => !m.dead && !m.gone); if (ms.length < 2) return;
  const L = g.leader; const low = ms.find(m => m.hp < m.maxhp * .45); const tao = ms.find(m => m.cls === 'T'); const fq = g.fq; const mon = fq ? monSh(fq.need) : null;
  let who, text, reply = null, rwho = null;
  const others = x => ms.filter(m => m !== x);
  if (low && tao && low !== tao && R() < .6) { who = low; text = pick(['heal pls', 'heal!', 'hp low', 'heals??', 'help']); rwho = tao; reply = pick(['got u', 'healing', 'ok ok', 'oom sec', 'on it']); }
  else if (fq && !fq.done && R() < .3) { who = pick(ms); text = pick([`${fq.n}/${fq.N}`, `${fq.N - fq.n} more ${mon}`, `where r the ${mon}`, `${mon} over here`]); }
  else if (R() < .5) { who = L; text = pick(['pull more', 'this way', 'next room', 'go go', 'wait for mana', `lets do ${mon || 'this spawn'}`, 'stack up', 'follow me', 'dont pull too many lol']); rwho = pick(others(L)); reply = pick(['k', 'ok', 'omw', 'kk', 'wait', 'sec', 'lag', 'going']); }
  else { who = pick(others(L)) || L; text = pick(['brb 1 min', 'mana', 'lol', 'nice', 'this is slow', 'ty', 'oom', 'gotta go soon', `lvl ${who.lv + 1} soon`, 'where r u', 'anyone got pots?', ':)']); if (R() < .5) { rwho = pick(others(who)); reply = pick(['k', 'lol', 'np', 'same', 'ok', 'hurry']); } }
  botSay(who, blStyle(who, text));
  if (reply && rwho) setTimeoutGame(1.5 + R() * 2.5, () => { if (blAlive(rwho)) botSay(rwho, blStyle(rwho, reply)); });
}
function blPartyChat() {
  const b = pick(S.party); if (!b) return; const p = S.player; let t;
  if (p.hp < p.maxhp * .35) t = pick(['pot!!', 'ur low', 'careful']);
  else if (b.cls === 'T' && R() < .3) t = pick(['mana', 'oom, sec', 'buffs up', 'stay close so i can heal']);
  else t = pick(['nice', 'lol', 'brb 1 min', 'this spawn is good', 'more mobs pls', `${mapSh(S.map.id)} is packed today`, 'ty for the grp', 'going ok?', 'xp is nice here', 'pull more', 'wait for me', 'lag', ':)', `lvl ${b.lv + 1} soon`, 'where next?']);
  chat('party', blStyle(b, t), b.name);
}
function blGuildChat() {
  const G = S.P.guild; const on = G.members.filter(m => m.on); if (!on.length) return; const m = pick(on); const P = S.P; const pq = QUESTS[P.q];
  const L = ['anyone need help?', 'siege prep tonight', `who wants to farm ${mapSh(pick(['mine', 'mirewood', 'temple']))}?`, 'lol', 'brb food', 'hi guild', 'anyone have spare sun pots?', 'Kael says we need more members', `anyone at ${mapSh(S.map.id)}?`, `lf ${pick(['tao', 'war', 'wiz'])} for ${pick(['bk', 'warlord', 'mino'])}`, `just hit ${m.lv}`, 'guild bank when', `got a ${pick(['Coral Ring', 'Magic Helmet', 'Bone Necklace', 'Crystal Staff'])} drop, anyone need?`, 'gn guild', 'hi all'];
  if (pq && P.qa) L.push(`${P.name} how is ${pq.name} going?`, `need help with ${monSh(pq.need)} ${P.name}?`);
  if (S.castle === G.name) L.push('we hold varn, gg all', 'defend the castle next siege!');
  chat('guild', blStyle(m.name, pick(L)), m.name);
  if (on.length > 1 && R() < .35) { const o = pick(on.filter(x => x !== m)); setTimeoutGame(2 + R() * 4, () => chat('guild', blStyle(o.name, pick(['lol', 'same', 'me', 'k', 'ty', 'sure', 'later'])), o.name)); }
}
function blPkWatch() {
  const reds = blBots(b => b.red && !b.party);
  for (const r of reds) {
    if (!BL.seenRed.has(r.id) && R() < .45 && blQuiet(4, 12)) { BL.seenRed.add(r.id); const w = pick(blBots(b => !b.red && !b.party)) || null; const nm = w ? w.name : blFreeName(); chat('shout', blStyle(nm, pick([`red name ${r.name} at ${blLandmark(S.map.id, r.x, r.y)}!!`, `pker ${blLandmark(S.map.id, r.x, r.y)}, watch out`, `${r.name} is pking ${blLandmark(S.map.id, r.x, r.y)}`, `red name at ${blLandmark(S.map.id, r.x, r.y)}!!`])), nm); return; }
    if (blNear(r, 12)) { const near = blBots(b => !b.red && !b.party && blNear(b, 12) && cheb(b.x, b.y, r.x, r.y) < 12); if (near.length && R() < .4) { const b = pick(near); botSay(b, blStyle(b, pick(['red name!! run', 'pker!', `careful, ${r.name} is red`, 'run']))); } }
  }
}
function blDayNight() {
  if (!S.P || typeof dayPhase !== 'function') return; const isN = dayPhase().night > .5;
  if (BL.night === null) { BL.night = isN; return; }
  if (isN === BL.night) return; BL.night = isN;
  const n = blFreeName();
  setTimeoutGame(3 + R() * 8, () => chat('shout', blStyle(n, pick(isN ? ['its getting dark', 'night time, scarecrows come out lol', 'gn all, bed time', 'mirewood at night is creepy', 'cant see anything at night lol', 'night grind ftw'] : ['morning ashvale', 'gm all', 'sun is up finally', 'day time, back to farming', 'gm'])), n));
}

/* ---------- unsolicited whispers / invites / trade requests to the player ---------- */
function blPickTrader(it) {
  const d = it ? ITEMS[it.id] : null;
  const c = blBots(b => !b.party && !b.red && !b.afk && !(b.act && b.act.k === 'vendor') && b.mode !== 'travel' && (!d || !d.cls || d.cls === b.cls) && (!d || b.lv >= Math.min(30, (d.lv || 1) - 2) && (!d.q || b.lv >= 15)));
  if (!c.length) return null; c.sort((a, b) => cheb(a.x, a.y, S.player.x, S.player.y) - cheb(b.x, b.y, S.player.x, S.player.y));
  return R() < .5 ? c[0] : pick(c);
}
function blPing() {
  if (S.time < BL.nextPing || S.dead || !S.player) return;
  const P = S.P; const inCombat = (S.combatT || 0) > 0;
  const opts = [];
  const lfgC = S.party.length < 4 ? blBots(b => !b.party && !b.red && !b.afk && b.mode === 'hunt' && Math.abs(b.lv - P.lv) <= 6 && (!b.grp || (b.grp.leader === b && b.grp.members.length + S.party.length <= 4))) : [];
  if (lfgC.length) opts.push(['lfg', 3]);
  if (blBagCands(null).length) opts.push(['wtb', 3]);
  opts.push(['wts', 2.5]);
  const nearT = blBots(b => !b.party && !b.red && !b.afk && blNear(b, 8) && b.mode !== 'travel' && !b.come);
  if (nearT.length && !inCombat && !TR.cur) opts.push(['treq', 2]);
  if (!P.guild && P.lv >= 5) opts.push(['guild', .8]);
  opts.push(['social', 1]);
  const k = pickW(opts);
  BL.nextPing = S.time + 60 + R() * 90;
  if (k === 'lfg') {
    lfgC.sort((a, b) => cheb(a.x, a.y, S.player.x, S.player.y) - cheb(b.x, b.y, S.player.x, S.player.y)); const b = R() < .6 ? lfgC[0] : pick(lfgC);
    const q = b.fq && QUESTS[b.fq.qi];
    const msg = b.grp ? pick([`we have ${b.grp.members.length}, want to join? doing ${q ? monSh(q.need) : mapSh(S.map.id)}`, 'our grp needs 1 more, u in?']) : pick([`hey want to group? ${b.lv} ${clsSh(b.cls)}`, q ? `u doing ${q.name}? lets duo` : `wanna duo ${mapSh(S.map.id)}?`, b.cls === 'T' ? 'grp? i can heal' : b.cls === 'W' ? 'need a tank?' : 'grp? i do big dmg lol', 'wanna party up? xp is better']);
    blWhisper(b, msg);
    if (R() < .5) setTimeoutGame(3 + R() * 3, () => { if (blAlive(b) && !b.party && S.party.length < 4 && window.UI && UI.invitePrompt) UI.invitePrompt(b); });
    else BL.pend[b.name.toLowerCase()] = { kind: 'lfg', t: S.time };
    return;
  }
  if (k === 'wtb') {
    const o0 = blBuyOffer(null); if (!o0) return; const bot = blPickTrader(o0.item); const nm = bot ? bot.name : blFreeName(); const o = blBuyOffer(bot, o0.item) || o0; const n = itemName(o.item);
    blWhisper(bot || nm, pick([`wtb ur ${n}? ${fmtK(o.price)}`, `hey u selling ${n}? ill give ${fmtK(o.price)}`, `saw u got ${n}, ${fmtK(o.price)} for it?`, `${fmtK(o.price)} for ${n}, deal?`]));
    BL.pend[nm.toLowerCase()] = { kind: 'wtb', offer: o, t: S.time };
    if (bot && blNear(bot, 10) && R() < .5) setTimeoutGame(4 + R() * 3, () => { if (BL.pend[nm.toLowerCase()]) { delete BL.pend[nm.toLowerCase()]; blReqTrade(bot, o, `WTB ${n}`); } });
    return;
  }
  if (k === 'wts') {
    const bot = blPickTrader(null); const nm = bot ? bot.name : blFreeName(); const o = blSellOffer(bot); if (!o) return; const n = itemName(o.item) + (o.item.n > 1 ? ' x' + o.item.n : ''); const d = ITEMS[o.item.id];
    const up = BL_GEAR.includes(d.slot) && blEquipLv(d.slot) < (d.lv || 0);
    blWhisper(bot || nm, up ? pick([`need a better ${d.slot}? got ${n} for ${fmtK(o.price)}`, `saw ur ${d.slot}, want an upgrade? wts ${n} ${fmtK(o.price)}`]) : pick([`wts ${n} ${fmtK(o.price)}, interested?`, `selling ${n} cheap, ${fmtK(o.price)}`, `u need ${n}? ${fmtK(o.price)}`]));
    BL.pend[nm.toLowerCase()] = { kind: 'wts', offer: o, t: S.time };
    return;
  }
  if (k === 'treq') { const b = pick(nearT); const o = (blBagCands(b).length && R() < .5) ? blBuyOffer(b) : blSellOffer(b); if (o) blReqTrade(b, o, (o.mode === 'buy' ? 'WTB ' : 'WTS ') + itemName(o.item)); return; }
  if (k === 'guild') { const gs = GUILDS.filter(g => P.lv >= g.minLv); const g = pick(gs); const nm = blFreeName(); blWhisper(nm, pick([`hey, ${g.name} is recruiting, want an invite?`, `u want to join ${g.name}? we're chill`, `looking for a guild? ${g.name} has room`])); BL.pend[nm.toLowerCase()] = { kind: 'guild', g, t: S.time }; return; }
  const nm = (blPickTrader(null) || {}).name || blFreeName(); const ar = S.P.equip.armour;
  blWhisper(nm, pick([ar ? `nice ${ITEMS[ar.id].name.toLowerCase()}` : 'hi', 'whats ur lvl?', 'hi :)', P.lv < 8 ? 'u new? need help?' : 'u in a guild?', `can u help me with ${pick(['tusk', 'bk', 'warlord'])} later?`, 'where did u get that weapon?']));
}

/* ================= TRADING ================= */
const TR = { cur: null, req: null, reqEl: null };
function blEquipLv(slot) { const E = S.P.equip; const ks = slot === 'bracelet' ? ['braceletL', 'braceletR'] : slot === 'ring' ? ['ringL', 'ringR'] : [slot]; let m = 99; for (const k of ks) { const it = E[k]; const l = it ? (ITEMS[it.id].lv || 0) : -1; if (l < m) m = l; } return m; }
function blBagCands(bot) {
  const out = [];
  for (const it of S.P.inv) { if (!it) continue; const d = ITEMS[it.id]; if (!d) continue; const v = sellPrice(it); if (v < 25) continue; if (bot && d.cls && d.cls !== bot.cls) continue; out.push([it, Math.pow(v, .6) * (d.q === 2 ? 5 : d.q ? 3 : 1) * (addTotal(it) > 0 ? 2.5 : 1) * (d.slot === 'mat' ? 1.5 : 1)]); }
  return out;
}
function blBuyOffer(bot, it) { if (!it) { const c = blBagCands(bot); if (!c.length) return null; it = pickW(c); } const base = sellPrice(it); return { mode: 'buy', item: it, base, price: blRound(Math.min(base * 2.75, base * (1.4 + R() * 1.1))), haggles: 0, annoy: 0 }; }
function blSellOffer(bot, forPlayer) {
  const P = S.P; const self = forPlayer === false && bot; const cls = self ? bot.cls : P.cls, lv = self ? bot.lv : P.lv;
  let rare = R() < .08;
  let c = Object.values(ITEMS).filter(d => !d.raid && !d.special && BL_GEAR.includes(d.slot) && (!d.cls || d.cls === cls) && (d.lv || 1) <= lv + 3 && (d.lv || 1) >= lv - 7 && (!d.q || (rare && d.q === 1)));
  if (rare) { const r = c.filter(d => d.q === 1); if (r.length) c = r; else rare = false; }
  let it;
  if (!c.length || R() < .22) {
    const pool = lv < 10 ? [['hp_s', 20], ['mp_s', 20], ['hp_m', 10], ['town_scroll', 3], ['random_scroll', 5]] : lv < 22 ? [['hp_m', 20], ['mp_m', 20], ['sun_potion', 5], ['black_ore', 2], ['random_scroll', 10]] : [['hp_l', 10], ['mp_l', 10], ['sun_potion', 10], ['black_ore', 3]];
    const [id, n] = pick(pool); it = makeItem(id, n);
  } else {
    const w = c.map(d => [d, blEquipLv(d.slot) < (d.lv || 0) ? 3 : 1]);
    it = makeItem(pickW(w).id);
  }
  const d = ITEMS[it.id]; const base = sellPrice(it);
  return { mode: 'sell', item: it, base, price: blRound(base * (d.q ? 2.4 + R() * 1.0 : 1.3 + R() * .9)), haggles: 0, annoy: 0 };
}
function blOfferValid(o) { if (!o) return false; if (o.mode === 'buy') return S.P.inv.indexOf(o.item) >= 0; return true; }
function blStockVendor(e) {
  if (R() < .2) { const id = pick(['black_ore', 'sun_potion', 'hp_l', 'mp_l', 'ring_teleport', 'luck_pendant', pick(Object.values(ITEMS).filter(d => BL_GEAR.includes(d.slot) && !d.raid && d.lv >= 10)).id]); e.wtb = { id, per: blRound(sellPrice({ id }) * (1.4 + R() * .6)) }; e.shop = null; return; }
  e.shop = blSellOffer(e, R() < .6 ? true : false); e.wtb = null;
}
function blVendorLine(e) {
  if (e.wtb) { const d = ITEMS[e.wtb.id]; return pick([`WTB ${d.name} ${fmtK(e.wtb.per)}`, `B> ${d.name} ${fmtK(e.wtb.per)}`, `buying ${d.name}`]); }
  const o = e.shop; if (!o) return 'closed'; const n = itemName(o.item) + (o.item.n > 1 ? ' x' + o.item.n : '');
  return pick([`WTS ${n} ${fmtK(o.price)}`, `S> ${n} ${fmtK(o.price)}`, `selling ${n} ${fmtK(o.price)}`, `${n} ${fmtK(o.price)}, trade me`]);
}
function blDecideOffer(bot) {
  if (bot.shop) { const o = bot.shop; return Object.assign({}, o, { haggles: 0, annoy: 0, last: false, vendor: true }); }
  if (bot.wtb) { const it = S.P.inv.find(x => x && x.id === bot.wtb.id); if (!it) return null; const base = sellPrice(it); return { mode: 'buy', item: it, base, price: Math.min(blRound(base * 2.75), blRound(bot.wtb.per * (it.n || 1))), haggles: 0, annoy: 0, vendor: true }; }
  const c = blBagCands(bot);
  return c.length && R() < .45 ? blBuyOffer(bot) : blSellOffer(bot);
}
window.openTrade = function (bot) {
  if (!bot || bot.kind !== 'bot' || !blAlive(bot) || !S.player) return;
  if (TR.cur) blTradeClose('replace');
  sys(`You request a trade with ${bot.name}.`);
  if (bot.party && R() < .3) { /* group mates trade happily */ }
  if (bot.red || bot.pkOn) { setTimeoutGame(1, () => blWhisper(bot, pick(['lol no', 'trade this', 'no']))); return; }
  if (bot.afk) { setTimeoutGame(25 + R() * 25, () => { if (blAlive(bot)) blWhisper(bot, 'sry was afk, still wanna trade?'); BL.pend[bot.name.toLowerCase()] = { kind: 'wts', offer: blSellOffer(bot), t: S.time }; }); return; }
  if (cheb(bot.x, bot.y, S.player.x, S.player.y) > 12) { sys(`${bot.name} is too far away to trade.`); return; }
  if (bot.wtb && !S.P.inv.some(x => x && x.id === bot.wtb.id)) { setTimeoutGame(1, () => blWhisper(bot, pick([`u dont have any ${ITEMS[bot.wtb.id].name} lol`, `only buying ${ITEMS[bot.wtb.id].name}`]))); return; }
  if (bot.target && !bot.target.dead && bot.target.kind === 'mon' && R() < .6) { setTimeoutGame(1, () => blWhisper(bot, pick(['busy killing, 1 sec', 'sec', 'after this mob']))); setTimeoutGame(5 + R() * 3, () => { if (blAlive(bot) && !TR.cur) botTradeUI(bot); }); return; }
  if (!bot.shop && !bot.wtb && !bot.party && R() < .1) { setTimeoutGame(1 + R(), () => blWhisper(bot, pick(['nothing to trade sry', 'no thx', 'im broke lol']))); return; }
  setTimeoutGame(.6 + R() * 1.1, () => { if (blAlive(bot) && !TR.cur) botTradeUI(bot); });
};
function blEnsureCss() {
  if (document.getElementById('bl-css')) return;
  const st = document.createElement('style'); st.id = 'bl-css';
  st.textContent = `
.bt-win{width:380px;max-width:calc(100% - 16px)}
.bt-who{margin-bottom:8px;display:flex;gap:6px;align-items:baseline;flex-wrap:wrap}
.bt-who b{font-family:var(--display);font-weight:400;font-size:16px;color:var(--bronze-hi)}
.bt-cols{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.bt-side{background:rgba(0,0,0,.28);border:1px solid #2a2620;padding:6px;min-width:0}
.bt-h{font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);margin-bottom:6px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.bt-item{display:flex;gap:8px;align-items:flex-start;min-width:0}
.bt-ic{width:44px;height:44px;cursor:default}
.bt-in{min-width:0}
.bt-nm{font-weight:700;font-size:13px;line-height:1.2;overflow-wrap:anywhere}
.bt-st{font-size:11px;color:var(--muted);line-height:1.35}
.bt-st .bad{color:#ff7a6a}
.bt-v{font-size:11px;color:#f0d070;font-variant-numeric:tabular-nums}
.bt-coin{width:44px;height:44px;flex:none;border-radius:50%;background:radial-gradient(circle at 35% 30%,#fff3b0,#f0c040 40%,#9a6a10 75%,#5a3a06);box-shadow:0 0 0 1px #000,inset 0 0 0 3px rgba(255,230,140,.35)}
.bt-gold{font-size:18px;font-weight:800;color:#f0d070;font-variant-numeric:tabular-nums;line-height:1.2}
.bt-say{margin-top:8px;font-style:italic;min-height:18px;color:var(--text)}
.bt-btns{display:grid;grid-template-columns:1fr 1fr 1fr;gap:6px;margin-top:10px}
.bt-btns .btn{padding:6px 0}
#bt-req{position:absolute;left:50%;top:170px;transform:translateX(-50%);padding:10px 14px;display:none;text-align:center;z-index:31;max-width:calc(100% - 32px)}
#bt-req .row{justify-content:center;margin-top:8px}`;
  document.head.appendChild(st);
}
function blStatLine(it) {
  const d = ITEMS[it.id], a = it.add || {}, P = S.P; const out = [];
  const rg = (k, lab) => { if (d[k] || a[k] || (k === 'dc' && it.r)) { const lo = d[k] ? d[k][0] : 0; const hi = (d[k] ? d[k][1] : 0) + (a[k] || 0) + ((k === 'dc' || (k === 'mc' && d.mc) || (k === 'sc' && d.sc)) ? (it.r || 0) : 0); out.push(`${lab} ${lo}-${hi}`); } };
  rg('dc', 'DC'); rg('mc', 'MC'); rg('sc', 'SC'); rg('ac', 'AC'); rg('mac', 'MAC');
  if (d.acc || a.acc) out.push(`Acc +${(d.acc || 0) + (a.acc || 0)}`); if (d.luck || a.luck) out.push(`Luck +${(d.luck || 0) + (a.luck || 0)}`); if (d.hp) out.push(`HP +${d.hp}`);
  if (d.heal) out.push(`Heals ${d.heal}`); if (d.mana) out.push(`Mana ${d.mana}`); if (d.sdesc) out.push(d.sdesc);
  let h = esc(out.join(' · '));
  const req = []; if (d.cls) req.push(`<span class="${d.cls !== P.cls ? 'bad' : ''}">${CLASSES[d.cls].name}</span>`); if (d.lv > 1) req.push(`<span class="${P.lv < d.lv ? 'bad' : ''}">Lv ${d.lv}</span>`);
  if (req.length) h += (h ? '<br>' : '') + req.join(', ');
  return h;
}
function blIcon(id) { try { return typeof iconUrl === 'function' ? iconUrl(id) : ''; } catch (err) { return ''; } }
function botTradeUI(bot, offer) {
  if (!bot || !blAlive(bot)) return;
  if (!offer || !blOfferValid(offer)) offer = blDecideOffer(bot);
  if (!offer) { blWhisper(bot, pick(['nothing to trade atm sry', 'nvm, got nothing u need'])); return; }
  blEnsureCss(); if (TR.cur) blTradeClose('replace');
  const wins = document.getElementById('wins'); if (!wins) return;
  const el = document.createElement('div'); el.className = 'win frame bt-win';
  el.innerHTML = `<div class="wh"><h3>Trade</h3><div class="x" title="Close" role="button" aria-label="Close">✕</div></div><div class="wb"></div>`;
  wins.appendChild(el);
  const vw = S.vw || 800; el.style.left = Math.max(8, Math.round(vw / 2 - 190)) + 'px'; el.style.top = '90px';
  if (window.UI) { UI.z = (UI.z || 10) + 1; el.style.zIndex = UI.z; }
  el.addEventListener('pointerdown', () => { if (window.UI) el.style.zIndex = ++UI.z; });
  const h = el.querySelector('.wh');
  h.addEventListener('pointerdown', ev => { if (ev.target.classList.contains('x')) return; const app = document.getElementById('app') || document.body; const r = el.getBoundingClientRect(), ar = app.getBoundingClientRect(); const ox = ev.clientX - r.left, oy = ev.clientY - r.top; const mv = e2 => { el.style.left = clamp(e2.clientX - ar.left - ox, 0, S.vw - 60) + 'px'; el.style.top = clamp(e2.clientY - ar.top - oy, 0, S.vh - 40) + 'px'; }; const up = () => { window.removeEventListener('pointermove', mv); window.removeEventListener('pointerup', up); }; window.addEventListener('pointermove', mv); window.addEventListener('pointerup', up); });
  el.querySelector('.x').onclick = () => blTradeDecline();
  const first = offer.mode === 'sell' ? pick([`${fmtK(offer.price)}, good deal`, 'cheapest on server', `its ${fmtK(offer.price)}, u want it?`, 'no lowballs pls', 'good roll on this one']) : pick([`${fmtK(offer.price)} for ur ${itemName(offer.item)}?`, 'fair price imo', `i need that ${SLOTNAME[ITEMS[offer.item.id].slot] ? SLOTNAME[ITEMS[offer.item.id].slot].toLowerCase() : 'item'}`, `${fmtK(offer.price)}, more than the npc gives`]);
  TR.cur = { bot, offer, el, line: blStyle(bot, first) };
  if (window.UI && UI.wins) UI.wins.trade = { el, body: el.querySelector('.wb'), render: () => blRenderTrade(), id: 'trade' };
  bot.holdT = S.time + 120; bot.path = null; blFace(bot, S.player);
  blRenderTrade(); sfx('whisper');
}
function blRenderTrade() {
  const T = TR.cur; if (!T) return; const b = T.bot, o = T.offer, P = S.P; const body = T.el.querySelector('.wb');
  const itemCell = it => `<div class="bt-item"><div class="slot bt-ic" style="background-image:url(${blIcon(it.id)})">${it.n > 1 ? `<span class="c">${it.n}</span>` : ''}</div><div class="bt-in"><div class="bt-nm" style="color:${itemColor(it)}">${esc(itemName(it))}${it.n > 1 ? ' x' + it.n : ''}</div><div class="bt-st">${blStatLine(it)}</div><div class="bt-v">Value ${fmt(sellPrice(it))} g</div></div></div>`;
  const goldCell = g => `<div class="bt-item"><div class="bt-coin" aria-hidden="true"></div><div class="bt-in"><div class="bt-gold">${fmt(g)}</div><div class="bt-st">gold</div></div></div>`;
  const them = o.mode === 'sell' ? itemCell(o.item) : goldCell(o.price), you = o.mode === 'sell' ? goldCell(o.price) : itemCell(o.item);
  const short = o.mode === 'sell' && P.gold < o.price;
  body.innerHTML = `<div class="bt-who"><b>${esc(b.name)}</b><span class="muted small">Lv ${b.lv} ${CLASSES[b.cls].name}${b.guild ? ' · ' + esc(b.guild) : ''}</span></div>
  <div class="bt-cols"><div class="bt-side"><div class="bt-h">${esc(b.name)} gives</div>${them}</div><div class="bt-side"><div class="bt-h">You give</div>${you}</div></div>
  <div class="bt-say">“${esc(T.line || '')}”</div>
  <div class="row small" style="margin-top:6px"><span class="muted">Your gold</span><span style="color:${short ? '#ff7a6a' : '#f0d070'};font-variant-numeric:tabular-nums">${fmt(P.gold)} g${short ? ' (not enough)' : ''}</span></div>
  <div class="bt-btns"><button class="btn" data-t="h" ${o.last ? 'disabled' : ''}>Haggle</button><button class="btn" data-t="d">Decline</button><button class="btn gold" data-t="a">Accept</button></div>`;
  body.querySelectorAll('[data-t]').forEach(bt => { bt.onclick = () => { sfx('click'); const k = bt.dataset.t; if (k === 'h') blTradeHaggle(); else if (k === 'd') blTradeDecline(); else blTradeAccept(); }; });
}
function blTradeHaggle() {
  const T = TR.cur; if (!T) return; const o = T.offer, b = T.bot; if (o.last) return;
  o.haggles++;
  const chance = .45 - (o.haggles - 1) * .06 - o.annoy * .05;
  if (R() < chance) {
    const f = .08 + R() * .07;
    if (o.mode === 'sell') o.price = Math.max(blRound(o.base * 1.15), blRound(o.price * (1 - f))); else o.price = Math.min(blRound(o.base * 2.75), blRound(o.price * (1 + f)));
    if (o.haggles >= 2 || R() < .3) { o.last = true; T.line = pick([`fine, ${fmtK(o.price)}, last offer`, `ok ok ${fmtK(o.price)}, final`, `ugh fine, ${fmtK(o.price)}`]); } else T.line = pick([`${fmtK(o.price)} then`, `ok ${fmtK(o.price)}`, `meet u at ${fmtK(o.price)}`, `fine, ${fmtK(o.price)}`]);
    T.line = blStyle(b, T.line); sfx('gold');
  } else {
    o.annoy++;
    if (R() < (o.annoy >= 2 ? .7 : .35)) { blTradeEnd(false, pick(['nvm then', 'forget it', 'ur wasting my time', 'lol no, bye', 'not worth it']), true); return; }
    T.line = blStyle(b, pick(o.mode === 'sell' ? ['thats already cheap', 'no', 'take it or leave it', `${fmtK(o.price)} is fair`, 'lol no', 'cant go lower'] : ['no', 'take it or leave it', `${fmtK(o.price)} is fair`, 'cant go higher', 'npc gives u way less lol']));
  }
  if (blNear(b, 14)) say(b, T.line);
  blRenderTrade();
}
function blTradeAccept() {
  const T = TR.cur; if (!T) return; const o = T.offer, b = T.bot, P = S.P;
  if (!blAlive(b)) { blTradeClose('gone'); return; }
  if (o.mode === 'sell') {
    if (P.gold < o.price) { sys('Not enough gold.'); sfx('error'); T.line = blStyle(b, pick(['u dont have enough gold lol', 'come back with gold', 'short on gold?'])); blRenderTrade(); return; }
    if (!invAdd(o.item)) { sys('Your bag is full.'); sfx('error'); T.line = blStyle(b, 'ur bag is full lol'); blRenderTrade(); return; }
    P.gold -= o.price;
    chat('loot', `Traded ${fmt(o.price)} gold to ${b.name} for ${itemName(o.item)}${o.item.n > 1 ? ' x' + o.item.n : ''}`, itemColor(o.item));
    if (o.vendor && b.shop) { b.shop = null; setTimeoutGame(20 + R() * 40, () => { if (blAlive(b) && b.act && b.act.k === 'vendor') blStockVendor(b); }); }
  } else {
    const i = P.inv.indexOf(o.item);
    if (i < 0) { sys(`You no longer have ${itemName(o.item)}.`); sfx('error'); blTradeEnd(false, 'u dont even have it anymore lol', false); return; }
    P.inv[i] = null; P.gold += o.price;
    chat('loot', `Traded ${itemName(o.item)}${o.item.n > 1 ? ' x' + o.item.n : ''} to ${b.name} for ${fmt(o.price)} gold`, '#f0d070');
  }
  sfx('gold'); sys(`Trade with ${b.name} complete.`); if (window.UI) UI.invDirty = true; b.traded = S.time;
  blTradeEnd(true, pick(['ty!', 'pleasure', 'gl with it', 'ty, enjoy', 'ty :)', 'nice doing business']), false);
}
function blTradeDecline() { const T = TR.cur; if (!T) return; sys('Trade declined.'); blTradeEnd(false, R() < .6 ? pick(['k', 'np', 'ur loss', 'ok np, pm me if u change ur mind', 'fine']) : null, false); }
function blTradeEnd(done, line, walkAway) {
  const T = TR.cur; if (!T) return; const b = T.bot;
  blTradeClose(null);
  if (!blAlive(b)) return;
  b.holdT = 0;
  if (line) { const t = blStyle(b, line); if (blNear(b, 14)) botSay(b, t); else blWhisper(b, t); }
  if (walkAway) {
    sys(`${b.name} cancelled the trade.`); b.tradeMad = S.time;
    if (b.mode === 'town') { if (!(b.act && b.act.k === 'vendor')) { b.act = null; b.plan = ['wander'].concat(b.plan || []); } }
    else { const s = randomFree(S.map, b.x, b.y, 8, (x, y) => cheb(x, y, S.player.x, S.player.y) > 5); if (s) b.dest = s; b.target = null; }
  }
}
function blTradeClose(why) {
  const T = TR.cur; if (!T) return; TR.cur = null;
  try { T.el.remove(); } catch (err) { }
  if (window.UI && UI.wins && UI.wins.trade && UI.wins.trade.el === T.el) delete UI.wins.trade;
  if (T.bot) T.bot.holdT = 0;
  if (why === 'gone' || why === 'far') sys(`${T.bot.name} ${why === 'far' ? 'moved too far away' : 'left'}. Trade cancelled.`);
}
function blTradeTick() {
  const T = TR.cur; if (!T) return;
  if (!document.body.contains(T.el)) { TR.cur = null; if (T.bot) T.bot.holdT = 0; return; } /* closed with Esc */
  if (!blAlive(T.bot)) { blTradeClose('gone'); return; }
  if (!S.player || S.dead || cheb(T.bot.x, T.bot.y, S.player.x, S.player.y) > 16) { blTradeClose('far'); return; }
}
function blEnsureReq() {
  if (TR.reqEl && document.body.contains(TR.reqEl)) return TR.reqEl;
  blEnsureCss(); const el = document.createElement('div'); el.id = 'bt-req'; el.className = 'frame';
  (document.getElementById('app') || document.body).appendChild(el); TR.reqEl = el; return el;
}
function blReqTrade(bot, offer, note) {
  if (!blAlive(bot) || TR.cur || TR.req || S.dead) return false;
  const el = blEnsureReq();
  el.innerHTML = `<div><b>${esc(bot.name)}</b> <span class="muted">(Lv ${bot.lv} ${CLASSES[bot.cls].name})</span> wants to trade with you.${note ? `<div class="small muted" style="margin-top:2px">${esc(note)}</div>` : ''}</div><div class="row"><button class="btn gold" data-r="y" style="padding:4px 14px">Accept</button><button class="btn" data-r="n" style="padding:4px 14px">Decline</button></div>`;
  el.style.display = 'block'; sfx('whisper');
  const done = ok => { if (!TR.req) return; clearTimeout(TR.req.tm); TR.req = null; el.style.display = 'none'; if (ok) { if (blAlive(bot)) botTradeUI(bot, offer && blOfferValid(offer) ? offer : null); } else if (blAlive(bot) && R() < .6) blWhisper(bot, pick(['ok np', 'k', 'nvm then'])); };
  TR.req = { bot, offer, tm: setTimeout(() => done(false), 15000) };
  el.querySelector('[data-r="y"]').onclick = () => { sfx('click'); done(true); };
  el.querySelector('[data-r="n"]').onclick = () => { sfx('click'); done(false); };
  bot.holdT = S.time + 15; blFace(bot, S.player);
  return true;
}

/* ================= WORLD TICK (replaces js4's) ================= */
function blSecond() {
  const T = BL.t;
  for (const k in T) if (k !== 'sec') T[k] -= 1;
  for (const k in BL.pend) if (S.time - BL.pend[k].t > 300) delete BL.pend[k];
  if (T.pop <= 0) { T.pop = 5; blPopTick(); }
  if (T.shout <= 0) { T.shout = 6 + R() * 7 + (1 - blCurve()) * 4; if (blQuiet(2, 12, 'shout') && blQuiet(5, 12)) blShout(); else T.shout = 2; }
  if (T.say <= 0) { T.say = 12 + R() * 14; if (blQuiet(1, 10, 'say') && blQuiet(4, 12)) blLocalSay(); }
  if (T.grp <= 0) { T.grp = 4 + R() * 4; blGroupTick(); }
  if (T.ping <= 0) { T.ping = 12; blPing(); }
  if (T.pk <= 0) { T.pk = 15 + R() * 15; blPkWatch(); }
  if (T.guild <= 0) { T.guild = 35 + R() * 45; if (S.P.guild && blQuiet(4, 12)) blGuildChat(); }
  if (T.party <= 0) { T.party = 35 + R() * 50; if (S.party.length && blQuiet(4, 12)) blPartyChat(); }
  blDayNight(); blTradeTick(); blHelpTick();
}
function worldTick(dt) {
  S.siegeT -= dt;
  if (R() < dt * .5) { const target = 900 + 750 * blCurve(); S.online = Math.round(clamp(S.online + (target - S.online) * .04 + rnd(-5, 5), 700, 1900)); }
  BL.t.sec -= dt;
  if (BL.t.sec <= 0) { BL.t.sec += 1; if (BL.t.sec < 0) BL.t.sec = 1; try { blSecond(); } catch (err) { console.error(err); } }
  const G2 = S.P.guild;
  if (S.siegeT <= 0) {
    if (!S.siegeOn) { S.siegeOn = 1; S.siegeT = 120; chat('shout', 'The siege of Castle Varn has begun!', 'System'); if (G2 && G2.members.length) chat('guild', 'SIEGE STARTED, everyone to Varn!!', pick(G2.members).name); }
    else {
      S.siegeOn = 0; S.siegeT = 900 + R() * 300; const contenders = GUILDS.map(g => g.name).concat(G2 && G2.own ? [G2.name] : []);
      let w = pick(contenders); if (G2 && R() < (G2.own ? .15 + G2.members.length * .01 : .3)) w = G2.name; S.castle = w;
      chat('shout', `${w} has conquered Castle Varn!`, 'System'); if (G2 && w === G2.name) { sys('Your guild holds Castle Varn! Guild members gain +10% experience.'); sfx('rare'); }
    }
  }
  if (G2) { for (const m of G2.members) if (R() < dt * .004) m.on = !m.on; }
  for (const b of S.party.slice()) if (S.time > b.partyUntil && b.helpOff) blHelpLeave(b, pick(['gtg, gl!', 'np, good luck', 'gl with ur quest', 'cya, whisper me if u need help']));
  for (const b of S.party.slice()) if (S.time > b.partyUntil) { chat('party', blStyle(b, pick(['gtg, thx for the group', 'bed time, cya', 'ty all, logging', 'gtg, ty for grp', 'cya, was fun'])), b.name); leaveParty(b); botLeave(b, 'teleport'); }
}

window.botTradeUI = botTradeUI;
window.BOTLIFE = { BL, TR, spawnTownBot, spawnFieldBot, spawnFieldGroup, blReqTrade, blGroups, blSellOffer, blBuyOffer };
