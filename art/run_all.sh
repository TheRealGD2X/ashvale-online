#!/bin/sh
# Renders every job in priority order (playable sets first), packing each as it finishes.
#   nohup sh art/run_all.sh > art/_render/log.txt 2>&1 &
cd "$(dirname "$0")/.."
mkdir -p art/_render
ORDER="${*:-head_knight hair_knight head_barbarian hair_barbarian head_mage hair_mage head_rogue hair_rogue hair_hood \
 body_leather_hide body_robe_purple body_tao_green body_plate_iron \
 w_sword_1h w_staff w_wand w_dagger w_axe_1h w_sword_2h \
 helm_knight hat_mage hat_barbarian cape_knight cape_mage cape_rogue cape_barbarian \
 sk_warrior sk_minion sk_mage sk_rogue \
 body_plate_dark body_plate_bronze body_plate_gold body_plate_abyss body_leather_dark body_leather_green \
 body_robe_blue body_robe_arcane body_robe_abyss body_robe_red body_tao_spirit body_tao_abyss body_tao_blue \
 w_axe_2h w_crossbow w_bone_blade w_bone_axe w_bone_staff \
 cr_boar cr_deer cr_wolf cr_bear cr_hen cr_spider cr_bat cr_moth cr_snake cr_maggot}"
for j in $ORDER; do
  if [ -f "art/_render/$j/meta.json" ]; then echo "skip $j (rendered)"; continue; fi
  echo "=== $j $(date +%H:%M:%S)"
  case $j in props_*) R=art/render_props.py ;; *) R=art/render.py ;; esac
  python3 $R "art/jobs/$j.json" 2>&1 | grep -E 'done:|missing|Error|!!'
  python3 art/pack.py "art/_render/$j" 2>&1 | tail -2
done
echo "=== all done $(date +%H:%M:%S)"
