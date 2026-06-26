// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SevereWeatherUI",
    platforms: [
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "SevereWeatherUI",
            targets: ["SevereWeatherUI"]),
    ],
    dependencies: [
        .package(path: "../SevereWeatherShared"),
        .package(path: "../RealityKitContent")
    ],
    targets: [
        .target(
            name: "SevereWeatherUI",
            dependencies: [
                "SevereWeatherShared",
                "RealityKitContent"
            ],
            resources: [
                .process("Resources")
            ]),
    ]
)
