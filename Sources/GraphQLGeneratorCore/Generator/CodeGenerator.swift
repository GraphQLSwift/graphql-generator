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
        files["BuildGraphQLSchema.swift"] = try SchemaGenerator().generate(schema: schema)
        files["GraphQLRawSDL.swift"] = try SDLGenerator().generate(source: source)
        files["GraphQLTypes.swift"] = try TypeGenerator().generate(schema: schema)

        return files
    }
}
