import GraphQL

public func swapiSchema() throws -> GraphQLSchema {
    return try buildGraphQLSchema(resolvers: Resolvers.self)
}
