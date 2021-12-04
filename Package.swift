// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

/**
 *  Shift
 *  Copyright (c) Vinh Nguyen 2021
 *  MIT license, see LICENSE file for details
 */

import PackageDescription

let package = Package(
    name: "Shift",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Shift",
            targets: ["Shift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Shift",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
            ]),
        .testTarget(
            name: "ShiftTests",
            dependencies: ["Shift"]),
    ]
)
