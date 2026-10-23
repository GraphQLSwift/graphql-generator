import Foundation
import PackagePlugin

@main
struct GraphQLGeneratorCommand {
    func runCommand(
        targetWorkingDirectory: URL,
        tool: (String) throws -> PluginContext.Tool,
        sourceFiles: FileList,
        targetName: String
    ) throws {
        let inputs = try PluginUtils.validateInputs(
            pluginWorkDirectory: targetWorkingDirectory,
            tool: tool,
            sourceFiles: sourceFiles,
            sourceDirectory: targetWorkingDirectory,
            targetName: targetName,
            pluginSource: .command
        )

        let process = Process()
        process.executableURL = inputs.tool.url
        process.arguments = inputs.arguments
        process.environment = [:]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw PluginError.generatorFailure(targetName: targetName) }
    }
}

extension GraphQLGeneratorCommand: CommandPlugin {
    /// Entry point for creating command plugins for targets in Swift packages.
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let targetNameArguments = arguments.filter({ $0 != "--target" })
        let targets: [Target]
        if targetNameArguments.isEmpty {
            targets = context.package.targets
        } else {
            let matchingTargets = try context.package.targets(named: targetNameArguments)
            let packageTargets = Set(context.package.targets.map(\.id))
            let withLocalDependencies = matchingTargets.flatMap { [$0] + $0.recursiveTargetDependencies }
                .filter { packageTargets.contains($0.id) }
            let enumeratedKeyValues = withLocalDependencies.map(\.id).enumerated()
                .map { (key: $0.element, value: $0.offset) }
            let indexLookupTable = Dictionary(enumeratedKeyValues, uniquingKeysWith: { l, _ in l })
            let groupedByID = Dictionary(grouping: withLocalDependencies, by: \.id)
            let sortedUniqueTargets = groupedByID.map(\.value[0])
                .sorted { indexLookupTable[$0.id, default: 0] < indexLookupTable[$1.id, default: 0] }
            targets = sortedUniqueTargets
        }

        guard !targets.isEmpty else { throw PluginError.noTargetsMatchingTargetNames(targetNameArguments) }

        var hadASuccessfulRun = false

        for target in targets {
            print("Considering target '\(target.name)':")
            guard let target = target as? SwiftSourceModuleTarget else {
                print("- Not a swift source module. Can't generate GraphQL code.")
                continue
            }
            do {
                print("- Trying GraphQL code generation.")
                try runCommand(
                    targetWorkingDirectory: target.directoryURL,
                    tool: context.tool,
                    sourceFiles: target.sourceFiles,
                    targetName: target.name
                )
                print("- ✅ GraphQL code generation for target '\(target.name)' successfully completed.")
                hadASuccessfulRun = true
            } catch PluginError.noSchemaFiles {
                print("- No GraphQL schema files found. Skipping.")
                continue
            } catch {
                print("- GraphQL code generation failed with error.")
                throw error
            }
        }

        guard hadASuccessfulRun else { throw PluginError.noTargetsGenerated(targetNames: targets.map(\.name)) }
    }
}
