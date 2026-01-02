***WARNING***: This package is in beta. It's API is still evolving and is subject to breaking changes.

# GraphQL Generator for Swift

A Swift package plugin that generates server-side GraphQL API code from GraphQL schema files, inspired by [GraphQL Tools' makeExecutableSchema](https://the-guild.dev/graphql/tools/docs/generate-schema) and [Swift's OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

## Features

- **Build-time code generation**: Code is generated at build time and doesn't need to be committed
- **Type-safe**: Leverages Swift's type system for compile-time safety
- **Minimal boilerplate**: Generates all GraphQL definition code - you write the business logic

## Installation

Add the package to your `Package.swift`. Be sure to add the `GraphQLGeneratorRuntime` dependency to your package, and add the `GraphQLGeneratorPlugin` to the plugins section:

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

When you build, the plugin will automatically generate Swift code that you can view in the `.build/plugins/outputs` directory:
- `BuildGraphQLSchema.swift` - Defines `buildGraphQLSchema` function that builds an executable schema.
- `GraphQLRawSDL.swift` - The `graphQLRawSDL` global property, which is a Swift string literal of the input schema. This is internally used at runtime to parse the schema.
- `GraphQLTypes.swift` - Swift protocols and types for your GraphQL types. These are all namespaced within `GraphQLGenerated`.

### 3. Create required types

Create a type named `GraphQLContext`:

```swift
public actor GraphQLContext {
    // Add any features you like
}
```

Create any scalar types (with names matching GraphQL), and conform them to `Scalar`. See the `Scalars` usage section below for details.

Create a resolvers struct with the required typealiases:
```swift
struct Resolvers: ResolversProtocol {
    typealias Query = ExamplePackage.Query
    typealias Mutation = ExamplePackage.Mutation
    typealias Subscription = ExamplePackage.Subscription
}
```

As you build the `Query`, `Mutation`, and `Subscription` types and their resolution logic, you will be forced to define a concrete type for every reachable GraphQL result, according to its generated protocol:

```swift
struct Query: GraphQLGenerated.Query {
    // This is required by `GraphQLGenerated.Query`, and used by GraphQL query resolution.
    static func user(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> (any UserProtocol)? {
        // You can implement resolution logic however you like.
        return context.user
    }
}

struct User: GraphQLGenerated.User {
    // You can define the type internals however you like
    let name: String
    let email: String

    // These are required by `GraphQLGenerated.User`, and used by GraphQL field resolution.
    func name(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
        return name
    }
    func email(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> EmailAddress {
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

## Design

All generated types other than `GraphQLContext` and scalar types are namespaced inside of `GraphQLGenerated` to minimize polluting the inheriting package's type namespace.

### Root Types
Root types (Query, Mutation, and Subscription) are modeled as Swift protocols with static method requirements for each field. The user must implement these types and provide them to the `buildGraphQLSchema` function.

### Object Types
Object types are modeled as Swift protocols with instance method requirements for each field. This is to enable maximum implementation flexibility. Internally, GraphQL passes result objects directly through to subsequent resolvers. By only specifying the interface, we allow the backing types to be incredibly dynamic - they can be simple codable structs or complex stateful actors, reference or values types, or any other type configuration.

Furthermore, by only referencing protocols, we can have multiple Swift types back a particular GraphQL type, and can easily mock portions of the schema. As an example, consider the following schema snippet:
```graphql
type A {
  foo: String
}
```

This would result in the following protocol:
```swift
public protocol A: Sendable {
    func foo(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String
}
```

You could define two conforming types. To use `ATest` in tests, simply return it from the relevant resolvers.
```swift
struct A: GraphQLGenerated.A {
    let foo: String
    func foo(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
        return foo
    }
}
struct ATest: GraphQLGenerated.A {
    func foo(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
        return "test"
    }
}
```

Also, by not providing default resolvers based on reflection of the type's properties, we improve performance and setup the inheriting package up well for evolving the schema over time.

### Interface Types
Interfaces are modeled as a protocol with required methods for each relevant field. Implementing objects and interfaces are marked as requiring conformance to the interface protocol.

### Union Types
Union types are modeled as a marker protocol, with no required properties or functions. Related objects are marked as requiring conformance to the union protocol.

### Input Object Types
Input object types are modeled as a deterministic Codable struct with the declared fields. If more complex objects must be created from the codable struct, this can be done in the resolver itself, since input objects only relevant for their associated resolver (they are not passed to downstream resolvers).

### Enum Types
Enum types are modeled as a deterministic String enum with values matching the declared fields and associated representations. If you need different values or more complex implementations, simply convert to/from a different representation inside your resolvers.

### Scalar Types
Scalar types are not modeled by the generator. They are simply referenced using the Scalar's name, and you are expected to implement the required type. Since GraphQL uses a different serialization system than Swift, you must conform the type to Swift's `Codable` and GraphQL's `Scalar`, and have them agree on a representation.

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

1. Directives: Directives are currently not supported

## Contributing

This project is in active development. Contributions are welcome!
