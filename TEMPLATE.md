# Supabase Self-Hosted Backend — Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **Supabase Self-Hosted Backend** (no version label: Supabase self-hosting is a set of separately versioned images; the stack follows the upstream bundle `self-hosted/v0.8.2`) |
| Description | Postgres, auth, storage, realtime, edge functions and Studio in one stack. (74 chars, unchanged) |
| Category | Starters |
| Tags | supabase, postgres, auth, storage, realtime, edge-functions, baas, firebase-alternative |

Everything the description promises is delivered: Postgres, Auth (GoTrue), Storage (on a Railway Bucket), Realtime, Edge Functions and Studio, plus PostgREST, postgres-meta, imgproxy, Supavisor and the Envoy API gateway.

## Base market template

- **Base: `supabase`** (6ixfalls, 213 active projects, the market leader). Kept as ideas: one generated root secret from which every service derives the API keys at start, a repo-built Postgres image so Railway's database tabs work, Storage on a Railway Bucket, Envoy as gateway with Studio behind it. Its repository has **no license**, so nothing was copied; the equivalent files were written from the official Apache-2.0 `supabase/supabase` `docker/` directory. Rejected: secrets tool built from the repo's unpinned `main` branch at image build time, public TCP proxy on Postgres, no Edge Functions, `STORAGE_S3_FORCE_PATH_STYLE=true`.
- `supabase-firebase-alternative` (praveen-ks-2001, 11 active): Postgres 15 image whose start command runs `rm -rf /var/lib/postgresql/data/pgdata` before every start (the database is wiped on each restart/redeploy), Kong gateway (deprecated upstream since 0.8.0), Storage on a local volume, Logflare without Vector. Services reference `ANON_KEY`/`SERVICE_ROLE_KEY` on the postgres service but the template defines no values for them, so keys have to be produced by hand. Its three repos have no license: reference only.
- `MGUlUB` ("Supabase Postgres", 59 active): only an unpinned `supabase/postgres` with a public TCP proxy. Nothing taken.

## Pinned versions

All tags are the ones in upstream `docker/docker-compose.yml` at tag `self-hosted/v0.8.2` (2026-09-23); each was confirmed on Docker Hub on 2026-10-10.

| Service | Image / source | Tag | Image date | Checked |
|---|---|---|---|---|
| Postgres | `services/postgres` → `supabase/postgres` | `17.6.1.136` | 2026-06-15 | 2026-10-10 |
| Gateway | `services/api-gateway` → `envoyproxy/envoy` | `v1.39.1` | 2026-08-27 | 2026-10-10 |
| Studio | `services/studio` → `supabase/studio` | `2026.09.07-sha-7996410` | 2026-09-07 | 2026-10-10 |
| Auth | `supabase/gotrue` | `v2.196.0` | 2026-08-18 | 2026-10-10 |
| REST | `postgrest/postgrest` | `v14.17` | 2026-08-13 | 2026-10-10 |
| Realtime | `supabase/realtime` | `v2.134.10` | 2026-09-07 | 2026-10-10 |
| Storage | `services/storage` → `supabase/storage-api` | `v1.74.0` | 2026-09-07 | 2026-10-10 |
| imgproxy | `darthsim/imgproxy` | `v3.31.4` | 2026-06-09 | 2026-10-10 |
| Meta | `supabase/postgres-meta` | `v0.99.0` | 2026-08-31 | 2026-10-10 |
| Functions | `services/functions` → `supabase/edge-runtime` | `v1.76.2` | 2026-09-02 | 2026-10-10 |
| Supavisor | `services/supavisor` → `supabase/supavisor` | `2.9.12` | 2026-08-29 | 2026-10-10 |

Not included (upstream optional overrides): Analytics/Logflare + Vector (`docker-compose.logs.yml`; Vector collects logs from the Docker socket, which Railway does not expose), Kong (deprecated), MinIO/RustFS (replaced by a Railway Bucket), Caddy/nginx TLS proxies (Railway terminates TLS), PgBouncer (Supavisor is the default pooler).

## Architecture

