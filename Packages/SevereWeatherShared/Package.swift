// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SevereWeatherShared",
    platforms: [
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "SevereWeatherShared",
            targets: ["SevereWeatherShared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ratafani/ILSpatial.git", branch: "main"),
        .package(path: "../RealityKitContent")
    ],
    targets: [
        .target(
            name: "SevereWeatherShared",
            dependencies: [
                .product(name: "ILSFoundation", package: "ILSpatial"),
                .product(name: "ILSEngine", package: "ILSpatial"),
                .product(name: "ILSHandTracking", package: "ILSpatial"),
                "RealityKitContent"
            ]),
    ]
)
