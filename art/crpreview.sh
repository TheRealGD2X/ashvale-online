#!/bin/sh
# Quick look at creatures: builds them and renders a few directions/poses into one sheet.
#   sh art/crpreview.sh boar wolf hen      → art/_render/_crpreview.png
cd "$(dirname "$0")/.."
mkdir -p art/_render/_prev
for n in "$@"; do
  python3 art/creatures.py $n > /dev/null 2>&1
  python3 - "$n" <<'PY'
import json, sys
n = sys.argv[1]; j = json.load(open(f'art/jobs/cr_{n}.json')); j['name'] = 'prev_' + n; j['samples'] = 8
json.dump(j, open(f'art/_render/_prev/{n}.json', 'w'))
PY
  python3 art/render.py art/_render/_prev/$n.json --dirs 2,3,4,6 --anims idle,walk,attack --out art/_render/_prev/$n > /dev/null 2>&1
done
python3 - "$@" <<'PY'
import sys, json
from PIL import Image
names = sys.argv[1:]; C = 160
sheet = Image.new('RGBA', (C * 8, C * len(names)), (76, 90, 58, 255))
for r, n in enumerate(names):
    for k, (an, d, i) in enumerate([('idle', 2, 0), ('idle', 3, 0), ('idle', 4, 0), ('idle', 6, 0), ('walk', 3, 2), ('walk', 2, 5), ('attack', 3, 3), ('attack', 2, 2)]):
        try: im = Image.open(f'art/_render/_prev/{n}/{an}_{d}_{i}.png')
        except Exception: continue
        ax, ay = im.width // 2, int(im.height * .7); sheet.alpha_composite(im.crop((ax - C // 2, ay - C + 30, ax + C // 2, ay + 30)), (k * C, r * C))
sheet.save('art/_render/_crpreview.png'); print('ok')
PY
