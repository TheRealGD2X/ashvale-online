"""Headless smoke test. Opens index.html in Chromium, creates a character, simulates a minute
of combat in every map, then prints per-map timings, recent chat, render timing and any
console errors. Exit code 1 if there were page errors.

    python3 tests/smoke_test.py            # from the project root
    python3 tests/smoke_test.py --shots    # also saves f_title.png / f_town.png / f_sanctum.png
"""
import asyncio, sys, json, os
from playwright.async_api import async_playwright

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = '--shots' in sys.argv

async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch()
        pg = await b.new_page(viewport={'width': 1280, 'height': 800})
        errs = []
        pg.on('pageerror', lambda e: errs.append('PAGEERR: ' + str(e)))
        pg.on('console', lambda m: errs.append(m.text) if m.type == 'error' and 'ERR_' not in m.text else None)
        await pg.goto('file://' + os.path.join(ROOT, 'index.html'))
        await pg.wait_for_timeout(800)
        if SHOTS: await pg.screenshot(path='f_title.png')
        await pg.click('#create'); await pg.wait_for_timeout(300)
        await pg.fill('#cname', 'Tester'); await pg.click('.cls[data-c="T"]'); await pg.click('#go')
        await pg.wait_for_timeout(2500)
        if SHOTS: await pg.screenshot(path='f_town.png')
        # contract sanity: the event bus exists and is shared by all scripts
        ok = await pg.evaluate("() => typeof EV === 'object' && typeof EV.emit === 'function' && typeof CONTRACT_VERSION === 'number'")
        print('event bus:', 'ok' if ok else 'MISSING')
        res = await pg.evaluate("""()=>{ const out={}; const P=S.P; P.lv=32; for(const k of Object.keys(SKILLS)) if(SKILLS[k].cls==='T') P.skills[k]={rank:2,pts:0,cd:0}; P.keys=['healing','poison','soulfire','skeleton','soulshield','massheal','hound',null]; computeStats();
          for (const m of ['ashvale','mine','mirewood','temple','sanctum']) { const M=getMap(m); changeMap(m,M.start.x,M.start.y); const p=S.player; p.hp=p.maxhp; p.mp=p.maxmp;
            const t0=performance.now(); let n=0;
            for(let i=0;i<1800;i++){ if(i%60===0){ let best=null,bd=99; for(const e of S.ents) if(e.kind==='mon'&&!e.dead){const d=cheb(e.x,e.y,p.x,p.y); if(d<bd){bd=d;best=e;}} p.target=best; if(best && i%120===0) castSkill('soulfire', best); if(i%600===0) castSkill('hound'); if(S.dead){revive(); changeMap(m,M.start.x,M.start.y);} p.hp=Math.max(p.hp,p.maxhp*.5);} update(1/30); n++; }
            out[m]={ms:+((performance.now()-t0)/n).toFixed(3), ents:S.ents.length, bots:S.ents.filter(e=>e.kind==='bot').length, kills:P.kills}; }
          out.chat=CHAT.slice(-12).map(c=>c.ch+':'+(c.from||'')+':'+c.text); return out; }""")
        print(json.dumps(res, indent=1))
        t = await pg.evaluate("()=>{ const t0=performance.now(); for(let i=0;i<30;i++) render(); return [+((performance.now()-t0)/30).toFixed(1), FX.length, PARTS.length, FLOATS.length, S.ents.length, TIMERS.length, S.proj.length, S.map.id]; }")
        print('render ms', t)
        await pg.wait_for_timeout(500)
        if SHOTS: await pg.screenshot(path='f_sanctum.png')
        for e in errs[:20]: print(e)
        await b.close()
        return 1 if any(e.startswith('PAGEERR') for e in errs) else 0

sys.exit(asyncio.run(main()))
