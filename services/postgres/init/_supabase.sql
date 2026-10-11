-- From supabase/supabase docker/volumes/db/_supabase.sql at tag self-hosted/v0.8.2 (Apache-2.0, Copyright Supabase). Unchanged.
\set pguser `echo "$POSTGRES_USER"`

CREATE DATABASE _supabase WITH OWNER :pguser;
