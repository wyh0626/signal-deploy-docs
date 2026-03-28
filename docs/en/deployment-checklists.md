# Deployment Checklists

中文: [../deployment-checklists.md](../deployment-checklists.md)

This document splits deployment planning into two tracks:

- `Low-cost test checklist`
  Use this when the goal is to validate local backend behavior, verification flows, and `Signal-Desktop` standalone debugging as cheaply as possible.
- `Production-prep checklist`
  Use this when the goal is to move toward a public beta or a real service by replacing local stand-ins with real cloud services, push credentials, SMS delivery, observability, and secret management.

Short version:

- If you only need local validation, do not buy SGX, Bigtable, or real SMS capacity yet.
- If you are preparing for public traffic, first build a `production-ready beta` without SGX.
- Only after that should you open a separate `SGX` track for `Contact Discovery Service` and `SVR2`.

## Which path to choose

| Goal | Choose this checklist | Do not buy yet |
| --- | --- | --- |
| Local `Signal-Server` / `Signal-Desktop` debugging | Low-cost test checklist | SGX, Bigtable, Pub/Sub, real SMS, real APNs/FCM |
| Small internal beta / public beta | Production-prep checklist first, without SGX | Do not promise full private contact discovery or PIN recovery yet |
| Closer-to-complete product capability | Production-prep checklist plus SGX sub-checklist | Do not mix SGX into the default one-click dev stack |

## Low-cost test checklist

### Best fit

- Run local `Signal-Server`
- Run local `registration-service`
- Validate verification-session and registration flows
- Let `Signal-Desktop` talk to the local stack in standalone mode
- Prepare for later Android / iOS local integration

### Minimum resource suggestion

- Main development machine:
  - `8 vCPU`
  - `16 GB RAM`
  - at least `80 GB` free SSD space
- If you want a cheap remote demo host:
  - `1` Linux VM with `4 vCPU / 8 GB RAM / 100 GB SSD`
  - `1` domain
  - reverse proxy and TLS

### What you need

- Docker or Docker Desktop
- `bash`, `git`, and `python3`
- network access that can clone upstream Signal repositories
- optional:
  - domain
  - reverse proxy
  - public HTTPS entrypoint

### Local replacements already provided by this repo

| Official dependency | Test replacement | Current repo behavior |
| --- | --- | --- |
| `DynamoDB` | `DynamoDB Local` | included |
| `S3` / `GCS` | `MinIO` | included |
| multiple `Redis Cluster` groups | single-node Redis Cluster | included |
| `Pub/Sub` | `noop` / emulator | included |
| `Firestore` / `Bigtable` | emulator / dummy config | included |
| SMS delivery | dev-mode verification codes | included |
| `APNs` / `FCM` | disabled or no-op | included |
| `CDS` / `SVR2` / `Key Transparency` | stubs / dummy config | included |

### What not to buy on this path

- `Apple Developer Program`
- `Google Play` developer account
- paid `Twilio` / `MessageBird` capacity
- `Firebase Blaze` billing project
- `Bigtable`
- `Pub/Sub`
- `Azure SGX`
- self-managed production `FoundationDB`
- managed HA `Redis`

### Fast acceptance steps

1. Copy the environment file:

```bash
cp .env.example .env
```

2. Start the local stack:

```bash
./scripts/dev-up.sh
```

3. Run the minimal backend validation flow:

```bash
./scripts/dev-up.sh --smoke-test
```

4. If you also want Desktop:

```bash
./scripts/dev-up.sh --include-desktop
```

### Exit criteria for this path

- `signal-server` healthcheck is passing
- `registration-service` can complete verification sessions
- the local verification rule works: last 6 digits of the phone number
- `Signal-Desktop` can register against the local stack in standalone mode
- the team is clear on which integrations are stubs instead of production-ready services

## Production-prep checklist

### Boundary first

This repo currently gives you a production-prep entrypoint and a low-cost validation environment. It is not a finished official production deployment.

For public traffic, split the work into two stages:

- `Stage A: production-ready beta`
  Get real SMS, real push, real storage, real monitoring, and stable operations working first, without SGX.
- `Stage B: full production track`
  Then add `CDS`, `SVR2`, potentially `Key Transparency`, and the stricter trusted-hardware and operational requirements around them.

### Services you should expect to buy

#### Cloud and platform accounts

- `AWS`
  - `DynamoDB`
  - `S3`
  - `IAM`
  - and usually `KMS`, logging, and alerting
- `GCP` / `Firebase`
  - `Firestore`
  - `Bigtable`
  - `Pub/Sub`
  - `FCM`
  - a billing-enabled project
- `Apple Developer Program`
  - iOS builds, signing, `APNs`, and App Store Connect
- `Google Play Console`
  - Android distribution, signing, and store configuration
- SMS provider
  - `Twilio Verify` or `MessageBird`
- core networking
  - domain
  - DNS
  - TLS certificates
  - CDN / WAF

#### Baseline service-node sizing

This is a conservative small-public-beta starting point, not an official minimum:

| Component | Suggested starting point |
| --- | --- |
| `Signal-Server` | `3` nodes, each `4 vCPU / 16 GB RAM` |
| `registration-service` | `2` nodes, each `2 vCPU / 8 GB RAM` |
| reverse proxy / API gateway | `2` nodes, each `2 vCPU / 4 GB RAM` |
| `TURN` | `2` nodes, each `4 vCPU / 8 GB RAM` |
| `Redis` | `3` nodes, preferably managed, or at least `4 vCPU / 16 GB RAM` class |

