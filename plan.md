# GraphQL Generator for Swift - Implementation Plan

## Project Overview

Create a Swift package plugin that generates server-side GraphQL API code from GraphQL schema files (.graphql), similar to how swift-openapi-generator works with OpenAPI specs. The generator will produce Swift code using the GraphQL Swift package for implementing GraphQL servers.

## Architecture

### Core Components

1. **Build Plugin** - Swift Package Manager build tool plugin that discovers `.graphql` files and invokes the generator
2. **Generator Executable** - CLI tool that parses GraphQL schemas and generates Swift code
3. **Generator Core** - Shared logic for parsing and code generation
4. **Runtime Library** (optional) - Helper types and utilities for generated code

### Package Structure

```
graphql-generator/
├── Package.swift
├── Plugins/
│   └── GraphQLGeneratorPlugin/         # Build plugin
│       └── plugin.swift
├── Sources/
│   ├── GraphQLGenerator/               # CLI executable
│   │   └── main.swift
│   ├── GraphQLGeneratorCore/           # Shared logic
│   │   ├── Parser/
│   │   │   ├── GraphQLSchemaParser.swift
│   │   │   └── SchemaModels.swift
│   │   ├── Generator/
│   │   │   ├── SwiftCodeEmitter.swift
│   │   │   ├── TypeGenerator.swift
│   │   │   ├── ResolverGenerator.swift
│   │   │   └── SchemaGenerator.swift
│   │   └── Config/
│   │       └── GeneratorConfig.swift
│   └── GraphQLGeneratorRuntime/        # Runtime support (optional)
│       ├── ResolverContext.swift
│       └── Helpers.swift
├── Tests/
│   └── GraphQLGeneratorTests/
│       ├── ParserTests/
│       ├── GeneratorTests/
│       └── IntegrationTests/
└── Examples/
    ├── HelloWorldServer/
    └── AdvancedSchema/
```

### Code Generation Strategy

#### Input: GraphQL Schema
```graphql
type Query {
  user(id: ID!): User
  posts(limit: Int = 10): [Post!]!
}

type User {
  id: ID!
  name: String!
  email: String!
}

type Post {
  id: ID!
  title: String!
  author: User!
}
```

#### Generated Output

**Types.swift** - Swift structs matching GraphQL types
```swift
struct User: Codable {
    let id: String
    let name: String
    let email: String
}

struct Post: Codable {
    let id: String
    let title: String
    let authorId: String
}
```

**Resolvers.swift** - Protocol for implementing business logic
```swift
protocol GraphQLResolvers {
    func user(id: String, context: ResolverContext) async throws -> User?
    func posts(limit: Int, context: ResolverContext) async throws -> [Post]
    func postAuthor(post: Post, context: ResolverContext) async throws -> User
}
```

**Schema.swift** - GraphQL schema builder using GraphQL Swift
```swift
func buildGraphQLSchema(resolvers: GraphQLResolvers) throws -> GraphQLSchema {
    // Generated GraphQLObjectType definitions with resolver callbacks
}
```

## Implementation Phases

### Phase 1: Foundation ✓ (Current Phase)

**Goal**: Set up the basic package structure and build plugin

- [x] Set up Package.swift with proper dependencies
- [x] Create build plugin structure
- [x] Implement .graphql file discovery
- [x] Create basic schema parser foundation
- [x] Set up test infrastructure

**Deliverables**:
- Working build plugin that discovers .graphql files
- Basic GraphQL SDL tokenizer and parser
- Project structure ready for code generation

### Phase 2: Schema Parsing (Weeks 1-2)

**Goal**: Complete GraphQL schema parsing with full SDL support

Tasks:
1. Implement complete SDL parser
   - Object types, fields, arguments
   - Scalar types (built-in and custom)
   - Enum types
   - Interface types
   - Union types
   - Input object types
   - Directives
2. Create AST/IR models for schema representation
3. Add validation and error reporting
4. Write comprehensive parser tests

**Deliverables**:
- Full-featured GraphQL SDL parser
- Schema representation models
- Parser test suite

### Phase 3: Type Generation (Weeks 3-4)

**Goal**: Generate Swift types from GraphQL schema

Tasks:
1. Build Swift code emitter infrastructure
2. Generate Swift structs from GraphQL object types
   - Handle field types and nullability
   - Handle lists/arrays
   - Add Codable conformance
3. Generate Swift enums from GraphQL enums
4. Handle custom scalar mappings (ID -> String, etc.)
5. Generate input types for mutations
6. Add code formatting and documentation comments

**Deliverables**:
- Types.swift generation
- Type mapping configuration
- Type generation tests

### Phase 4: Resolver Protocol Generation (Weeks 5-6)

**Goal**: Generate resolver protocols with proper signatures

Tasks:
1. Generate protocol with resolver methods
   - Query field resolvers
   - Nested field resolvers (e.g., Post.author)
   - Mutation resolvers
2. Handle async/await patterns
3. Include proper argument types
4. Add default argument values
5. Generate resolver context protocol

**Deliverables**:
- Resolvers.swift generation
- ResolverContext protocol
- Resolver generation tests

### Phase 5: Schema Builder Generation (Weeks 7-8)

**Goal**: Generate GraphQL Swift schema construction code

