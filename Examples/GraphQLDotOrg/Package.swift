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
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", from: "4.0.0"),
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