```
                    Internet (HTTPS, Railway edge)
                                │
                                ▼
                  ┌───────────────────────────┐  /health (Envoy direct response)
                  │ Gateway  (Envoy :8000)    │  apikey checks, CORS, Studio basic auth
                  └─┬──┬───┬───┬───┬───┬───┬──┘
       /auth/v1 ────┘  │   │   │   │   │   └──── /  (basic auth) ──► Studio :3000 ──► Meta :8080
       /rest/v1, /graphql/v1 ──► REST :3000                          (volume /app/snippets)
       /realtime/v1 ──────► Realtime :4000   (Host rewritten to tenant realtime-dev)
       /storage/v1 ───────► Storage :5000 ──► imgproxy :5001
                                  │  └──────► Railway Bucket (S3, presigned for imgproxy)
       /functions/v1 ─────► Functions :9000 (edge-runtime, functions baked from git)
       /pg ───────────────► Meta (service_role key only)
                                  │
     Auth, REST, Realtime, Storage, Meta, Studio, Functions, Supavisor
                                  ▼
                  ┌───────────────────────────┐
                  │ Postgres :5432 (supabase/  │  volume /var/lib/postgresql/data
                  │ postgres 17, private only) │◄── Supavisor :6543 / :5432 (pooler)
                  └───────────────────────────┘
```

**API keys without a key-generation step.** `JWT_SECRET` is generated once on the Gateway service. Every service that needs `ANON_KEY` / `SERVICE_ROLE_KEY` (Gateway, Studio, Storage, Functions) sources `supabase-keys.sh` at start, which signs fixed claims (`role`, `iss=supabase`, `iat=2026-01-01`, `exp=2036-01-01`) with HS256. The output is deterministic, so all services hold byte-identical keys without passing them around, and the template boots with zero manual input. The Gateway prints the anon key (public by design) in its deploy log; Studio shows both keys under Project Settings → API. Auth, REST, Realtime and Supavisor only need `JWT_SECRET` itself. To pin existing keys (migration), set `ANON_KEY`/`SERVICE_ROLE_KEY` on the Gateway; the other services reference them and skip derivation.

**New API keys (optional).** Upstream 0.8.x supports opaque `sb_publishable_…`/`sb_secret_…` keys with ES256 JWTs. They require an EC key pair distributed to Auth, REST, Realtime, Storage and Functions, which cannot be generated by Railway template functions. The template runs upstream's default legacy mode (same as upstream with empty keys); the README explains how to opt in using upstream's `utils/add-new-auth-keys.sh`.

## Services

All services: restart ON_FAILURE (10 retries), 1 replica, no TCP proxy. Only the Gateway has a public domain.

### Postgres
- Source: repo `baranberkay96/supabase-railway`, root `/services/postgres`. Image `supabase/postgres:17.6.1.136` with upstream init SQL baked in at the paths upstream bind-mounts them, `PGDATA` in a subdirectory of the volume, and a `pgsodium_getkey.sh` that reads the Vault root key from `PGSODIUM_ROOT_KEY` (upstream persists it with a second named volume; a Railway service has one volume).
- Start: image CMD `postgres -c config_file=/etc/postgresql/postgresql.conf -c data_directory=/var/lib/postgresql/data/pgdata -c log_min_messages=fatal`.
- Healthcheck: none (TCP). Volume: `/var/lib/postgresql/data`.

| Variable | Value | Description |
|---|---|---|
| POSTGRES_PASSWORD | `${{secret(32, a-zA-Z0-9)}}` | Password of supabase_admin and all Supabase roles; set once. |
| POSTGRES_USER | `supabase_admin` | Image bootstrap superuser (must stay). |
| POSTGRES_DB | `postgres` | Main database. |
| POSTGRES_PORT | `5432` | Used by init scripts. |
| PGDATA | `/var/lib/postgresql/data/pgdata` | Cluster dir inside the volume. |
| PGHOST / PGPORT / PGUSER / PGPASSWORD / PGDATABASE | private domain, `5432`, `postgres`, password, db | Railway Data panel and clients. |
| DATABASE_URL | `postgresql://postgres:…@${{RAILWAY_PRIVATE_DOMAIN}}:5432/postgres` | Direct private connection string. |
| JWT_EXP | `${{Gateway.JWT_EXPIRY}}` | Written to `app.settings.jwt_exp` on first init. |
| PGSODIUM_ROOT_KEY | `${{secret(64, hex)}}` | Vault root key; never change or lose. |
| RAILWAY_DEPLOYMENT_DRAINING_SECONDS | `60` | Clean shutdown. |

