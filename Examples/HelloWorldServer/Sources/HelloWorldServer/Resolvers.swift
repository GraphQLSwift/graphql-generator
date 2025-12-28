import Foundation
import GraphQL
import GraphQLGeneratorRuntime

// Must be created by user and named `Context`.
public class Context: @unchecked Sendable {
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
// Scalars must be represented by a Swift type of the same name, conforming to the Scalar protocol
public struct EmailAddress: Scalar {
    let email: String

    init(email: String) {
        self.email = email
    }

    // Codability conformance. Required for usage in InputObject
    public init(from decoder: any Decoder) throws {
        self.email = try decoder.singleValueContainer().decode(String.self)
    }
    public func encode(to encoder: any Encoder) throws {
        try self.email.encode(to: encoder)
    }

    // Scalar conformance. Not necessary, but default methods are very inefficient.
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

// Now create types that conform to the expected protocols
struct Resolvers: ResolversProtocol {
    typealias Query = HelloWorldServer.Query
    typealias Mutation = HelloWorldServer.Mutation
}
struct User: UserProtocol {
    // User can choose structure
    let id: String
    let name: String
    let email: String
    let age: Int?
    let role: Role?

    // Required implementations
    func id(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
    func name(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return name
    }
    func email(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> EmailAddress {
        return EmailAddress(email: email)
    }
    func age(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return age
    }
    func role(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> Role? {
        return role
    }
}
struct Contact: ContactProtocol {
    // User can choose structure
    let email: String

    // Required implementations
    func email(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> EmailAddress {
        return EmailAddress(email: email)
    }
}
struct Post: PostProtocol {
    // User can choose structure
    let id: String
    let title: String
    let content: String
    let authorId: String

    // Required implementations
    func id(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
    func title(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return title
    }
    func content(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> String {
        return content
    }
    func author(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> any UserProtocol {
        return context.users[authorId]!
    }
}

struct Query: QueryProtocol {
    // Required implementations
    static func user(id: String, context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> (any UserProtocol)? {
        return context.users[id]
    }
    static func users(context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> [any UserProtocol] {
        return context.users.values.map { $0 as any UserProtocol }
    }
    static func post(id: String, context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> (any PostProtocol)? {
        return context.posts[id]
    }
    static func posts(limit: Int?, context: Context, info: GraphQL.GraphQLResolveInfo) async throws -> [any PostProtocol] {
        return context.posts.values.map { $0 as any PostProtocol }
    }
    static func userOrPost(id: String, context: Context, info: GraphQLResolveInfo) async throws -> (any UserOrPostUnion)? {
        return context.users[id] ?? context.posts[id]
    }
}

struct Mutation: MutationProtocol {
    // Required implementations
    static func upsertUser(userInfo: UserInfoInput, context: Context, info: GraphQLResolveInfo) -> any UserProtocol {
        let user = User(
            id: userInfo.id,
            name: userInfo.name,
            email: userInfo.email.email,
            age: userInfo.age,
            role: userInfo.role
        )
        context.users[userInfo.id] = user
        return user
    }
}
