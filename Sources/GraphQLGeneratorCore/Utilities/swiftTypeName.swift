import GraphQL

/// Convert GraphQL type to Swift type reference. In particular, this includes the relevant `any`, optional `?`, or array
/// `[`/`]` in the result.
/// - Parameters:
///   - type: The GraphQL Type to generate a reference to
///   - includeNamespace: Whether to include the `GraphQLGenerated` type namespace in the result
///   - nameGenerator: The name generator
func swiftTypeReference(for type: GraphQLType, includeNamespace: Bool, nameGenerator: SafeNameGenerator) throws -> String {
    if let nonNull = type as? GraphQLNonNull {
        let innerType = try swiftTypeReference(for: nonNull.ofType, includeNamespace: includeNamespace, nameGenerator: nameGenerator)
        // Remove the optional marker if present
        if innerType.hasSuffix("?") {
            if innerType.hasPrefix("(") {
                // Remove parentheses and trailing ? around "(any X)?"
                return String(innerType.dropFirst().dropLast().dropLast())
            }
            // Remove trailing ? on "X?"
            return String(innerType.dropLast())
        }
        return innerType
    }

    if let list = type as? GraphQLList {
        let innerType = try swiftTypeReference(for: list.ofType, includeNamespace: includeNamespace, nameGenerator: nameGenerator)
        if innerType.hasSuffix("?") {
            let baseType = String(innerType.dropLast())
            return "[\(baseType)]?"
        }
        return "[\(innerType)]?"
    }

    if let namedType = type as? GraphQLNamedType {
        let baseName = try swiftTypeDeclaration(for: namedType, includeNamespace: includeNamespace, nameGenerator: nameGenerator)

        // By default, GraphQL fields are nullable, so add "?"
        if namedType is GraphQLUnionType || namedType is GraphQLInterfaceType || namedType is GraphQLObjectType {
            // These are all interfaces, so we must wrap them in 'any' and parentheses for optionals.
            return "(any \(baseName))?"
        }
        if let scalarType = namedType as? GraphQLScalarType {
            let swiftScalar = mapScalarType(scalarType, nameGenerator: nameGenerator)
            return "\(swiftScalar)?"
        }
        return "\(baseName)?"
    }

    throw GeneratorError.unsupportedType("Unknown type: \(type)")
}

/// Convert GraphQL type to Swift type declaration name. This will not include modifiers for optionals/lists/etc.
/// - Parameters:
///   - type: The GraphQL Type to generate a reference to
///   - includeNamespace: Whether to include the `GraphQLGenerated` type namespace in the result
///   - nameGenerator: The name generator
func swiftTypeDeclaration(for type: GraphQLType, includeNamespace: Bool, nameGenerator: SafeNameGenerator) throws -> String {
    if let nonNull = type as? GraphQLNonNull {
        // Declarations must be for non-nulls, so just pass through
        return try swiftTypeDeclaration(for: nonNull.ofType, includeNamespace: includeNamespace, nameGenerator: nameGenerator)
    }

    if let list = type as? GraphQLList {
        // Declarations must be for non-lists, so just pass through
        return try swiftTypeDeclaration(for: list.ofType, includeNamespace: includeNamespace, nameGenerator: nameGenerator)
    }

    if let namedType = type as? GraphQLNamedType {
        var baseName = nameGenerator.swiftTypeName(for: namedType.name)
        if includeNamespace {
            baseName = "GraphQLGenerated.\(baseName)"
        }
        return baseName
    }

    throw GeneratorError.unsupportedType("Unknown type: \(type)")
}

/// Map GraphQL leaf types to Swift types.
///
/// - Parameters:
///   - graphQLType: The GraphQL Type to generate a reference to
///   - includeNamespace: Whether to include the `GraphQLGenerated` type namespace in the result
///   - nameGenerator: The name generator
func mapScalarType(_ type: GraphQLScalarType, nameGenerator: SafeNameGenerator) -> String {
    switch type.name {
    case "ID": return "String"
    case "String": return "String"
    case "Int": return "Int"
    case "Float": return "Double"
    case "Boolean": return "Bool"
    default:
        // For custom scalars, use safe name generator
        let baseName = nameGenerator.swiftTypeName(for: type.name)
        return "GraphQLScalars.\(baseName)"
    }
}
