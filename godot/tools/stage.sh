#!/bin/sh
# Photo studio render (see tools/stage.gd):  sh tools/stage.sh --out=/tmp/x.png --what=avatars
cd "$(dirname "$0")/.."
W=${W:-1600}; H=${H:-800}
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json timeout ${TMO:-420} xvfb-run -a -s "-screen 0 ${W}x${H}x24" \
  godot --path . --resolution ${W}x${H} --windowed --fixed-fps 30 -s tools/stage.gd -- "$@" 2>&1 | grep -vE "ALSA|audio|^$|init_output|at: (init|initialize)|dummy driver|^\s+\[|GDScript backtrace" | tail -${LINES:-15}
