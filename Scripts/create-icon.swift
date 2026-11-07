import AppKit
import Foundation
let side = 1024
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(calibratedRed: 0.018, green: 0.045, blue: 0.032, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: side, height: side)).fill()
let green = NSColor(calibratedRed: 0.20, green: 0.95, blue: 0.46, alpha: 1)
green.setStroke()
let ring = NSBezierPath(ovalIn: NSRect(x: 208, y: 208, width: 608, height: 608))
ring.lineWidth = 54
ring.stroke()
let path = NSBezierPath()
path.move(to: NSPoint(x: 340, y: 490)); path.line(to: NSPoint(x: 462, y: 365)); path.line(to: NSPoint(x: 706, y: 654)); path.lineWidth = 50
path.lineCapStyle = .round; path.lineJoinStyle = .round; path.stroke()
let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 56, weight: .semibold), .foregroundColor: green]
("OSIGN" as NSString).draw(at: NSPoint(x: 426, y: 98), withAttributes: attributes)
NSGraphicsContext.restoreGraphicsState()
let png = bitmap.representation(using: .png, properties: [:])!
for arg in CommandLine.arguments.dropFirst() { try png.write(to: URL(fileURLWithPath: arg)) }
