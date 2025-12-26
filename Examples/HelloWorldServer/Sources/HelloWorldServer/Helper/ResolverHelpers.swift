import GraphQL

public extension GraphQLResolvers {
    func cast<T: Sendable>(_ anySendable: any Sendable, to resultType: T.Type) throws -> T {
        guard let result = anySendable as? T else {
            throw GraphQLError(
                message: "Expected source type \(T.self) but got \(type(of: anySendable))"
            )
        }
        return result
    }
}
