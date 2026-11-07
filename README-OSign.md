# OSign (unofficial Feather fork)

Local modified source based on https://github.com/claration/Feather at
`31ab6de455f2a6108f6830e343dee826310c03be` (upstream version string 2.9.0).
This is not ESign and contains no proprietary ESign assets. Feather is copyright
Samara M and contributors, licensed under GNU GPL version 3. The original LICENSE,
source headers and contributor credits remain. OSign changes are dated 2026.
No warranty. No upstream endorsement. No remote publication was performed.

## Features

* Original native Feather import/library, P12 + mobileprovision certificate manager,
  signing options, and local zsign signing engine are retained.
* Signed IPA export uses the system share sheet: choose Save to Files or AirDrop.
* Install now packages locally with visible progress and errors, then requires an
  explicit Install button and an operator-provided trusted HTTPS manifest URL.
  UIApplication.open completion is displayed as accepted/rejected, never as proof
  that an installation completed. No private install entitlement or trust bypass.
* Black/dark default appearance, green accent, original OSign check-ring icon.
* Existing internal Feather identifiers remain for storage compatibility and
  maintenance. App display name is OSign; application ID is local.osign.app.

## Installation setup

1. Sign an imported IPA using **your own** authorized certificate/profile.
2. Open the signed app's Install or Export action; export the prepared IPA.
3. Either install it from a Mac with Apple Configurator, or host that exact IPA
   and an Apple-format installation manifest on a trusted HTTPS server you control.
   Both must be reachable by the phone's system installer; no authentication UI,
   self-signed TLS exception or local filesystem URL will work here.
4. Generate a manifest using `Scripts/make-manifest.py` below, upload it yourself,
   then paste its HTTPS URL into OSign's Install screen and tap Install.
   Example (replace metadata with the actual signed app's values):
   `python3 Scripts/make-manifest.py --ipa-url https://YOUR-HOST/App.ipa --bundle-id YOUR.BUNDLE.ID --version 1.0 --title App --output manifest.plist`
5. Accept iOS's prompt. An accepted URL handoff does not mean installed: check
   Home Screen and any system error. Device authorization, certificate validity,
   entitlements and Apple policies still apply. If no prompt appears, use Export
   and Configurator; do not repeatedly assume signing is broken.

No file is uploaded automatically. No Apple account was used. No personal
certificate was accessed. No existing signer or Tailscale service was modified.
The former Feather pairing/local HTTP/remote manifest-generator installation UI
is not used by OSign's replacement install workflow. Some upstream implementation
files remain compiled for maintainability but are not selected by this workflow.

## Build

Requires the full Xcode at /Applications/Xcode.app, iPhoneOS SDK, and network access
for upstream open-source dependencies. Minimum iOS target: **16.0**. Built using
Xcode 27.2 on this Mac; **physical iOS 27.2 compatibility and signing/install runtime
are not established without device testing**. Simulator on this host reports an
outdated CoreSimulator runtime; this does not imply phone runtime compatibility.

The huge historical OpenSSL git fetch stalled; the dependency is now pinned to a
local shallow checkout of official tag 3.3.3001 (commit
623c84da314e85363236507ca38a4bde65df21c3). Preserve its license/source. The checked-out
Zsign submodule's Package.swift contains the corresponding local path adjustment.

```sh
cd /Users/shqipts/Projects/OSign
git submodule update --init --recursive
# Do NOT reset Zsign/Package.swift: it contains the local OpenSSL dependency patch.
mkdir -p Vendor
# If absent:
git clone --depth 1 --branch 3.3.3001 https://github.com/krzyzanowskim/OpenSSL Vendor/OpenSSL
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc \
  Feather/Utilities/InstallRequest.swift Tests/main.swift -o .build/osign-tests
.build/osign-tests
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -workspace Feather.xcworkspace -scheme Feather -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath .build/DerivedData \
  -clonedSourcePackagesDirPath .build/SourcePackages \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= \
  DEPLOYMENT_LOCATION=NO
```

Package only the resulting device `.app` under `Payload/OSign.app`, not a simulator
build. An unsigned IPA must itself be signed before it can run on stock iOS.
Do not distribute a modified binary without the GPL-required corresponding source,
license notices and reproducible build changes, including the Zsign patch.
