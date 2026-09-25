"""Screenshots of the title screen and character creation (tests/_shots/title.png, create_*.png).
    python3 tests/screens.py
"""
import asyncio, os
from playwright.async_api import async_playwright
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'tests', '_shots'); os.makedirs(OUT, exist_ok=True)

async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(); pg = await b.new_page(viewport={'width': 1600, 'height': 900})
        errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
        await pg.goto('file://' + os.path.join(ROOT, 'index.html')); await pg.wait_for_timeout(2500)
        await pg.screenshot(path=os.path.join(OUT, 'title.png'))
        await pg.click('#create'); await pg.wait_for_timeout(2500)
        await pg.screenshot(path=os.path.join(OUT, 'create_W.png'))
        await pg.click('.cls[data-c="M"]'); await pg.click('#headchips .chip[data-h="mage"]'); await pg.click('#hairsw i[data-h="#e8e8e8"]'); await pg.wait_for_timeout(1800)
        await pg.screenshot(path=os.path.join(OUT, 'create_M.png'))
        await pg.click('.cls[data-c="T"]'); await pg.click('#bodychips .chip[data-f="1"]'); await pg.click('#hairsw i[data-h="#a0522d"]'); await pg.wait_for_timeout(1800)
        await pg.screenshot(path=os.path.join(OUT, 'create_T.png'))
        print('errors:', errs[:5])
        await b.close()
asyncio.run(main())