### Gateway
- Source: repo root `/services/api-gateway` (Envoy `v1.39.1` + upstream `envoy.yaml`, `cds.yaml`, `lds.template.yaml` adapted: hosts from Railway private domains, listener on `[::]` with IPv4 compatibility, `xff_num_trusted_hops: 1` for Railway's edge, `/health` route).
- Healthcheck `/health` (300 s). Public domain → port 8000.

| Variable | Value | Description |
|---|---|---|
| PORT | `8000` | Envoy port. |
| SUPABASE_PUBLIC_URL | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public project URL; change for a custom domain. |
| JWT_SECRET | `${{secret(64, a-zA-Z0-9)}}` | Project JWT secret; API keys derive from it. |
| JWT_EXPIRY | `3600` | Access token lifetime (s). |
| ANON_KEY / SERVICE_ROLE_KEY | *(empty)* | Optional pinned keys; empty = derived. |
| DASHBOARD_USERNAME | `supabase` | Studio basic-auth user. |
| DASHBOARD_PASSWORD | `${{secret(32, a-zA-Z0-9)}}` | Studio basic-auth password. |
| AUTH_HOST, REST_HOST, REALTIME_HOST, STORAGE_HOST, FUNCTIONS_HOST, META_HOST, STUDIO_HOST | `${{<Service>.RAILWAY_PRIVATE_DOMAIN}}` | Upstream hosts (ports default to upstream values; override with `*_PORT`). |
| SUPABASE_PUBLISHABLE_KEY, SUPABASE_SECRET_KEY, ANON_KEY_ASYMMETRIC, SERVICE_ROLE_KEY_ASYMMETRIC | *(empty)* | Optional new-key mode. |

### Studio
- Source: repo root `/services/studio` (image + key derivation entrypoint). Healthcheck `/api/platform/profile` (300 s). No public domain (served by the Gateway behind basic auth). Volume `/app/snippets`.
- Variables: `PORT=3000`, `HOSTNAME=::`, `STUDIO_PG_META_URL=http://${{Meta.RAILWAY_PRIVATE_DOMAIN}}:8080`, `POSTGRES_HOST/PORT/DB/PASSWORD` (Postgres refs), `POSTGRES_USER_READ_WRITE=postgres`, `PG_META_CRYPTO_KEY=${{Meta.CRYPTO_KEY}}`, `PGRST_DB_SCHEMAS/MAX_ROWS/EXTRA_SEARCH_PATH` (REST refs), `DEFAULT_ORGANIZATION_NAME`, `DEFAULT_PROJECT_NAME`, `OPENAI_API_KEY` (optional), `SUPABASE_URL=http://${{Gateway.RAILWAY_PRIVATE_DOMAIN}}:8000`, `SUPABASE_PUBLIC_URL`, `JWT_SECRET`, `AUTH_JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY` (Gateway refs), `ENABLED_FEATURES_LOGS_ALL=false`, `SNIPPETS_MANAGEMENT_FOLDER=/app/snippets`.

### Auth
- Image `supabase/gotrue:v2.196.0`. Healthcheck `/health` (300 s).
- Variables: `PORT=9999`, `GOTRUE_API_HOST=::`, `GOTRUE_API_PORT=9999`, `API_EXTERNAL_URL=${{Gateway.SUPABASE_PUBLIC_URL}}/auth/v1`, `GOTRUE_DB_DRIVER=postgres`, `GOTRUE_DB_DATABASE_URL` (supabase_auth_admin, private), `GOTRUE_SITE_URL` (defaults to the project URL; set your app URL), `GOTRUE_URI_ALLOW_LIST`, `GOTRUE_DISABLE_SIGNUP=false`, JWT settings (`ADMIN_ROLES=service_role`, `AUD`/`DEFAULT_GROUP_NAME=authenticated`, `EXP`, `SECRET`, `ISSUER`), `GOTRUE_EXTERNAL_EMAIL_ENABLED=true`, `GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED=false`, `GOTRUE_MAILER_AUTOCONFIRM=true` (until SMTP is set), SMTP (`ADMIN_EMAIL`, `HOST`, `PORT=587`, `USER`, `PASS`, `SENDER_NAME`), mailer URL paths `/auth/v1/verify`, `GOTRUE_EXTERNAL_PHONE_ENABLED=false`, `GOTRUE_SMS_AUTOCONFIRM=false`.

### REST
- Image `postgrest/postgrest:v14.17`. Healthcheck `/` (OpenAPI root, 300 s).
- Variables: `PORT=3000`, `PGRST_SERVER_HOST=*`, `PGRST_SERVER_PORT=3000`, `PGRST_DB_URI` (authenticator, private), `PGRST_DB_SCHEMAS=public,graphql_public`, `PGRST_DB_MAX_ROWS=1000`, `PGRST_DB_EXTRA_SEARCH_PATH=public`, `PGRST_DB_ANON_ROLE=anon`, `PGRST_JWT_SECRET`, `PGRST_DB_USE_LEGACY_GUCS=false`, `PGRST_APP_SETTINGS_JWT_EXP`, `PGRST_ADMIN_SERVER_PORT=3001`, `PGRST_ADMIN_SERVER_HOST=localhost`.

### Realtime
- Image `supabase/realtime:v2.134.10`. Healthcheck `/healthcheck` (300 s). IP version for DB and HTTP is auto-detected by the image (IPv6 when available).
- Variables: `PORT=4000`, `DB_HOST/PORT/NAME/PASSWORD` (Postgres refs), `DB_USER=supabase_admin`, `DB_AFTER_CONNECT_QUERY=SET search_path TO _realtime`, `DB_ENC_KEY=${{secret(16, hex)}}`, `API_JWT_SECRET`, `METRICS_JWT_SECRET`, `SECRET_KEY_BASE=${{secret(64)}}`, `ERL_AFLAGS=-proto_dist inet_tcp`, `DNS_NODES=''`, `RLIMIT_NOFILE=10000`, `APP_NAME=realtime`, `SEED_SELF_HOST=true`, `RUN_JANITOR=true`, `DISABLE_HEALTHCHECK_LOGGING=true`.

### Storage
- Source: repo root `/services/storage` (image + `openssl` + key derivation entrypoint). Healthcheck `/status` (300 s).
- Variables: `PORT=5000`, `SERVER_HOST=::`, `JWT_SECRET`, `AUTH_JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY` (Gateway refs), `POSTGREST_URL=http://${{REST.RAILWAY_PRIVATE_DOMAIN}}:3000`, `DATABASE_URL` (supabase_storage_admin), `STORAGE_PUBLIC_URL`, `REQUEST_ALLOW_X_FORWARDED_PATH=true`, `FILE_SIZE_LIMIT=52428800`, `STORAGE_BACKEND=s3`, `GLOBAL_S3_BUCKET/ENDPOINT`, `REGION`, `AWS_ACCESS_KEY_ID/SECRET_ACCESS_KEY` (Bucket refs), `GLOBAL_S3_FORCE_PATH_STYLE=false`, `STORAGE_S3_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED`, `STORAGE_S3_RESPONSE_CHECKSUM_VALIDATION=WHEN_REQUIRED`, `TENANT_ID=stub`, `ENABLE_IMAGE_TRANSFORMATION=true`, `IMGPROXY_URL=http://${{imgproxy.RAILWAY_PRIVATE_DOMAIN}}:5001`, `S3_PROTOCOL_ACCESS_KEY_ID=${{secret(32, hex)}}`, `S3_PROTOCOL_ACCESS_KEY_SECRET=${{secret(64, hex)}}`.

### imgproxy
- Image `darthsim/imgproxy:v3.31.4`. Healthcheck `/health` (120 s). Fetches originals through 10-minute presigned Bucket URLs created by Storage, so it needs no shared volume.
- Variables: `PORT=5001`, `IMGPROXY_BIND=:5001`, `IMGPROXY_USE_ETAG=true`, `IMGPROXY_AUTO_WEBP=true`, `IMGPROXY_MAX_SRC_RESOLUTION=16.8`.

### Meta
- Image `supabase/postgres-meta:v0.99.0`. Healthcheck `/health` (120 s).
- Variables: `PORT=8080`, `PG_META_HOST=::`, `PG_META_PORT=8080`, `PG_META_DB_HOST/PORT/NAME/PASSWORD` (Postgres refs), `PG_META_DB_USER=postgres`, `CRYPTO_KEY=${{secret(48)}}`.

### Functions
- Source: repo root `/services/functions` (edge-runtime + upstream `main` worker with an added `/_internal/health` route + example `hello` function). Healthcheck `/_internal/health` (300 s). Functions are deployed by committing `functions/<name>/index.ts`.
- Variables: `PORT=9000`, `JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY`, `SUPABASE_URL` (private Gateway), `SUPABASE_PUBLIC_URL`, `SUPABASE_PUBLISHABLE_KEYS`, `SUPABASE_SECRET_KEYS` (JSON, empty in legacy mode), `SUPABASE_DB_URL` (private), `VERIFY_JWT=false` (upstream default).

### Supavisor
- Source: repo root `/services/supavisor` (image + upstream `pooler.exs`; upstream start sequence: migrate → create tenant → serve). Healthcheck `/api/health` (300 s).
- Variables: `PORT=4000`, `ADDR_TYPE=inet6`, `SUPAVISOR_DB_IP_VERSION=ipv6`, `POSTGRES_HOST/PORT/DB/PASSWORD`, `DATABASE_URL` (ecto, `_supabase` DB), `CLUSTER_POSTGRES=true`, `SECRET_KEY_BASE`, `VAULT_ENC_KEY=${{secret(32, hex)}}`, `API_JWT_SECRET`, `METRICS_JWT_SECRET`, `REGION=local`, `ERL_AFLAGS=-proto_dist inet_tcp`, `POOLER_TENANT_ID=supabase`, `POOLER_DEFAULT_POOL_SIZE=20`, `POOLER_MAX_CLIENT_CONN=100`, `POOLER_POOL_MODE=transaction`, `DB_POOL_SIZE=5`, convenience `POOLER_URL_TRANSACTION` (`:6543`) and `POOLER_URL_SESSION` (`:5432`).

### Bucket
Railway Bucket `Bucket` (private, S3-compatible). Referenced by Storage as `${{Bucket.BUCKET}}`, `${{Bucket.ENDPOINT}}`, `${{Bucket.REGION}}`, `${{Bucket.ACCESS_KEY_ID}}`, `${{Bucket.SECRET_ACCESS_KEY}}`. All public reads go through Storage (signed URLs, RLS-checked public buckets), so the Railway Bucket staying private is not a limitation.

## Improvements over market templates

1. **Current upstream bundle** (`self-hosted/v0.8.2`, Envoy gateway, Postgres 17, all 11 images pinned) instead of mixed/older tags or the deprecated Kong path.
2. **Zero-touch API keys**: deterministic HS256 derivation from one generated `JWT_SECRET` using upstream's own signing routine; no generator website, no manual paste, no unpinned build-time tool.
3. **Data and Vault key are durable**: no destructive start command (one market template wipes `PGDATA` on every start), and the pgsodium/Vault root key is an explicit generated variable (`PGSODIUM_ROOT_KEY`) that survives redeploys and can be reused when restoring a dump elsewhere.
4. **Full stack incl. Edge Functions and Supavisor**, with functions deployed from git and a health route.
5. **Storage on a Railway Bucket** with virtual-hosted addressing and conservative S3 checksum settings; imgproxy works through presigned URLs (no shared volume).
6. **Nothing public except the Gateway**: no TCP proxy on Postgres or the pooler; Studio only reachable through the Gateway with basic auth.
7. **Real healthchecks for every HTTP service** and IPv6/dual-stack listeners (`::`) so the private network works in old and new Railway environments; Supavisor forced to IPv6 for its metadata DB.
8. **Correct client IP / scheme behind Railway's edge** (`xff_num_trusted_hops: 1`), which Auth rate limiting relies on.
9. **Safer auth defaults** for a deploy without SMTP/SMS: email auto-confirm on (documented to switch off once SMTP is set), phone sign-up off.
10. **Postgres keeps Railway conventions** (`Postgres` service name, `PG*`/`DATABASE_URL` variables, volume at `/var/lib/postgresql/data`) while running the Supabase image.

## Resource estimate

| Service | Idle RAM | Typical RAM | Typical vCPU | Volume |
|---|---|---|---|---|
| Postgres | 250 MB | 500 MB | 0.20 | 1–5 GB |
| Gateway (Envoy) | 40 MB | 80 MB | 0.05 | — |
| Studio | 200 MB | 300 MB | 0.05 | < 0.1 GB |
| Auth | 20 MB | 50 MB | 0.03 | — |
| REST | 30 MB | 80 MB | 0.05 | — |
| Realtime | 150 MB | 250 MB | 0.10 | — |
| Storage | 120 MB | 200 MB | 0.05 | — (Bucket) |
| imgproxy | 60 MB | 200 MB | 0.10 | — |
| Meta | 80 MB | 120 MB | 0.02 | — |
| Functions | 100 MB | 250 MB | 0.10 | — |
| Supavisor | 150 MB | 250 MB | 0.05 | — |
| **Total** | **~1.2 GB, ~0.15 vCPU** | **~2.3 GB, ~0.8 vCPU** | | **~2–5 GB + Bucket** |

Estimated cost at Railway prices (RAM $10/GB-month, vCPU $20/vCPU-month, volume $0.15/GB-month, Bucket $0.015/GB-month):
- Idle / development project: 1.2 × $10 + 0.15 × $20 + 2 × $0.15 ≈ **$15–16 / month**.
- Typical production app (moderate API and realtime traffic): 2.3 × $10 + 0.8 × $20 + 5 × $0.15 ≈ **$40 / month**, plus Bucket storage and egress.

Minimum plan: **Hobby** (11 services; each fits the Trial's 1 GB per service, but the stack's total footprint and volume needs are beyond a trial). Pro for larger databases or higher Postgres memory.

## Verification checklist

1. All 11 services build and turn healthy; Gateway log shows `Envoy running in legacy API key mode` and prints the anon key.
2. `GET https://<gateway-domain>/health` → `200 ok`.
3. `https://<gateway-domain>/` prompts for basic auth; `DASHBOARD_USERNAME`/`DASHBOARD_PASSWORD` open Studio. Table editor lists schemas; SQL editor runs `select 1`; a saved snippet survives a Studio redeploy.
4. Studio → Project Settings → API shows the same anon key as the Gateway log.
5. REST: `curl -H "apikey: <anon>" https://<gw>/rest/v1/` → 200 (OpenAPI). Create table `todos` with RLS policy, insert and read it via REST.
6. Auth: `curl -X POST -H "apikey: <anon>" -H "Content-Type: application/json" -d '{"email":"a@b.co","password":"Passw0rd!x"}' https://<gw>/auth/v1/signup` → user + session (auto-confirm).
7. Storage: create a bucket in Studio, upload an image, open it; request `/storage/v1/render/image/public/<bucket>/<file>?width=200` (imgproxy). Confirm objects appear in the Railway Bucket's Files tab.
8. Realtime: subscribe with supabase-js to `todos` changes and see an insert event.
9. Functions: `curl -H "Authorization: Bearer <anon>" "https://<gw>/functions/v1/hello?name=test"` → JSON.
10. Pooler: from another service on the private network, `psql "$POOLER_URL_TRANSACTION" -c 'select 1'`.
11. Redeploy Postgres: data persists; Vault secret created before (`select vault.create_secret('x')`) is still readable (`select decrypted_secret from vault.decrypted_secrets`).
12. Confirm no service except Gateway has a public domain or TCP proxy.

## Open questions

- Not deployed in this workspace and no image was built locally; Envoy config validity relies on upstream's tested `lds`/`cds` plus three small edits (listener address, trusted hops, `/health` route) that should be checked with the first deploy (`envoy --mode validate` in CI would catch errors).
- Supavisor's proxy listeners (5432/6543) bind IPv4 only in 2.9.12. They are reachable over the private network in Railway environments with IPv4 private networking (all newer environments); in legacy IPv6-only environments apps must connect to Postgres directly.
- No public database access by default. A TCP proxy can be added to Supavisor or Postgres, but traffic is not TLS-encrypted by these images; document this risk before enabling.
- Deterministic keys share fixed `iat`/`exp` (2026-01-01 → 2036-01-01). Rotating requires a new `JWT_SECRET` (logs everyone out) or pinned keys.
- Studio's Edge Functions page cannot read the functions folder (it lives in another service); functions are managed in git.
- Logs Explorer is disabled: Logflare + Vector need the Docker socket for log collection, which Railway does not provide.
- `POSTGRES_PASSWORD` is baked into roles on first init; changing the variable later breaks service logins until roles are updated (upstream `utils/db-passwd.sh` procedure).
- Railway Bucket compatibility with storage-api multipart/TUS uploads is expected (Tigris supports multipart) but not verified.
