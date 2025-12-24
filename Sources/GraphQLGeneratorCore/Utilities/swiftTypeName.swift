import GraphQL

/// Convert GraphQL type to Swift type name
func swiftTypeName(for type: GraphQLType, nameGenerator: SafeNameGenerator) throws -> String {
    if let nonNull = type as? GraphQLNonNull {
        let innerType = try swiftTypeName(for: nonNull.ofType, nameGenerator: nameGenerator)
        // Remove the optional marker if present
        if innerType.hasSuffix("?") {
            return String(innerType.dropLast())
        }
        return innerType
    }

    if let list = type as? GraphQLList {
        let innerType = try swiftTypeName(for: list.ofType, nameGenerator: nameGenerator)
        if innerType.hasSuffix("?") {
            let baseType = String(innerType.dropLast())
            return "[\(baseType)]?"
        }
        return "[\(innerType)]?"
    }

    if let namedType = type as? GraphQLNamedType {
        let typeName = namedType.name
        let swiftType = mapScalarType(typeName, nameGenerator: nameGenerator)
        // By default, GraphQL fields are nullable, so add optional marker
        return "\(swiftType)?"
    }

    throw GeneratorError.unsupportedType("Unknown type: \(type)")
}

/// Map GraphQL scalar types to Swift types
func mapScalarType(_ graphQLType: String, nameGenerator: SafeNameGenerator) -> String {
    switch graphQLType {
    case "ID": return "String"
    case "String": return "String"
    case "Int": return "Int"
    case "Float": return "Double"
    case "Boolean": return "Bool"
    default:
        // For custom types (enums, objects), use safe name generator
        return nameGenerator.swiftTypeName(for: graphQLType)
    }
}
