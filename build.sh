#!/bin/sh
# Optional. The game runs straight from index.html — no build step is needed.
# This script makes ONE self-contained file (dist/ashvale.html) that you can
# email or drop anywhere: the stylesheet and every script are inlined in the
# same order index.html loads them.
cd "$(dirname "$0")"
mkdir -p dist
{
  echo '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><title>Ashvale Online</title>'
  echo '<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
  echo '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Cinzel:wght@500;700;900&family=Cinzel+Decorative:wght@700;900&family=Marcellus+SC&family=Alegreya+Sans:wght@400;500;700;800&display=swap">'
  echo '<style>'; cat src/view/style.css; echo '</style></head><body>'
  # body markup = everything in index.html between <body> and the first <script
  sed -n '/^<body>/,/^<!-- Load order/p' index.html | sed '1d;$d'
  echo '<script>'
  for f in $(grep -o 'src="src/[^"]*\.js"' index.html | sed 's/src="//;s/"//'); do cat "$f"; echo; done
  echo '</script></body></html>'
} > dist/ashvale.html
node -e "const fs=require('fs');const s=fs.readFileSync('dist/ashvale.html','utf8');new Function(s.split('<script>')[1].split('</script>')[0]);" \
  && echo "BUILD OK: dist/ashvale.html ($(wc -c < dist/ashvale.html) bytes)"
