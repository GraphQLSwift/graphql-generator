
import Foundation
import GraphQL

public protocol TypeMapProtocol {
    associatedtype Context: Sendable
    associatedtype Post: PostProtocol where Post.TypeMap == Self
    associatedtype User: UserProtocol where User.TypeMap == Self
}

/// Protocol defining all resolver methods for your GraphQL schema
public protocol GraphQLResolvers: Sendable {
    associatedtype TypeMap: TypeMapProtocol

    // MARK: - Query Resolvers

    /// Get a user by ID
    func user(id: String, context: TypeMap.Context, info: GraphQLResolveInfo) async throws -> TypeMap.User?

    /// Get all users
    func users(context: TypeMap.Context, info: GraphQLResolveInfo) async throws -> [TypeMap.User]

    /// Get a post by ID
    func post(id: String, context: TypeMap.Context, info: GraphQLResolveInfo) async throws -> TypeMap.Post?

    /// Get recent posts
    func posts(limit: Int?, context: TypeMap.Context, info: GraphQLResolveInfo) async throws -> [TypeMap.Post]
}
