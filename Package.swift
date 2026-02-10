// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MouseMover",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MouseMover",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "MouseMoverTests",
            dependencies: ["MouseMover"]
        ),
    ]
)
