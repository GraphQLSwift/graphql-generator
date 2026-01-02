import Foundation
import PackagePlugin

@main
struct GraphQLGeneratorPlugin: BuildToolPlugin {
    /// Entry point for creating build commands for targets in Swift packages.
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // This plugin only runs for package targets that can have source files.
        guard let sourceFiles = target.sourceModule?.sourceFiles else { return [] }

        // Find the GraphQL schema files
        let schemaFiles = sourceFiles.filter { file in
            file.url.pathExtension == "graphql" || file.url.pathExtension == "gql"
        }

        // If no schema files found, return early
        guard !schemaFiles.isEmpty else { return [] }

        // Find the generator tool
        let generatorTool = try context.tool(named: "GraphQLGenerator")

        // Create output directory for generated files
        let outputDirectory = context.pluginWorkDirectoryURL

        // Generate a single set of files from all schema files
        // (We could also generate per-file, but typically GraphQL schemas are combined)
        let schemaInputs = schemaFiles.map(\.url)

        let outputFiles = [
            outputDirectory.appendingPathComponent("BuildGraphQLSchema.swift"),
            outputDirectory.appendingPathComponent("GraphQLRawSDL.swift"),
            outputDirectory.appendingPathComponent("GraphQLTypes.swift"),
        ]

        let arguments = schemaInputs.flatMap { ["\($0.path)"] } + [
            "--output-directory", outputDirectory.path,
        ]

        return [
            .buildCommand(
                displayName: "Generating GraphQL Swift code from \(schemaFiles.count) schema file(s)",
                executable: generatorTool.url,
                arguments: arguments,
                inputFiles: schemaInputs,
                outputFiles: outputFiles
            ),
        ]
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension GraphQLGeneratorPlugin: XcodeBuildToolPlugin {
        /// Entry point for creating build commands for targets in Xcode projects.
        func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
            // Find GraphQL schema files
            let schemaFiles = target.inputFiles.filter { file in
                file.url.pathExtension == "graphql" || file.url.pathExtension == "gql"
            }

            // If no schema files found, return early
            guard !schemaFiles.isEmpty else { return [] }

            // Find the generator tool
            let generatorTool = try context.tool(named: "GraphQLGenerator")

            // Create output directory for generated files
            let outputDirectory = context.pluginWorkDirectoryURL

            let schemaInputs = schemaFiles.map(\.url)

            let outputFiles = [
                outputDirectory.appendingPathComponent("Types.swift"),
                outputDirectory.appendingPathComponent("Schema.swift"),
            ]

            let arguments = schemaInputs.flatMap { ["\($0.path)"] } + [
                "--output-directory", outputDirectory.path,
            ]

            return [
                .buildCommand(
                    displayName: "Generating GraphQL Swift code from \(schemaFiles.count) schema file(s)",
                    executable: generatorTool.url,
                    arguments: arguments,
                    inputFiles: schemaInputs,
                    outputFiles: outputFiles
                ),
            ]
        }
    }

#endif
