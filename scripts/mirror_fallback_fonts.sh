#!/usr/bin/env bash
# Copie dans le site les polices de secours que Flutter web va chercher
# d'habitude chez Google (fonts.gstatic.com) : Roboto et les polices Noto
# (emojis, symboles, arabe, cyrillique...). L'appli les lit ensuite chez
# nous (voir web/flutter_bootstrap.js, fontFallbackBaseUrl) : le navigateur
# des joueurs ne contacte jamais Google (RGPD).
# Le téléchargement se fait au moment du build, depuis le serveur de build.
# Usage : scripts/mirror_fallback_fonts.sh build/web
set -euo pipefail

out="${1:-build/web}/fonts/gstatic"
flutter_root="$(cd "$(dirname "$(command -v flutter)")/.." && pwd)"
engine="$flutter_root/bin/cache/flutter_web_sdk/lib/_engine/engine"
list="$(mktemp)"

{
  grep -ohE "'[a-z0-9]+/v[0-9]+/[A-Za-z0-9_.-]+\.(woff2|ttf|otf)'" \
    "$engine/font_fallback_data.dart" "$engine/canvaskit/fonts.dart" | tr -d "'"
  grep -ohE "roboto/v[0-9]+/[A-Za-z0-9_.-]+\.woff2" "$engine/canvaskit/fonts.dart"
} | sort -u > "$list"

count=$(wc -l < "$list")
echo "Polices de secours à copier : $count"

# 8 téléchargements en parallèle ; un échec n'arrête pas le build (le
# caractère concerné s'afficherait juste en carré), mais il est signalé.
failed=0
xargs -P 8 -I{} sh -c '
  mkdir -p "$(dirname "$0/{}")"
  curl -sSfL --retry 3 -o "$0/{}" "https://fonts.gstatic.com/s/{}" || echo "ÉCHEC {}"
' "$out" < "$list" | tee /dev/stderr | grep -q "ÉCHEC" && failed=1 || true

copied=$(find "$out" -type f | wc -l)
echo "Polices de secours copiées : $copied / $count ($(du -sh "$out" | cut -f1))"
[ "$failed" = 0 ] || echo "Attention : certaines polices n'ont pas pu être copiées." >&2
rm -f "$list"
