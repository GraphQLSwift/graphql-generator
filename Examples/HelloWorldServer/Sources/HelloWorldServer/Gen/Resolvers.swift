
import Foundation
import GraphQL

public protocol ResolversProtocol {
    associatedtype Query: QueryProtocol
    associatedtype Mutation: MutationProtocol
}
