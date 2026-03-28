# Signal Deployment Docs

中文: [README.md](./README.md)

This repository turns a working local Signal development deployment into an open-source, reproducible, versioned project.

The goal is not to recreate Signal production exactly. The goal is to provide a stable local dev stack so that we can:

- start `Signal-Server` in Docker
- use local `registration-service` for verification flows
- replace cloud dependencies with MinIO, DynamoDB Local, Redis, and GCloud emulators
- point `Signal-Desktop` at the local backend for standalone debugging
- maintain branches, patches, and docs that map cleanly to upstream Signal versions

## At A Glance

- `./scripts/dev-up.sh`
  Brings up the full backend stack.
- `./scripts/dev-up.sh --smoke-test`
  Brings up the backend stack and runs a minimal verification flow smoke test.
- `./scripts/dev-up.sh --include-desktop`
  Brings up the backend and then prepares and launches `Signal-Desktop`.

## Documentation Map

The full docs index is in [docs/en/README.md](./docs/en/README.md).

Suggested reading order:

- [docs/en/modules.md](./docs/en/modules.md)
- [docs/en/dev-replacements.md](./docs/en/dev-replacements.md)
- [docs/en/non-local-services.md](./docs/en/non-local-services.md)
- [docs/en/patches.md](./docs/en/patches.md)
- [docs/en/sgx.md](./docs/en/sgx.md)
- [docs/en/desktop-local.md](./docs/en/desktop-local.md)
- [docs/en/versioning.md](./docs/en/versioning.md)
- [docs/en/maintenance.md](./docs/en/maintenance.md)
- [docs/en/roadmap.md](./docs/en/roadmap.md)

## What Is In This Repo

- `deploy/docker-compose.yml`
  Local Signal dependency orchestration, including DynamoDB Local, MinIO, Redis, GCloud emulators, `registration-service`, and `signal-server`.
- `deploy/config/signal-server.yml.tmpl`
  Local `Signal-Server` config template. It is rendered into `deploy/generated/signal-server.yml`.
- `deploy/config/registration-service.yml`
  Local config for `registration-service`.
- `deploy/docker/*.Dockerfile`
  Local image definitions built from upstream source.
- `patches/`
  Minimal local development patches for `Signal-Server` and `Signal-Desktop`.
- `scripts/`
  Bootstrap upstream repos, apply patches, generate certs and secrets, start and stop the stack, run smoke tests, and launch Desktop.
- `versions/`
  Pinned upstream version manifests. `current.env` is the active default combination.
- `docs/`
  Module inventory, local replacements, unsupported external services, patches, SGX notes, maintenance guidance, and roadmap docs.

## Verified Version Set

See [versions/current.env](./versions/current.env).

Current defaults:

- `Signal-Server`: `v20260324.1.0`
- `registration-service`: `2.58.0`
- `Signal-Desktop`: `v7.42.0-adhoc.20250124.1-1503-ge8efc3c66`

## Quick Start

```bash
git clone <your-repo-url> signal-deploy-docs
cd signal-deploy-docs
cp .env.example .env
./scripts/dev-up.sh
```

To bring the backend up and immediately verify the critical path:

```bash
./scripts/dev-up.sh --smoke-test
```

To bring up the backend and Desktop together:

```bash
./scripts/dev-up.sh --include-desktop
```

Default endpoints:

- API: `http://localhost:8090`
- HTTPS API: `https://localhost:9443`
- Admin: `http://localhost:8091/healthcheck`
- MinIO Console: `http://localhost:9001`
- DynamoDB Local: `http://localhost:8000`

## Local Verification Rules

`registration-service` runs with `MICRONAUT_ENVIRONMENTS=dev,local`, which means:

- no real SMS is sent
- the verification code is the last 6 digits of the phone number
- the captcha token can be `noop.noop.registration.localtest`

Example:

- phone number: `+14155550131`
- code: `550131`

## Desktop Debugging

Start the backend:

```bash
./scripts/dev-up.sh
```

Then start Desktop:

```bash
./scripts/desktop-up.sh
```

Or do both in one step:

```bash
./scripts/dev-up.sh --include-desktop
```

Desktop supports two paths:

- `Standalone Device`
  No Android device required. Desktop registers directly against the local backend.
- `Link Device`
  Requires a primary Android device that is also pointed at this same local backend. Store-installed Signal mobile apps cannot link to this local stack.

See [docs/en/desktop-local.md](./docs/en/desktop-local.md) for details.

## Branching And Versioning

This repo should track `Signal-Server` versions explicitly:

- `main`
  Ongoing work and next-version preparation.
- `signal-server/v20260324.1.0`
  Verified branch for `Signal-Server v20260324.1.0`.

Each version branch should update:

- `versions/current.env`
- `patches/`
- `deploy/config/`
- compatibility notes in both Chinese and English docs

See [docs/en/versioning.md](./docs/en/versioning.md).

## Known Limits

- This is not an official production deployment.
- SGX-backed services do not have a full local equivalent here.
- FCM/APNs, payments, and app store validation are all dummy or no-op local substitutes.
- Local `Signal-Desktop` works for debugging, but real QR linking still needs a locally configured mobile primary device.

## Open-Source Maintenance Rules

- Keep both Chinese and English docs in sync.
- Keep `docs/plans/` for local planning only; do not publish plan notes.
- Keep `patches/` minimal and purpose-driven.
- Before and after version upgrades, run:
  - `./scripts/dev-up.sh --smoke-test`
  - `./scripts/desktop-up.sh`

More detail lives in [CONTRIBUTING.md](./CONTRIBUTING.md) and [docs/en/maintenance.md](./docs/en/maintenance.md).

## License / Notice

This repo contains deployment scripts and derivative patches for Signal open-source projects. Keep AGPL-compatible licensing and clearly reference upstream projects in `NOTICE`:

- [Signal-Server](https://github.com/signalapp/Signal-Server)
- [Signal-Desktop](https://github.com/signalapp/Signal-Desktop)
- [registration-service](https://github.com/signalapp/registration-service)
