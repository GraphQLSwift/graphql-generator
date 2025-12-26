
import Foundation
import GraphQL

public protocol TypeMapProtocol {
    associatedtype Context: Sendable
    associatedtype DateTime: Scalar
    associatedtype User: UserProtocol where User.TypeMap == Self
    associatedtype Contact: ContactProtocol where Contact.TypeMap == Self
    associatedtype Post: PostProtocol where Post.TypeMap == Self
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

    /// Get a user or post by ID
    func userOrPost(id: String, context: TypeMap.Context, info: GraphQLResolveInfo) async throws -> (any UserOrPostUnion)?

    // MARK: - Mutation Resolvers

    func upsertUser(userInfo: UserInfoInput, context: TypeMap.Context, info: GraphQLResolveInfo) async throws -> TypeMap.User
}
