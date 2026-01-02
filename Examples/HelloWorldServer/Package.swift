// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HelloWorldServer",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(name: "graphql-generator", path: "../.."),
        // TODO: Mainline when merged: https://github.com/GraphQLSwift/GraphQL/pull/174
        .package(url: "https://github.com/NeedleInAJayStack/GraphQL.git", revision: "44bdda71e28b59201dd4fe4178eddbffba748394"),
    ],
    targets: [
        .target(
            name: "HelloWorldServer",
            dependencies: [
                .product(name: "GraphQL", package: "GraphQL"),
                .product(name: "GraphQLGeneratorRuntime", package: "graphql-generator"),
            ],
            plugins: [
                .plugin(name: "GraphQLGeneratorPlugin", package: "graphql-generator"),
            ]
        ),
        .testTarget(
            name: "HelloWorldServerTests",
            dependencies: [
                "HelloWorldServer",
                .product(name: "GraphQL", package: "GraphQL"),
            ]
        ),
    ]
)
