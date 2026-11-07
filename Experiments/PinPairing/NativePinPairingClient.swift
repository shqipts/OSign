// OSign experimental native code-based remote pairing. GPL-3.0.
import Foundation
import SwiftUI
import IDevice
import IDeviceSwift

private final class PairingRequestState {
    let exchange = PairingCodeExchange()
    private let lock = NSLock()
    private var cancelled = false
    private var codeBuffer: UnsafeMutablePointer<CChar>?
    let onCodeRequested: () -> Void
    init(onCodeRequested: @escaping () -> Void) { self.onCodeRequested = onCodeRequested }
    func cancel() { lock.lock(); cancelled = true; lock.unlock(); exchange.cancel() }
    func isCancelled() -> Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
    func requestCode() -> UnsafePointer<CChar>? {
        onCodeRequested()
        guard let code = exchange.wait(seconds: 90), !isCancelled() else { return nil }
        lock.lock()
        defer { lock.unlock() }
        codeBuffer = strdup(code)
        return codeBuffer.map { UnsafePointer($0) }
    }
    deinit {
        if let codeBuffer {
            memset(codeBuffer, 0, strlen(codeBuffer))
            free(codeBuffer)
        }
    }
}

final class NativePinPairingClient: ObservableObject {
    @Published var busy = false
    @Published var waitingForCode = false
    @Published var message = "Create a new private connection without exporting or importing a file. This experimental flow still needs testing on your iPhone."
    private var current: PairingRequestState?
    struct Failure: LocalizedError {
        let reason: String
        var errorDescription: String? { reason }
    }
    private static func nativeFailure(_ error: UnsafeMutablePointer<IdeviceFfiError>) -> Failure {
        let reason = error.pointee.message.map { String(cString: $0) } ?? "Native pairing failed"
        let code = error.pointee.code
        let subcode = error.pointee.sub_code
        idevice_error_free(error)
        return Failure(reason: "\(reason) (code \(code), detail \(subcode))")
    }
    @MainActor func submit(_ code: String) {
        if current?.exchange.submit(code) == true {
            waitingForCode = false
            message = "Checking the code with this iPhone…"
        } else { message = "Enter the six-digit pairing code on this phone. Do not send it in chat." }
    }
    @MainActor func cancel() {
        current?.cancel()
        waitingForCode = false
        if busy { message = "Cancelling the pairing request…" }
    }
    @MainActor func pair(address: String, port: Int) async {
        guard !busy else { return }
        guard InstallRequest.validLocalEndpoint(address: address, port: String(port)), let tcpPort = UInt16(exactly: port) else {
            message = "Set a valid local device IPv4 and the current remote-pairing port first."
            return
        }
        busy = true
        waitingForCode = false
        message = "Requesting a new pairing named OSign. Approve ONLY OSign if iOS asks. If a code appears, return here and enter it."
        let state = PairingRequestState { [weak self] in
            DispatchQueue.main.async {
                self?.waitingForCode = true
                self?.message = "iOS requested a pairing code. Enter it below within 90 seconds. The code stays on this phone."
            }
        }
        current = state
        let background = UIApplication.shared.beginBackgroundTask(withName: "OSign pairing") { state.cancel() }
        defer {
            if background != .invalid { UIApplication.shared.endBackgroundTask(background) }
            current = nil
            waitingForCode = false
            busy = false
        }
        do {
            let recordData = try await Task.detached(priority: .userInitiated) {
                let context = Unmanaged.passRetained(state).toOpaque()
                defer { Unmanaged<PairingRequestState>.fromOpaque(context).release() }
                var record: OpaquePointer?
                let error = address.withCString { endpoint in
                    "OSign".withCString { label in
                        osign_network_pair(endpoint, tcpPort, label, { pointer in
                            guard let pointer else { return nil }
                            return Unmanaged<PairingRequestState>.fromOpaque(pointer).takeUnretainedValue().requestCode()
                        }, { pointer in
                            guard let pointer else { return true }
                            return Unmanaged<PairingRequestState>.fromOpaque(pointer).takeUnretainedValue().isCancelled()
                        }, context, &record)
                    }
                }
                defer { if let record { rp_pairing_file_free(record) } }
                if let error { throw Self.nativeFailure(error) }
                guard !state.isCancelled(), let record else { throw Failure(reason: "Pairing was cancelled; your previous record was kept.") }
                var bytes: UnsafeMutablePointer<UInt8>?
                var length = 0
                if let error = rp_pairing_file_to_bytes(record, &bytes, &length) { throw Self.nativeFailure(error) }
                guard let bytes else { throw Failure(reason: "Native pairing returned no record.") }
                defer { idevice_data_free(bytes, length) }
                return Data(bytes: bytes, count: length)
            }.value
            guard !state.isCancelled(), InstallRequest.validPairingRecord(recordData) else {
                throw Failure(reason: "Pairing was cancelled or returned an invalid record. Your previous record was kept.")
            }
            try recordData.write(to: URL(fileURLWithPath: HeartbeatManager.pairingFile()), options: [.atomic, .completeFileProtection])
            message = "Pairing completed and saved privately on this phone. No manual file import was needed. Run Check Local Connection next; pairing alone is not install success."
        } catch {
            message = "Pairing did not complete: \(error.localizedDescription). Your previous record was kept."
        }
    }
}
