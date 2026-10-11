#!/bin/bash
# pgsodium / Supabase Vault root key for Railway.
#
# The upstream image generates a random key into /etc/postgresql-custom, which upstream
# docker-compose persists with a second named volume. A Railway service has exactly one
# volume, so the key comes from the PGSODIUM_ROOT_KEY variable instead (64 hex chars,
# generated once by the template). Losing or changing it makes Vault secrets unreadable.
# Without the variable, a key file inside PGDATA (on the volume) is used, created on first call.
set -euo pipefail

if [[ -n "${PGSODIUM_ROOT_KEY:-}" ]]; then
    if [[ ! "${PGSODIUM_ROOT_KEY}" =~ ^[0-9a-fA-F]{64}$ ]]; then
        echo "pgsodium_getkey: PGSODIUM_ROOT_KEY must be 64 hexadecimal characters" >&2
        exit 1
    fi
    printf '%s' "${PGSODIUM_ROOT_KEY}"
    exit 0
fi

KEY_FILE="${PGSODIUM_KEY_FILE:-${PGDATA:-/var/lib/postgresql/data/pgdata}/pgsodium_root.key}"
if [[ ! -s "${KEY_FILE}" ]]; then
    echo "pgsodium_getkey: PGSODIUM_ROOT_KEY not set; creating ${KEY_FILE}" >&2
    head -c 32 /dev/urandom | od -A n -t x1 | tr -d ' \n' > "${KEY_FILE}"
    chmod 600 "${KEY_FILE}"
fi
cat "${KEY_FILE}"
