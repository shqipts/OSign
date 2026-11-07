import Foundation

var failures = 0
func check(_ condition: Bool, _ name: String) {
    if !condition { print("FAIL: \(name)"); failures += 1 }
    else { print("PASS: \(name)") }
}
func rejects(_ value: String) -> Bool {
    do { _ = try InstallRequest.manifestURL(value); return false }
    catch { return true }
}
check(rejects("http://example.com/manifest.plist"), "HTTP rejected")
check(rejects("https://user:secret@example.com/manifest.plist"), "credentials rejected")
check(rejects("file:///manifest.plist"), "local files rejected")
check(rejects(""), "missing manifest rejected")
let manifest = try InstallRequest.manifestURL("https://example.com/a.plist?token=a%26b&x=2")
let action = InstallRequest.handoffURL(manifest)
let items = URLComponents(url: action, resolvingAgainstBaseURL: false)!.queryItems!
check(items.first(where: {$0.name == "url"})?.value == manifest.absoluteString, "nested URL query preserved")
check(action.scheme == "itms-services", "system handoff scheme")
check(InstallRequest.handoffMessage(accepted: false).contains("Export"), "rejected handoff has export recovery")
check(InstallRequest.handoffMessage(accepted: true).contains("not confirmation"), "accepted is not install success")
check(InstallRequest.validMetadata(identifier: nil, version: "1", title: "App") == false, "missing ID rejected")
check(InstallRequest.validMetadata(identifier: "local.test", version: "1", title: "App"), "valid metadata accepted")
let capability = String(repeating: "A", count: 43)
check(InstallRequest.relayManifest(Data("{\"manifestURL\":\"https://87.106.127.145/osign/files/\(capability)/manifest.plist\"}".utf8))?.host == "87.106.127.145", "public IP manifest accepted")
check(InstallRequest.relayManifest(Data("{\"manifestURL\":\"http://evil.test/a\"}".utf8)) == nil, "untrusted relay response rejected")
check(InstallRequest.relayManifest(Data("not json".utf8)) == nil, "malformed relay response rejected")
check(InstallRequest.relayManifest(Data("{\"manifestURL\":\"https://ubuntu.tail4dcadb.ts.net:8443/osign/files/test/manifest.plist\"}".utf8)) == nil, "old private endpoint rejected")
for bad in ["https://87.106.127.145:8443/osign/files/\(capability)/manifest.plist", "https://87.106.127.145/osign/files/test/manifest.plist", "https://87.106.127.145/osign/files/\(capability)/manifest.plist?extra=1", "https://evil.test/osign/files/\(capability)/manifest.plist"] {
    let data = try JSONSerialization.data(withJSONObject: ["manifestURL":bad])
    check(InstallRequest.relayManifest(data) == nil, "invalid public relay URL rejected: \(bad)")
}
check(InstallRequest.relayManifest(Data("{\"manifestURL\":\"https://ubuntu.tail4dcadb.ts.net:9999/osign/files/test/manifest.plist\"}".utf8)) == nil, "wrong VPS port rejected")
check(!InstallRequest.pairingAllowed(hasRecord: false, isSelfUpdate: false), "missing pairing blocked")
check(!InstallRequest.pairingAllowed(hasRecord: true, isSelfUpdate: true), "self update blocked")
check(InstallRequest.pairingAllowed(hasRecord: true, isSelfUpdate: false), "configured pairing enabled")
check(InstallRequest.validLocalEndpoint(address: "10.7.0.1", port: "52107"), "dynamic local port accepted")
check(!InstallRequest.validLocalEndpoint(address: "10.7.0.1", port: "0"), "zero port rejected")
check(!InstallRequest.validLocalEndpoint(address: "not-an-ip", port: "49152"), "non-IP rejected")
check(!InstallRequest.validPairingRecord(Data("bad".utf8)), "malformed pairing rejected")
let pairingFixture = try PropertyListSerialization.data(fromPropertyList: ["public_key": Data(repeating: 0, count: 32), "private_key": Data(repeating: 0, count: 32), "identifier": "LOCAL UNIT TEST ONLY"] as [String: Any], format: .xml, options: 0)
check(InstallRequest.validPairingRecord(pairingFixture), "remote pairing shape accepted")
if failures > 0 { exit(1) }
print("All installation action tests passed")
