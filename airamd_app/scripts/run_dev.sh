#!/bin/bash
# ============================================================
# Run airaMD in DEV mode
# Usage: ./scripts/run_dev.sh
# ============================================================

set -e

# Load environment from .env.dev
if [ ! -f .env.dev ]; then
  echo "❌ .env.dev not found. Copy .env.example to .env.dev and fill in values."
  exit 1
fi

source .env.dev

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENV=dev
