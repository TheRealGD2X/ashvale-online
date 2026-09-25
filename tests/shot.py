"""Visual check: opens the game headlessly, makes a character, waits for sprites to load and saves
screenshots (tests/_shots/). Optional args: class letter (W/M/T) and a JS snippet to run before the shot.

    python3 tests/shot.py W
    python3 tests/shot.py W "S.player.atk=0.4"
"""
import asyncio, sys, os
from playwright.async_api import async_playwright
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLS = sys.argv[1] if len(sys.argv) > 1 else 'W'
JS = sys.argv[2] if len(sys.argv) > 2 else ''
OUT = os.path.join(ROOT, 'tests', '_shots'); os.makedirs(OUT, exist_ok=True)

async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(); pg = await b.new_page(viewport={'width': 1280, 'height': 800})
        errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
        await pg.goto('file://' + os.path.join(ROOT, 'index.html')); await pg.wait_for_timeout(600)
        await pg.click('#create'); await pg.wait_for_timeout(200)
        await pg.fill('#cname', 'Tester'); await pg.click(f'.cls[data-c="{CLS}"]'); await pg.click('#go')
        await pg.wait_for_timeout(1500)
        # ask for the atlases and wait until they're in
        await pg.evaluate("() => { ATLAS.get('knight'); ATLAS.get('w_sword_1h'); }")
        for _ in range(40):
            ok = await pg.evaluate("() => !!(ATLAS.atlases.knight && ATLAS.atlases.knight.ready)")
            if ok: break
            await pg.wait_for_timeout(250)
        if JS: await pg.evaluate("() => { " + JS + " }")
        await pg.wait_for_timeout(300)
        await pg.screenshot(path=os.path.join(OUT, f'{CLS}_full.png'))
        # zoomed crop around the player
        pos = await pg.evaluate("() => { const p=S.player; return [ (epx(p)-S.cam.ox)*S.zoom, (epy(p)-S.cam.oy)*S.zoom ]; }")
        x, y = pos
        await pg.screenshot(path=os.path.join(OUT, f'{CLS}_zoom.png'), clip={'x': max(0, x - 200), 'y': max(0, y - 160), 'width': 400, 'height': 260})
        print('atlas ready:', ok, 'errors:', errs[:3])
        await b.close()
asyncio.run(main())
