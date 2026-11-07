# OSign build 6 — Semi Local only (historical)

**Current build and public HTTPS deployment: see PUBLIC-IP.md (build 7).** The private connectivity instructions, artifact size/hash and build number below describe build 6 only; build 7 does not require Tailscale.

This supersedes the multi-method and experimental PIN-pairing designs. The active Installation settings mirror the requested layout: Installation Type = Server, Server Type = Semi Local, Only use localhost address = always enabled. Export is retained. Pairing/PIN setup is not in the active app.

## Data flow

1. OSign signs and packages locally using the retained native signing engine.
2. A short-lived server binds ONLY 127.0.0.1 on a random port in 4000...8000. It does not bind 0.0.0.0 or a Wi-Fi address. The IPA path includes a random UUID.
3. OSign posts a small JSON object containing only identifier, version, title and the HTTP localhost IPA URL to the authorized private VPS HTTPS /osign/manifest endpoint. No IPA, provisioning-profile file, signing key, P12 or password is posted by this method.
4. The VPS creates an expiring HTTPS Apple installation manifest in memory, referencing http://127.0.0.1:<port>/<UUID>.ipa. It does not fetch that URL and stores no IPA for this request. Manifest TTL is ten minutes.
5. The on-phone Safari installation page hands the HTTPS manifest to itms-services. iOS must then fetch the IPA directly from localhost. A direct system-prompt fallback and Export are available. No installed-success state is inferred from a prompt or HTTP transfer.

## SSL and connectivity

The existing VPS certificate for ubuntu.tail4dcadb.ts.net is used with standard TLS trust evaluation. Tailscale Serve handles HTTPS and certificate renewal. The app's Check SSL Certificate button performs a normal trusted HTTPS check; it does not falsely claim to force certificate renewal. A VPS certificate is NOT installed for 127.0.0.1 (the name would not match).

The localhost leg intentionally uses HTTP, matching the upstream Semi Local architecture. Only NSAllowsLocalNetworking is set; internet arbitrary loads or TLS trust bypass are not enabled.

The VPS is private to the tailnet. Keep Tailscale connected and LocalDevVPN disconnected. Only the tiny manifest request/download traverses the VPS, not the IPA. No Funnel/public exposure, firewall changes, replacement of public web services or global Xcode selection changes were made.

## Verification

- Real Xcode iPhoneOS Release build succeeded (BuildLogs/build-semi-local.log).
- Bundle local.osign.app, display OSign, build 6, minimum iOS 16.0, SDK iPhoneOS 27.2.
- Real main executable is Mach-O arm64, platform IOS. Main app and packaged OpenSSL framework unsigned. ZIP CRC integrity passed. No pairing record is embedded.
- Swift Semi Local policy tests passed: exact 127.0.0.1 URL, bounded port, metadata-only body, LAN rejection and correctly encoded handoff page. Other active validation checks pass.
- Both relay tests passed, covering legacy compatibility plus new authorization, loopback-only manifest validation, no-IPA storage, absent remote IPA download and expiry.
- Actual VPS readback matched the deployed Python source SHA-256; service active. Live HTTPS check: unauthenticated metadata 401, authenticated metadata POST 201, manifest GET 200 with exact localhost payload URL, and remote IPA URL 404. Test request was 172 bytes, not an IPA.

Not verified: accepting/installing this Semi Local flow on a physical iPhone. A build and a valid manifest do not prove iOS 27.2 will accept a loopback HTTP payload. Keep the app open; stock iOS signature/provisioning and delivery restrictions still apply. Do not claim unrestricted local installation. Export remains the fallback.

OSign cannot update itself while serving its own IPA because replacing it stops the server. Sign/install this build as an update using the previously working VPS method, Apple Configurator or another installer. Keep the same bundle ID and do not delete the existing app if preserving certificates/data.

## Source and artifact

Artifact: /Users/shqipts/Downloads/OSign-unsigned.ipa
Bytes: 13,126,019
SHA-256: d4573bf364ad1c43f39f528a7e480dd6dbdc0ca54412ed130bbd9f3a4d348ed1
Source: /Users/shqipts/Projects/OSign. GPL-3.0 license, original source credits and corresponding patches retained. No remote publication performed. Personalized manifest bearer configuration is ignored by source control and must not be redistributed.

The unfinished native code-pairing prototype is archived under Experiments/PinPairing, with its separate native source under ignored Vendor/idevice-source and its IDeviceKitten patch under Patches/experimental-pairing-idvicekit.patch. It is not built or advertised in build 6. The app uses the original pinned IDevice binary dependency again.
