# Notice

## Upstream software

| Component | License | Image (publisher) |
|---|---|---|
| Supabase self-hosting configuration (`supabase/supabase` `docker/`) | Apache-2.0 | — (files adapted, see below) |
| Supabase Postgres | PostgreSQL License (`supabase/postgres` repo); bundled extensions under their own licenses | `supabase/postgres` (Supabase) |
| Supabase Studio | Apache-2.0 | `supabase/studio` (Supabase) |
| Supabase Auth (GoTrue) | MIT | `supabase/gotrue` (Supabase) |
| PostgREST | MIT | `postgrest/postgrest` (PostgREST) |
| Supabase Realtime | Apache-2.0 | `supabase/realtime` (Supabase) |
| Supabase Storage API | Apache-2.0 | `supabase/storage-api` (Supabase) |
| postgres-meta | Apache-2.0 | `supabase/postgres-meta` (Supabase) |
| Supabase Edge Runtime | MIT | `supabase/edge-runtime` (Supabase) |
| Supavisor | Apache-2.0 | `supabase/supavisor` (Supabase) |
| imgproxy | Apache-2.0 (open-source edition) | `darthsim/imgproxy` (imgproxy) |
| Envoy | Apache-2.0 | `envoyproxy/envoy` (Envoy Project) |

## Verified against

| What | Source | Ref | Checked |
|---|---|---|---|
| Service list, images, env vars, commands | `docker/docker-compose.yml`, `docker/.env.example` — https://github.com/supabase/supabase/tree/self-hosted/v0.8.2/docker | tag `self-hosted/v0.8.2` (commit 564eab8ad784, 2026-09-23) | 2026-10-10 |
| Release notes, deprecations (Kong, MinIO), optional overrides | `docker/CHANGELOG.md`, `docker-compose.logs.yml`, `docker-compose.s3.yml` | same tag | 2026-10-10 |
| Gateway config | `docker/volumes/api/envoy/{envoy.yaml,cds.yaml,lds.template.yaml,docker-entrypoint.sh}` | same tag | 2026-10-10 |
| Key generation | `docker/utils/generate-keys.sh`, `docker/utils/add-new-auth-keys.sh` | same tag | 2026-10-10 |
| DB init scripts, pooler seed, functions main | `docker/volumes/db/*.sql`, `docker/volumes/pooler/pooler.exs`, `docker/volumes/functions/*` | same tag | 2026-10-10 |
| Postgres image config (data_directory, pg_hba, pgsodium getkey, migrate.sh) | https://github.com/supabase/postgres (`ansible/files/...`, `migrations/db/migrate.sh`, `Dockerfile-17`) | tag `17.6.1.136` | 2026-10-10 |
| Storage env names (S3 backend, checksums, SERVER_HOST) | https://github.com/supabase/storage `src/config.ts`, `src/storage/backend/s3/adapter.ts` | tag `v1.74.0` | 2026-10-10 |
| Realtime IPv6 detection and `/healthcheck` | https://github.com/supabase/realtime `config/runtime.exs`, `lib/realtime_web/router.ex` | tag `v2.134.10` | 2026-10-10 |
| Supavisor IPv6 settings | https://github.com/supabase/supavisor `config/runtime.exs`, `lib/supavisor/helpers.ex` | tag `v2.9.12` | 2026-10-10 |
| Edge runtime CLI flags | https://github.com/supabase/edge-runtime `cli/src/flags.rs` | tag `v1.76.2` | 2026-10-10 |
| postgres-meta env names | https://github.com/supabase/postgres-meta `src/server/constants.ts` | tag `v0.99.0` | 2026-10-10 |
| Image tags exist | Docker Hub tag API for all 11 images | — | 2026-10-10 |
| Railway Bucket behaviour | https://docs.railway.com/guides/storage-buckets | — | 2026-10-10 |

## Adapted code

From `supabase/supabase` (https://github.com/supabase/supabase), tag `self-hosted/v0.8.2`, licensed under the Apache License 2.0, Copyright (c) Supabase, Inc. Each adapted file carries a header naming its source and changes.

| Template file | Upstream file | Changes |
|---|---|---|
| `services/api-gateway/envoy.yaml` | `docker/volumes/api/envoy/envoy.yaml` | none |
| `services/api-gateway/cds.template.yaml` | `docker/volumes/api/envoy/cds.yaml` | hosts/ports replaced by placeholders |
| `services/api-gateway/lds.template.yaml` | `docker/volumes/api/envoy/lds.template.yaml` | listener `[::]` + IPv4 compat, `xff_num_trusted_hops: 1`, `/health` route |
| `services/api-gateway/railway-entrypoint.sh` | `docker/volumes/api/envoy/docker-entrypoint.sh` | key derivation, cds templating, escaping, validation |
| `services/*/supabase-keys.sh` | `gen_token` routine in `docker/utils/generate-keys.sh` | fixed iat/exp, no file output. That routine notes: "Portions of this code are derived from Inder Singh's setup.sh shell script. Copyright 2025 Inder Singh. Licensed under Apache License 2.0." |
| `services/postgres/init/*.sql` | `docker/volumes/db/*.sql` | none (header comment only) |
| `services/supavisor/pooler.exs` | `docker/volumes/pooler/pooler.exs` | none (header comment only) |
| `services/functions/functions/main/index.ts` | `docker/volumes/functions/main/index.ts` | `/_internal/health` route |
| `services/functions/functions/deno.jsonc` | `docker/volumes/functions/deno.jsonc` | none (header comment only) |

Apache License 2.0 text: https://www.apache.org/licenses/LICENSE-2.0. Written for this template (not adapted): the Dockerfiles, `pgsodium_getkey.sh`, the Studio/Storage/Functions entrypoints and `functions/hello/index.ts`.

## Reference only (not copied)

- `6ixfalls/supabase` (market template `supabase`): no license file — read for ideas (root-secret key derivation, repo-built Postgres, Envoy gateway layout); no files or text copied.
- `praveen-ks-2001/supabase-kong-railway`, `supabase-postgres-railway`, `supabase-supavisor-railway` (market template `supabase-firebase-alternative`): no license — read only.
- Market template `MGUlUB`: configuration only, nothing copied.

## Trademarks

Supabase is a trademark of Supabase, Inc. Envoy is a project of the Cloud Native Computing Foundation. PostgreSQL is a trademark of the PostgreSQL Community Association. This is a community template and is not affiliated with or endorsed by Supabase, Inc.
