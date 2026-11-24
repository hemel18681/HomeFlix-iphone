// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HomeFlix",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "HomeFlix",
            targets: ["HomeFlix"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "HomeFlix",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources"),
                .process("Assets.xcassets")
            ]
        )
    ]
)
