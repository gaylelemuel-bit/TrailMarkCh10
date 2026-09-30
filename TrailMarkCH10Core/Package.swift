// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TrailMarkCH10Core",
    platforms: [
        .iOS("26.0"),
        .watchOS("10.0")
    ],
    products: [
        .library(
            name: "TrailMarkCH10Core",
            targets: ["TrailMarkCH10Core"]
        ),
    ],
    targets: [
        .target(
            name: "TrailMarkCH10Core"
        ),

    ]
)
