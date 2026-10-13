#!/usr/bin/env bash
# Build web de production pour un hébergeur sans Flutter préinstallé
# (Cloudflare Pages, Vercel...). Même commande que netlify.toml.
# Variables à définir chez l'hébergeur : SUPABASE_URL, SUPABASE_ANON_KEY
# (clé "anon"/"publishable", jamais la clé service_role), SENTRY_DSN optionnel.
set -euo pipefail

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "SUPABASE_URL et SUPABASE_ANON_KEY doivent être définies." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -d _flutter ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b 3.44.7 _flutter
  fi
  export PATH="$PATH:$(pwd)/_flutter/bin"
fi

flutter config --enable-web
flutter pub get
flutter build web --release \
  --dart-define=ENVIRONMENT=prod \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=SENTRY_DSN="${SENTRY_DSN:-}"

# Cloudflare Pages : en-têtes de sécurité et routage (équivalent de
# netlify.toml). L'app utilise des URL en "#/..." : pas de réécriture
# nécessaire, toutes les pages passent par index.html.
cat > build/web/_headers <<'HEADERS'
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(self), microphone=(self), geolocation=()
  Strict-Transport-Security: max-age=31536000; includeSubDomains
HEADERS
