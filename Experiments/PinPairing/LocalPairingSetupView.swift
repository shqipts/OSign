// OSign local pairing diagnostics. GPL-3.0.
import SwiftUI
import IDeviceSwift
import UniformTypeIdentifiers

final class PairingServiceDiscovery: NSObject, ObservableObject, NetServiceBrowserDelegate, NetServiceDelegate {
    struct Endpoint: Identifiable {
        let id: String
        let name: String
        let port: Int
    }
    @Published var endpoints: [Endpoint] = []
    @Published var message = "Discover the current remote-pairing port on your Wi-Fi network."
    private let browser = NetServiceBrowser()
    private var resolving: [NetService] = []
    func start() {
        browser.stop()
        resolving.forEach { $0.stop() }
        resolving.removeAll()
        endpoints.removeAll()
        message = "Searching… Allow local-network access when iOS asks."
        browser.delegate = self
        browser.searchForServices(ofType: "_remotepairing._tcp.", inDomain: "local.")
    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        resolving.append(service)
        service.delegate = self
        service.resolve(withTimeout: 6)
    }
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard sender.port > 0 else { return }
        let id = sender.name + sender.domain
        endpoints.removeAll { $0.id == id }
        endpoints.append(Endpoint(id: id, name: sender.name, port: sender.port))
        message = "Select THIS iPhone's service—not another device. This sets the port only."
    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        message = "Discovery unavailable (\(errorDict)). Check Settings → Privacy & Security → Local Network → OSign. You can enter the port manually."
    }
    func stop() { browser.stop(); resolving.forEach { $0.stop() } }
}

