import Foundation
// Dummy values for a local unit test; no real device code is used or printed.
let exchange = PairingCodeExchange()
assert(!exchange.submit("12x456"))
DispatchQueue.global().async { _ = exchange.submit("123456") }
guard exchange.wait(seconds: 2) == "123456" else { print("FAIL: callback did not receive code"); exit(1) }
assert(!exchange.submit("654321"))
let cancelled = PairingCodeExchange()
cancelled.cancel()
assert(cancelled.wait(seconds: 1) == nil)
let expired = PairingCodeExchange()
assert(expired.wait(seconds: 0.01) == nil)
assert(!expired.submit("123456"))
print("PASS: code validation, private callback delivery, cancellation, timeout and reuse rejection")
