#!/bin/bash
# ============================================================
# Build airaMD for PRODUCTION
# Usage: ./scripts/build_prod.sh [apk|appbundle|ios|ipa]
# ============================================================

set -e

BUILD_TYPE=${1:-appbundle}

if [ -f .env.prod ]; then
  source .env.prod
elif [ -f .env.dev ]; then
  echo "⚠️  .env.prod not found — falling back to .env.dev"
  source .env.dev
else
  echo "❌ No .env.prod or .env.dev found. Please create .env.prod with SUPABASE_URL and SUPABASE_ANON_KEY."
  exit 1
fi

echo "🏗️  Building airaMD ($BUILD_TYPE) for PRODUCTION..."

if [ "$BUILD_TYPE" = "ipa" ]; then
  /Users/faztycoding/development/flutter/bin/flutter build ipa \
    --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=ENV=prod \
    --export-options-plist=ios/ExportOptions.plist
else
  /Users/faztycoding/development/flutter/bin/flutter build "$BUILD_TYPE" \
    --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=ENV=prod
fi

echo "✅ Production build complete!"
