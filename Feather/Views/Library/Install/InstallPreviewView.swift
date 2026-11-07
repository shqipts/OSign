// OSign Semi Local installation. Based on Feather by Samara M; GPL-3.0.
import SwiftUI
import NimbleViews
import IDeviceSwift

struct InstallPreviewView: View {
    var app: AppInfoPresentable
    var isSharing: Bool
    @StateObject private var viewModel = InstallerStatusViewModel(isIdevice:false)
    @State private var package: URL?
    @State private var server: ServerInstaller?
    @State private var manifest: URL?
    @State private var manifestExpires = Date.distantPast
    @State private var showBrowser = false
    @State private var message = "Preparing IPA on this iPhone…"
    @State private var busy = true
    @State private var started = false
    @State private var backgroundTask = UIBackgroundTaskIdentifier.invalid

    init(app: AppInfoPresentable, isSharing: Bool=false) {
        self.app=app; self.isSharing=isSharing
    }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                Label(isSharing ? "Export IPA" : "Semi Local installation",systemImage:"arrow.down.app.fill").font(.title2.bold())
                Text(app.name ?? "Application").font(.headline)
                if busy {
                    ProgressView(value:viewModel.packageProgress)
                    ProgressView().frame(maxWidth:.infinity)
                }
                Text(message).font(.callout).textSelection(.enabled)
                if let package {
                    if !isSharing {
                        Label("Only localhost · 127.0.0.1",systemImage:"network").font(.headline)
                        Text("The IPA stays on this iPhone. Only app name, bundle ID, version and a localhost URL are sent to your VPS to create the HTTPS manifest. A normal internet connection is enough; Tailscale is not required. LocalDevVPN and pairing are not used.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button { Task { await install() } } label: {
                            Label("Install signed IPA",systemImage:"arrow.down.app").frame(maxWidth:.infinity)
                        }.buttonStyle(.borderedProminent).disabled(busy)
                        if let manifest {
                            Button("Open system prompt directly") { handoff(manifest) }.disabled(busy)
                        }
                        Text("Keep OSign open while iOS fetches the IPA from localhost. A prompt or completed transfer does not prove installation. iOS may reject this delivery route or the provisioning; any system error matters.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Divider()
                    }
                    Button { UIActivityViewController.show(activityItems:[package]) } label: {
                        Label("Export IPA",systemImage:"square.and.arrow.up").frame(maxWidth:.infinity)
                    }.buttonStyle(.bordered)
                }
            }.padding(24)
        }
        .background(Color(white:0.035)).foregroundStyle(.white)
        .tint(Color(red:0.20,green:0.95,blue:0.46))
        .sheet(isPresented:$showBrowser) {
            if let server { SafariRepresentableView(url:server.pageEndpoint).ignoresSafeArea() }
        }
        .onReceive(viewModel.$status) { status in
            switch status {
            case .sendingPayload: message="iOS is fetching the IPA directly from this iPhone's localhost server…"
            case .installing:
                message="Local delivery response sent. Check the system prompt and Home Screen; this is not installation confirmation."
            case .broken(let error): message="Local delivery failed: \(error.localizedDescription)"; endBackgroundTime()
            default: break
            }
        }
        .task {
            guard !started else { return }
            started=true
            await prepare()
        }
        .onDisappear { endBackgroundTime() }
    }
    @MainActor private func prepare() async {
        guard InstallRequest.validMetadata(identifier:app.identifier,version:app.version,title:app.name) else {
            message="This app is missing its bundle identifier, version or name. Re-import a valid IPA."
            busy=false; return
        }
        do {
            let handler=ArchiveHandler(app:app,viewModel:viewModel)
            try await handler.move()
            let result=try await handler.archive()
            guard FileManager.default.fileExists(atPath:result.path) else { throw CocoaError(.fileNoSuchFile) }
            package=result
            message="IPA ready on this phone. Choose Install or Export."
        } catch { message="IPA preparation failed: \(error.localizedDescription)" }
        busy=false
    }
    @MainActor private func install() async {
        guard !busy, let package else { return }
        guard app.identifier != Bundle.main.bundleIdentifier else {
            message="OSign cannot replace itself while serving its own IPA. Export it and use another installer for OSign updates."
            return
        }
        busy=true
        do {
            if server == nil {
                message="Starting the localhost-only server…"
                let local=try ServerInstaller(app:app,viewModel:viewModel)
                local.packageUrl=package
                server=local
            }
            guard let server else { throw CocoaError(.fileReadUnknown) }
            if manifest == nil || manifestExpires <= Date() {
                message="Creating the small HTTPS manifest on your VPS. The IPA is NOT being uploaded…"
                let url=try await InstallRelayClient().createManifest(identifier:app.identifier ?? "",version:app.version ?? "",title:app.name ?? "",payload:server.payloadEndpoint)
                manifest=url
                manifestExpires=Date().addingTimeInterval(8*60)
                server.externalManifestURL=url
            }
            if backgroundTask == .invalid {
                backgroundTask=UIApplication.shared.beginBackgroundTask(withName:"OSign local delivery") {
                    Task { @MainActor in
                        message="iOS background time expired. Return to OSign and retry while keeping it open."
                        endBackgroundTime()
                    }
                }
            }
            message="Opening the Semi Local installation page. Accept the iOS prompt."
            showBrowser=true
        } catch { message="Install preparation failed: \(InstallRelayClient.explanation(error))" }
        busy=false
    }
    @MainActor private func handoff(_ manifest: URL) {
        UIApplication.shared.open(InstallRequest.handoffURL(manifest),options:[:]) { accepted in
            message=InstallRequest.handoffMessage(accepted:accepted)
        }
    }
    private func endBackgroundTime() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
