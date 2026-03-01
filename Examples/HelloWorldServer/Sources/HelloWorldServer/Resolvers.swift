import Foundation
import GraphQL
import GraphQLGeneratorMacros
import GraphQLGeneratorRuntime

/// Must be created by user and named `GraphQLContext`.
class GraphQLContext: @unchecked Sendable {
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

/// Scalars must be represented by a Swift type of the same name in the GraphQLScalars namespace, conforming to
/// the GraphQLScalar protocol
extension GraphQLScalars {
    struct EmailAddress: GraphQLScalar {
        let email: String

        init(email: String) {
            self.email = email
        }

        /// Codability conformance. Required for usage in InputObject
        init(from decoder: any Decoder) throws {
            email = try decoder.singleValueContainer().decode(String.self)
        }

        func encode(to encoder: any Encoder) throws {
            try email.encode(to: encoder)
        }

        /// Scalar conformance. Not necessary, but default methods are very inefficient.
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

/// Now create types that conform to the expected protocols
struct Resolvers: GraphQLGenerated.Resolvers {
    typealias Query = HelloWorldServer.Query
    typealias Mutation = HelloWorldServer.Mutation
    typealias Subscription = HelloWorldServer.Subscription
}

struct User: GraphQLGenerated.User {
    // User can choose structure

    // Properties with auto-generated GraphQL resolvers.

    @graphQLResolver let id: String
    @graphQLResolver let name: String
    @graphQLResolver let age: Int?
    @graphQLResolver let role: GraphQLGenerated.Role?

    // Required implementations
    // Can't use @graphQLResolver macro because we must convert from String to GraphQLScalars.EmailAddress

    let email: String
    func email(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> GraphQLScalars.EmailAddress {
        return .init(email: email)
    }
}

struct Contact: GraphQLGenerated.Contact {
    // User can choose structure

    /// Required implementations
    let email: String
    func email(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> GraphQLScalars.EmailAddress {
        return .init(email: email)
    }
}

struct Post: GraphQLGenerated.Post {
    // User can choose structure

    @graphQLResolver let id: String
    @graphQLResolver let title: String
    @graphQLResolver let content: String

    /// Required implementations
    let authorId: String
    func author(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> any GraphQLGenerated.User {
        return context.users[authorId]!
    }
}

struct Query: GraphQLGenerated.Query {
    /// Required implementations
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
    /// Required implementations
    static func upsertUser(userInfo: GraphQLGenerated.UserInfo, context: GraphQLContext, info _: GraphQLResolveInfo) -> any GraphQLGenerated.User {
        let user = User(
            id: userInfo.id,
            name: userInfo.name,
            age: userInfo.age,
            role: userInfo.role,
            email: userInfo.email.email
        )
        context.users[userInfo.id] = user
        return user
    }
}

struct Subscription: GraphQLGenerated.Subscription {
    /// Required implementations
    static func watchUser(id: String, context: GraphQLContext, info _: GraphQLResolveInfo) async throws -> AnyAsyncSequence<(any GraphQLGenerated.User)?> {
        return AsyncStream<(any GraphQLGenerated.User)?> { continuation in
            context.onTriggerWatch = { [weak context] in
                continuation.yield(context?.users[id])
            }
        }.any()
    }
}
