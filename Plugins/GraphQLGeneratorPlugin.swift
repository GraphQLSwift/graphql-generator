import Foundation
import PackagePlugin

@main
struct GraphQLGeneratorPlugin: BuildToolPlugin {
    /// Entry point for creating build commands for targets in Swift packages.
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // This plugin only runs for Swift source targets.
        guard let target = target as? SwiftSourceModuleTarget else {
            return []
        }

        // Find the config file, if present
        let configFile = findConfigFile(in: target.sourceFiles)

        // Find the generator tool
        let generatorTool = try context.tool(named: "GraphQLGenerator")

        // Create output directory for generated files
        let outputDirectory = context.pluginWorkDirectoryURL

        let outputFiles = [
            outputDirectory.appendingPathComponent("BuildGraphQLSchema.swift"),
            outputDirectory.appendingPathComponent("GraphQLRawSDL.swift"),
            outputDirectory.appendingPathComponent("GraphQLTypes.swift"),
        ]

        var arguments: [String] = []

        // Pass the target's source directory for fallback schema discovery
        arguments += ["--source-directory", target.directoryURL.path()]

        // Pass output directory
        arguments += ["--output-directory", outputDirectory.path]

        // Pass config file if found
        if let configURL = configFile {
            arguments += ["--config", configURL.path]
        }

        let inputFiles: [URL] = configFile.map { [$0] } ?? []

        return [
            .buildCommand(
                displayName: "Generating GraphQL Swift code",
                executable: generatorTool.url,
                arguments: arguments,
                inputFiles: inputFiles,
                outputFiles: outputFiles
            )
        ]
    }

    /// Supported config file names in the target's source directory.
    private static let supportedConfigFiles: Set<String> = [
        "graphql-generator-config.yaml",
        "graphql-generator-config.yml",
    ]

    /// Finds the generator config file in the target's source files, if present.
    private func findConfigFile(in sourceFiles: FileList) -> URL? {
        let configs = sourceFiles.map(\.url).filter {
            Self.supportedConfigFiles.contains($0.lastPathComponent)
        }
        return configs.first
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension GraphQLGeneratorPlugin: XcodeBuildToolPlugin {
        /// Entry point for creating build commands for targets in Xcode projects.
        func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws
            -> [Command]
        {
            // Find the config file
            let configFile = findConfigFile(in: target.inputFiles)

            // Derive the source directory from the target's input files
            let sourceDirectory =
                target.inputFiles.first?.url.deletingLastPathComponent().path
                ?? context.xcodeProject.directoryURL.path

            // Find the generator tool
            let generatorTool = try context.tool(named: "GraphQLGenerator")

            // Create output directory for generated files
            let outputDirectory = context.pluginWorkDirectoryURL

            let outputFiles = [
                outputDirectory.appendingPathComponent("Types.swift"),
                outputDirectory.appendingPathComponent("Schema.swift"),
            ]

            var arguments: [String] = []

            // Pass the source directory for fallback schema discovery
            arguments += ["--source-directory", sourceDirectory]

            // Pass output directory
            arguments += ["--output-directory", outputDirectory.path]

            // Pass config file if found
            if let configURL = configFile {
                arguments += ["--config", configURL.path]
            }

            let inputFiles: [URL] = configFile.map { [$0] } ?? []

            return [
                .buildCommand(
                    displayName: "Generating GraphQL Swift code",
                    executable: generatorTool.url,
                    arguments: arguments,
                    inputFiles: inputFiles,
                    outputFiles: outputFiles
                )
            ]
        }
    }

#endif
