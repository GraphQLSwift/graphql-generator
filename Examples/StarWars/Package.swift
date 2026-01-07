// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "StarWars",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "StarWars",
            targets: ["StarWars"]
        ),
    ],
    dependencies: [
        .package(name: "graphql-generator", path: "../.."),
        .package(url: "https://github.com/GraphQLSwift/DataLoader", from: "2.0.0"),
        .package(url: "https://github.com/GraphQLSwift/GraphQL", from: "4.1.0"),
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "StarWars",
            dependencies: [
                .product(name: "AsyncDataLoader", package: "DataLoader"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "GraphQL", package: "GraphQL"),
                .product(name: "GraphQLGeneratorRuntime", package: "graphql-generator"),
            ],
            plugins: [
                .plugin(name: "GraphQLGeneratorPlugin", package: "graphql-generator"),
            ]
        ),
        .testTarget(
            name: "StarWarsTests",
            dependencies: [
                "StarWars",
            ]
        ),
    ]
)
