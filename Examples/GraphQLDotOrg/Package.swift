// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GraphQLDotOrg",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "GraphQLDotOrg",
            targets: ["GraphQLDotOrg"]
        ),
    ],
    dependencies: [
        .package(name: "graphql-generator", path: "../.."),
        // TODO: Mainline when merged: https://github.com/GraphQLSwift/GraphQL/pull/174
        .package(url: "https://github.com/NeedleInAJayStack/GraphQL.git", revision: "42ac35a0f69b9ffffcf9d02398c0b13d0c0e71aa"),
    ],
    targets: [
        .target(
            name: "GraphQLDotOrg",
            dependencies: [
                .product(name: "GraphQL", package: "GraphQL"),
                .product(name: "GraphQLGeneratorRuntime", package: "graphql-generator"),
            ],
            plugins: [
                .plugin(name: "GraphQLGeneratorPlugin", package: "graphql-generator"),
            ]
        ),
    ]
)
