// OSign Semi Local settings. Original source credits retained; GPL-3.0.
import SwiftUI
import NimbleViews

struct InstallationView: View {
    @State private var checking=false
    @State private var sslMessage=""
    var body: some View {
        NBList("Installation") {
            Section {
                HStack {
                    Label("Installation Type",systemImage:"arrow.down.app")
                    Spacer(); Text("Server").foregroundStyle(.secondary)
                }
            } footer: {
                Text("Uses a localhost server on this iPhone and the system installation prompt. No pairing file or LocalDevVPN is used.")
            }
            Section {
                HStack {
                    Label("Server Type",systemImage:"server.rack")
                    Spacer(); Text("Semi Local").foregroundStyle(.secondary)
                }
                Toggle(isOn:.constant(true)) {
                    Label("Only use localhost address",systemImage:"network")
                }.disabled(true).tint(.green)
            } footer: {
                Text("Always enabled: the IPA server binds only to 127.0.0.1, never your Wi-Fi/LAN address. Your IPA stays on this phone. The VPS receives only app metadata and the localhost URL to generate a small HTTPS manifest. The public VPS uses trusted HTTPS with automatic certificate renewal. Tailscale is not required.")
            }
            Section {
                Button {
                    checking=true
                    Task {
                        do { sslMessage=try await InstallRelayClient.checkSSL() }
                        catch { sslMessage=InstallRelayClient.explanation(error) }
                        checking=false
                    }
                } label: {
                    Label("Check SSL Certificate",systemImage:"doc.badge.arrow.up")
                }.disabled(checking)
                if checking { ProgressView("Checking VPS HTTPS…") }
                if !sslMessage.isEmpty { Text(sslMessage).font(.footnote).textSelection(.enabled) }
            } footer: {
                Text("The VPS already has a trusted HTTPS certificate with automatic renewal. No self-signed certificate, private TLS key import, or trust bypass is needed on your phone.")
            }
            Section {
                Text("Keep OSign open while the system fetches the IPA from localhost. Installation still depends on valid signatures, provisioning and iOS delivery policy. Export remains available if the system rejects Semi Local installation.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
