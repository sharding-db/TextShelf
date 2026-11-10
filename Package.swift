// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TextShelf",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "TextShelf", targets: ["TextShelf"])],
    targets: [
        .target(name: "ClipboardCore"),
        .target(name: "ClipboardMac", dependencies: ["ClipboardCore"]),
        .executableTarget(name: "TextShelf", dependencies: ["ClipboardCore", "ClipboardMac"]),
        .executableTarget(name: "ClipboardChecks", dependencies: ["ClipboardCore", "ClipboardMac"], path: "Tests/ClipboardTests"),
    ],
    swiftLanguageModes: [.v5]
)
