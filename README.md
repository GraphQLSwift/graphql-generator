# GraphQL Generator for Swift

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FGraphQLSwift%2Fgraphql-generator%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/GraphQLSwift/graphql-generator)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FGraphQLSwift%2Fgraphql-generator%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/GraphQLSwift/graphql-generator)

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

Take a look at the example projects to see real, fully featured implementations:
- [HelloWorldServer](Examples/HelloWorldServer) - Demonstrates all GraphQL type mappings with a comprehensive schema
- [StarWars](Examples/StarWars) - A production-like example using the SWAPI with DataLoader for caching

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

As you build the `Query`, `Mutation`, and `Subscription` types and their resolution logic, you will be forced to define a concrete type for every reachable GraphQL type, according to its generated protocol:

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

## Design Philosophy

This generator is designed with the following guiding principles:

- **Protocol-based flexibility**: GraphQL types are generated as Swift protocols (except where concrete types are needed), allowing you to implement backing types however you want - structs, actors, classes, or any combination.
- **Explicit over implicit**: No default resolvers based on reflection. While more verbose, this provides better performance and clearer schema evolution handling.
- **Type safety**: Leverage Swift's type system to ensure compile-time conformance with your GraphQL schema.
- **Namespace isolation**: All generated types (except `GraphQLContext` and custom scalars) are namespaced inside `GraphQLGenerated` to avoid polluting your package's type namespace.

## GraphQL to Swift Type Mappings

This section describes how each GraphQL type is converted to Swift code, with concrete examples from the [HelloWorldServer](Examples/HelloWorldServer) example. Note that all generated types are namespaced inside `GraphQLGenerated`

### Root Types (Query, Mutation, Subscription)

GraphQL root types are generated as Swift protocols with static methods for each field.

**GraphQL:**
```graphql
type Query {
  user(id: ID!): User
  users: [User!]!
}

type Mutation {
  upsertUser(userInfo: UserInfo!): User!
}

type Subscription {
  watchUser(id: ID!): User
}
```

**Generated Swift:**
```swift
protocol Query: Sendable {
    static func user(id: String, context: GraphQLContext, info: GraphQLResolveInfo) async throws -> (any User)?
    static func users(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> [any User]
}

protocol Mutation: Sendable {
    static func upsertUser(userInfo: UserInfo, context: GraphQLContext, info: GraphQLResolveInfo) async throws -> any User
}

protocol Subscription: Sendable {
    static func watchUser(id: String, context: GraphQLContext, info: GraphQLResolveInfo) async throws -> AnyAsyncSequence<(any User)?>
}
```

### Object Types

GraphQL object types are generated as Swift protocols with instance methods for each field. This allows for flexible implementations - you can use structs, actors, classes, or any other type that conforms to the protocol.

**GraphQL:**
```graphql
type User {
  id: ID!
  name: String!
  email: EmailAddress!
  age: Int
}
```

**Generated Swift:**
```swift
protocol User: Sendable {
    func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String
    func name(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String
    func email(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> GraphQLScalars.EmailAddress
    func age(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> Int?
}
```

**Example Implementation:**
```swift
struct User: GraphQLGenerated.User {
    let id: String
    let name: String
    let emailAddress: String
    let age: Int?

    func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
        return id
    }
    func name(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
        return name
    }
    func email(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> GraphQLScalars.EmailAddress {
        return .init(email: emailAddress)
    }
    func age(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> Int? {
        return age
    }
}
```

Because these are protocols, you can have multiple implementations of the same GraphQL type (useful for testing or different data sources):

```swift
struct MockUser: GraphQLGenerated.User {
    func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String { "test-id" }
    func name(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String { "Test User" }
    func email(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> GraphQLScalars.EmailAddress {
        .init(email: "test@example.com")
    }
    func age(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> Int? { nil }
}
```

### Interface Types

GraphQL interfaces are generated as Swift protocols with required methods for each field. Types implementing the interface will have their protocol marked as conforming to the interface protocol.

**GraphQL:**
```graphql
interface HasEmail {
  email: EmailAddress!
}

type User implements HasEmail {
  id: ID!
  name: String!
  email: EmailAddress!
}
```

**Generated Swift:**
```swift
protocol HasEmail: Sendable {
    func email(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> GraphQLScalars.EmailAddress
}

protocol User: HasEmail, Sendable {
    func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String
    func name(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String
    func email(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> GraphQLScalars.EmailAddress
}
```

### Union Types

GraphQL union types are generated as Swift marker protocols with no required properties or methods. Union member types have their protocols marked as conforming to the union protocol.

**GraphQL:**
```graphql
union UserOrPost = User | Post

type User {
  id: ID!
  name: String!
}

type Post {
  id: ID!
  title: String!
}
```

**Generated Swift:**
```swift
protocol UserOrPost: Sendable {}

protocol User: UserOrPost, Sendable {
    func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String
    func name(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String
}

protocol Post: UserOrPost, Sendable {
    func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String
    func title(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String
}
```

### Input Object Types

GraphQL input object types are generated as concrete Swift structs with properties for each field. These are `Codable` and `Sendable`.

**GraphQL:**
```graphql
input UserInfo {
  id: ID!
  name: String!
  email: EmailAddress!
  age: Int
  role: Role = USER
}
```

**Generated Swift:**
```swift
struct UserInfo: Codable, Sendable {
    let id: String
    let name: String
    let email: GraphQLScalars.EmailAddress
    let age: Int?
    let role: Role?
}
```

### Enum Types

GraphQL enum types are generated as concrete Swift enums with raw `String` values. Each GraphQL enum case becomes a Swift enum case with its raw value matching the GraphQL case name.

**GraphQL:**
```graphql
enum Role {
  ADMIN
  USER
  GUEST
}
```

**Generated Swift:**
```swift
enum Role: String, Codable, Sendable {
    case admin = "ADMIN"
    case user = "USER"
    case guest = "GUEST"
}
```

These generated enums can be used directly in your code without any additional implementation.

### Scalar Types

GraphQL scalar types are not generated by the plugin. Instead, they are referenced as `GraphQLScalars.<name>`, and you must define the type and conform it to `GraphQLScalar`.

**GraphQL:**
```graphql
scalar EmailAddress

type User {
  email: EmailAddress!
}
```

**Required Implementation:**
```swift
extension GraphQLScalars {
    struct EmailAddress: GraphQLScalar {
        let email: String

        init(email: String) {
            self.email = email
        }

        // Codable conformance - for Swift serialization
        init(from decoder: any Decoder) throws {
            self.email = try decoder.singleValueContainer().decode(String.self)
        }
        func encode(to encoder: any Encoder) throws {
            try self.email.encode(to: encoder)
        }

        // GraphQLScalar conformance - for GraphQL serialization
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

Ensure that your `Codable` and `GraphQLScalar` conformances agree on the same representation format.
