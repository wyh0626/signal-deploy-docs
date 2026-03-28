# Versioning And Branching

中文: [../versioning.md](../versioning.md)

## Goal

Make the deployment docs repo map cleanly to upstream Signal versions so that docs, scripts, and the actually working setup do not drift apart.

## Convention

- `main`
  ongoing maintenance and next-version preparation
- `signal-server/<tag>`
  verified branch that maps directly to a specific `Signal-Server` tag

Example:

- `signal-server/v20260324.1.0`

## Version Manifests

Each verified branch should include:

- `versions/current.env`
  the default upstream version set for that branch
- `versions/<signal-server-tag>.env`
  a snapshot named after the branch target

## Update Flow

1. Create a new branch from `main` or the last verified branch, for example `signal-server/v20260401.1.0`
2. Update `versions/current.env`
3. Add `versions/v20260401.1.0.env`
4. Run:
   - `./scripts/bootstrap-upstream.sh`
   - `./scripts/dev-up.sh --smoke-test`
   - `./scripts/desktop-up.sh` if Desktop is in scope
5. Adjust as needed:
   - `patches/Signal-Server/*`
   - `patches/Signal-Desktop/*`
   - `deploy/config/signal-server.yml.tmpl`
   - compatibility notes in both Chinese and English docs
6. Push the verified branch once validation is complete

## Why `Signal-Server` Is The Primary Version Anchor

This repository exists primarily to make the backend environment reproducible, so the most stable primary anchor is the `Signal-Server` tag. `registration-service` and `Signal-Desktop` are pinned alongside it within the same branch.

## Suggested PR Checklist

- `Signal-Server` still reaches healthy startup
- `registration-service` still completes the local verification flow
- `dynamic-config` and seeded objects are still consumed correctly
- `Signal-Desktop` still supports standalone flow if applicable
- local patches remain minimal and well-justified
- Chinese and English docs still match the scripts
