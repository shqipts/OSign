# OSign build 4: three methods

Supersedes build-1 manual hosting and build-3 Mac-relay instructions.

## Actions
1. Install via VPS: the private Tailscale HTTPS endpoint is now https://ubuntu.tail4dcadb.ts.net:8443/osign on the user's confirmed Linux VPS root@100.109.97.123. No Mac is required. The embedded private upload token matches /etc/osign-relay/upload-token. Do not redistribute this personalized binary/token.
2. Export signed IPA: native share sheet / Save to Files; no upload.
3. Local pairing installation: native IDeviceKitten installation proxy, real local transfer/system progress callbacks, visible errors. Requires the private RPPairing record and LocalDevVPN on the phone. Disconnect Tailscale before using LocalDevVPN. No self-replacement via this route; use VPS/export for OSign updates. No private installation entitlement or policy bypass.

The UI keeps donations/About/repository links and legacy labels removed. Original source headers and GPL-3 notices remain.

## VPS deployment

- Dedicated non-login osign-relay system user, loopback 127.0.0.1:8081, code /opt/osign-relay/relay.py, state /var/lib/osign-relay, token /etc/osign-relay/upload-token (root:osign-relay 0640).
- systemd osign-install-relay.service is active and enabled for automatic startup; hardened filesystem access and no new privileges.
- Tailscale Serve on port 8443, path /osign. Public existing services on ports 80/443 were not altered. No Tailscale Funnel/public exposure was configured.
- Authenticated uploads, capability URLs, 30-minute expiry, periodic cleanup and four retained IPA slots. The signed IPA includes its embedded profile; P12/private signing keys/passwords do not upload.
- The old Mac relay is retained for compatibility with previous installed builds. No unrelated signer code was changed.

## iPhone setup performed

- iPhone detected over USB; native ProductVersion returned 27.2.
- User approved trust. idevicepair validation and pairing succeeded.
- Official idevice-tools v0.1.57 for macOS arm64 generated an RPPairing record using `rppairing pair OSign <private-output>`.
- USB RPPairing tunnel test returned a service listing with no error.
- Record transferred through trusted USB app Documents access to local.osign.app at Documents/pairingFile.plist. Downloaded back and byte-for-byte compared successfully. No credential contents printed.
- Private backup is under ~/.config/osign-pairing, directory 0700, file 0600. Not sent to VPS, Telegram, source control or embedded in IPA.

Install this build as an UPDATE with the same local.osign.app bundle ID, not by deleting the existing app, to retain the pairing file/certificates. In Settings > Installation, use Connect to LocalDevVPN (or install it via the provided App Store button if needed) and approve any OS VPN configuration yourself. The agent cannot approve phone security prompts.

## Verified vs unverified

Verified: Xcode Release device build succeeded; arm64 iOS device executable; ZIP CRC integrity; unsigned main app and packaged framework; minimum iOS 16.0; build number 4. Eighteen Swift action/response checks passed; relay unit test passed. VPS live HTTPS test uploaded the actual unsigned build, generated correct metadata, returned 206 ranges and full bytes matching SHA-256. systemd state read back active/enabled, HTTPS health 200.

Not verified: physically installing a signed app through the on-phone local VPN route. USB RPPairing success does not establish that final path. Personal signing keys were not accessed. System signing authorization still applies. VPS throughput was not benchmarked against the Mac route; no guaranteed speed increase is claimed.

Artifact: /Users/shqipts/Downloads/OSign-unsigned.ipa
Size: 13,126,037 bytes
SHA-256: cb14440395abe867a4ed0ff27d989d495434ba269fdf6ad1324d392c0dee49ce
Build log: BuildLogs/build-three-methods.log
Corresponding modified source, LICENSE and dependency pins remain in /Users/shqipts/Projects/OSign; no remote source publication performed.
