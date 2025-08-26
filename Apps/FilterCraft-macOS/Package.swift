// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "FilterCraft-macOS",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "FilterCraft-macOS", targets: ["FilterCraft-macOS"])
    ],
    dependencies: [
        .package(path: "../../Packages/FilterCraftCore")
    ],
    targets: [
        .executableTarget(
            name: "FilterCraft-macOS",
            dependencies: [
                .product(name: "FilterCraftCore", package: "FilterCraftCore")
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        .testTarget(
            name: "FilterCraft-macOSTests",
            dependencies: ["FilterCraft-macOS"],
            path: "Tests"
        )
    ]
)