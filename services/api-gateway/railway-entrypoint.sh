#!/bin/sh
# Envoy API gateway entrypoint for Supabase on Railway.
# Adapted from supabase/supabase docker/volumes/api/envoy/docker-entrypoint.sh
# (tag self-hosted/v0.8.2, Apache-2.0, Copyright Supabase). Changes: API keys are derived
# from JWT_SECRET at start (supabase-keys.sh), upstream cluster hosts/ports come from
# Railway private-domain variables, values are escaped before substitution, inputs validated.
set -eu

. /usr/local/bin/supabase-keys.sh

require() {
    for _name in "$@"; do
        eval "_value=\${${_name}:-}"
        if [ -z "$_value" ]; then
            echo "api-gateway: required variable ${_name} is empty" >&2
            exit 1
        fi
    done
}

require SUPABASE_PUBLIC_URL DASHBOARD_USERNAME DASHBOARD_PASSWORD \
    AUTH_HOST REST_HOST REALTIME_HOST STORAGE_HOST FUNCTIONS_HOST META_HOST STUDIO_HOST

case "$DASHBOARD_USERNAME" in
    *[!A-Za-z0-9._-]*)
        echo "api-gateway: DASHBOARD_USERNAME may only contain letters, digits, '.', '_' and '-'" >&2
        exit 1
        ;;
esac

# Escape a value for use on the right-hand side of a sed "s|...|...|" expression.
esc() {
    printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'
}

# Envoy basic auth expects htpasswd-style SHA1 entries.
PASSWORD_HASH="$(printf '%s' "$DASHBOARD_PASSWORD" | openssl sha1 -binary | openssl base64)"
DASHBOARD_BASIC_AUTH="${DASHBOARD_USERNAME}:{SHA}${PASSWORD_HASH}"

echo "Generating Envoy configuration..."

sed -e "s|\${ANON_KEY}|$(esc "$ANON_KEY")|g" \
    -e "s|\${ANON_KEY_ASYMMETRIC}|$(esc "${ANON_KEY_ASYMMETRIC:-}")|g" \
    -e "s|\${SERVICE_ROLE_KEY}|$(esc "$SERVICE_ROLE_KEY")|g" \
    -e "s|\${SERVICE_ROLE_KEY_ASYMMETRIC}|$(esc "${SERVICE_ROLE_KEY_ASYMMETRIC:-}")|g" \
    -e "s|\${SUPABASE_PUBLISHABLE_KEY}|$(esc "${SUPABASE_PUBLISHABLE_KEY:-}")|g" \
    -e "s|\${SUPABASE_SECRET_KEY}|$(esc "${SUPABASE_SECRET_KEY:-}")|g" \
    -e "s|\${SUPABASE_PUBLIC_URL}|$(esc "$SUPABASE_PUBLIC_URL")|g" \
    -e "s|\${DASHBOARD_BASIC_AUTH}|$(esc "$DASHBOARD_BASIC_AUTH")|g" \
    /etc/envoy/lds.template.yaml > /etc/envoy/lds.yaml

sed -e "s|\${AUTH_HOST}|$(esc "$AUTH_HOST")|g" \
    -e "s|\${AUTH_PORT}|${AUTH_PORT:-9999}|g" \
    -e "s|\${REST_HOST}|$(esc "$REST_HOST")|g" \
    -e "s|\${REST_PORT}|${REST_PORT:-3000}|g" \
    -e "s|\${REALTIME_HOST}|$(esc "$REALTIME_HOST")|g" \
    -e "s|\${REALTIME_PORT}|${REALTIME_PORT:-4000}|g" \
    -e "s|\${STORAGE_HOST}|$(esc "$STORAGE_HOST")|g" \
    -e "s|\${STORAGE_PORT}|${STORAGE_PORT:-5000}|g" \
    -e "s|\${FUNCTIONS_HOST}|$(esc "$FUNCTIONS_HOST")|g" \
    -e "s|\${FUNCTIONS_PORT}|${FUNCTIONS_PORT:-9000}|g" \
    -e "s|\${META_HOST}|$(esc "$META_HOST")|g" \
    -e "s|\${META_PORT}|${META_PORT:-8080}|g" \
    -e "s|\${STUDIO_HOST}|$(esc "$STUDIO_HOST")|g" \
    -e "s|\${STUDIO_PORT}|${STUDIO_PORT:-3000}|g" \
    /etc/envoy/cds.template.yaml > /etc/envoy/cds.yaml

if [ -n "${SUPABASE_SECRET_KEY:-}" ] && [ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ] && \
   [ -n "${SERVICE_ROLE_KEY_ASYMMETRIC:-}" ] && [ -n "${ANON_KEY_ASYMMETRIC:-}" ]; then
    echo "Envoy sb_ key translation enabled"
else
    echo "Envoy running in legacy API key mode (sb_ keys disabled)"
fi

# The anon key is public by design (it ships in browser apps); the service role key is not logged.
echo "Supabase URL:      ${SUPABASE_PUBLIC_URL}"
echo "Supabase anon key: ${ANON_KEY}"
echo "Starting Envoy..."

exec envoy -c /etc/envoy/envoy.yaml "$@"
