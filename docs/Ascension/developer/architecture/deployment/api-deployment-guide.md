---
id: 67f09eaf-15d6-4df0-88dc-a0b6e3d207d7
---

:::success
**Version:** 1.1
:::

---

# API Deployment Guide

This guide describes how the Go API runs in production: the Coolify application that builds it, its variables and secrets, the automatic deployment on every push to `main`, and how to check, roll back and troubleshoot it.

:::warning
This guide never holds a password or a secret. They live in the Coolify environment variables of the application and in the team's password storage, never in the repository.
:::

---

## 1\. Components

| Component           | Value                                                                                                                                | Role                                                                    |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------- |
| Coolify application | `ascension-api` (UUID `xwraxbcreb0niv0lhfobogs9`), project `Ascension`, environment `production`                                     | Builds and runs the API and the cron jobs                               |
| Source              | `https://github.com/Ascension-EIP/Ascension`, branch `main`, base directory `/apps/server`                                           | Code deployed in production                                             |
| Compose file        | [apps/server/docker-compose.coolify.yml](https://github.com/Ascension-EIP/Ascension/blob/dev/apps/server/docker-compose.coolify.yml) | Two services built from `apps/server/Dockerfile`                        |
| Service `api`       | `https://api.ascension-eip.fr`, container port `8080`                                                                                | The API, behind Traefik and Cloudflare                                  |
| Service `cron`      | No domain, runs `./cron` from the same image                                                                                         | Deletes expired sessions and videos                                     |
| PostgreSQL 18       | Coolify database `ascension-postgres`, host `i8hc7tklpho8bwo92gzdnzrl`                                                               | Data, migrations applied by hand (see section 2.4)                      |
| RabbitMQ            | Coolify service `ascension-rabbitmq`, host `rabbitmq-qqu2ictjftetdiyyif9ffctg`                                                       | Analysis jobs for the AI worker                                         |
| Object Storage      | OVHcloud bucket `ascension-videos`                                                                                                   | Videos, see the [S3 Object Storage Guide](./s3-object-storage-guide.md) |

The diagram below shows the deployment flow: a push to `main` reaches Coolify through a GitHub webhook, Coolify builds the image from the repository and replaces the containers, which reach the database and the broker over the `coolify` Docker network.

```mermaid
flowchart LR
    Dev[Push to main] --> GH[GitHub]
    GH -->|webhook push| Coolify[Coolify<br/>coolify.ascension-eip.fr]
    Coolify -->|docker compose build + up| API[api container]
    Coolify --> Cron[cron container]
    API -->|coolify network| PG[(PostgreSQL)]
    API --> MQ[RabbitMQ]
    Cron --> PG
    API -->|HTTPS| S3[(OVHcloud S3)]
    User[Mobile app] -->|https://api.ascension-eip.fr| API
```

---

## 2\. Automatic deployment

### 2.1 How a push becomes a deployment

1. A commit lands on `main` (release from `staging`).
2. GitHub sends the `push` event to `https://coolify.ascension-eip.fr/webhooks/source/github/events/manual`, signed with the application's webhook secret.
3. Coolify checks the signature and the branch, then builds `docker-compose.coolify.yml`.
4. Coolify stops the old `api` and `cron` containers and starts the new ones: the API is unavailable for a few seconds.
5. The new `api` container answers `/healthz`. It does not apply the database migrations: see section 2.4.

Coolify is the only deployment path. The GitHub Actions workflow `deploy.yml` still publishes images to GHCR on version tags, as release artifacts, but nothing deploys them.

### 2.2 GitHub webhook

Repository settings › _Webhooks_:

| Setting      | Value                                                                   |
| ------------ | ----------------------------------------------------------------------- |
| Payload URL  | `https://coolify.ascension-eip.fr/webhooks/source/github/events/manual` |
| Content type | `application/json`                                                      |
| Secret       | _Webhooks_ section of the `ascension-api` application in Coolify        |
| Events       | **Just the push event**                                                 |

Check a delivery in _Webhooks › Recent Deliveries_: Coolify answers `200` with the deployment it queued, or with the reason it skipped the push (another branch).

### 2.3 Manual deployment and rollback

- **Redeploy:** Coolify › `ascension-api` › **Redeploy**, or `POST /api/v1/applications/xwraxbcreb0niv0lhfobogs9/restart` with a Coolify API token.
- **Roll back:** revert the faulty commit on `main`. The push redeploys the previous code. A migration is never reverted automatically: write a new migration that undoes it.
- **Follow a deployment:** Coolify › `ascension-api` › _Deployments_ shows the build logs of every deployment, with its commit.

### 2.4 Database migrations

:::warning
Since the `v0.3.0` release (13 November 2026), the API no longer applies the migrations when it starts: the call is commented out in `internal/app/app.go` and in `cmd/cron/main.go`. A deployment that brings a new migration leaves the database behind until someone applies it by hand. On 13 November 2026, production was at version `20261030200100`, without `20261112120000_fix_videos_climbing_session_fkey`.
:::

The migrations ship in the API image (`/app/migrations`), so the ones applied always match the deployed code. On the VPS, run the `migrate` CLI of the same version as the project (`v4.19.1`) on the `coolify` network:

```bash
API=$(sudo docker ps -q --filter name=api-xwraxbcreb0niv0lhfobogs9)
DIR=$(mktemp -d)
sudo docker cp -q "$API":/app/migrations "$DIR"/
PW=$(sudo docker exec i8hc7tklpho8bwo92gzdnzrl printenv POSTGRES_PASSWORD)
DB="postgres://ascension:$PW@i8hc7tklpho8bwo92gzdnzrl:5432/ascension?sslmode=disable"
migrate() {
  sudo docker run --rm --network coolify -v "$DIR"/migrations:/migrations:ro \
    migrate/migrate:v4.19.1 -path /migrations -database "$DB" "$@"
}

migrate version   # Current version, read only
migrate up        # Applies every missing migration
sudo rm -rf "$DIR"
```

- Take a backup of `ascension-postgres` first (_Backups_ › **Back Up Now**, see the [Backup and Restore Guide](./backup-and-restore-guide.md)).
- Compare `migrate version` with the last file of `/app/migrations`: the same timestamp means nothing is missing.
- `migrate up` only applies the migrations newer than the current version. A migration added later with an older timestamp is skipped for good: `20260924221631_create_video_contexts_table` never reached production for this reason. Give a new migration the timestamp of the day it is written.
- After a failed migration, the version is marked `dirty`. Fix the database by hand, then mark the version with `migrate force <version>` before running `migrate up` again.

---

## 3\. Configuration

### 3.1 Variables

Every variable is set in Coolify › `ascension-api` › _Environment Variables_. The compose file marks the required ones with `${VAR:?}`: a missing value stops the deployment.

| Variable                                         | Value                                                                        |
| ------------------------------------------------ | ---------------------------------------------------------------------------- |
| `POSTGRES_HOST`                                  | `i8hc7tklpho8bwo92gzdnzrl` (internal host of `ascension-postgres`)           |
| `POSTGRES_DB`, `POSTGRES_USER`                   | `ascension`, `ascension`                                                     |
| `POSTGRES_PASSWORD`                              | Password of `ascension-postgres` (Coolify › database › _General_)            |
| `RABBITMQ_HOST`                                  | `rabbitmq-qqu2ictjftetdiyyif9ffctg`                                          |
| `RABBITMQ_USER`, `RABBITMQ_PASS`                 | `SERVICE_USER_RABBITMQ`, `SERVICE_PASSWORD_RABBITMQ` of `ascension-rabbitmq` |
| `MINIO_ENDPOINT`, `MINIO_REGION`, `MINIO_BUCKET` | `https://s3.gra.io.cloud.ovh.net`, `gra`, `ascension-videos`                 |
| `MINIO_ID`, `MINIO_SECRET`                       | Keys of the OVHcloud user `ascension-app`                                    |
| `AUTH_JWT_SECRET`, `AUTH_SESSION_SECRET`         | Random secrets of 64 characters, generated for production                    |

Optional: `LOG_LEVEL` (default `info`), `POSTGRES_PORT` (`5432`), `POSTGRES_PARAMS` (`sslmode=disable`, the database is only reachable on the internal network), `RABBITMQ_PORT` (`5672`).

:::danger
Changing `AUTH_JWT_SECRET` logs every user out at once: their access tokens no longer verify. Changing `AUTH_SESSION_SECRET` invalidates the refresh sessions. Rotate them only on purpose, and expect every client to log in again.
:::

### 3.2 Network

The application is connected to the predefined `coolify` Docker network (_Connect to Predefined Network_), where the database and the broker are reachable by their container names. Neither is exposed on the Internet.

---

## 4\. Checking the deployment

```bash
# Must answer HTTP/2 200
curl -IL https://api.ascension-eip.fr/healthz
```

On the VPS:

```bash
# Containers of the application: api must be healthy, cron running
sudo docker ps --filter name=xwraxbcreb0niv0lhfobogs9 --format '{{.Names}} {{.Status}}'

# Last lines of the API: "server starting on :8080", then the /healthz requests
sudo docker logs --tail 20 $(sudo docker ps -q --filter name=api-xwraxbcreb0niv0lhfobogs9)
```

The first deployment, on 12 November 2026, was checked end to end against production: account creation, presigned upload URL on `https://s3.gra.io.cloud.ovh.net`, direct upload to OVHcloud, `upload-done`, download of the same bytes. The test account, video and object were deleted afterwards.

---

## 5\. Troubleshooting

| Symptom                                                    | Cause and fix                                                                                                                                          |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Deployment fails with `required variable ... is missing`   | A `${VAR:?}` variable is empty in Coolify: set it and redeploy                                                                                         |
| A route answers `500` after a deployment, the logs show a missing table, column or constraint | A migration was not applied: compare `migrate version` with `/app/migrations` and apply it (section 2.4) |
| `failed to create a new rabbitmq queue`                    | Wrong `RABBITMQ_*` values, or the application lost the `coolify` network                                                                               |
| `failed to create a new minio storage`                     | See the troubleshooting of the [S3 Object Storage Guide](./s3-object-storage-guide.md)                                                                 |
| A push to `main` deploys nothing                           | Check _Webhooks › Recent Deliveries_ on GitHub. A `401` means the secret differs from Coolify's                                                        |
| `502 Bad Gateway` on `api.ascension-eip.fr`                | The `api` container is not healthy yet, or the domain lost its `:8080` port in Coolify (_Domains for api_ must be `https://api.ascension-eip.fr:8080`) |
