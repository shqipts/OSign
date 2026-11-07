// OSign semi-local delivery policy. GPL-3.0.
import Foundation

enum LocalDelivery {
    static let host = "127.0.0.1"
    static func payloadURL(id: UUID, port: Int) -> URL? {
        guard (4000...8000).contains(port) else { return nil }
        var parts=URLComponents()
        parts.scheme="http"; parts.host=host; parts.port=port
        parts.path="/\(id.uuidString).ipa"
        return parts.url
    }
    static func manifestRequest(identifier: String, version: String, title: String, payload: URL) throws -> Data {
        guard InstallRequest.validMetadata(identifier: identifier, version: version, title: title),
              payload.scheme == "http", payload.host == host,
              let port=payload.port, (4000...8000).contains(port),
              payload.user == nil, payload.password == nil, payload.query == nil, payload.fragment == nil,
              payload.path.hasSuffix(".ipa"), payload.pathComponents.count == 2,
              UUID(uuidString: String(payload.lastPathComponent.dropLast(4))) != nil else {
            throw NSError(domain:"OSign.LocalDelivery",code:1,userInfo:[NSLocalizedDescriptionKey:"Invalid app metadata or non-local IPA URL. Installation was not started."])
        }
        return try JSONSerialization.data(withJSONObject:["identifier":identifier,"version":version,"title":title,"ipaURL":payload.absoluteString])
    }
    static func installPage(for manifest: URL) -> String {
        let handoff=InstallRequest.handoffURL(manifest).absoluteString
        let literal=(try? JSONEncoder().encode(handoff)).flatMap { String(data:$0,encoding:.utf8) } ?? "\"\""
        let href=handoff.replacingOccurrences(of:"&",with:"&amp;").replacingOccurrences(of:"\"",with:"&quot;")
        return """
        <!doctype html><html><meta name="viewport" content="width=device-width,initial-scale=1"><body style="background:#080c09;color:#eee;font:18px -apple-system;padding:28px">
        <h2>OSign · Semi Local</h2><p>Your IPA stays on this iPhone. Keep OSign open while iOS downloads it from localhost.</p>
        <p><a style="color:#33f276" href="\(href)">Tap here if the install prompt did not open</a></p>
        <p>Opening the system prompt does not confirm installation.</p><script>window.location.href=\(literal);</script></body></html>
        """
    }
}
