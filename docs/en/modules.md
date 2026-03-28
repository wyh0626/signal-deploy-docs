# Modules

中文: [../modules.md](../modules.md)

## Core Application Modules

| Module | Source | Purpose | Status In This Repo |
| --- | --- | --- | --- |
| `Signal-Server` | `signalapp/Signal-Server` | Main backend for accounts, messaging, config, attachments, WebSocket, and gRPC | Integrated |
| `registration-service` | `signalapp/registration-service` | Verification sessions, phone number validation, pre-registration flow | Integrated |
| `Signal-Desktop` | `signalapp/Signal-Desktop` | Local desktop debugging target | Optional |

## Infrastructure Modules

| Module | Local Replacement | Purpose | Notes |
| --- | --- | --- | --- |
| DynamoDB | DynamoDB Local | Account, message, session, and config tables | Schema aligned with `Signal-Server` test fixtures |
| S3 / GCS | MinIO | CDN, attachments, dynamic config, ASN data | S3-compatible and good enough for local work |
| Redis cacheCluster | Single-node Redis Cluster | cache cluster | Slots assigned via `CLUSTER ADDSLOTSRANGE` |
| Redis pushSchedulerCluster | Single-node Redis Cluster | push scheduling | Local goal is dependency compatibility |
| Redis rateLimitersCluster | Single-node Redis Cluster | rate limiting | Used by both `registration-service` and `signal-server` |
| Redis messageCache | Single-node Redis Cluster | message cache | Local startup-path validation |
| Redis pubsub | Standalone Redis | Pub/Sub | Kept as standalone |
| Firestore / PubSub / Bigtable | GCloud emulators | Local substitutes for `registration-service` dependencies | No real GCP project required |

## Stubbed Or Disabled Modules

| Module | Official Role | Local Handling |
| --- | --- | --- |
| Contact Discovery Service | Contact discovery | Not deployed, dummy config only |
| SVR2 / SVRB | PIN and backup recovery | Not deployed, dummy config only |
| Key Transparency | Public key transparency | Not deployed, dummy config only |
| APNs / FCM | Mobile push | Dummy credentials, no real push |
| Stripe / Braintree | Payments and subscriptions | Config structure kept, local no-op behavior |
| Google Play Billing / Apple App Store | Store validation | Dummy credentials so services can boot |
| FoundationDB runtime | Runtime dependency in official storage paths | No real FDB cluster in this local stack; runtime library is stubbed or preloaded for build/startup compatibility |

## Minimal Upstream Patches

### `Signal-Server`

- adds `registrationService.type=local`
  so `signal-server` can use plaintext gRPC for local `registration-service`
- adds `pubSubPublisher.type=noop`
  so local development can avoid a real Google Pub/Sub publisher

### `Signal-Desktop`

- `attachments.preload.ts`
  no longer crashes preload when `fs-xattr` is missing
- `desktopCapturer.preload.ts`
  adds a graceful fallback when `@indutny/mac-screen-share` is unavailable
- `scripts/start-local-dev.sh`
  injects local `NODE_CONFIG` that points Desktop at the generated local backend

See [patches.md](./patches.md) for the full patch rationale.
