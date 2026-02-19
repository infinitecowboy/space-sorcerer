// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SpaceSorcerer",
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
            name: "SpaceSorcerer",
            dependencies: ["CGSBridge"],
            path: "Sources/SpaceSorcerer",
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
