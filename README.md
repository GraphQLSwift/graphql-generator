# GraphQL Generator for Swift

A Swift package plugin that generates server-side GraphQL API code from GraphQL schema files, inspired by [GraphQL Tools' makeExecutableSchema](https://the-guild.dev/graphql/tools/docs/generate-schema).

This tool uses [GraphQL Swift](https://github.com/GraphQLSwift/GraphQL) to generate type-safe Swift code and protocol stubs from your GraphQL schema files, eliminating boilerplate while maintaining full control over your business logic.

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
  id: ID!
  name: String!
  email: String!
}

type Query {
  user(id: ID!): User
  users: [User!]!
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

Create any scalar types (with names matching GraphQL), and conform them to `Scalar`:

```swift
struct DateTime: Scalar {}
```

Create a resolvers struct with the required typealiases:
```swift
struct Resolvers: ResolversProtocol {
    typealias Query = ExamplePackage.Query
    typealias Mutation = ExamplePackage.Mutation
}
```

As you build the `Query` and `Mutation` types and their resolution logic, you will be forced to define a concrete type for every reachable GraphQL result, according to its generated protocol.
Here's a small example of a schema that allows querying for the current user, who is only identified by an email address:

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
    let email: String

    // This is required by `UserProtocol`, and used by GraphQL field resolution.
    func email(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        // You can implement resolution logic however you like.
        return email
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

## Development Roadmap

1. Default values: Default values are currently ignored
2. Directives: Directives are currently not supported
3. Subscription: Subscription definitions are currently ignored
4. Improved testing: Generator tests should cover much more of the functionality
5. Additional examples: Ideally large ones that cover significant GraphQL features
6. Executable Schema: To work around the immutability of some Schema components, we generate Swift code to fully recreate the defined schema. Instead, we could just add resolver logic to the schema parsed from the `.graphql` file SDL.

## Contributing

This project is in active development. Contributions are welcome!
