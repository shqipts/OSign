// OSign private in-memory pairing-code exchange. GPL-3.0.
import Foundation

final class PairingCodeExchange {
    private let lock = NSLock()
    private let signal = DispatchSemaphore(value: 0)
    private var code: String?
    private var closed = false
    @discardableResult func submit(_ value: String) -> Bool {
        guard value.count == 6, value.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }) else { return false }
        lock.lock()
        guard !closed else { lock.unlock(); return false }
        closed = true
        code = value
        lock.unlock()
        signal.signal()
        return true
    }
    func cancel() {
        lock.lock()
        guard !closed else { lock.unlock(); return }
        closed = true
        code = nil
        lock.unlock()
        signal.signal()
    }
    func wait(seconds: Double) -> String? {
        guard signal.wait(timeout: .now() + seconds) == .success else { cancel(); return nil }
        lock.lock()
        defer { code = nil; lock.unlock() }
        return code
    }
}
