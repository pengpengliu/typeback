// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Typeback",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "TypebackCore",
            targets: ["TypebackCore"]
        ),
        .executable(
            name: "Typeback",
            targets: ["Typeback"]
        ),
    ],
    targets: [
        .target(
            name: "TypebackCore"
        ),
        .executableTarget(
            name: "Typeback",
            dependencies: ["TypebackCore"]
        ),
        .testTarget(
            name: "TypebackCoreTests",
            dependencies: ["TypebackCore"]
        ),
    ]
)
