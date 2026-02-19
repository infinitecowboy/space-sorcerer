// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WindowWizard",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "CGSBridge",
            path: "Sources/CGSBridge",
            publicHeadersPath: "include",
            linkerSettings: [
                .unsafeFlags([
                    "-F/System/Library/PrivateFrameworks",
                    "-framework", "SkyLight",
                ]),
            ]
        ),
        .executableTarget(
            name: "WindowWizard",
            dependencies: ["CGSBridge"],
            path: "Sources/WindowWizard",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .unsafeFlags([
                    "-F/System/Library/PrivateFrameworks",
                    "-framework", "SkyLight",
                ]),
            ]
        ),
    ]
)
