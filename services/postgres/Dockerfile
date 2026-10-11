# Supabase Postgres for Railway.
# Same image and init scripts as supabase/supabase docker-compose (self-hosted/v0.8.2);
# the scripts that upstream bind-mounts are baked in because Railway has no bind mounts.
FROM supabase/postgres:17.6.1.136

# Init scripts, at the same paths upstream mounts them (run once, on an empty data dir).
COPY init/realtime.sql  /docker-entrypoint-initdb.d/migrations/99-realtime.sql
COPY init/webhooks.sql  /docker-entrypoint-initdb.d/init-scripts/98-webhooks.sql
COPY init/roles.sql     /docker-entrypoint-initdb.d/init-scripts/99-roles.sql
COPY init/jwt.sql       /docker-entrypoint-initdb.d/init-scripts/99-jwt.sql
COPY init/_supabase.sql /docker-entrypoint-initdb.d/migrations/97-_supabase.sql
COPY init/logs.sql      /docker-entrypoint-initdb.d/migrations/99-logs.sql
COPY init/pooler.sql    /docker-entrypoint-initdb.d/migrations/99-pooler.sql

# Vault/pgsodium root key from a Railway variable (see script header).
COPY --chown=postgres:postgres pgsodium_getkey.sh /usr/lib/postgresql/bin/pgsodium_getkey.sh
RUN chmod 0755 /usr/lib/postgresql/bin/pgsodium_getkey.sh

# Railway mounts the volume at /var/lib/postgresql/data; the cluster lives in a
# subdirectory so the volume's lost+found does not block initdb.
ENV PGDATA=/var/lib/postgresql/data/pgdata

CMD ["postgres", \
     "-c", "config_file=/etc/postgresql/postgresql.conf", \
     "-c", "data_directory=/var/lib/postgresql/data/pgdata", \
     "-c", "log_min_messages=fatal"]
