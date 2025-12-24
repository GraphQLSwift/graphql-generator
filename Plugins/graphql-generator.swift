import PackagePlugin
import struct Foundation.URL

@main
struct graphql_generator: BuildToolPlugin {
    /// Entry point for creating build commands for targets in Swift packages.
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // This plugin only runs for package targets that can have source files.
        guard let sourceFiles = target.sourceModule?.sourceFiles else { return [] }

        // Find the code generator tool to run (replace this with the actual one).
        let generatorTool = try context.tool(named: "my-code-generator")

        // Construct a build command for each source file with a particular suffix.
        return sourceFiles.map(\.url).compactMap {
            createBuildCommand(for: $0, in: context.pluginWorkDirectoryURL, with: generatorTool.url)
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension graphql_generator: XcodeBuildToolPlugin {
    // Entry point for creating build commands for targets in Xcode projects.
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        // Find the code generator tool to run (replace this with the actual one).
        let generatorTool = try context.tool(named: "my-code-generator")

        // Construct a build command for each source file with a particular suffix.
        return target.inputFiles.map(\.url).compactMap {
            createBuildCommand(for: $0, in: context.pluginWorkDirectoryURL, with: generatorTool.url)
        }
    }
}

#endif

extension graphql_generator {
    /// Shared function that returns a configured build command if the input files is one that should be processed.
    func createBuildCommand(for inputPath: URL, in outputDirectoryPath: URL, with generatorToolPath: URL) -> Command? {
        // Skip any file that doesn't have the extension we're looking for (replace this with the actual one).
        guard inputPath.pathExtension == "my-input-suffix" else { return .none }
        
        // Return a command that will run during the build to generate the output file.
        let inputName = inputPath.lastPathComponent
        let outputName = inputPath.deletingPathExtension().lastPathComponent + ".swift"
        let outputPath = outputDirectoryPath.appendingPathComponent(outputName)
        return .buildCommand(
            displayName: "Generating \(outputName) from \(inputName)",
            executable: generatorToolPath,
            arguments: ["\(inputPath)", "-o", "\(outputPath)"],
            inputFiles: [inputPath],
            outputFiles: [outputPath]
        )
    }
}
