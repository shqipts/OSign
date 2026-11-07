# OSign direct-install build (build 3)

This supersedes the manual-manifest workflow described in the original build-1 README and report.

## Use
1. Sign and install this updated OSign IPA using your existing method.
2. Connect Tailscale on your iPhone; keep the Mac online.
3. Sign an imported app locally. Open its Install action and tap **Install signed IPA**.
4. OSign uploads the signed IPA to the private Mac relay, obtains a generated HTTPS manifest and opens the iOS installation prompt. Accept the system prompt.

No URL copying, manual manifest generation or manual upload is needed. The system installer still enforces provisioning, signatures, entitlements and device authorization. Handoff acceptance is not a verified installed result. Physical-device installation remains untested by the developer. Your screenshot established that the prior build launched; it did not prove the new install workflow.

## Privacy and service

User explicitly approved temporary hosting on their existing private HTTPS server.
A signed IPA includes an embedded provisioning profile. No P12/private key or password is sent. Uploads use an app-specific bearer token, HTTPS and a loopback-only backend. Download/manifest URLs use unpredictable capabilities. Files expire after 30 minutes with a 30-second cleanup interval; restarting removes abandoned IPA files. Limits: 1 GiB per IPA, four concurrent retained uploads. This is a private build: do not redistribute its embedded relay configuration/token. Rotate/reconfigure before sharing source or IPA externally.

Tailscale Serve retains the original `/` proxy to port 8080 unchanged and adds `/osign` proxying the new independent loopback relay on port 8081. The existing signer code/process was not modified. Relay source is `Relay/relay.py`; dependencies are Flask and Waitress in Relay/.venv. Token is in ~/.config/osign-relay/upload-token, not in tracked source. The ignored app resource Feather/Resources/OSignRelay.json is generated locally from it.

The relay is running as a persistent background server. Automatic LaunchAgent registration was blocked by the execution environment; a plist was written but NOT registered. After reboot, start the relay manually, or register the LaunchAgent from your normal Terminal. LaunchAgent: ~/Library/LaunchAgents/local.osign.install-relay.plist. Service command:

```sh
cd /Users/shqipts/Projects/OSign
OSIGN_RELAY_STATE=/Users/shqipts/.local/share/osign-relay \
OSIGN_RELAY_TOKEN_FILE=/Users/shqipts/.config/osign-relay/upload-token \
OSIGN_RELAY_PUBLIC_BASE=https://imac.tail4dcadb.ts.net/osign \
Relay/.venv/bin/python Relay/relay.py
```

## Verification

- Actual iPhoneOS Release build succeeded with Xcode 27.2, minimum target iOS 16.0, arm64. Build log: BuildLogs/build-direct-install.log.
- 13 Swift action/response validation checks passed.
- Relay test covers authorization, upload, generated metadata, full/range downloads, malformed IPA rejection and expiry cleanup.
- Deployed HTTPS end-to-end test uploaded an actual built IPA, fetched its generated manifest, verified HTTP 206 byte ranges and matched the entire downloaded IPA SHA-256. This transport test uses an unsigned build, NOT a fabricated signing or phone-install success.
- Donation section, About/feedback/repository navigation, upstream icon picker and legacy visible references in source-import/installation screens removed. Required source/license notices retained; GPL license is bundled.

License remains GPL-3.0. Corresponding source and notices are preserved in this repository and its submodules; no publication performed.
