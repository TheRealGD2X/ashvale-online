"""Contact sheet of icons for review: python3 art/icon_sheet.py out.png name1 name2 ... (or a prefix list)"""
import sys, os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = os.path.join(ROOT, 'godot', 'assets', 'icons')
out = sys.argv[1]; names = sys.argv[2:]
W = 128; cols = 6; rows = (len(names) + cols - 1) // cols
sheet = Image.new('RGB', (cols * (W + 8) + 8, rows * (W + 24) + 8), (28, 26, 30))
dr = ImageDraw.Draw(sheet)
for i, n in enumerate(names):
    p = os.path.join(D, n + '.png')
    x = 8 + (i % cols) * (W + 8); y = 8 + (i // cols) * (W + 24)
    if os.path.exists(p): sheet.paste(Image.open(p).convert('RGB').resize((W, W), Image.LANCZOS), (x, y))
    dr.text((x, y + W + 4), n, fill=(220, 210, 190))
sheet.save(out)
