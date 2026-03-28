# Patches

中文: [../patches.md](../patches.md)

One of the core rules of this repo is to keep upstream behavior intact wherever possible. Patches exist only to solve issues that cannot be handled cleanly through configuration in local development.

## Why Patches Exist

Even with local infrastructure replacements in place, two categories still need code changes:

- upstream defaults that assume online credentials or trusted production-only integrations
- Desktop native module failures that can break local development before the app even starts

The goal is not to reshape Signal. The goal is to:

- add a narrow local-development entry point when one does not exist
- degrade gracefully when an optional native capability is missing

## Current Patch Set

### `patches/Signal-Server/0001-local-dev-registration-and-noop-pubsub.patch`

Purpose:

- adds `registrationService.type=local`
  so `signal-server` can talk to local `registration-service` over plaintext gRPC without identity-token credentials
- adds `pubSubPublisher.type=noop`
  so the local server can boot without a real Google Pub/Sub publisher

Impact:

- limited to local configuration choices
- does not replace the upstream default production types

### `patches/Signal-Desktop/0001-local-dev-desktop-fallbacks.patch`

Purpose:

- prevents preload from failing hard when `fs-xattr` is missing
- adds a fallback path when `@indutny/mac-screen-share` is unavailable
- adds `scripts/start-local-dev.sh`
  to inject local backend addresses, certs, and captcha into Desktop

Impact:

- focused on local Electron development ergonomics
- screen-sharing behavior is explicitly not the main validation target here

## Patch Maintenance Rules

- if config can solve it, prefer config over patching
- prefer additive local-only hooks over invasive behavior changes
- every patch should be explainable in one sentence
- if upstream adds a supported entry point later, remove the patch instead of carrying it forward

## How To Refresh A Patch

1. change the relevant code inside `upstream/`
2. confirm the diff is the smallest possible set
3. export the patch back into `patches/`
4. run `./scripts/bootstrap-upstream.sh`
5. run `./scripts/apply-local-patches.sh`
6. run `./scripts/dev-up.sh --smoke-test`
7. if Desktop changed, also run `./scripts/desktop-up.sh`
