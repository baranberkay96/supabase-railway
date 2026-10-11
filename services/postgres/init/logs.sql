-- From supabase/supabase docker/volumes/db/logs.sql at tag self-hosted/v0.8.2 (Apache-2.0, Copyright Supabase). Unchanged.
\set pguser `echo "$POSTGRES_USER"`

\c _supabase
create schema if not exists _analytics;
alter schema _analytics owner to :pguser;
\c postgres
