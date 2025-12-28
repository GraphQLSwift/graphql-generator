# GraphQL Generator for Swift

A Swift package plugin that generates server-side GraphQL API code from GraphQL schema files, inspired by [GraphQL Tools' makeExecutableSchema](https://the-guild.dev/graphql/tools/docs/generate-schema).

This tool uses [GraphQL Swift](https://github.com/GraphQLSwift/GraphQL) to generate type-safe Swift code and protocol stubs from your GraphQL schema files, eliminating boilerplate while allowing you full control over your business logic.

## Features

- **Build-time code generation**: Code is generated at build time and never needs to be committed
- **Type-safe**: Leverages Swift's type system for compile-time safety
- **Framework-agnostic**: Generated code works with any Swift server framework (Vapor, Hummingbird, etc.)
- **Modern Swift**: Uses async/await for all resolver functions
- **Minimal boilerplate**: Generates only ceremony code - you write the business logic

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/GraphQLSwift/GraphQL.git", from: "4.0.0"),
    .package(url: "https://github.com/GraphQLSwift/graphql-generator", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "GraphQL", package: "GraphQL"),
            .product(name: "GraphQLGeneratorRuntime", package: "graphql-generator"),
        ],
        plugins: [
            .plugin(name: "GraphQLGeneratorPlugin", package: "graphql-generator")
        ]
    )
]
```

## Quick Start

### 1. Create a GraphQL Schema

Create a `.graphql` file in your target's `Sources` directory:

**Sources/YourTarget/schema.graphql**:
```graphql
type User {
  name: String!
  email: EmailAddress!
}

type Query {
  user: User
}
```

### 2. Build Your Project

When you build, the plugin will automatically generate Swift code:
- `Types.swift` - Swift protocols for your GraphQL types
- `Schema.swift` - Schema

### 3. Create required types

Create a type named `Context`:

```swift
public actor Context {
    // Add any features you like
}
```

Create any scalar types (with names matching GraphQL), and conform them to `Scalar`. See the `Scalars` usage section below for details.

Create a resolvers struct with the required typealiases:
```swift
struct Resolvers: ResolversProtocol {
    typealias Query = ExamplePackage.Query
    typealias Mutation = ExamplePackage.Mutation
}
```

As you build the `Query` and `Mutation` types and their resolution logic, you will be forced to define a concrete type for every reachable GraphQL result, according to its generated protocol:

```swift
struct Query: QueryProtocol {
    // This is required by `QueryProtocol`, and used by GraphQL query resolution.
    static func user(context: Context, info: GraphQLResolveInfo) async throws -> (any UserProtocol)? {
        // You can implement resolution logic however you like.
        return context.user
    }
}

struct User: UserProtocol {
    // You can define the type internals however you like
    let name: String
    let email: String

    // These are required by `UserProtocol`, and used by GraphQL field resolution.
    func name(context: Context, info: GraphQLResolveInfo) async throws -> String {
        return name
    }
    func email(context: Context, info: GraphQLResolveInfo) async throws -> EmailAddress {
        // You can implement resolution logic however you like.
        return EmailAddress(email: self.email)
    }
}
```

### 4. Execute GraphQL Queries

```swift
import GraphQL

let schema = try buildGraphQLSchema(resolvers: Resolvers.self)

// Execute a query
let result = try await graphql(schema: schema, request: "{ users { name email } }")
print(result)
```

## Detailed Usage

### Scalars

Scalar types must be provided for each GraphQL scalar. Since GraphQL uses a different serialization system than Swift, you must conform the type to Swift's `Codable` and GraphQL's `Scalar`, and have them agree on a representation.

Below is an example that represents a scalar struct as a raw String:

```swift
public struct EmailAddress: Scalar {
    let email: String

    init(email: String) {
        self.email = email
    }

    // Codability conformance. Represent simply as `email` string.
    public init(from decoder: any Decoder) throws {
        self.email = try decoder.singleValueContainer().decode(String.self)
    }
    public func encode(to encoder: any Encoder) throws {
        try self.email.encode(to: encoder)
    }

    // Scalar conformance. Parse & serialize simply as `email` string.
    public static func serialize(this: Self) throws -> Map {
        return .string(this.email)
    }
    public static func parseValue(map: Map) throws -> Map {
        switch map {
        case .string:
            return map
        default:
            throw GraphQLError(message: "EmailAddress cannot represent non-string value: \(map)")
        }
    }
    public static func parseLiteral(value: any Value) throws -> Map {
        guard let ast = value as? StringValue else {
            throw GraphQLError(
                message: "EmailAddress cannot represent non-string value: \(print(ast: value))",
                nodes: [value]
            )
        }
        return .string(ast.value)
    }
}
```

## Development Roadmap

1. Default values: Default values are currently ignored
2. Directives: Directives are currently not supported
3. Subscription: Subscription definitions are currently ignored
4. Improved testing: Generator tests should cover much more of the functionality
5. Additional examples: Ideally large ones that cover significant GraphQL features
6. Executable Schema: To work around the immutability of some Schema components, we generate Swift code to fully recreate the defined schema. Instead, we could just add resolver logic to the schema parsed from the `.graphql` file SDL.

## Contributing

This project is in active development. Contributions are welcome!
