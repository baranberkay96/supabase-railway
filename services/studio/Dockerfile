# Supabase Studio for Railway (image pinned to the self-hosted/v0.8.2 release).
FROM supabase/studio:2026.09.07-sha-7996410

RUN set -eux; \
    if ! command -v openssl >/dev/null 2>&1; then \
        apt-get update; apt-get install -y --no-install-recommends openssl; rm -rf /var/lib/apt/lists/*; \
    fi; \
    openssl version

COPY supabase-keys.sh railway-entrypoint.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/supabase-keys.sh /usr/local/bin/railway-entrypoint.sh

# Setting ENTRYPOINT resets the inherited CMD, so CMD is repeated from the base image.
ENTRYPOINT ["/bin/sh", "/usr/local/bin/railway-entrypoint.sh"]
CMD ["node", "apps/studio/server.js"]
