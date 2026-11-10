import AppKit

// Vector artwork, rendered at each native macOS icon size.
func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}

func roundedRect(_ rect: NSRect, radius: CGFloat, fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func render(size: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                 isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0,
                                 bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let context = NSGraphicsContext.current!.cgContext
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)

    let tile = NSBezierPath(roundedRect: NSRect(x: 96, y: 96, width: 832, height: 832),
                            xRadius: 184, yRadius: 184)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -14), blur: 26,
                      color: NSColor.black.withAlphaComponent(0.18).cgColor)
    color(0x126D70).setFill()
    tile.fill()
    context.restoreGState()
    NSGradient(starting: color(0x12545F), ending: color(0x30B7A2))!.draw(in: tile, angle: 65)

    // A second sheet makes the history concept visible even at small sizes.
    roundedRect(NSRect(x: 337, y: 219, width: 410, height: 528), radius: 46,
                fill: color(0xC5EBE1, alpha: 0.62))

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 18,
                      color: color(0x053B43, alpha: 0.20).cgColor)
    roundedRect(NSRect(x: 277, y: 270, width: 430, height: 528), radius: 46,
                fill: color(0xFFFEF6))
    context.restoreGState()

    // Clipboard clasp and its small hanging hole.
    roundedRect(NSRect(x: 390, y: 744, width: 204, height: 100), radius: 30,
                fill: color(0xD5EEE5))
    color(0x1A776F).setFill()
    NSBezierPath(ovalIn: NSRect(x: 476, y: 793, width: 32, height: 32)).fill()

    for (y, width) in [(CGFloat(636), CGFloat(270)), (CGFloat(537), CGFloat(214)),
                       (CGFloat(438), CGFloat(252))] {
        roundedRect(NSRect(x: 357, y: y, width: width, height: 29), radius: 14.5,
                    fill: color(0x247C78, alpha: 0.88))
    }

    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

let project = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let iconset = project.appendingPathComponent(".build/AppIcon.iconset")
let resources = project.appendingPathComponent("Resources")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
let variants: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, size) in variants {
    try render(size: size).write(to: iconset.appendingPathComponent(name))
}
try render(size: 1024).write(to: resources.appendingPathComponent("AppIcon.png"))
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["--convert", "icns", "--output", resources.appendingPathComponent("AppIcon.icns").path, iconset.path]
try process.run()
process.waitUntilExit()
exit(process.terminationStatus)
