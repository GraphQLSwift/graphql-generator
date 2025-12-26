import Foundation
import GraphQL

struct Context {
    // User can choose structure
    var users: [String: User]
    var posts: [String: Post]
}
struct User: UserProtocol {
    // User can choose structure
    let id: String
    let name: String
    let email: String
    let age: Int?
    let role: Role?

    // Required implementations
    typealias Context = HelloWorldServer.Context
    func id(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
    func name(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return name
    }
    func email(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return email
    }
    func age(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return age
    }
    func role(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> Role? {
        return role
    }
}
struct Post: PostProtocol {
    // User can choose structure
    let id: String
    let title: String
    let content: String
    let authorId: String

    // Required implementations
    typealias Context = HelloWorldServer.Context
    func id(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
    func title(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return title
    }
    func content(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return content
    }
    // TODO: When referencing other types, we are implicitly casting to the Resolver typealias...
    func author(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> any UserProtocol {
        return context.users[authorId]!
    }
}

struct HelloWorldResolvers: GraphQLResolvers {
    // Required implementations

    // TypeMap
    typealias Context = HelloWorldServer.Context
    typealias Post = HelloWorldServer.Post
    typealias User = HelloWorldServer.User

    // Query
    func user(id: String, context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> User? {
        return context.users[id]
    }
    func users(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> [User] {
        return .init(context.users.values)
    }
    func post(id: String, context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> Post? {
        return context.posts[id]
    }
    func posts(limit: Int?, context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> [Post] {
        return .init(context.posts.values)
    }
}

let resolvers = HelloWorldResolvers()
let schema = try buildGraphQLSchema(resolvers: resolvers)

let queryResponse = try await graphql(
    schema: schema,
    request: """
    {
        posts {
            id
            title
            content
            author {
                id
                name
                email
                age
                role
            }
        }
    }
    """,
    context: HelloWorldResolvers.Context(
        users: ["1" : .init(id: "1", name: "John", email: "john@example.com", age: 18, role: .user)],
        posts: ["1" : .init(id: "1", title: "Foo", content: "bar", authorId: "1")]
    )
)

print(queryResponse)
