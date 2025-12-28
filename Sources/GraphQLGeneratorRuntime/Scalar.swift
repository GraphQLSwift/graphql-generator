import GraphQL
import OrderedCollections

public protocol Scalar: Sendable {
    static func serialize(any: Any) throws -> Map
    static func parseValue(map: Map) throws -> Map
    static func parseLiteral(value: any Value) throws -> Map
}

public extension Scalar {
    static func serialize(any: Any) throws -> Map {
        return try Map(any: any)
    }
    static func parseValue(map: Map) throws -> Map {
        return map
    }
    static func parseLiteral(value: any Value) throws -> Map {
        return value.map
    }
}


extension GraphQL.Value {
    var map: Map {
        if
            let value = self as? BooleanValue
        {
            return .bool(value.value)
        }

        if
            let value = self as? IntValue,
            let int = Int(value.value)
        {
            return .int(int)
        }

        if
            let value = self as? FloatValue,
            let double = Double(value.value)
        {
            return .double(double)
        }

        if
            let value = self as? StringValue
        {
            return .string(value.value)
        }

        if
            let value = self as? EnumValue
        {
            return .string(value.value)
        }

        if
            let value = self as? ListValue
        {
            let array = value.values.map { $0.map }
            return .array(array)
        }

        if
            let value = self as? ObjectValue
        {
            let dictionary: OrderedDictionary<String, Map> = value.fields
                .reduce(into: [:]) { result, field in
                    result[field.name.value] = field.value.map
                }

            return .dictionary(dictionary)
        }

        return .null
    }
}
