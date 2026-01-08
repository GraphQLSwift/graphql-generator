import GraphQL
import OrderedCollections

/// A type that can act as a GraphQL scalar value
public protocol GraphQLScalar: Sendable, Codable {
    /// Given an instance of this type, it defines how to convert the instance into a GraphQL JSON Map
    static func serialize(this: Self) throws -> Map

    /// Given any GraphQL JSON Map value, validate and conform it to a Map that represents this scalar
    static func parseValue(map: Map) throws -> Map

    /// Given a literal value, validate it and return the corresponding GraphQL JSON Map
    static func parseLiteral(value: any Value) throws -> Map
}

// Graphiti provides default serializations that use the underlying type's Codability requirements, but they are
// somewhat inefficient. They typically pass through a full serialize/deserialize step on each call.
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
