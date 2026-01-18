***WARNING***: This package is in beta. It's API is still evolving and is subject to breaking changes.

# GraphQL Generator for Swift

This is a Swift package plugin that generates server-side GraphQL API code from GraphQL schema files, inspired by [GraphQL Tools' makeExecutableSchema](https://the-guild.dev/graphql/tools/docs/generate-schema) and [Swift's OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

## Features

- **Data-driven**: Guarantee conformance with the declared GraphQL spec
- **Type-safe**: Leverages Swift's type system for compile-time safety
- **Flexible implementation**: Makes no assumptions about backing data types other than GraphQL type conformance
- **Minimal boilerplate**: Generates all the piping between Swift and GraphQL - you just write the resolvers

## Installation

Add the package to your `Package.swift`. Be sure to add the `GraphQLGeneratorRuntime` dependency to your package, and add the `GraphQLGeneratorPlugin` to the plugins section:

```swift
dependencies: [
    .package(url: "https://github.com/GraphQLSwift/GraphQL.git", from: "4.1.0"),
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

*Protip*: Take a look at the projects in the `Examples` directory to see real, fully featured examples.

### 1. Create a GraphQL Schema

Create a `.graphql` file in your target's `Sources` directory:

**Sources/ExamplePackage/schema.graphql**:
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

When you build, the plugin will automatically generate Swift code. If you want, you can view it in the `.build/plugins/outputs` directory:
- `BuildGraphQLSchema.swift` - Defines `buildGraphQLSchema` function that builds an executable schema.
- `GraphQLRawSDL.swift` - The `graphQLRawSDL` global property, which is a Swift string literal of the input schema. This is used at runtime to parse the schema.
- `GraphQLTypes.swift` - Swift protocols and types for your GraphQL types. These are all namespaced within `GraphQLGenerated`.

### 3. Create required types

Create a type named `GraphQLContext`:

```swift
actor GraphQLContext {
    // Add any features you like
}
```

If your schema has any custom scalar types, you must create them manually in the `GraphQLScalars` namespace. See the `Scalars` section below for details.

Create a struct that conforms to `GraphQLGenerated.Resolvers` by defining the required typealiases:
```swift
struct Resolvers: GraphQLGenerated.Resolvers {
    typealias Query = ExamplePackage.Query
    typealias Mutation = ExamplePackage.Mutation
    typealias Subscription = ExamplePackage.Subscription
}
```

As you build the `Query`, `Mutation`, and `Subscription` types and their resolution logic, you will be forced to define a concrete type for every reachable GraphQL result, according to its generated protocol:

```swift
struct Query: GraphQLGenerated.Query {
    // This is required by `GraphQLGenerated.Query`, and used by GraphQL query resolution
    static func user(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> (any GraphQLGenerated.User)? {
        // You can implement resolution logic however you like
        return context.user
    }
}

struct User: GraphQLGenerated.User {
    // You can define the type internals however you like
    let name: String
    let email: String

    // These are required by `GraphQLGenerated.User`, and used by GraphQL field resolution
    func name(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
        return name
    }
    func email(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> GraphQLScalars.EmailAddress {
        // You can implement resolution logic however you like
        return .init(email: self.email)
    }
}
```

Let the protocol conformance guide you on what resolver methods your types must define, and keep going until everything compiles.

### 4. Execute GraphQL Queries

You're done! You can now instantiate your GraphQL schema by calling `buildGraphQLSchema`, and run queries against it:

```swift
import GraphQL

// Build the auto-generated schema
let schema = try buildGraphQLSchema(resolvers: Resolvers.self)

// Execute a query against it
let result = try await graphql(schema: schema, request: "{ users { name email } }", context: GraphQLContext())
print(result)
```

## Design

All generated types other than `GraphQLContext` and scalar types are namespaced inside of `GraphQLGenerated` to minimize polluting the inheriting package's type namespace.

### Root Types
GraphQL root types (Query, Mutation, and Subscription) are modeled as Swift protocols with static method for each GraphQL field. The user must implement these types and provide them to the `buildGraphQLSchema` function via the `Resolvers` typealiases.

### Object Types
GraphQL object types are modeled as Swift protocols with a method for each GraphQL field. This allows the Swift implementation to be very flexible. Internally, GraphQL passes result objects directly through to subsequent resolvers. By only specifying the interface, we allow the backing types to be incredibly dynamic - they can be simple codable structs or complex stateful actors, reference or values types, or any other type configuration, as long as they conform to the generated protocol.

Furthermore, by only referencing protocols, we can have multiple Swift types back a particular GraphQL type, and can easily mock portions of the schema. As an example, consider the following schema snippet:
```graphql
type A {
  foo: String
}
```

This would result in the following generated protocol:
```swift
protocol A: Sendable {
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

This package does not provide default resolvers based on reflection of the type's properties. While this can cause the conformance code to be more verbose, it was chosen to improve performance and better handle schema evolution.

### Interface Types
GraphQL interfaces are modeled as a Swift protocol with required methods for each GraphQL field. Implementing objects and interfaces are marked as requiring conformance to the interface protocol.

### Union Types
GraphQL union types are modeled as a Swift marker protocol, with no required properties or functions. The members of the union have their generated Swift protocol marked as conforming to the to the union protocol.

### Input Object Types
GraphQL input object types are modeled as a concrete Swift struct with a property for each of the GraphQL fields.

### Enum Types
GraphQL enum types are modeled as a concrete Swift enum with a string case for each the GraphQL cases.

### Scalar Types
GraphQL scalar types are not modeled by the generator. They are simply referenced as `GraphQLScalars.<name>`, and you are expected to define the type and conform it to `GraphQLScalar`. Since GraphQL uses a different serialization system than Swift, you should be sure that the type's conformance to Swift's `Codable` and GraphQL's `GraphQLScalar` agree on a representation. Here is an example that represents an email address as a raw String:

```swift
extension GraphQLScalars {
    struct EmailAddress: GraphQLScalar {
        let email: String

        init(email: String) {
            self.email = email
        }

        // Codability conformance. Represent simply as `email` string.
        init(from decoder: any Decoder) throws {
            self.email = try decoder.singleValueContainer().decode(String.self)
        }
        func encode(to encoder: any Encoder) throws {
            try self.email.encode(to: encoder)
        }

        // Scalar conformance. Parse & serialize simply as `email` string.
        static func serialize(this: Self) throws -> Map {
            return .string(this.email)
        }
        static func parseValue(map: Map) throws -> Map {
            switch map {
            case .string:
                return map
            default:
                throw GraphQLError(message: "EmailAddress cannot represent non-string value: \(map)")
            }
        }
        static func parseLiteral(value: any Value) throws -> Map {
            guard let ast = value as? StringValue else {
                throw GraphQLError(
                    message: "EmailAddress cannot represent non-string value: \(print(ast: value))",
                    nodes: [value]
                )
            }
            return .string(ast.value)
        }
    }
}
```

## Development Roadmap

1. Add Directive support
2. Add configuration to reference different `.graphql` source file locations.
