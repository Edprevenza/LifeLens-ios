// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LifeLensServices",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "LifeLensServices",
            targets: ["LifeLensServices"]),
    ],
    dependencies: [
        .package(path: "../LifeLensCore"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")
    ],
    targets: [
        .target(
            name: "LifeLensServices",
            dependencies: [
                "LifeLensCore",
                "Alamofire",
                "KeychainAccess"
            ],
            path: "Sources"),
        .testTarget(
            name: "LifeLensServicesTests",
            dependencies: ["LifeLensServices"],
            path: "Tests"),
    ]
)