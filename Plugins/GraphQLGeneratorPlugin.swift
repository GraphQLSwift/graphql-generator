import Foundation
import PackagePlugin

@main
struct GraphQLGeneratorPlugin: BuildToolPlugin {
    private static let schemaExtensions: Set<String> = ["graphql", "gql"]

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

        let inputFiles = try commandInputFiles(
            in: target.sourceFiles,
            sourceDirectory: target.directoryURL,
            configFile: configFile
        )

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

    /// Returns all files whose contents can affect generated output.
    private func commandInputFiles(
        in sourceFiles: FileList,
        sourceDirectory: URL,
        configFile: URL?
    ) throws -> [URL] {
        let schemaFiles: [URL]
        if let configFile, let configuredPaths = try configuredSchemaPaths(in: configFile) {
            schemaFiles = try resolveSchemaFiles(configuredPaths, relativeTo: sourceDirectory)
        } else {
            schemaFiles = sourceFiles.map(\.url).filter {
                Self.schemaExtensions.contains($0.pathExtension.lowercased())
            }
        }
        return (configFile.map { [$0] } ?? []) + schemaFiles
    }

    /// Decodes the optional top-level `schemas` YAML sequence used by the generator.
    private func configuredSchemaPaths(in configFile: URL) throws -> [String]? {
        let contents = try String(contentsOf: configFile, encoding: .utf8)
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed == "schemas:" || trimmed.hasPrefix("schemas: ") else { continue }

            let inlineValue = trimmed.dropFirst("schemas:".count)
                .trimmingCharacters(in: .whitespaces)
            if inlineValue == "null" || inlineValue == "~" {
                return nil
            }
            if inlineValue.hasPrefix("["), inlineValue.hasSuffix("]") {
                let values = inlineValue.dropFirst().dropLast()
                if values.trimmingCharacters(in: .whitespaces).isEmpty {
                    return []
                }
                return values.split(separator: ",").map {
                    unquote($0.trimmingCharacters(in: .whitespaces))
                }
            }
            guard inlineValue.isEmpty else {
                throw PluginConfigError.unsupportedSchemasFormat(configFile.path)
            }

            let indentation = line.prefix { $0 == " " || $0 == "\t" }.count
            var paths: [String] = []
            for nestedLine in lines.dropFirst(index + 1) {
                let nestedIndentation = nestedLine.prefix { $0 == " " || $0 == "\t" }.count
                let nested = nestedLine.trimmingCharacters(in: .whitespaces)
                if nested.isEmpty || nested.hasPrefix("#") { continue }
                if nestedIndentation <= indentation { break }
                guard nested.hasPrefix("-") else {
                    throw PluginConfigError.unsupportedSchemasFormat(configFile.path)
                }
                paths.append(unquote(nested.dropFirst().trimmingCharacters(in: .whitespaces)))
            }
            return paths
        }

        return nil
    }

    private func unquote(_ value: String) -> String {
        guard value.count >= 2,
            let first = value.first,
            let last = value.last,
            (first == "\"" && last == "\"") || (first == "'" && last == "'")
        else {
            return value
        }
        return String(value.dropFirst().dropLast())
    }

    private func resolveSchemaFiles(_ paths: [String], relativeTo baseURL: URL) throws -> [URL] {
        let fileManager = FileManager.default
        var result: Set<URL> = []

        for path in paths {
            let resolvedURL = baseURL.appendingPathComponent(path).standardizedFileURL
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: resolvedURL.path, isDirectory: &isDirectory) else {
                throw PluginConfigError.schemaPathNotFound(path, resolvedURL.path)
            }

            if isDirectory.boolValue {
                guard
                    let enumerator = fileManager.enumerator(
                        at: resolvedURL,
                        includingPropertiesForKeys: [.isDirectoryKey],
                        options: [.skipsHiddenFiles]
                    )
                else {
                    continue
                }
                for case let fileURL as URL in enumerator
                where (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true
                    && Self.schemaExtensions.contains(fileURL.pathExtension.lowercased())
                {
                    result.insert(fileURL.standardizedFileURL)
                }
            } else {
                result.insert(resolvedURL)
            }
        }

        return result.sorted { $0.path < $1.path }
    }
}

private enum PluginConfigError: Error, CustomStringConvertible {
    case unsupportedSchemasFormat(String)
    case schemaPathNotFound(String, String)

    var description: String {
        switch self {
        case .unsupportedSchemasFormat(let path):
            "Unsupported schemas format in \(path); use a YAML list of paths"
        case .schemaPathNotFound(let path, let resolvedPath):
            "Schema path not found: \(path) (resolved to \(resolvedPath))"
        }
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
            let sourceDirectory = context.xcodeProject.directoryURL

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

            // Pass the source directory for fallback schema discovery
            arguments += ["--source-directory", sourceDirectory.path]

            // Pass output directory
            arguments += ["--output-directory", outputDirectory.path]

            // Pass config file if found
            if let configURL = configFile {
                arguments += ["--config", configURL.path]
            }

            let inputFiles = commandInputFiles(
                in: target.inputFiles,
                sourceDirectory: sourceDirectory,
                configFile: configFile
            )

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
