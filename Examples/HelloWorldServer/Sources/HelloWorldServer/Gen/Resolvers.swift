
import Foundation
import GraphQL

public protocol ResolversProtocol {
    associatedtype Context: Sendable
    associatedtype DateTime: Scalar
    associatedtype User: UserProtocol where User.Resolvers == Self
    associatedtype Contact: ContactProtocol where Contact.Resolvers == Self
    associatedtype Post: PostProtocol where Post.Resolvers == Self
    associatedtype Query: QueryProtocol where Query.Resolvers == Self
    associatedtype Mutation: MutationProtocol where Mutation.Resolvers == Self
}
