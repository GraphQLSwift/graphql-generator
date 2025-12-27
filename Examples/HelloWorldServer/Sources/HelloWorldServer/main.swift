import Foundation
import GraphQL

class Context: @unchecked Sendable {
    // User can choose structure
    var users: [String: User]
    var posts: [String: Post]

    init(
        users: [String: User],
        posts: [String: Post]
    ) {
        self.users = users
        self.posts = posts
    }
}
struct TypeMap: TypeMapProtocol {
    typealias Context = HelloWorldServer.Context
    typealias DateTime = HelloWorldServer.DateTime
    typealias User = HelloWorldServer.User
    typealias Contact = HelloWorldServer.Contact
    typealias Post = HelloWorldServer.Post
    typealias Query = HelloWorldServer.Query
    typealias Mutation = HelloWorldServer.Mutation
}
struct DateTime: Scalar { }
struct User: UserProtocol {
    // User can choose structure
    let id: String
    let name: String
    let email: String
    let age: Int?
    let role: Role?

    // Required implementations
    typealias TypeMap = HelloWorldServer.TypeMap
    func id(context: TypeMap.Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
    func name(context: TypeMap.Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return name
    }
    func email(context: TypeMap.Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return email
    }
    func age(context: TypeMap.Context, info: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return age
    }
    func role(context: TypeMap.Context, info: GraphQL.GraphQLResolveInfo) async throws -> Role? {
        return role
    }
}
struct Contact: ContactProtocol {
    // User can choose structure
    let email: String

    // Required implementations
    typealias TypeMap = HelloWorldServer.TypeMap
    func email(context: TypeMap.Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return email
    }
}
struct Post: PostProtocol {
    // User can choose structure
    let id: String
    let title: String
    let content: String
    let authorId: String

    // Required implementations
    typealias TypeMap = HelloWorldServer.TypeMap
    func id(context: TypeMap.Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
    func title(context: TypeMap.Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return title
    }
    func content(context: TypeMap.Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return content
    }
    func author(context: TypeMap.Context, info: GraphQL.GraphQLResolveInfo) async throws -> TypeMap.User {
        return context.users[authorId]!
    }
}

struct Query: QueryProtocol {
    // Required implementations
    typealias TypeMap = HelloWorldServer.TypeMap
    static func user(id: String, context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> User? {
        return context.users[id]
    }
    static func users(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> [User] {
        return .init(context.users.values)
    }
    static func post(id: String, context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> Post? {
        return context.posts[id]
    }
    static func posts(limit: Int?, context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> [Post] {
        return .init(context.posts.values)
    }
    static func userOrPost(id: String, context: TypeMap.Context, info: GraphQLResolveInfo) async throws -> (any UserOrPostUnion)? {
        return context.users[id] ?? context.posts[id]
    }
}

struct Mutation: MutationProtocol {
    // Required implementations
    typealias TypeMap = HelloWorldServer.TypeMap
    static func upsertUser(userInfo: UserInfoInput, context: TypeMap.Context, info: GraphQLResolveInfo) -> User {
        let user = User(
            id: userInfo.id,
            name: userInfo.name,
            email: userInfo.email,
            age: userInfo.age,
            role: userInfo.role
        )
        context.users[userInfo.id] = user
        return user
    }
}

let schema = try buildGraphQLSchema(typeMap: TypeMap.self)

let context = Context(
    users: ["1" : .init(id: "1", name: "John", email: "john@example.com", age: 18, role: .user)],
    posts: ["1" : .init(id: "1", title: "Foo", content: "bar", authorId: "1")]
)
print(
    try await graphql(
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
        context: context
    )
)

print(
    try await graphql(
        schema: schema,
        request: """
        mutation {
            upsertUser(userInfo: {id: "2", name: "Jane", email: "jane@example.com"}) {
                id
                name
                email
                age
                role
            }
        }
        """,
        context: context
    )
)
