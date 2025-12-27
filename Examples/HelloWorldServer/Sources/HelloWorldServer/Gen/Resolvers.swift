
import Foundation
import GraphQL

public protocol TypeMapProtocol {
    associatedtype Context: Sendable
    associatedtype DateTime: Scalar
    associatedtype User: UserProtocol where User.TypeMap == Self
    associatedtype Contact: ContactProtocol where Contact.TypeMap == Self
    associatedtype Post: PostProtocol where Post.TypeMap == Self
    associatedtype Query: QueryProtocol where Query.TypeMap == Self
    associatedtype Mutation: MutationProtocol where Mutation.TypeMap == Self
}