struct LocalPairingSetupView: View {
    @AppStorage("OSign.localPairingAddress") private var address = "10.7.0.1"
    @AppStorage("OSign.localPairingPort") private var port = 49152
    @StateObject private var discovery = PairingServiceDiscovery()
    @StateObject private var pairing = NativePinPairingClient()
    @State private var pairingCode = ""
    @State private var message = "A pairing file and a working local VPN are both required. Returning from the VPN app is not a connection test."
    @State private var hasRecord = false
    @State private var checking = false
    @State private var importing = false
    @State private var waitingForVPN = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Form {
            Section("Pair by code / automatic pairing — experimental") {
                Text("No file export/import is needed for this route. First enable LocalDevVPN and set this iPhone's local endpoint below. Tap Pair, approve only OSign in iOS, and enter any requested code HERE—not in chat. Keep Developer Mode enabled. If iOS does not offer a code, the protocol may instead request approval.")
                    .font(.footnote)
                Button("Pair a new OSign connection") { Task { await pairing.pair(address: address, port: port) } }
                    .disabled(pairing.busy || checking)
                if pairing.busy { ProgressView("Pairing request in progress…") }
                if pairing.waitingForCode {
                    SecureField("Six-digit pairing code", text: $pairingCode)
                        .keyboardType(.numberPad).textContentType(.oneTimeCode).privacySensitive()
                    Button("Submit code privately") { pairing.submit(pairingCode); pairingCode = "" }
                }
                if pairing.busy { Button("Cancel pairing", role: .cancel) { pairing.cancel(); pairingCode = "" } }
                Text(pairing.message).font(.callout).textSelection(.enabled)
                Text("The existing private record is replaced only after pairing succeeds. Afterward run Check Local Connection. This is a test feature, not a promise of local installation.").font(.footnote)
            }
            Section("1 · Existing pairing record / fallback") {
                Label(hasRecord ? "Remote-pairing record found" : "Missing or invalid remote-pairing record", systemImage: hasRecord ? "checkmark.shield" : "exclamationmark.shield")
                Button("Import private pairing file") { importing = true }.disabled(pairing.busy || checking)
                Text("The record stays on this phone. Do not upload or send it in chat.").font(.footnote)
            }
            Section("2 · Local VPN") {
                Button("Open / enable LocalDevVPN") { openVPN() }
                Button("Get LocalDevVPN from App Store") {
                    UIApplication.shared.open(URL(string: "https://apps.apple.com/us/app/localdevvpn/id6755608044")!)
                }
                Text("Disconnect Tailscale. In LocalDevVPN, confirm the VPN itself says Connected. Match the DEVICE/PEER IP below, not its tunnel/interface IP. OSign cannot approve VPN permissions or read another app's private VPN configuration.")
                    .font(.footnote)
            }
            Section("3 · Local endpoint") {
                TextField("Device / peer IPv4", text: $address).keyboardType(.decimalPad).autocorrectionDisabled()
                TextField("Remote-pairing TCP port", value: $port, format: .number).keyboardType(.numberPad)
                Text("The old default is 10.7.0.1:49152. The actual remote-pairing port can differ; discover it below or enter the correct port. Never choose another device's service.").font(.footnote)
                Button("Discover remote-pairing services") { discovery.start() }
                Text(discovery.message).font(.caption)
                ForEach(discovery.endpoints) { endpoint in
                    Button("\(endpoint.name) · port \(endpoint.port)") {
                        port = endpoint.port
                        message = "Port selected. Enable LocalDevVPN, then run Check Local Connection."
                    }
                }
            }
            Section("4 · Verify connection") {
                Button("Check Local Connection") { Task { await check() } }.disabled(checking || pairing.busy)
                if checking { ProgressView("Testing the encrypted pairing tunnel…") }
                Text(message).font(.callout).textSelection(.enabled)
                Text("Only a successful check proves that this endpoint and record can open a pairing tunnel. Installation may still be rejected by the device.").font(.footnote)
            }
        }
        .navigationTitle("Local pairing setup")
        .onAppear { refreshRecord() }
        .onDisappear { discovery.stop(); pairing.cancel(); pairingCode = "" }
        .onChange(of: pairing.busy) { busy in
            if !busy { refreshRecord(); pairingCode = "" }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active && waitingForVPN {
                waitingForVPN = false
                message = "Returned from LocalDevVPN. Connection is NOT verified yet—tap Check Local Connection."
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.xmlPropertyList, .data]) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                guard InstallRequest.validPairingRecord(data) else {
                    message = "This is not a valid remote-pairing record. Use the RPPairing file generated for this iPhone, not a USB lockdown plist."
                    return
                }
                let destination = URL(fileURLWithPath: HeartbeatManager.pairingFile())
                try data.write(to: destination, options: [.atomic, .completeFileProtection])
                refreshRecord()
                message = "Private record imported locally. Run Check Local Connection."
            } catch { message = "Pairing import failed: \(error.localizedDescription)" }
        }
    }
    private func refreshRecord() {
        hasRecord = (try? Data(contentsOf: URL(fileURLWithPath: HeartbeatManager.pairingFile()))).map(InstallRequest.validPairingRecord) ?? false
    }
    private func openVPN() {
        waitingForVPN = true
        message = "Opening LocalDevVPN. Approve its VPN prompt if needed; return and run Check Local Connection."
        UIApplication.shared.open(URL(string: "localdevvpn://enable?scheme=osign")!, options: [:]) { opened in
            if !opened { waitingForVPN = false; message = "LocalDevVPN could not be opened. Install it using the App Store button." }
        }
    }
    @MainActor private func check() async {
        refreshRecord()
        guard hasRecord else { message = "Missing or invalid remote-pairing record. Import it first."; return }
        guard InstallRequest.validLocalEndpoint(address: address, port: String(port)) else {
            message = "Enter a valid device IPv4 address and TCP port from 1 to 65535."
            return
        }
        checking = true
        message = "Testing \(address):\(port)…"
        do {
            try await HeartbeatManager.shared.testLocalConnection()
            message = "CONNECTED: encrypted remote-pairing handshake succeeded at \(address):\(port). Return to the signed IPA and tap Install locally."
        } catch {
            message = "NOT CONNECTED: \(error.localizedDescription)"
        }
        checking = false
    }
}
