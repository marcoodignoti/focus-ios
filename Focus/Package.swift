// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Focus",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // An xtool project should contain exactly one library product,
        // representing the main app.
        .library(
            name: "Focus",
            targets: ["Focus"]
        ),
    ],
    targets: [
        .target(
            name: "Focus",
            path: "Focus",
            exclude: [
                "Info.plist",
            ],
            resources: [
                .process("Assets.xcassets"),
            ]
        ),
    ]
)
