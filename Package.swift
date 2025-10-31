// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SmartTextInputSystem",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SmartTextInputSystem",
            targets: ["SmartTextInputSystem"]),
    ],
    targets: [
        .target(
            name: "SmartTextInputSystem",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SmartTextInputSystemTests",
            dependencies: ["SmartTextInputSystem"]),
    ],
    swiftLanguageVersions: [.v5]
)