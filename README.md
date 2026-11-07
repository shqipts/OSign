# OSign

Personal iOS IPA-signing app based on [Feather](https://github.com/claration/feather), preserving GPL-3.0 and original contributor attribution. Upstream foundation: `31ab6de455f2a6108f6830e343dee826310c03be`.

## Current version

Build 7: on-device signing, certificate/profile management, signed IPA export, explicit installation handoff and visible errors. Custom Osmonaj artwork, black launch screen and no GitHub-star prompt. The owner reports this build works on their phone; that is user-reported rather than an independently observed device test.

Semi Local delivery keeps the IPA on the iPhone at `127.0.0.1`; a protected public HTTPS service supplies only a short-lived manifest. No IPA/P12/private signing-key upload is performed by this flow. Standard TLS and iOS provisioning restrictions apply. See [PUBLIC-IP.md](PUBLIC-IP.md) for current architecture and deployment details. Historical designs are labeled separately.

## Build

Use macOS with `/Applications/Xcode.app`; select it using process-scoped `DEVELOPER_DIR`, not global settings.

```bash
bash Scripts/bootstrap-source.sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -workspace Feather.xcworkspace -scheme Feather -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath .build/DerivedData \
  -clonedSourcePackagesDirPath .build/SourcePackages \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= \
  DEPLOYMENT_LOCATION=NO CURRENT_PROJECT_VERSION=7
python3 Scripts/package-osign.py --build 7
```

Bootstrap restores pinned OpenSSL and applies the retained Zsign patch. The authenticated manifest configuration is deliberately **not committed**. Bootstrap can restore it from the owner's local `~/.config/osign-relay/public-manifest-token`; another machine needs its own authorized configuration. Do not put this token in source control.

Minimum deployment target: iOS 16.0. The unsigned release must be signed with a valid certificate/profile before installation. Preserve bundle ID `local.osign.app` and update in place to retain app data; use another working installer to update OSign itself.

## Privacy and releases

This is a private repository. Build caches, signing credentials, pairing records and manifest tokens are excluded from source control. The personalized unsigned release contains the owner's manifest-service configuration and must remain private. GitHub Actions are disabled to avoid running inherited release workflows unintentionally.

## License

GPL-3.0: see [LICENSE](LICENSE). Original Feather source headers and bundled legal notices remain. OSign modifications and corresponding build/deployment scripts are included here. Dependency licenses remain with their respective projects; no proprietary ESign assets are included.
