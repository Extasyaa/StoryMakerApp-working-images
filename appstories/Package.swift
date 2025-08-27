// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "StoryMaker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "TaskRunner", targets: ["TaskRunner"]),
        .library(name: "StoryCore", targets: ["StoryCore"])
    ],
    targets: [
        .target(
            name: "TaskRunner",
            dependencies: []
        ),
        .target(
            name: "StoryCore",
            dependencies: []
        ),
        .testTarget(
            name: "StoryCoreTests",
            dependencies: ["StoryCore"]
        )
    ]
)
