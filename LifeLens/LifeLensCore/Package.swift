// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LifeLensCore",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "LifeLensCore",
            targets: ["LifeLensCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LifeLensCore",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "LifeLensCoreTests",
            dependencies: ["LifeLensCore"],
            path: "Tests"),
    ]
)