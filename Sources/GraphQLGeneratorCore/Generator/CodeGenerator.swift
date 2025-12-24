import Foundation
import GraphQL

/// Main code generator that orchestrates generation of all Swift files
public struct CodeGenerator {
    let schema: GraphQLSchema

    public init(schema: GraphQLSchema) {
        self.schema = schema
    }

    /// Generate all Swift files from the schema
    /// Returns a dictionary of filename -> file content
    public func generate() throws -> [String: String] {
        var files: [String: String] = [:]

        // Generate Types.swift
        let typeGenerator = TypeGenerator(schema: schema)
        files["Types.swift"] = try typeGenerator.generate()

        // Generate Resolvers.swift
        let resolverGenerator = ResolverGenerator(schema: schema)
        files["Resolvers.swift"] = try resolverGenerator.generate()

        // Generate Schema.swift
        let schemaGenerator = SchemaGenerator(schema: schema)
        files["Schema.swift"] = try schemaGenerator.generate()

        return files
    }
}