Inference note:

- `DynamoDB`, `S3`, `Firestore`, `Bigtable`, and `Pub/Sub` are usually better purchased as managed services than recreated by hand.
- The host sizes above are a beta-friendly floor, not a long-term scale target.

### Stage A: production-ready beta checklist

#### Application and infrastructure

- replace local `DynamoDB Local` with real `DynamoDB`
- replace local `MinIO` with real `S3`
- replace dummy `GCP` config with real `Firestore`, `Bigtable`, and `Pub/Sub`
- replace single-node local Redis clusters with managed or multi-node HA Redis
- use a real domain and public TLS
- move secrets out of local files and into a real secret-management system

#### Accounts and mobile delivery

- configure a real `APNs` key
- configure a real `FCM` project
- configure a real SMS provider
- build iOS and Android signing and release pipelines
- define environment-aware backend endpoint strategies for Desktop, Android, and iOS

#### Operations and security

- metrics and dashboards
- application logs and audit logs
- on-call alerting
- backup and restore drills
- vulnerability scanning and dependency upgrade cadence
- least-privilege access control
- rate limiting and WAF
- rollout and rollback procedures

#### Pre-launch acceptance

- real SMS registration succeeds
- `APNs` / `FCM` delivery is working
- Android primary-device registration succeeds
- Desktop link-device succeeds
- iOS test-device registration succeeds
- load tests, rate limits, alerting, and recovery procedures have been exercised

### Stage B: full production track checklist

#### Additional capabilities to add

- `Contact Discovery Service`
- `SVR2` / `SVRB`
- a more complete `Key Transparency` path
- remote attestation, proof, and trusted-hardware operations

#### SGX server guidance

The easiest public-cloud SGX family to obtain today is Azure `DCsv3 / DCdsv3`. Azure still documents them as SGX VM families, and the published `DCdsv3` sizes include:

- `Standard_DC4ds_v3`: `4 vCPU / 32 GB / 16 GiB EPC`
- `Standard_DC8ds_v3`: `8 vCPU / 64 GB / 32 GiB EPC`
- `Standard_DC16ds_v3`: `16 vCPU / 128 GB / 64 GiB EPC`
- `Standard_DC48ds_v3`: `48 vCPU / 384 GB / 256 GiB EPC`

One important limitation:

- Azure documents that `DCsv3` and `DCdsv3` are not compatible with Intel's attestation service.
- So before you decide to run `CDS` or `SVR2` there, you should validate the upstream software path against Azure attestation.

#### SGX starting suggestion

This is an engineering suggestion, not an upstream requirement:

- `Contact Discovery Service`
  - start with `2 x Standard_DC4ds_v3`
  - or move directly to `2 x Standard_DC8ds_v3` for more headroom
- `SVR2`
  - start at no less than `3 x Standard_DC8ds_v3`
  - move to `3 x Standard_DC16ds_v3` when usage grows

#### SGX sub-checklist

- choose cloud and region
- confirm the attestation path
- confirm EPC sizing versus enclave size
- build the enclave build, signing, and release workflow
- build enclave rollback and upgrade workflows
- run failure drills and attestation-chain validation

### When to move from test to production-prep

Move from the low-cost test path when these become true:

- local smoke tests are stable
- Desktop standalone is stable
- the team now needs real SMS or real push delivery
- you are preparing for external users
- you accept the operational cost of a multi-cloud and multi-service system

## Official references

- `registration-service` README:
  [signalapp/registration-service](https://github.com/signalapp/registration-service)
- `SecureValueRecovery2`:
  [signalapp/SecureValueRecovery2](https://github.com/signalapp/SecureValueRecovery2)
- Apple Developer Program cost and benefits:
  [Membership Details - Apple Developer Program](https://developer.apple.com/programs/whats-included/)
- APNs token setup:
  [Communicate with APNs using authentication tokens](https://developer.apple.com/help/account/capabilities/communicate-with-apns-using-authentication-tokens/)
- Firebase pricing:
  [Firebase Pricing](https://firebase.google.com/pricing)
- Firebase Blaze billing plan:
  [Firebase pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans)
- Bigtable pricing:
  [Bigtable pricing](https://cloud.google.com/bigtable/pricing)
- Pub/Sub pricing:
  [Pub/Sub pricing](https://cloud.google.com/pubsub/pricing)
- Firestore pricing:
  [Firestore](https://cloud.google.com/products/firestore)
- Twilio Verify pricing:
  [Verify Pricing](https://www.twilio.com/en-us/verify/pricing)
- Google Play service fee note:
  [Changes to Google Play's service fee in 2021](https://support.google.com/googleplay/android-developer/answer/10632485)
- Azure SGX VM family:
  [DC family VM size series](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/general-purpose/dc-family)
- Azure SGX attestation:
  [Attestation for SGX enclaves](https://learn.microsoft.com/en-us/azure/confidential-computing/attestation)
- Azure `DCdsv3` size table:
  [DCdsv3 系列大小](https://learn.microsoft.com/zh-tw/azure/virtual-machines/sizes/general-purpose/dcdsv3-series)
