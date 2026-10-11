# Supabase API gateway (Envoy) for Railway.
# Config files are adapted from supabase/supabase docker/volumes/api/envoy (self-hosted/v0.8.2).
FROM envoyproxy/envoy:v1.39.1

# openssl is used for key derivation and the basic-auth hash (pulled in by ca-certificates
# in the upstream image; installed explicitly if a future base drops it).
RUN set -eux; \
    if ! command -v openssl >/dev/null 2>&1; then \
        apt-get update; apt-get install -y --no-install-recommends openssl; rm -rf /var/lib/apt/lists/*; \
    fi; \
    openssl version

COPY envoy.yaml cds.template.yaml lds.template.yaml /etc/envoy/
COPY supabase-keys.sh railway-entrypoint.sh /usr/local/bin/
RUN chmod 0644 /etc/envoy/*.yaml && chmod 0755 /usr/local/bin/supabase-keys.sh /usr/local/bin/railway-entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/bin/sh", "/usr/local/bin/railway-entrypoint.sh"]
