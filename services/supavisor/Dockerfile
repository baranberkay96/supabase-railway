# Supavisor connection pooler for Railway (image pinned to the self-hosted/v0.8.2 release).
# pooler.exs creates the pooler tenant on first start (upstream bind-mounts it).
FROM supabase/supavisor:2.9.12

COPY pooler.exs /etc/pooler/pooler.exs

# Same start sequence as upstream docker-compose: migrate metadata DB, seed tenant, serve.
CMD ["/bin/sh", "-c", "/app/bin/migrate && /app/bin/supavisor eval \"$(cat /etc/pooler/pooler.exs)\" && /app/bin/server"]
