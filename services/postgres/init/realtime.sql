-- From supabase/supabase docker/volumes/db/realtime.sql at tag self-hosted/v0.8.2 (Apache-2.0, Copyright Supabase). Unchanged.
\set pguser `echo "$POSTGRES_USER"`

create schema if not exists _realtime;
alter schema _realtime owner to :pguser;
