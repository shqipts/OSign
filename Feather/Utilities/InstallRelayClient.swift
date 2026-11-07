// OSign semi-local manifest client. GPL-3.0. Never uploads an IPA or signing key.
import Foundation

final class InstallRelayClient: NSObject, URLSessionTaskDelegate {
    private struct Configuration: Decodable { let manifestURL: String; let token: String }
    enum RelayError: LocalizedError {
        case configuration, response(Int), invalidReply
        var errorDescription: String? {
            switch self {
            case .configuration: return "The private manifest-server configuration is missing. Use the configured OSign build."
            case .response(let code): return "Manifest server returned HTTP \(code). Check server availability and retry."
            case .invalidReply: return "Manifest server returned an invalid HTTPS URL. Nothing was handed to iOS."
            }
        }
    }
    func createManifest(identifier: String, version: String, title: String, payload: URL) async throws -> URL {
        guard let file=Bundle.main.url(forResource:"OSignRelay",withExtension:"json"),
              let config=try? JSONDecoder().decode(Configuration.self,from:Data(contentsOf:file)),
              let url=URL(string:config.manifestURL), url.absoluteString == "https://87.106.127.145/osign/manifest" else {
            throw RelayError.configuration
        }
        let body=try LocalDelivery.manifestRequest(identifier:identifier,version:version,title:title,payload:payload)
        var request=URLRequest(url:url)
        request.httpMethod="POST"
        request.setValue("Bearer \(config.token)",forHTTPHeaderField:"Authorization")
        request.setValue("application/json",forHTTPHeaderField:"Content-Type")
        request.httpBody=body
        request.timeoutInterval=30
        let session=URLSession(configuration:.ephemeral,delegate:self,delegateQueue:nil)
        defer { session.finishTasksAndInvalidate() }
        let (data,response)=try await session.data(for:request)
        guard let http=response as? HTTPURLResponse, http.statusCode==201 else {
            throw RelayError.response((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        guard let manifest=InstallRequest.relayManifest(data) else { throw RelayError.invalidReply }
        return manifest
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
    static func checkSSL() async throws -> String {
        let url=URL(string:"https://87.106.127.145/osign/health")!
        var request=URLRequest(url:url); request.timeoutInterval=15
        let (_,response)=try await URLSession.shared.data(for:request)
        guard (response as? HTTPURLResponse)?.statusCode==200 else { throw RelayError.invalidReply }
        return "VPS HTTPS/TLS validated successfully. Certificate renewal is managed on the VPS; no SSL key or certificate needs importing on this phone."
    }
    static func explanation(_ error: Error) -> String {
        let native=error as NSError
        if native.domain==NSURLErrorDomain && [NSURLErrorCannotFindHost,NSURLErrorDNSLookupFailed].contains(native.code) {
            return "Cannot reach the public manifest server. Check your internet connection and retry. Tailscale is not required; the IPA has not left this phone."
        }
        return error.localizedDescription
    }
}
