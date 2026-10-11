#!/bin/sh
# Supabase Edge Functions entrypoint for Railway: derives the API keys from JWT_SECRET
# (same keys as every other service) and starts the edge runtime on [::] so the
# private network works in IPv6-only and dual-stack Railway environments.
set -eu
. /usr/local/bin/supabase-keys.sh
SUPABASE_ANON_KEY="${ANON_KEY}"
SUPABASE_SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY}"
export SUPABASE_ANON_KEY SUPABASE_SERVICE_ROLE_KEY
exec edge-runtime start \
    --main-service /home/deno/functions/main \
    --ip "${FUNCTIONS_LISTEN_IP:-::}" \
    --port "${PORT:-9000}" \
    "$@"
