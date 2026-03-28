# Roadmap

中文: [../roadmap.md](../roadmap.md)

This roadmap is not meant to say “do everything now”. It is meant to keep the project moving in a clear order.

## Phase 1: Stable Local Backend

Goals:

- `./scripts/dev-up.sh` brings up the backend in one step
- `./scripts/dev-up.sh --smoke-test` validates the critical path in one step
- branches, patches, docs, and version manifests stay aligned

This is the current foundation.

## Phase 2: Desktop Demo

Goals:

- `Signal-Desktop` works against the local backend through `Standalone Device`
- README and `docs/desktop-local.md` provide a clear demo path
- known fallbacks are documented so the demo focuses on the flows that matter

Why it is worth doing:

- fast to show
- good for demonstrating that the local stack is actually alive
- connects backend setup with a visible client workflow

## Phase 3: Android Primary Device

Goals:

- prepare an Android build that points at the local backend
- support local primary-device registration
- unlock a real source for Desktop `Link Device`

This is the key step for QR linking.

## Phase 4: iOS Development Prep

Goals:

- get local iOS builds working
- document signing, certificates, provisioning, and APNs prerequisites
- clearly separate “can install for local debug” from “can publish through TestFlight/App Store”

Real constraints:

- Apple Developer Program membership
- device signing and capability configuration
- APNs configuration if real push is later required

## Phase 5: More Production-Like Infrastructure

Goals:

- multi-node Redis
- real FoundationDB
- observability, backups, persistence, and failure drills

Important:

- this is a different layer of work from the default local-dev docs
- it is cleaner to document this separately than to overload the default Compose setup

## Phase 6: Mobile Release Readiness

Android track:

- Firebase and FCM credentials
- Play Console
- app signing, versioning, release tracks

iOS track:

- Apple Developer Program
- bundle IDs, capabilities, provisioning
- App Store Connect
- APNs keys or certs
- TestFlight and App Store release flow

## Recommended Order

1. keep the local backend docs healthy
2. make the Desktop standalone demo solid
3. add Android local primary-device support
4. then invest in iOS development support
5. only after that split out production-like and SGX-specific tracks
