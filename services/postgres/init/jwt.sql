-- From supabase/supabase docker/volumes/db/jwt.sql at tag self-hosted/v0.8.2 (Apache-2.0, Copyright Supabase). Unchanged.
\set jwt_exp `echo "$JWT_EXP"`

ALTER DATABASE postgres SET "app.settings.jwt_exp" TO :'jwt_exp';
