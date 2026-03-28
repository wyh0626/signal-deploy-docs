# Signal-Desktop Local Debugging

中文: [../desktop-local.md](../desktop-local.md)

## Two Ways To Use Desktop

### 1. Standalone Device

This is the fastest local validation path.

- no Android primary device required
- Desktop talks directly to the local `signal-server`
- useful for registration, config loading, WebSocket, and basic API connectivity

How to start:

```bash
./scripts/dev-up.sh
./scripts/desktop-up.sh
```

Or in one step:

```bash
./scripts/dev-up.sh --include-desktop
```

In the Desktop app, choose:

- `File -> Set Up as Standalone Device`

Local rules:

- captcha: `noop.noop.registration.localtest`
- verification code: last 6 digits of the phone number

### 2. Link Device

This is the QR-code device-linking flow.

Requirements:

- the primary device must also point at this same local backend
- the best practical path is a locally configured Android build

Important:

- store-installed Signal Android and iOS apps point at official environments
- they cannot directly link to this local Desktop setup

## What This Repo Changes For Desktop

- applies a minimal local patch to `Signal-Desktop`
- adds `scripts/start-local-dev.sh`
- injects the following settings via `NODE_CONFIG`
  - `serverUrl`
  - `storageUrl`
  - `directoryUrl`
  - `cdn`
  - `challengeUrl`
  - `registrationChallengeUrl`
  - `certificateAuthority`
  - `serverPublicParams`
  - `hardcodedCaptchaForLocalTestingOnly`

## macOS Compatibility Notes

This repo adds graceful degradation for two common native-module failure points:

- `fs-xattr`
  preload no longer fails hard when it does not build
- `@indutny/mac-screen-share`
  Desktop can fall back instead of crashing on startup

That means:

- registration and core debugging flows remain usable
- screen-sharing-specific behavior is not guaranteed
