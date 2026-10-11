# Deploy and Host Supabase with Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/supabase-self-hosted-backend)

Run your own Supabase on Railway: Postgres 17 with Supabase extensions, Auth, auto-generated REST and GraphQL APIs, Realtime, Storage backed by a Railway Bucket, Edge Functions, the Supavisor pooler and Studio. Keys are generated on deploy with no manual setup, and only the API gateway is public. Community template.

## About Hosting Supabase

Self-hosted Supabase is not one container. It is about a dozen cooperating services that must share one JWT secret and matching API keys, reach Postgres over a private network, and sit behind a gateway that checks API keys and protects the dashboard. This template follows the official `supabase/supabase` Docker setup (release `self-hosted/v0.8.2`) and adapts it to Railway: init scripts and gateway config are baked into images instead of bind mounts, files go to a Railway Bucket instead of a local disk, each service listens on IPv6 and IPv4 for Railway's private network, and the anon and service_role keys are derived from one generated secret when each service starts.

## Common Use Cases

- Backend for web and mobile apps: Postgres, row-level security, auth and file uploads behind one URL
- Data residency or compliance needs that rule out a shared cloud project
- Realtime features (chat, live dashboards, presence) on your own infrastructure
- Internal tools that need an admin UI (Studio) plus an instant REST/GraphQL API
- Staging environments that mirror a Supabase Cloud project

## Dependencies for Supabase Hosting

- Postgres (`supabase/postgres` 17.6) with a persistent volume
- Railway Bucket for Storage objects
- Envoy API gateway, GoTrue (Auth), PostgREST, Realtime, Storage API, imgproxy, postgres-meta, Edge Runtime, Supavisor, Studio

### Deployment Dependencies

- Supabase self-hosting guide: https://supabase.com/docs/guides/self-hosting/docker
- Upstream Docker files: https://github.com/supabase/supabase/tree/master/docker
- Self-hosted changelog: https://github.com/supabase/supabase/blob/master/docker/CHANGELOG.md
- API keys for self-hosting: https://supabase.com/docs/guides/self-hosting/self-hosted-auth-keys
- Railway Buckets: https://docs.railway.com/guides/storage-buckets

### Implementation Details

| Service | Image | Role |
|---|---|---|
| Gateway | `envoyproxy/envoy:v1.39.1` + template config | Only public service: routes `/auth/v1`, `/rest/v1`, `/graphql/v1`, `/realtime/v1`, `/storage/v1`, `/functions/v1`, `/pg`; Studio at `/` behind basic auth |
| Postgres | `supabase/postgres:17.6.1.136` + init scripts | Database, volume `/var/lib/postgresql/data` |
| Studio | `supabase/studio:2026.09.07-sha-7996410` | Dashboard, SQL snippets on a volume |
| Auth | `supabase/gotrue:v2.196.0` | Sign-up, sign-in, JWTs |
| REST | `postgrest/postgrest:v14.17` | REST + GraphQL over Postgres |
| Realtime | `supabase/realtime:v2.134.10` | Database changes, broadcast, presence |
| Storage | `supabase/storage-api:v1.74.0` | Files in the Railway Bucket |
| imgproxy | `darthsim/imgproxy:v3.31.4` | Image resizing |
| Meta | `supabase/postgres-meta:v0.99.0` | Schema API for Studio |
| Functions | `supabase/edge-runtime:v1.76.2` | Edge Functions from `services/functions/functions` |
| Supavisor | `supabase/supavisor:2.9.12` | Connection pooler (private network) |

**First login**

1. Deploy. No input is required. Wait until all services are healthy (Postgres initialises on the first boot).
2. Open the Gateway's public domain. Log in with `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD` from the Gateway service's Variables tab.
3. Get your keys: Studio → Project Settings → API, or the Gateway deploy log (anon key only). Use the Gateway URL as `SUPABASE_URL` in supabase-js.
4. Set `GOTRUE_SITE_URL` (and `GOTRUE_URI_ALLOW_LIST`) on the Auth service to your app's URL. Configure SMTP on Auth, then set `GOTRUE_MAILER_AUTOCONFIRM=false` so new users must confirm their email.

**Database access**: apps on Railway use `DATABASE_URL` from the Postgres service (direct) or `POOLER_URL_TRANSACTION` from Supavisor (pooled). Nothing is exposed publicly by default; adding a TCP proxy sends unencrypted Postgres traffic over the internet.

**Edge Functions**: add `services/functions/functions/{name}/index.ts` in your repository and push; Railway rebuilds the Functions service. Call it at `/functions/v1/{name}`. Set `VERIFY_JWT=true` on Functions to require a valid JWT.

**Optional new API keys**: run upstream `docker/utils/add-new-auth-keys.sh` locally with your `JWT_SECRET`, then set `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY`, `ANON_KEY_ASYMMETRIC`, `SERVICE_ROLE_KEY_ASYMMETRIC` on the Gateway, `GOTRUE_JWT_KEYS` (JWT_KEYS) on Auth, and the public JWKS as `PGRST_JWT_SECRET` (REST), `API_JWT_JWKS` (Realtime), `JWT_JWKS` (Storage) and `SUPABASE_JWKS` (Functions).

**Scaling**: raise memory/CPU per service in Railway. Postgres is the usual bottleneck; tune pool sizes on Supavisor. Stateless services (Auth, REST, Realtime, Storage, imgproxy, Functions) can be given more resources independently.

**Pinning and upgrades**: image tags follow one upstream release. To upgrade, compare the next release in the upstream changelog, update the tags (image services in Railway, `FROM` lines in `services/*/Dockerfile`) and apply any listed config changes. Do not change `POSTGRES_PASSWORD`, `JWT_SECRET` or `PGSODIUM_ROOT_KEY` after the first deploy unless you follow the upstream rotation guides.

### Why Deploy Supabase on Railway?

Railway runs each Supabase component as its own service on a private network, with volumes, a managed bucket, generated secrets and per-second billing. You get the full self-hosted stack with keys already wired, and you can resize, redeploy or roll back each component independently instead of managing a VM and Docker Compose yourself.
