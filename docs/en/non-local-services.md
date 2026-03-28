# Official Services Not Fully Reproduced Locally

中文: [../non-local-services.md](../non-local-services.md)

This document answers two questions:

- which official dependencies are not fully reproduced in this repo
- what those services actually do inside the wider Signal system

## Dependency Inventory

| Module | Official Role | Current Status | Why It Is Not Fully Included | What Production Would Need |
| --- | --- | --- | --- | --- |
| Contact Discovery Service | Private contact discovery | Not deployed | Depends on SGX-backed service paths | SGX hardware, remote attestation, dedicated service deployment |
| SVR2 / SVRB | PIN, secret, and backup recovery flows | Not deployed | Depends on SGX and dedicated operational workflow | SGX hardware, recovery service, attestation chain, key management |
| Key Transparency | Public key transparency and anti-equivocation protections | Not deployed | Outside the scope of the current local demo | Dedicated service, log infrastructure, client verification integration |
| APNs | iOS push delivery | Dummy config | Requires Apple developer credentials and push configuration | Apple Developer Program, APNs keys or certs |
| FCM | Android push delivery | Dummy config | Requires Google/Firebase project setup | Firebase project, sender config, service accounts |
| Stripe / Braintree | Payments, subscriptions, donations | No-op / dummy | Local demo does not validate payment flows | Merchant accounts, webhooks, compliance |
| Google Play Billing | Android purchase validation | Dummy config | Needs real Play Console credentials and products | Play Console, service account, product setup |
| Apple App Store | iOS receipt and subscription validation | Dummy config | Needs App Store Connect credentials and trust material | Apple Developer, App Store Connect, key rotation |
| FoundationDB cluster | Distributed storage runtime for official data paths | No cluster deployment | The current dev stack does not model full FDB behavior | Real FDB cluster, backups, monitoring, rolling upgrades |
| Multi-node Redis | Cache, rate limiting, scheduling, message cache | Single-node clusters only | Local goal is compatibility, not production HA | At least three nodes, persistence, failover |
| Real SMS providers | Verification SMS and voice delivery | `dev` mode replacement | Local debugging does not need real delivery | Twilio, MessageBird, or equivalent provider setup |

## What This Local Stack Is Good For

- full backend boot validation
- local verification flow
- Desktop-to-local-backend integration
- object storage and dynamic config wiring

## What This Local Stack Is Not Good For

- real push delivery
- privacy-critical contact discovery flows
- PIN and secure backup recovery
- store payment flows
- true production-grade distributed operations

## A Useful Mental Model

It helps to group the missing pieces into three buckets:

- enhancements outside the core registration and messaging path
  such as push, billing, and store validation
- privacy services that depend on trusted hardware
  such as CDS and SVR2
- infrastructure that only becomes necessary when operating a real service in production
  such as multi-node Redis and FoundationDB clusters
