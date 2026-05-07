#!/bin/bash
# ============================================================
# Build airaMD for PRODUCTION
# Usage: ./scripts/build_prod.sh [apk|appbundle|ios|ipa]
# ============================================================

set -e

BUILD_TYPE=${1:-appbundle}

if [ ! -f .env.prod ]; then
  echo "❌ .env.prod not found. Copy .env.example to .env.prod and fill in production values."
  exit 1
fi

source .env.prod

echo "🏗️  Building airaMD ($BUILD_TYPE) for PRODUCTION..."

flutter build "$BUILD_TYPE" \
  --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENV=prod

echo "✅ Production build complete!"
