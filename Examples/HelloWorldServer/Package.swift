// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HelloWorldServer",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(name: "graphql-generator", path: "../.."),
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "HelloWorldServer",
            dependencies: [
                .product(name: "GraphQL", package: "GraphQL"),
                .product(name: "GraphQLGeneratorRuntime", package: "graphql-generator"),
            ],
            plugins: [
                .plugin(name: "GraphQLGeneratorPlugin", package: "graphql-generator")
            ]
        ),
    ]
)
