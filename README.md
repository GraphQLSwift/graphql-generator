# GraphQL Generator for Swift

A Swift package plugin that generates server-side GraphQL API code from GraphQL schema files, inspired by [swift-openapi-generator](https://github.com/apple/swift-openapi-generator).

This tool uses [GraphQL Swift](https://github.com/GraphQLSwift/GraphQL) to generate type-safe Swift code from your GraphQL schemas, eliminating boilerplate while maintaining full control over your business logic.

## Status

🚧 **Phase 1 Complete** - Foundation is in place with basic code generation

Currently implemented:
- ✅ Build plugin for SPM integration
- ✅ GraphQL schema parsing using GraphQL Swift's `buildSchema`
- ✅ Type generation (Swift structs from GraphQL types)
- ✅ Resolver protocol generation
- ✅ Basic runtime library with ResolverContext
- ✅ CLI tool for code generation

Still in development (see [plan.md](plan.md)):
- ⏳ Complete schema builder generation (Phase 5)
- ⏳ Mutations and subscriptions support
- ⏳ Custom scalar mappings
- ⏳ Configuration file support
- ⏳ Complete test coverage
- ⏳ Working end-to-end examples

## Features

- **Build-time code generation**: Code is generated at build time and never needs to be committed
- **Type-safe**: Leverages Swift's type system for compile-time safety
- **Framework-agnostic**: Generated code works with any Swift server framework (Vapor, Hummingbird, etc.)
- **Modern Swift**: Uses async/await for all resolver functions
- **Minimal boilerplate**: Generates only ceremony code - you write the business logic

## Requirements

- Swift 6.2+
- macOS 13+, iOS 16+, tvOS 16+, or watchOS 9+
- GraphQL Swift 4.0+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/GraphQLSwift/GraphQL.git", from: "4.0.0"),
    .package(url: "https://github.com/YourOrg/graphql-generator", from: "1.0.0")
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
- `Types.swift` - Swift structs for your GraphQL types
- `Resolvers.swift` - Protocol defining resolver methods
- `Schema.swift` - Schema builder (coming in Phase 5)

### 3. Implement the Resolver Protocol

```swift
import GraphQL
import GraphQLGeneratorRuntime

struct MyResolvers: GraphQLResolvers {
    func user(id: String, context: ResolverContext) async throws -> User? {
        // Your business logic here
        return User(id: id, name: "John Doe", email: "john@example.com")
    }

    func users(context: ResolverContext) async throws -> [User] {
        // Your business logic here
        return [
            User(id: "1", name: "Alice", email: "alice@example.com"),
            User(id: "2", name: "Bob", email: "bob@example.com"),
        ]
    }
}
```

### 4. Execute GraphQL Queries

```swift
import GraphQL

// Create resolvers
let resolvers = MyResolvers()

// Build schema (Phase 5 - not yet implemented)
// let schema = try buildGraphQLSchema(resolvers: resolvers)

// Execute a query
// let result = try await graphql(schema: schema, request: "{ users { name email } }")
// print(result)
```

## Project Structure

```
graphql-generator/
├── Package.swift
├── README.md
├── plan.md                           # Detailed implementation plan
├── Plugins/
│   └── GraphQLGeneratorPlugin.swift  # SPM build plugin
├── Sources/
│   ├── GraphQLGenerator/             # CLI executable
│   ├── GraphQLGeneratorCore/         # Parsing and generation logic
│   │   ├── Parser/
│   │   │   └── SchemaParser.swift
│   │   └── Generator/
│   │       ├── CodeGenerator.swift
│   │       ├── TypeGenerator.swift
│   │       ├── ResolverGenerator.swift
│   │       └── SchemaGenerator.swift
│   └── GraphQLGeneratorRuntime/      # Runtime support library
│       └── ResolverContext.swift
├── Tests/
│   └── GraphQLGeneratorTests/
└── Examples/
    └── HelloWorldServer/
```

## Generated Code Examples

### From this GraphQL schema:

```graphql
type User {
  id: ID!
  name: String!
  email: String!
}
```

### Generates this Swift code:

```swift
// Types.swift
public struct User: Codable {
    public let id: String
    public let name: String
    public let email: String

    public init(
        id: String,
        name: String,
        email: String
    ) {
        self.id = id
        self.name = name
        self.email = email
    }
}

// Resolvers.swift
public protocol GraphQLResolvers {
    func user(id: String, context: ResolverContext) async throws -> User?
    func users(context: ResolverContext) async throws -> [User]
}
```

## Development Roadmap

See [plan.md](plan.md) for the complete implementation plan across 8 phases:

- **Phase 1: Foundation** ✅ - Basic infrastructure and plugin setup
- **Phase 2: Schema Parsing** - Complete SDL parsing (in progress)
- **Phase 3: Type Generation** - Full type generation with all GraphQL constructs
- **Phase 4: Resolver Generation** - Complete resolver protocol generation
- **Phase 5: Schema Builder** - Generate executable GraphQL schema
- **Phase 6: Advanced Features** - Mutations, subscriptions, custom scalars
- **Phase 7: Runtime & Ergonomics** - Helper utilities and patterns
- **Phase 8: Examples & Documentation** - Complete examples and guides

## Contributing

This project is in active development. Contributions are welcome!

## License

TBD

## Inspiration

This project is inspired by:
- [swift-openapi-generator](https://github.com/apple/swift-openapi-generator) - Build plugin architecture
- [GraphQL Swift](https://github.com/GraphQLSwift/GraphQL) - Runtime GraphQL implementation

## Related Projects

- [GraphQL Swift](https://github.com/GraphQLSwift/GraphQL) - The Swift GraphQL implementation
- [Vapor](https://github.com/vapor/vapor) - Server-side Swift framework
- [Hummingbird](https://github.com/hummingbird-project/hummingbird) - Lightweight server framework
