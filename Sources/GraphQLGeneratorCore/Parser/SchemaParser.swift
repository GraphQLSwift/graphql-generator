import Foundation
import GraphQL

/// Parses GraphQL schema files and builds a GraphQLSchema
public struct SchemaParser {
    public init() {}

    /// Parse GraphQL schema files and combine them into a single schema
    public func parseSchemaFiles(_ filePaths: [String]) throws -> GraphQLSchema {
        var combinedSource = ""

        // Read and combine all schema files
        for filePath in filePaths {
            let url = URL(fileURLWithPath: filePath)
            let content = try String(contentsOf: url, encoding: .utf8)
            combinedSource += content + "\n"
        }

        // Use GraphQL Swift's built-in buildSchema function
        return try GraphQL.buildSchema(source: combinedSource)
    }

    /// Parse a single GraphQL schema string
    public func parseSchema(_ source: String) throws -> GraphQLSchema {
        return try GraphQL.buildSchema(source: source)
    }
}
