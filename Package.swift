// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Jsonconverter",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Jsonconverter", targets: ["Jsonconverter"])
    ],
    targets: [
        .target(name: "Jsonconverter", path: "Sources")
    ]
)
