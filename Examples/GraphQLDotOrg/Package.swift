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
        .package(url: "https://github.com/NeedleInAJayStack/GraphQL.git", revision: "30873303575b92f2395a900869ec8f253efad1b2"),
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
