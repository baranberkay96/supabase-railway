#!/bin/sh
# Supabase Storage entrypoint for Railway: derives the API keys from JWT_SECRET
# (same keys as every other service) and hands over to the image's entrypoint.
set -eu
. /usr/local/bin/supabase-keys.sh
SERVICE_KEY="${SERVICE_ROLE_KEY}"
export ANON_KEY SERVICE_KEY
exec docker-entrypoint.sh "$@"
