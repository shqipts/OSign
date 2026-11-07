import Foundation
let error = IDeviceSwiftError(-7001, message: "Remote pairing endpoint TCP connection failed")
if !error.localizedDescription.contains("Remote pairing endpoint TCP connection failed") || !error.localizedDescription.contains("-7001") {
    print("FAIL: native pairing reason/code is hidden: \(error.localizedDescription)")
    exit(1)
}
print("PASS: native pairing reason and code are visible")
