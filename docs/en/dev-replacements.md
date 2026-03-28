# Dev Replacements

中文: [../dev-replacements.md](../dev-replacements.md)

## Replacement Strategy

This repo follows three rules:

- keep upstream code paths as intact as possible
- replace only the cloud capabilities that are not realistically available in local development
- stub what can be stubbed, and document the boundary when it cannot be reproduced

## Replacement Table

| Official Dependency | Local Replacement | Integrated | Notes |
| --- | --- | --- | --- |
| AWS DynamoDB | DynamoDB Local | Yes | Schema aligned with `DynamoDbExtensionSchema` |
| AWS S3 | MinIO | Yes | Used for CDN, dynamic config, ASN, and prekeys |
| Google Cloud Storage | MinIO | Yes | Unified through the S3-compatible path locally |
| Multiple Redis clusters | Single-node Redis Cluster + standalone Redis | Yes | 4 clusters + 1 standalone |
| Firestore | Firestore emulator | Yes | Required by `registration-service` |
| Pub/Sub | Pub/Sub emulator / no-op publisher | Yes | Server side uses a no-op publisher hook |
| Bigtable | Bigtable emulator | Yes | Required by `registration-service` |
| Twilio / MessageBird | `dev` mode verification flow | Yes | Verification code = last 6 digits of the phone number |
| APNs | dummy config | Yes | Service starts, no real push |
| FCM | dummy config | Yes | Service starts, no real push |
| Stripe / Braintree | dummy config + no-op behavior | Yes | No real payment path locally |
| Google Play Billing | dummy service account | Yes | Startup compatibility only |
| Apple App Store | dummy key + root cert | Yes | Startup compatibility only |
| Contact Discovery Service | stub | No | No SGX-backed local reproduction |
| SVR2 / SVRB | stub | No | No SGX-backed local reproduction |
| Key Transparency | stub | No | Not part of this local stack |
| FoundationDB cluster | not started; runtime compatibility only | No | This stack does not model a real FDB cluster |

## What You Can Test

- backend startup
- verification session creation
- local verification code flow
- Desktop standalone registration path
- basic WebSocket connectivity
- local object storage and dynamic config loading

## What You Cannot Test Like Production

- SGX-backed privacy services
- real SMS delivery
- real mobile push delivery
- real store payment and subscription validation
- true multi-node Redis or FoundationDB operational behavior

See [non-local-services.md](./non-local-services.md) for what those missing services actually do.
