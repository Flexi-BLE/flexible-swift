// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flexiBLE-swift",
    platforms: [
        .iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "flexible-swift",
            targets: ["FlexiBLE"]),
    ],
    dependencies: [
        .package(
            name: "GRDB",
            url: "https://github.com/groue/GRDB.swift.git",
            branch: "master"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FlexiBLE",
            dependencies: [
                .product(name: "GRDB", package: "GRDB")
            ],
            resources: [.process("resources")]
        ),
        .testTarget(
            name: "FlexiBLETests",
            dependencies: ["FlexiBLE"]),
    ]
)
