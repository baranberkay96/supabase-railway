# Supabase Storage API for Railway (image pinned to the self-hosted/v0.8.2 release).
FROM supabase/storage-api:v1.74.0

# Alpine base: openssl CLI is needed for the API key derivation.
RUN apk add --no-cache openssl && openssl version

COPY supabase-keys.sh railway-entrypoint.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/supabase-keys.sh /usr/local/bin/railway-entrypoint.sh

# Setting ENTRYPOINT resets the inherited CMD, so CMD is repeated from the base image.
ENTRYPOINT ["/bin/sh", "/usr/local/bin/railway-entrypoint.sh"]
CMD ["node", "dist/start/server.js"]
