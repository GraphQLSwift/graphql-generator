// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "graphql-generator",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .plugin(
            name: "GraphQLGeneratorPlugin",
            targets: ["GraphQLGeneratorPlugin"]
        ),
        .library(
            name: "GraphQLGeneratorRuntime",
            targets: ["GraphQLGeneratorRuntime"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", from: "4.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .plugin(
            name: "GraphQLGeneratorPlugin",
            capability: .buildTool(),
            dependencies: ["GraphQLGenerator"]
        ),
        .executableTarget(
            name: "GraphQLGenerator",
            dependencies: [
                "GraphQLGeneratorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "GraphQLGeneratorCore",
            dependencies: [
                .product(name: "GraphQL", package: "GraphQL"),
            ]
        ),
        .target(
            name: "GraphQLGeneratorRuntime",
            dependencies: [
                .product(name: "GraphQL", package: "GraphQL"),
            ]
        ),
        .testTarget(
            name: "GraphQLGeneratorCoreTests",
            dependencies: [
                "GraphQLGeneratorCore",
            ]
        ),
    ]
)
