
import Foundation
import GraphQL

/// Protocol defining all resolver methods for your GraphQL schema
public protocol GraphQLResolvers: Sendable {
    associatedtype Context: Sendable
    associatedtype Post: PostProtocol where Post.Context == Context
    associatedtype User: UserProtocol where User.Context == Context

    // MARK: - Query Resolvers

    /// Get a user by ID
    func user(id: String, context: Context, info: GraphQLResolveInfo) async throws -> User?

    /// Get all users
    func users(context: Context, info: GraphQLResolveInfo) async throws -> [User]

    /// Get a post by ID
    func post(id: String, context: Context, info: GraphQLResolveInfo) async throws -> Post?

    /// Get recent posts
    func posts(limit: Int?, context: Context, info: GraphQLResolveInfo) async throws -> [Post]
}
