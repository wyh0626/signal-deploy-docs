# Contributing

This repository is meant to be maintainable over time, not just runnable once.

## Ground Rules

- Keep patches minimal and explain why each patch exists.
- Keep Chinese and English docs in sync.
- Do not commit local planning notes under `docs/plans/`.
- Do not commit generated runtime artifacts from `deploy/generated/`.
- Do not silently update upstream refs without updating the version manifest and docs.

## Version Update Workflow

1. Create a new branch named after the target `Signal-Server` tag, for example `signal-server/v20260401.1.0`.
2. Update `versions/current.env`.
3. Add `versions/<tag>.env`.
4. Refresh upstream repos with `./scripts/bootstrap-upstream.sh`.
5. Re-apply or refresh patches in `patches/`.
6. Start the stack with `./scripts/dev-up.sh --smoke-test`.
7. If Desktop support is part of the target release, also run `./scripts/desktop-up.sh`.
8. Update both Chinese and English docs before merging or publishing.

## Patch Hygiene

- Patch upstream code in `upstream/` first.
- Export the smallest possible diff into `patches/`.
- Prefer additive local-dev hooks over invasive behavior changes.
- If a patch is no longer required by upstream, remove it instead of carrying dead code.

## What To Verify

- `signal-server` reaches a healthy admin endpoint.
- verification session creation still works
- captcha answer still works
- verification code request still works
- verification code submission still works
- Desktop standalone boot still works if Desktop is in scope

## Pull Requests

- Explain which upstream refs were tested.
- Call out any new local-only assumptions.
- Mention whether docs and patches were updated together.
