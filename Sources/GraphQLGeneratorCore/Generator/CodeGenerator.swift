import Foundation
import GraphQL

/// Main code generator that orchestrates generation of all Swift files
package struct CodeGenerator {
    package init() { }

    /// Generate all Swift files from the schema
    /// Returns a dictionary of filename -> file content
    package func generate(schema: GraphQLSchema) throws -> [String: String] {
        var files: [String: String] = [:]

        // Generate Types.swift
        let typeGenerator = TypeGenerator()
        files["Types.swift"] = try typeGenerator.generate(schema: schema)

        // Generate Resolvers.swift
        let resolverGenerator = ResolverGenerator()
        files["Resolvers.swift"] = try resolverGenerator.generate(schema: schema)

        // Generate Schema.swift
        let schemaGenerator = SchemaGenerator()
        files["Schema.swift"] = try schemaGenerator.generate(schema: schema)

        return files
    }
}
