# Maintenance Guide

中文: [../maintenance.md](../maintenance.md)

Long-term maintainability comes less from complicated scripting and more from making upgrade, verification, documentation, and rollback habits explicit.

## Maintenance Goals

- keep a clean mapping to upstream `Signal-Server` versions
- keep patches small and short-lived
- keep scripts and bilingual docs aligned
- make it fast to prove that the stack still works after each update

## Recommended Maintenance Rhythm

### When Upstream Releases A New Version

1. create a new version branch
2. update `versions/current.env`
3. add `versions/<tag>.env`
4. refresh upstream repos and re-apply patches
5. run `./scripts/dev-up.sh --smoke-test`
6. if Desktop is in scope, also run `./scripts/desktop-up.sh`
7. update both Chinese and English docs

### When Patches Change

1. record why the change is still necessary
2. confirm that config cannot solve it instead
3. rerun the smoke test
4. if Desktop changed, rerun the standalone boot path

## Suggested Acceptance Gates

- `signal-server` health endpoint is healthy
- verification session creation succeeds
- captcha submission succeeds
- verification code request succeeds
- verification code submission succeeds
- `dynamic-config` and seeded objects are still consumed correctly
- Desktop still reaches the local dev entry path if it is in scope

## Documentation Rules

- keep README and docs aligned
- update Chinese and English versions in the same change when possible
- keep `docs/plans/` for local planning only
- always document what capability is lost when a cloud dependency is replaced locally

## What Not To Do

- vendor full upstream repos into this repository
- grow a large long-lived patch stack instead of using config and docs
- let `main` accumulate too many unverified experiments
- treat local demo success as proof of production readiness
