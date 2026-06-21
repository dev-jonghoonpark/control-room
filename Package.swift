// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ControlRoom",
    platforms: [.macOS(.v13)],
    targets: [
        // C shim exposing private SkyLight / Accessibility symbols.
        .target(
            name: "CGSPrivate",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "ControlRoom",
            dependencies: ["CGSPrivate"],
            linkerSettings: [
                // SkyLight is where the SLS* (CoreGraphics Spaces) symbols live.
                .unsafeFlags([
                    "-F", "/System/Library/PrivateFrameworks",
                    "-framework", "SkyLight",
                ])
            ]
        ),
    ]
)
