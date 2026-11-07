// OSign modifications, 2026. GPL-3.0; see LICENSE.
import Foundation

enum InstallRequest {
    enum ValidationError: LocalizedError {
        case invalidManifest
        var errorDescription: String? {
            "Enter an HTTPS manifest URL with a hostname and no embedded credentials. Export the signed IPA and host it with its manifest on a server you control."
        }
    }
    static func manifestURL(_ value: String) throws -> URL {
        guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https", let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil, url.fragment == nil else {
            throw ValidationError.invalidManifest
        }
        return url
    }
    static func relayManifest(_ data: Data) -> URL? {
        struct Reply: Decodable { let manifestURL: String }
        guard let reply = try? JSONDecoder().decode(Reply.self, from: data),
              let url = try? manifestURL(reply.manifestURL),
              url.host == "87.106.127.145", (url.port == nil || url.port == 443), url.query == nil,
              url.path.range(of: "^/osign/files/[A-Za-z0-9_-]{43}/manifest[.]plist$", options: .regularExpression) != nil else { return nil }
        return url
    }
    static func validLocalEndpoint(address: String, port: String) -> Bool {
        let components = address.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count == 4, components.allSatisfy({ !$0.isEmpty && $0.allSatisfy({ $0.isASCII && $0.isNumber }) && UInt8($0) != nil }),
              let number = UInt16(port), number > 0 else { return false }
        return true
    }
    static func validPairingRecord(_ data: Data) -> Bool {
        guard data.count < 1024 * 1024,
              let record = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let pub = record["public_key"] as? Data, !pub.isEmpty,
              let secret = record["private_key"] as? Data, !secret.isEmpty,
              let identifier = record["identifier"] as? String, !identifier.isEmpty else { return false }
        return true
    }
    static func pairingAllowed(hasRecord: Bool, isSelfUpdate: Bool) -> Bool {
        hasRecord && !isSelfUpdate
    }
    static func handoffURL(_ manifest: URL) -> URL {
        var components = URLComponents()
        components.scheme = "itms-services"
        components.host = ""
        components.queryItems = [URLQueryItem(name: "action", value: "download-manifest"), URLQueryItem(name: "url", value: manifest.absoluteString)]
        return components.url!
    }
    static func validMetadata(identifier: String?, version: String?, title: String?) -> Bool {
        [identifier, version, title].allSatisfy { !($0?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
    }
    static func handoffMessage(accepted: Bool) -> String {
        accepted
        ? "Handed to iOS — this is not confirmation of installation. Accept the system prompt and check the Home Screen. If nothing happens, Export the IPA and install using Apple Configurator."
        : "iOS declined the install handoff. Export the signed IPA and install using Apple Configurator, or check your trusted HTTPS manifest and device provisioning."
    }
}
