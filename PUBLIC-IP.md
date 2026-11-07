# OSign build 7 — public-IP HTTPS and custom branding

This is the current deployment. It supersedes the **private endpoint and build numbers** in SEMI-LOCAL.md, while retaining that document's on-phone localhost delivery design and limitations.

## User-visible changes

- Primary app icon uses the supplied teal Osmonaj globe/triangle artwork on black. Both the legacy app-icon assets and the current Icon Composer document use this artwork. The compiled primary PNG was extracted and inspected.
- Plain black launch screen; no Feather launch glyph. Signing toolbar now reads OSign.
- Removed the GitHub-star counter and alert, rather than merely suppressing it once.
- Installation and SSL checks use `https://87.106.127.145/osign` over the normal internet. Tailscale is not required by build 7. Keep OSign open during local delivery; LocalDevVPN and pairing are not used.
- Native signing, certificate management, export, visible system-handoff errors and legal attribution remain.

## Public service boundary

An isolated `osign-public.service`, running as `osign-public`, binds only `127.0.0.1:8082`. Apache exposes the health check, authenticated metadata POST and expiring capability-manifest downloads on public HTTPS port 443. JSON/request bodies are limited to 16 KiB. Legacy upload and remote IPA download routes are blocked by the proxy and/or backend.

The public service receives only identifier, version, title and a loopback IPA URL. It never fetches the localhost URL, accepts no IPA/P12 upload and stores no IPA. The on-phone server remains bound to exact `127.0.0.1`; the IPA does not traverse this VPS. Manifest lifetime is 600 seconds.

Public port 8443 proved unreachable externally, so the final deployment uses 443. `000-0-osign-public.conf` makes the IP certificate the default on the existing wildcard TLS listener: IP clients generally do not send hostname SNI. Existing named website vhosts are retained; `shqipts.com` was tested with correct SNI directly against this server and returned HTTP 200. The old private Tailscale service/endpoint still works for existing builds. No Tailscale configuration or existing private service unit was changed.

The new bearer token is private, ignored by git and embedded only in this personalized build. Do not publish its configuration or IPA. Source and GPL-3.0 attribution are retained; no GitHub publication occurred.

## Certificate and renewal

A real Let's Encrypt certificate with IP SAN `87.106.127.145` was issued. Initial observed validity: 2026-11-07 06:19:51 UTC to 2026-11-13 22:19:50 UTC. Trust evaluation is standard; no certificate pin override or trust bypass exists.

Certbot 5.9.0 runs from isolated `/opt/osign-acme`, separate from the existing website's Certbot installation. Its configuration, work and log directories are `/etc/letsencrypt-osign-ip`, `/var/lib/letsencrypt-osign-ip`, and `/var/log/letsencrypt-osign-ip`. The certificate name is `osign-public-ip`, required ACME profile `shortlived`, with HTTP-01 webroot `/var/www/html`. Public port 80 must remain reachable for validation; retain that webroot and a stable public IP.

Enabled `osign-ip-renew.timer` checks four times daily with up to five minutes of jitter. Renewal validates Apache configuration and reloads it only after a successful renewal. The service also fails if the live certificate has less than 48 hours remaining. Failure is visible in systemd/journal logs; no Telegram/email alert delivery has been configured.

A real staging renewal rehearsal with `--dry-run --run-deploy-hooks --no-random-sleep-on-renew` succeeded, including Apache configtest/reload. This does not replace the production certificate with an untrusted staging certificate. Logs: `/var/log/osign-ip-dry-run.log`. Timer/unit sources are under Relay/ and were verified against actual deployed files.

## Build and verification

Release build command is recorded in `BuildLogs/build-public-ip-7.log` and returned `BUILD SUCCEEDED`. Xcode was selected with process-scoped DEVELOPER_DIR, not a global change.

- Bundle: `local.osign.app`; display: OSign; build: 7; minimum iOS: 16.0.
- Swift request/action and Semi Local tests passed.
- Three branding regression tests and the manifest-generator test passed.
- Three relay tests passed, including manifest-only public mode and size limits.
- Actual Foundation URLSession SSL check passed against the public IP.
- Live HTTPS: unauthenticated metadata 401, authenticated POST 201, manifest GET 200, exact localhost IPA URL; remote IPA route blocked with 403. No IPA or signing credentials sent.
- Public service, timer, existing private service and Apache were active; public service/timer enabled; public state contained zero IPA files.
- Real package verified ZIP CRC, unencrypted arm64 iOS executable, unsigned code, bundled GPL notice, private configuration and absence of pairing/signing records.

Artifact: `/Users/shqipts/Downloads/OSign-unsigned.ipa`
Bytes: 15228737
SHA256: `368c93f68d38d64b1e89c00832649ba4b6388d58eb36a2e1bc4d085c25308a5e`
Repackage with `python3 Scripts/package-osign.py --build 7` after building the matching app.

**Not tested:** final installation on the user's physical iPhone/iOS 27.2. A valid manifest and accepted handoff do not prove that iOS accepts the loopback payload or provisioning. Export remains the fallback. Re-sign this unsigned IPA and update the existing OSign using Configurator or another working installer; do not delete the existing app or change its bundle ID if preserving data. OSign cannot safely replace itself while it is serving its own IPA.
