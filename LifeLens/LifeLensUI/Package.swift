// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LifeLensUI",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "LifeLensUI",
            targets: ["LifeLensUI"]),
    ],
    dependencies: [
        .package(path: "../LifeLensCore"),
        .package(url: "https://github.com/danielgindi/Charts.git", from: "4.1.0")
    ],
    targets: [
        .target(
            name: "LifeLensUI",
            dependencies: [
                "LifeLensCore",
                .product(name: "Charts", package: "Charts")
            ],
            path: "Sources"),
        .testTarget(
            name: "LifeLensUITests",
            dependencies: ["LifeLensUI"],
            path: "Tests"),
    ]
)