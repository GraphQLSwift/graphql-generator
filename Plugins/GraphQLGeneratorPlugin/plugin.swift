import Foundation
import PackagePlugin

@main struct GraphQLGeneratorPlugin {
    func createBuildCommands(
        pluginWorkDirectory: URL,
        tool: (String) throws -> PluginContext.Tool,
        sourceFiles: FileList,
        sourceDirectory: URL,
        targetName: String
    ) throws -> [Command] {
        let inputs = try PluginUtils.validateInputs(
            pluginWorkDirectory: pluginWorkDirectory,
            tool: tool,
            sourceFiles: sourceFiles,
            sourceDirectory: sourceDirectory,
            targetName: targetName,
            pluginSource: .build
        )

        let outputFiles = OutputFileName.allCases.map { inputs.outputDirectory.appending(component: $0.rawValue) }
        var inputFiles = inputs.schemaFiles
        if let config = inputs.config {
            inputFiles.append(config)
        }
        return [
            .buildCommand(
                displayName: "Generating GraphQL Swift code",
                executable: inputs.tool.url,
                arguments: inputs.arguments,
                environment: [:],
                inputFiles: inputFiles,
                outputFiles: outputFiles
            )
        ]
    }
}

extension GraphQLGeneratorPlugin: BuildToolPlugin {
    /// Entry point for creating build commands for targets in Swift packages.
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let swiftTarget = target as? SwiftSourceModuleTarget else {
            throw PluginError.incompatibleTarget(name: target.name)
        }
        return try createBuildCommands(
            pluginWorkDirectory: context.pluginWorkDirectoryURL,
            tool: context.tool,
            sourceFiles: swiftTarget.sourceFiles,
            sourceDirectory: swiftTarget.directoryURL,
            targetName: target.name
        )
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension GraphQLGeneratorPlugin: XcodeBuildToolPlugin {
        /// Entry point for creating build commands for targets in Xcode projects.
        func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws
            -> [Command]
        {
            return try createBuildCommands(
                pluginWorkDirectory: context.pluginWorkDirectoryURL,
                tool: context.tool,
                sourceFiles: target.inputFiles,
                sourceDirectory: context.xcodeProject.directoryURL,
                targetName: target.displayName
            )
        }
    }

#endif
