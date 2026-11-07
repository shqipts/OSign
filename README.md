# OSign

**Sign, manage and install your iOS apps from your iPhone.**

OSign brings IPA imports, signing certificates, provisioning profiles and signed app exports together in one app. Signing happens on your device, with a dark interface and clear progress and error messages.

## What you can do

- **Import IPA files** and view app information.
- **Manage certificates and profiles** used to sign your apps.
- **Sign on your iPhone** using the native signing engine.
- **Install signed apps** through an explicit iOS installation handoff.
- **Export signed IPAs** to Files or another installer.

## How it works

1. Import an IPA and add your signing certificate and provisioning profile.
2. Select your signing options and sign the app locally.
3. Choose **Install** or **Export**.

For installation, OSign uses **Semi Local delivery**: a temporary server on your iPhone serves the signed IPA only at `127.0.0.1`. A protected HTTPS service creates a small, short-lived installation manifest pointing to that local file. iOS receives the manifest and requests the IPA from your phone.

**The IPA, signing certificate, private key and password are not uploaded by this installation flow.** Only the app name, bundle identifier, version and local delivery URL are sent to the manifest service. A normal internet connection is enough—Tailscale and device pairing are not required.

The HTTPS service uses a trusted certificate with automatic renewal. Standard iOS signing, provisioning and installation restrictions still apply; accepting the system handoff is not confirmation that installation finished. Export remains available as a fallback.

## Download

Get **OSign-unsigned.ipa** from the [OSign release](https://github.com/shqipts/OSign/releases/latest).

- Requires **iOS 16.0 or later**.
- The IPA is **unsigned**: sign it with a valid certificate and provisioning profile before installing.
- Update your existing OSign installation without deleting it to preserve its data. Use another working installer to update OSign itself.

This repository and its personalized release are private. Do not redistribute the release's authenticated manifest-service configuration.

## Development

Source, native signing integration, regression tests and deployment scripts are included. See [technical documentation](https://github.com/shqipts/OSign/blob/main/PUBLIC-IP.md) and [build instructions](https://github.com/shqipts/OSign/blob/main/README-OSign.md). Restore pinned dependencies with `bash Scripts/bootstrap-source.sh`; private configuration is intentionally excluded from source control.

## License & credits

OSign is based on Feather by Samara and its contributors, with GPL-3.0 and original attribution preserved. See [LICENSE](https://github.com/shqipts/OSign/blob/main/LICENSE) and [upstream acknowledgements](https://github.com/shqipts/OSign/blob/main/UPSTREAM-NOTICES.md).
