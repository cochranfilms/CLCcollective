// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CLCcollective",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CLCcollective",
            targets: ["CLCcollective"]),
    ],
    dependencies: [
        .package(url: "https://github.com/auth0/Auth0.swift", exact: "2.5.0"),
    ],
    targets: [
        .target(
            name: "CLCcollective",
            dependencies: [
                .product(name: "Auth0", package: "Auth0.swift"),
            ]),
        .testTarget(
            name: "CLCcollectiveTests",
            dependencies: ["CLCcollective"]
        ),
    ]
)
