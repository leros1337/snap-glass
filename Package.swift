// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SnapGlass",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "SnapGlass", targets: ["SnapGlass"]),
        .library(name: "SnapGlassCore", targets: ["SnapGlassCore"])
    ],
    targets: [
        .target(name: "SnapGlassCore"),
        .executableTarget(
            name: "SnapGlass",
            dependencies: ["SnapGlassCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "SnapGlassCoreTests",
            dependencies: ["SnapGlassCore"]
        )
    ]
)

