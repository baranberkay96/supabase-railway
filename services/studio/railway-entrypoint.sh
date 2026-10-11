#!/bin/sh
# Supabase Studio entrypoint for Railway: derives the API keys from JWT_SECRET
# (same keys as every other service) and hands over to the image's entrypoint.
set -eu
. /usr/local/bin/supabase-keys.sh
SUPABASE_ANON_KEY="${ANON_KEY}"
SUPABASE_SERVICE_KEY="${SERVICE_ROLE_KEY}"
export SUPABASE_ANON_KEY SUPABASE_SERVICE_KEY
mkdir -p "${SNIPPETS_MANAGEMENT_FOLDER:-/app/snippets}"
exec docker-entrypoint.sh "$@"
