import Foundation
import GraphQL
import GraphQLGeneratorRuntime

// Must be created by user and named `GraphQLContext`.
public class GraphQLContext: @unchecked Sendable {
    // User can choose structure
    var users: [String: User]
    var posts: [String: Post]
    var onTriggerWatch: () -> Void = {}

    init(
        users: [String: User],
        posts: [String: Post]
    ) {
        self.users = users
        self.posts = posts
    }

    func triggerWatch() {
        onTriggerWatch()
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
        email = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        try email.encode(to: encoder)
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
struct Resolvers: GraphQLGenerated.Resolvers {
    typealias Query = HelloWorldServer.Query
    typealias Mutation = HelloWorldServer.Mutation
    typealias Subscription = HelloWorldServer.Subscription
}

struct User: GraphQLGenerated.User {
    // User can choose structure
    let id: String
    let name: String
    let email: String
    let age: Int?
    let role: GraphQLGenerated.Role?

    // Required implementations
    func id(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }

    func name(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return name
    }

    func email(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> EmailAddress {
        return EmailAddress(email: email)
    }

    func age(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return age
    }

    func role(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> GraphQLGenerated.Role? {
        return role
    }
}

struct Contact: GraphQLGenerated.Contact {
    // User can choose structure
    let email: String

    // Required implementations
    func email(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> EmailAddress {
        return EmailAddress(email: email)
    }
}

struct Post: GraphQLGenerated.Post {
    // User can choose structure
    let id: String
    let title: String
    let content: String
    let authorId: String

    // Required implementations
    func id(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }

    func title(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return title
    }

    func content(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return content
    }

    func author(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> any GraphQLGenerated.User {
        return context.users[authorId]!
    }
}

struct Query: GraphQLGenerated.Query {
    // Required implementations
    static func user(id: String, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.User)? {
        return context.users[id]
    }

    static func users(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.User] {
        return context.users.values.map { $0 as any GraphQLGenerated.User }
    }

    static func post(id: String, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Post)? {
        return context.posts[id]
    }

    static func posts(limit _: Int?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Post] {
        return context.posts.values.map { $0 as any GraphQLGenerated.Post }
    }

    static func userOrPost(id: String, context: GraphQLContext, info _: GraphQLResolveInfo) async throws -> (any GraphQLGenerated.UserOrPost)? {
        return context.users[id] ?? context.posts[id]
    }
}

struct Mutation: GraphQLGenerated.Mutation {
    // Required implementations
    static func upsertUser(userInfo: GraphQLGenerated.UserInfo, context: GraphQLContext, info _: GraphQLResolveInfo) -> any GraphQLGenerated.User {
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

struct Subscription: GraphQLGenerated.Subscription {
    // Required implementations
    static func watchUser(id: String, context: GraphQLContext, info _: GraphQLResolveInfo) async throws -> AnyAsyncSequence<(any GraphQLGenerated.User)?> {
        return AsyncStream<(any GraphQLGenerated.User)?> { continuation in
            context.onTriggerWatch = { [weak context] in
                continuation.yield(context?.users[id])
            }
        }.any()
    }
}
