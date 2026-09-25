"""Sprite gallery: draws characters and monsters through the game's own renderer (ATLAS.drawEntity)
on a ground-coloured board and saves a screenshot per sheet in tests/_shots/. Use it to check scale,
anchors, layering, tints and animations of every sprite set without walking around the game.

    python3 tests/gallery.py                 # every sheet
    python3 tests/gallery.py dirs attack     # one sheet: a Warrior swinging in all 8 directions
Sheets: bodies, heads, dirs [anim], weapons, monsters, looks
"""
import asyncio, sys, os, json
from playwright.async_api import async_playwright
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'tests', '_shots'); os.makedirs(OUT, exist_ok=True)
SHEETS = sys.argv[1:2] or ['bodies', 'heads', 'dirs', 'weapons', 'monsters', 'looks']
ANIM = sys.argv[2] if len(sys.argv) > 2 else None

JS = r"""
async ([sheet, animArg]) => {
  const W = 1600, H = 900, cv = document.createElement('canvas'); cv.width = W; cv.height = H; cv.id = 'gal';
  Object.assign(cv.style, { position: 'fixed', left: 0, top: 0, zIndex: 99999 }); document.body.appendChild(cv);
  const c = cv.getContext('2d');
  const ent = (o) => Object.assign({ kind: 'bot', id: Math.random(), name: 'G' + Math.random(), cls: 'W', lv: 20, dir: 4, mt: 1, walk: 0, idle: 0, atk: -1, cast: -1, castDur: .45, flashT: 0,
                                     dead: false, deadT: 0, buffs: {}, look: {} }, o);
  const LOOK = (cls, armor, weapon, extra) => Object.assign({ skin: '#e0b48a', hair: '#5a3a1a', armor: Object.assign({ c: '#7a5534', style: 'leather' }, armor || {}), weapon: weapon || null }, extra || {});
  const cells = [];   // [entity, x, y, label, size]
  const CLS = { W: 'W', M: 'M', T: 'T' };
  const pose = (e, anim, f) => {   // set entity fields so ATLAS.anim picks `anim` frame f
    if (!anim || anim === 'idle') { e.idle = f / 5; return e; }
    if (anim === 'walk') { e.mt = .5; e.walk = f / 8; return e; }
    if (anim === 'attack' || anim === 'attack2') { e.atk = (f + .5) / 6; e._alt = anim === 'attack2'; e._atkPrev = 0; return e; }
    if (anim === 'cast') { e.cast = (f + .5) / 6; e._castPrev = 0; return e; }
    if (anim === 'raise') { e.cast = (f + .5) / 6; e._castPrev = 0; e._castRaise = true; return e; }
    if (anim === 'die') { e.dead = true; e.deadT = f / 10; return e; }
    if (anim === 'dead') { e.dead = true; e.deadT = 5; return e; }
    if (anim === 'hit') { e._hitT = .25 - (f + .5) / 3 * .25; return e; }
    if (anim === 'sit') { e.sitting = true; return e; }
    e.emote = { name: anim, t: f / 10 }; return e;
  };
  if (sheet === 'bodies') {
    const vs = Object.keys(ATLAS.VARIANT_COL);
    vs.forEach((v, i) => { const base = ATLAS.BASE_OF(v), cls = base === 'mage' ? 'M' : base === 'rogue' ? 'T' : 'W';
      const style = { knight: 'plate', barbarian: 'leather', mage: 'robe', rogue: 'taorobe' }[base];
      for (const [j, d] of [[0, 4], [1, 2]]) cells.push([ent({ cls, dir: d, look: LOOK(cls, { c: ATLAS.VARIANT_COL[v], style }) }), 70 + (i % 9) * 170 + j * 70, 190 + Math.floor(i / 9) * 260, j ? '' : v]); });
  } else if (sheet === 'heads') {
    const hairs = ['#1a1a1a', '#5a3a1a', '#a0522d', '#d8b060', '#e8e8e8', '#6a2a8a'];
    const heads = ['knight', 'barbarian', 'mage', 'rogue', 'hood'];
    heads.forEach((h, r) => hairs.forEach((hc, k) => [4, 1].forEach((d, j) => cells.push([ent({ dir: d, look: LOOK('W', { c: '#9aa2ac', style: 'plate' }, null, { head: h, hair: hc, hoodCol: hc }) }), 60 + k * 260 + j * 80, 150 + r * 165, j ? '' : h + ' ' + hc, 1.4]))));
  } else if (sheet === 'dirs') {
    const anims = animArg ? [animArg] : ['idle', 'walk', 'attack', 'cast'];
    anims.forEach((an, r) => { const n = { idle: 4, walk: 8, attack: 6, cast: 6, attack2: 6, raise: 6, die: 6, hit: 3 }[an] || 4;
      for (let f = 0; f < (anims.length === 1 ? n : 1); f++) for (let d = 0; d < 8; d++) {
        const e = pose(ent({ dir: d, look: LOOK('W', { c: '#9aa2ac', style: 'plate', cape: '#8a2020' }, { k: 'sword', c: '#c7ccd2' }, { helm: null, hairStyle: 'knight', hair: '#6a4a2a' }) }), an, anims.length === 1 ? f : 2);
        cells.push([e, 110 + d * 190, 170 + (anims.length === 1 ? f : r) * (anims.length === 1 ? 118 : 200), (anims.length === 1 ? f : r) === 0 ? 'dir ' + d : '', anims.length === 1 ? 1.2 : 1.6]); } });
  } else if (sheet === 'weapons') {
    const ks = ['sword', 'long', 'axe', 'greataxe', 'staff', 'wand', 'dagger', 'bow', 'boneblade', 'boneaxe', 'skullstaff'];
    ks.forEach((k, i) => [4, 6, 1].forEach((d, j) => { const e = pose(ent({ dir: d, look: LOOK('W', { c: '#4a3628', style: 'leather' }, { k, c: '#c7ccd2' }) }), j === 2 ? 'attack' : 'idle', 2);
      cells.push([e, 80 + (i % 6) * 250 + j * 70, 200 + Math.floor(i / 6) * 330, j ? '' : k, 1.5]); }));
  } else if (sheet === 'monsters') {
    const ids = Object.keys(MON).filter(k => MON[k].body !== 'biped' || ATLAS.MON_SET[k] || MON[k].bone || ATLAS.MON_STYLE[k]);
    ids.forEach((id, i) => { const d = MON[id]; const e = ent({ kind: 'mon', def: d, name: d.name, dir: 3, look: null });
      cells.push([e, 70 + (i % 12) * 128, 150 + Math.floor(i / 12) * 190, id, Math.min(1.6, d.size || 1)]); });
  } else if (sheet === 'looks') {   // what the town looks like: the real bots and npcs in the current map
    const es = S.ents.filter(e => ['bot', 'npc', 'guard', 'player'].includes(e.kind)).slice(0, 36);
    es.forEach((e0, i) => { const e = Object.assign({}, e0, { dir: 4, mt: 1, atk: -1, cast: -1, dead: false, flashT: 0 }); cells.push([e, 70 + (i % 12) * 128, 170 + Math.floor(i / 12) * 240, e.name, 1.3]); });
  }
  // wait for every atlas the sheet asks for
  const draw = () => { c.fillStyle = '#4c5a3a'; c.fillRect(0, 0, W, H); c.strokeStyle = 'rgba(0,0,0,.12)';
    for (let x = 0; x < W; x += 48) { c.beginPath(); c.moveTo(x, 0); c.lineTo(x, H); c.stroke(); } for (let y = 0; y < H; y += 32) { c.beginPath(); c.moveTo(0, y); c.lineTo(W, y); c.stroke(); }
    let ok = 0;
    for (const [e, x, y, label, size] of cells) { c.save(); c.translate(x, y); c.scale(size || 1.6, size || 1.6);
      if (ATLAS.drawEntity(c, e, 0, 0, e.kind === 'mon' ? { size: 1 } : undefined)) ok++; else { c.fillStyle = '#f33'; c.fillRect(-10, -40, 20, 40); }
      c.restore(); c.fillStyle = 'rgba(0,0,0,.8)'; c.fillRect(x - 60, y + 14, 0, 0);
      if (label) { c.font = '12px sans-serif'; c.fillStyle = '#fff'; c.textAlign = 'center'; c.fillText(label, x, y + 30); } }
    return ok; };
  const settled = () => Object.keys(ATLAS.loading).every(n => ATLAS.missing[n] || (ATLAS.atlases[n] && ATLAS.atlases[n].ready));
  for (let t = 0; t < 120; t++) { const ok = draw(); if (ok === cells.length && settled()) break; await new Promise(r => setTimeout(r, 150)); }
  // the tick bookkeeping must not run (no dt), but let lazy atlases finish
  const ok = draw();
  const missing = Object.keys(ATLAS.missing);
  return { cells: cells.length, drawn: ok, missing };
}
"""

async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(); pg = await b.new_page(viewport={'width': 1600, 'height': 900})
        errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
        await pg.goto('file://' + os.path.join(ROOT, 'index.html')); await pg.wait_for_timeout(600)
        await pg.click('#create'); await pg.wait_for_timeout(200)
        await pg.fill('#cname', 'Tester'); await pg.click('.cls[data-c="W"]'); await pg.click('#go')
        await pg.wait_for_timeout(1200)
        await pg.evaluate("() => { S.running = false; }")
        for sh in SHEETS:
            r = await pg.evaluate(JS, [sh, ANIM])
            await pg.screenshot(path=os.path.join(OUT, f'gallery_{sh}{"_" + ANIM if ANIM else ""}.png'))
            await pg.evaluate("() => document.getElementById('gal').remove()")
            print(sh, r)
        print('errors:', errs[:5])
        await b.close()
asyncio.run(main())
