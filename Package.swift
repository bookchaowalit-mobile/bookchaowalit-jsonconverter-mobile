// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Jsonconverter",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "JsonconverterCore", targets: ["JsonconverterCore"]),
        .library(name: "JsonconverterUI", targets: ["JsonconverterUI"]),
    ],
    targets: [
        // Foundation-only domain logic; no SwiftUI so it also builds on Linux.
        .target(name: "JsonconverterCore", path: "Sources/JsonconverterCore"),
        .target(name: "JsonconverterUI", dependencies: ["JsonconverterCore"], path: "Sources/JsonconverterUI"),
        .testTarget(name: "JsonconverterCoreTests", dependencies: ["JsonconverterCore"], path: "Tests/JsonconverterCoreTests"),
    ]
)
