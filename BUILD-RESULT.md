# Verified build result

- Artifact: /Users/shqipts/Downloads/OSign-unsigned.ipa
- Size: 13,126,119 bytes
- SHA-256: 1d6af8c2cf67cf97444a2c23daaa93dde783760ce8433a3a60de2b985fdd4e5f
- Release device build: BUILD SUCCEEDED (BuildLogs/build-release.log)
- Bundle ID local.osign.app; display name OSign; minimum iOS 16.0; SDK iPhoneOS 27.2.
- Main executable and embedded OpenSSL framework: Mach-O arm64, platform IOS.
- Main app unsigned. Vendor signature stripped from packaged OpenSSL framework; it is also unsigned. No embedded mobileprovision, no app extensions.
- ZIP CRC integrity passed (Python ZipFile.testzip returned None).
- Installation validation: 10 Swift checks passed. Offline manifest-generator unittest passed.
- No physical phone test, personal signing-certificate test, or system install test was performed.
- No HTTP/TLS exception added; inherited insecure ATS exception removed.
- No file hosting, Tailscale changes, Apple login or remote publication performed.

Source and GPL-3 license: this repository, including Zsign and IDeviceKitten submodules. OpenSSL is pinned to official 3.3.3001; see README-OSign.md and Patches/zsign-local-openssl.patch. Local modified source has not been externally published.

For OTA installation, OSign requires the user's explicit trusted HTTPS manifest URL. It does not set up hosting or silently upload files. Export to Configurator is the fallback. Handoff acceptance is not installation confirmation.
