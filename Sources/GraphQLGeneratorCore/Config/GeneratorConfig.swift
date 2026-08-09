/// Configuration for the GraphQL Generator, loaded from a YAML file.
///
/// Users can place a `graphql-generator-config.yaml` or `graphql-generator-config.yml`
/// file in their target's source directory to customize generator behavior.
package struct GeneratorConfig: Codable, Sendable {

    /// Paths to GraphQL schema files and/or directories containing schema files.
    ///
    /// Each entry is resolved relative to the target's source directory.
    /// Directories are recursively expanded to include all contained `.graphql` and `.gql` files.
    ///
    /// If nil, the plugin falls back to scanning the target's source files for `.graphql` and `.gql` files.
    package var schemas: [String]?

    package init(schemas: [String]? = nil) {
        self.schemas = schemas
    }
}
