// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "StoryMaker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "TaskRunner", targets: ["TaskRunner"])
    ],
    targets: [
        .target(
            name: "TaskRunner",
            dependencies: []
        )
    ]
)
