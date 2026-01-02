import GraphQL
import OrderedCollections

public protocol GraphQLScalar: Sendable, Codable {
    static func serialize(this: Self) throws -> Map
    static func parseValue(map: Map) throws -> Map
    static func parseLiteral(value: any Value) throws -> Map
}

// Graphiti provides default serializations that the underlying type's Codability requirements, but they are very
// inefficient. They typically pass through a full serialize/deserialize step on each call.
// Because of this, we have chosen not to vend defaults to force the user to implement more performant versions.

public extension GraphQLScalar {
    /// This wraps the GraphQLScalar definition in a type-safe one
    static func serialize(any: Any) throws -> Map {
        // We should always get a value of `Self` for custom scalars.
        guard let scalar = any as? Self else {
            throw GraphQLError(
                message: "Serialize expected type \(Self.self) but got \(type(of: any))"
            )
        }
        return try Self.serialize(this: scalar)
    }
}
