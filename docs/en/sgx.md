# SGX Notes

中文: [../sgx.md](../sgx.md)

## What SGX Is

Intel SGX is a TEE, or trusted execution environment, technology.

At a high level, it provides:

- an enclave, which is a protected execution region inside the CPU
- isolation for enclave code and data from the regular host environment
- remote attestation, which lets a remote party verify which enclave is running
- sealing, which allows enclave state to be persisted securely

## Why Signal Uses SGX Here

Signal does not put everything into SGX. It uses trusted hardware for the parts where reducing operator trust matters most.

The most relevant examples here are:

- Contact Discovery
  to reduce exposure of contact data during matching
- Secure Value Recovery
  to reduce exposure of PIN and recovery-related secrets

So in this context, SGX is not about performance. It is about reducing how much sensitive material ordinary server operators can see.

## How This Repo Handles SGX-Backed Features Today

The current local dev stack:

- does not deploy SGX services
- stubs or dummies the config that must exist for startup
- focuses validation on registration, config loading, object storage, and Desktop connectivity

That makes it useful for:

- local development
- Desktop debugging
- understanding the structure of the Signal backend

But it does not make this repo a production-equivalent deployment.

## What A Future SGX Deployment Would Need

Typical prerequisites include:

- SGX-capable Intel hardware
- SGX enabled in BIOS
- host drivers, runtime, and quote provider support
- remote attestation infrastructure
- enclave image build and deployment workflow
- service-specific operations, monitoring, and key rotation procedures

This is usually far beyond “add a few more services to Docker Compose”. In practice it means:

- dedicated bare metal or tightly controlled hosts
- explicit hardware and firmware policy
- a separate security and operations track

## Suggested Learning Path

1. learn TEE basics: enclaves, attestation, sealing
2. learn why Signal uses trusted hardware for CDS and SVR2
3. then study concrete deployment topics: drivers, quotes, PCCS, enclave build pipeline, and attestation integration

Good starting points to look up:

- Intel SGX architecture and terminology
- SGX/DCAP remote attestation concepts
- `signalapp/ContactDiscoveryService`
- `signalapp/SecureValueRecovery2`
- container or orchestration patterns for trusted execution environments

## Recommendation For This Repo

Do not force SGX services into the default one-click local deployment yet. A cleaner path is:

- keep this repo focused on the non-SGX local development stack
- add a separate SGX deployment document or branch later
- keep “local developer workflow” and “trusted-hardware production deployment” as clearly separate layers
