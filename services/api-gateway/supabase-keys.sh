#!/bin/sh
# supabase-keys.sh - derive the Supabase legacy API keys from JWT_SECRET.
#
# Source this file (". /usr/local/bin/supabase-keys.sh"). It exports ANON_KEY and
# SERVICE_ROLE_KEY as HS256-signed JWTs. The claims are fixed, so every service that
# sources this file with the same JWT_SECRET gets byte-identical keys - no service has
# to hand keys to another at deploy time. Values that are already set (non-empty) are
# kept, which lets you pin externally generated keys.
#
# The signing routine is adapted from supabase/supabase docker/utils/generate-keys.sh
# (Apache-2.0; portions Copyright 2025 Inder Singh, Apache-2.0). Changes: fixed iat/exp
# instead of "now", no file output.
#
# Identical copies live in services/api-gateway, studio, storage and functions (each
# Railway build context only sees its own directory). Keep them byte-identical.

SUPABASE_KEYS_IAT=1767225600   # 2026-01-01T00:00:00Z
SUPABASE_KEYS_EXP=2082758400   # 2036-01-01T00:00:00Z

supabase_b64url() {
    openssl base64 -A | tr '+/' '-_' | tr -d '='
}

supabase_jwt() {
    _sk_header='{"alg":"HS256","typ":"JWT"}'
    _sk_payload="{\"role\":\"$1\",\"iss\":\"supabase\",\"iat\":${SUPABASE_KEYS_IAT},\"exp\":${SUPABASE_KEYS_EXP}}"
    _sk_content="$(printf '%s' "$_sk_header" | supabase_b64url).$(printf '%s' "$_sk_payload" | supabase_b64url)"
    _sk_sig="$(printf '%s' "$_sk_content" | openssl dgst -binary -sha256 -hmac "$JWT_SECRET" | supabase_b64url)"
    printf '%s.%s' "$_sk_content" "$_sk_sig"
}

if [ -z "${JWT_SECRET:-}" ]; then
    echo "supabase-keys: JWT_SECRET is not set" >&2
    exit 1
fi
if [ "${#JWT_SECRET}" -lt 32 ]; then
    echo "supabase-keys: JWT_SECRET must be at least 32 characters" >&2
    exit 1
fi
if ! command -v openssl >/dev/null 2>&1; then
    echo "supabase-keys: openssl not found in image" >&2
    exit 1
fi

if [ -z "${ANON_KEY:-}" ]; then
    ANON_KEY="$(supabase_jwt anon)"
fi
if [ -z "${SERVICE_ROLE_KEY:-}" ]; then
    SERVICE_ROLE_KEY="$(supabase_jwt service_role)"
fi
export ANON_KEY SERVICE_ROLE_KEY
unset _sk_header _sk_payload _sk_content _sk_sig
