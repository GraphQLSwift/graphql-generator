import Foundation
import GraphQL

/// Main code generator that orchestrates generation of all Swift files
package struct CodeGenerator {
    package init() {}

    /// Generate all Swift files from the schema
    /// Returns a dictionary of filename -> file content
    package func generate(source: String) throws -> [String: String] {
        let schema = try GraphQL.buildSchema(source: source)

        var files: [String: String] = [:]

        // Generate Types.swift
        let typeGenerator = TypeGenerator()
        files["Types.swift"] = try typeGenerator.generate(schema: schema)

        // Generate Schema.swift
        let schemaGenerator = SchemaGenerator()
        files["Schema.swift"] = try schemaGenerator.generate(schema: schema)

        // Generate SDL.swift
        let sdlGenerator = SDLGenerator()
        files["SDL.swift"] = try sdlGenerator.generate(source: source)

        return files
    }
}
