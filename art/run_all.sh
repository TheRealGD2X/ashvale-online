#!/bin/sh
# Renders every job in priority order (playable sets first), packing each as it finishes.
#   nohup sh art/run_all.sh > art/_render/log.txt 2>&1 &
cd "$(dirname "$0")/.."
mkdir -p art/_render
ORDER="${*:-body_plate_iron head_knight helm_knight cape_knight w_sword_1h \
 body_robe_purple head_mage hat_mage cape_mage w_staff \
 body_tao_green head_rogue cape_rogue w_wand \
 sk_warrior sk_minion sk_mage sk_rogue \
 body_leather_hide head_barbarian hat_barbarian cape_barbarian w_sword_2h w_axe_1h w_dagger \
 body_plate_gold body_plate_abyss body_robe_arcane body_robe_abyss body_tao_spirit body_tao_abyss \
 body_plate_dark body_plate_bronze body_leather_dark body_leather_green body_robe_blue body_robe_red body_tao_blue \
 w_axe_2h w_crossbow w_bone_blade w_bone_axe w_bone_staff}"
for j in $ORDER; do
  if [ -f "art/_render/$j/meta.json" ]; then echo "skip $j (rendered)"; continue; fi
  echo "=== $j $(date +%H:%M:%S)"
  python3 art/render.py "art/jobs/$j.json" 2>&1 | grep -E 'done:|missing|Error' 
  python3 art/pack.py "art/_render/$j" 2>&1 | tail -1
done
echo "=== all done $(date +%H:%M:%S)"
