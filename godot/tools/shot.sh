#!/bin/sh
# Render a screenshot of the game in the cloud workspace (software Vulkan, slow but faithful).
#   sh tools/shot.sh out.png [game options...]     e.g. --hour=17 --cam=0,20,40,0,2,0 --lite
cd "$(dirname "$0")/.."
OUT="$1"; shift
W=${W:-1600}; H=${H:-900}
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json timeout ${TMO:-480} xvfb-run -a -s "-screen 0 ${W}x${H}x24" \
  godot --path . --resolution ${W}x${H} --windowed -- --shot="$OUT" "$@" 2>&1 | grep -vE "ALSA|audio|^$|init_output|at: (init|initialize)|dummy driver" | tail -${LINES:-15}
