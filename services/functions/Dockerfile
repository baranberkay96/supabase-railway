# Supabase Edge Functions (edge-runtime) for Railway.
# Your functions live in ./functions/<name>/index.ts and are baked into the image:
# add or change a function in git and Railway rebuilds this service.
FROM supabase/edge-runtime:v1.76.2

RUN set -eux; \
    if ! command -v openssl >/dev/null 2>&1; then \
        apt-get update; apt-get install -y --no-install-recommends openssl; rm -rf /var/lib/apt/lists/*; \
    fi; \
    openssl version

COPY functions/ /home/deno/functions/
COPY supabase-keys.sh railway-entrypoint.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/supabase-keys.sh /usr/local/bin/railway-entrypoint.sh

EXPOSE 9000
ENTRYPOINT ["/bin/sh", "/usr/local/bin/railway-entrypoint.sh"]
