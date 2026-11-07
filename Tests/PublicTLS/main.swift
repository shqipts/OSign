import Foundation
@main struct PublicTLSCheck {
    static func main() async throws {
        print(try await InstallRelayClient.checkSSL())
    }
}