Tasks:
1. Generate GraphQLObjectType definitions
2. Wire up resolver callbacks to protocol methods
3. Handle field arguments and return types
4. Support interfaces and unions
5. Add directive handling
6. Generate complete schema builder function

**Deliverables**:
- Schema.swift generation
- Working end-to-end generation
- Integration tests

### Phase 6: Advanced Features (Weeks 9-10)

**Goal**: Add mutations, subscriptions, and advanced patterns

Tasks:
1. Mutation support
   - Input types
   - Mutation resolvers
2. Subscription support (if needed)
   - Async sequences
   - Subscription resolvers
3. Custom scalar configuration
4. Directive support for code generation
5. Configuration file support (graphql-generator-config.yaml)

**Deliverables**:
- Mutation/subscription support
- Config file parsing
- Advanced feature tests

### Phase 7: Runtime Library & Ergonomics (Week 11)

**Goal**: Create runtime helpers for better developer experience

Tasks:
1. ResolverContext protocol and implementations
2. Error handling utilities
3. Common patterns (pagination, connections)
4. Authentication/authorization helpers
5. Testing utilities for resolvers

**Deliverables**:
- GraphQLGeneratorRuntime module
- Helper utilities
- Documentation

### Phase 8: Examples & Documentation (Week 12)

**Goal**: Provide examples and comprehensive documentation

Tasks:
1. Hello world server example
2. CRUD API example
3. Integration with Vapor example
4. Integration with Hummingbird example
5. Write README with quickstart
6. API documentation
7. Migration guide from manual GraphQL Swift usage

**Deliverables**:
- 4+ working examples
- Complete documentation
- Tutorial content

## Configuration

**graphql-generator-config.yaml** (optional)
```yaml
# What to generate
generate:
  - types          # Swift type definitions
  - resolvers      # Resolver protocol
  - schema         # Schema builder

# Custom scalar mappings
scalarMappings:
  DateTime: Foundation.Date
  UUID: Foundation.UUID
  URL: Foundation.URL

# Additional options
options:
  accessControl: public
  includeDocumentation: true
```

## Developer Usage

### Setup

**Package.swift**:
```swift
let package = Package(
    name: "MyGraphQLAPI",
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/GraphQL", from: "2.0.0"),
        .package(url: "https://github.com/YourOrg/graphql-generator", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyGraphQLAPI",
            dependencies: [
                .product(name: "GraphQL", package: "GraphQL"),
                .product(name: "GraphQLGeneratorRuntime", package: "graphql-generator")
            ],
            plugins: [
                .plugin(name: "GraphQLGeneratorPlugin", package: "graphql-generator")
            ]
        )
    ]
)
```

### Workflow

1. Add schema file: `Sources/MyGraphQLAPI/schema.graphql`
2. (Optional) Add config: `Sources/MyGraphQLAPI/graphql-generator-config.yaml`
3. Build project → code auto-generates into build directory
4. Implement resolver protocol with business logic
5. Create schema and integrate with server framework

### Example Implementation

```swift
import GraphQL
import GraphQLGeneratorRuntime

// Implement generated protocol
struct MyResolvers: GraphQLResolvers {
    func user(id: String, context: ResolverContext) async throws -> User? {
        // Business logic here
        return await database.findUser(id: id)
    }

    func posts(limit: Int, context: ResolverContext) async throws -> [Post] {
        return await database.fetchPosts(limit: limit)
    }

    func postAuthor(post: Post, context: ResolverContext) async throws -> User {
        return await database.findUser(id: post.authorId)
    }
}

// Build schema from generated function
let resolvers = MyResolvers()
let schema = try buildGraphQLSchema(resolvers: resolvers)

// Execute queries
let result = try await graphql(schema: schema, request: "{ user(id: \"1\") { name } }")
```

## Key Design Decisions

1. **Follow swift-openapi-generator patterns**: Build plugin architecture, build-time generation
2. **Type-safe by default**: Leverage Swift's type system for compile-time safety
3. **Framework-agnostic**: Generated code works with any Swift server framework (Vapor, Hummingbird, etc.)
4. **Async/await native**: All resolver functions use modern Swift concurrency
5. **Minimal generated code**: Generate only ceremony code, developers write business logic
6. **Extensible**: Allow custom scalar mappings and directive handling
7. **Zero runtime overhead**: Generated code is straightforward, no reflection or dynamic dispatch

## Dependencies

### Required
- **GraphQL Swift** (`https://github.com/GraphQLSwift/GraphQL`): Runtime dependency for schema execution
- **Swift Argument Parser**: For CLI tool argument parsing

### Optional
- **Swift Syntax**: For more robust Swift code generation (consider for future)

## Success Criteria

1. Plugin successfully discovers and processes .graphql files
2. Parses all standard GraphQL SDL constructs
3. Generates valid, compilable Swift code
4. Generated code integrates cleanly with GraphQL Swift
5. Developer experience matches swift-openapi-generator quality
6. Comprehensive test coverage (>80%)
7. Working examples for common use cases
8. Complete documentation

## Future Enhancements

- Xcode previews for generated code
- Watch mode for development
- GraphQL client generation (queries/mutations)
- Federation support
- Performance optimizations (caching, incremental generation)
- IDE integration (syntax highlighting, autocomplete)
- Migration tools from other GraphQL Swift patterns
