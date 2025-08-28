// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LifeLensML",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "LifeLensML",
            targets: ["LifeLensML"]),
    ],
    dependencies: [
        .package(path: "../LifeLensCore")
    ],
    targets: [
        .target(
            name: "LifeLensML",
            dependencies: ["LifeLensCore"],
            path: "Sources"),
        .testTarget(
            name: "LifeLensMLTests",
            dependencies: ["LifeLensML"],
            path: "Tests"),
    ]
)