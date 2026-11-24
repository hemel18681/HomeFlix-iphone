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
    dependencies: [
        .package(url: "https://github.com/kingslay/KSPlayer.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "HomeFlix",
            dependencies: [
                .product(name: "KSPlayer", package: "KSPlayer")
            ],
            path: "Sources",
            resources: [
                .process("Resources"),
                .process("Assets.xcassets")
            ]
        )
    ]
)
