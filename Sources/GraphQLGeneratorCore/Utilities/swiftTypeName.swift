import GraphQL

/// Convert GraphQL type to Swift type name
func swiftTypeReference(for type: GraphQLType, nameGenerator: SafeNameGenerator) throws -> String {
    if let nonNull = type as? GraphQLNonNull {
        let innerType = try swiftTypeReference(for: nonNull.ofType, nameGenerator: nameGenerator)
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
        let innerType = try swiftTypeReference(for: list.ofType, nameGenerator: nameGenerator)
        if innerType.hasSuffix("?") {
            let baseType = String(innerType.dropLast())
            return "[\(baseType)]?"
        }
        return "[\(innerType)]?"
    }

    if let namedType = type as? GraphQLNamedType {
        let baseName = try swiftTypeDeclaration(for: namedType, nameGenerator: nameGenerator)
        // By default, GraphQL fields are nullable, so add "?"
        if type is GraphQLUnionType || type is GraphQLInterfaceType || type is GraphQLObjectType {
            // These are all interfaces, so we must wrap them in 'any' and parentheses for optionals.
            return "(any \(baseName))?"
        } else if type is GraphQLScalarType {
            let swiftScalar = mapScalarType(namedType.name, nameGenerator: nameGenerator)
            return "\(swiftScalar)?"
        }
        return "\(baseName)?"
    }

    throw GeneratorError.unsupportedType("Unknown type: \(type)")
}

/// Convert GraphQL type to Swift type name
func swiftTypeDeclaration(for type: GraphQLType, nameGenerator: SafeNameGenerator) throws -> String {
    if let nonNull = type as? GraphQLNonNull {
        return try swiftTypeDeclaration(for: nonNull.ofType, nameGenerator: nameGenerator)
    }

    if let list = type as? GraphQLList {
        return try swiftTypeDeclaration(for: list.ofType, nameGenerator: nameGenerator)
    }

    if let namedType = type as? GraphQLNamedType {
        let baseName = nameGenerator.swiftTypeName(for: namedType.name)
        if type is GraphQLInputObjectType {
            return "\(baseName)Input"
        } else if type is GraphQLInterfaceType {
            return "\(baseName)Interface"
        } else if type is GraphQLObjectType {
            return "\(baseName)Protocol"
        } else if type is GraphQLUnionType {
            return "\(baseName)Union"
        }
        return baseName
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

/// Converts a Map value to valid Swift code representation
func mapToSwiftCode(_ map: Map) -> String {
    switch map {
    case .undefined:
        return ".undefined"
    case .null:
        return ".null"
    case .bool(let value):
        return ".bool(\(value))"
    case .number(let value):
        return ".number(Number(\(value)))"
    case .string(let value):
        // Escape special characters for Swift string literal
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        return ".string(\"\(escaped)\")"
    case .array(let values):
        let elements = values.map { mapToSwiftCode($0) }.joined(separator: ", ")
        return ".array([\(elements)])"
    case .dictionary(let dict):
        let pairs = dict.map { key, value in
            let escapedKey = key
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escapedKey)\": \(mapToSwiftCode(value))"
        }.joined(separator: ", ")
        return ".dictionary([\(pairs)])"
    }
}
