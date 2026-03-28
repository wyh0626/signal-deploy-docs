# Signal Local Deploy Repo Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an open-source repository that captures the working local Signal dev deployment as reusable docs, patches, Docker assets, and one-click scripts.

**Architecture:** Keep upstream repositories outside version control under `upstream/`, pin exact refs in `versions/`, apply minimal local patches, generate runtime config into `deploy/generated/`, and start the entire backend through Docker Compose.

**Tech Stack:** Bash, Docker Compose, Python, Java/Maven, Electron/pnpm.

---

### Task 1: Define repo structure

**Files:**
- Create: `README.md`
- Create: `docs/modules.md`
- Create: `docs/dev-replacements.md`
- Create: `docs/versioning.md`
- Create: `docs/desktop-local.md`
- Create: `versions/current.env`

**Step 1: Write repo entry docs**

Describe modules, replacements, version pinning, quick start, and local testing rules.

**Step 2: Record exact upstream refs**

Pin `Signal-Server`, `registration-service`, and `Signal-Desktop` in `versions/current.env`.

### Task 2: Add runtime assets

**Files:**
- Create: `deploy/docker-compose.yml`
- Create: `deploy/config/signal-server.yml.tmpl`
- Create: `deploy/config/registration-service.yml`
- Create: `deploy/docker/Signal-Server.Dockerfile`
- Create: `deploy/docker/registration-service.Dockerfile`
- Create: `deploy/redis-cluster/entrypoint.sh`
- Create: `deploy/seed/dynamic-config.yaml`

**Step 1: Move working local config into templates**

Render `signal-server` config from a template so `serverPublic` stays aligned with the pinned upstream version.

**Step 2: Make MinIO and DynamoDB self-initializing**

Ensure `dynamic-config.yaml`, `asn.tsv`, and DynamoDB tables appear automatically on first boot.

### Task 3: Automate upstream bootstrap and startup

**Files:**
- Create: `scripts/bootstrap-upstream.sh`
- Create: `scripts/apply-local-patches.sh`
- Create: `scripts/render-signal-config.sh`
- Create: `scripts/generate-secrets.sh`
- Create: `scripts/generate-localhost-cert.sh`
- Create: `scripts/init-dynamodb.py`
- Create: `scripts/init-dynamodb-local.sh`
- Create: `scripts/dev-up.sh`
- Create: `scripts/dev-down.sh`
- Create: `scripts/dev-status.sh`
- Create: `scripts/desktop-up.sh`

**Step 1: Clone and pin upstream repos**

Bootstrap only the repos needed for the selected workflow and refuse to trample dirty vendor trees.

**Step 2: Generate all runtime artifacts**

Create certs, secrets, and the rendered `signal-server.yml` automatically.

**Step 3: Start and verify services**

Bring up Compose and poll `healthcheck` until the stack is reachable.

### Task 4: Preserve local source fixes as patches

**Files:**
- Create: `patches/Signal-Server/*.patch`
- Create: `patches/Signal-Desktop/*.patch`

**Step 1: Store minimal local diffs**

Keep only the changes required for local plaintext registration and Electron preload fallbacks.

**Step 2: Apply patches idempotently**

Allow reruns without corrupting upstream clones.
