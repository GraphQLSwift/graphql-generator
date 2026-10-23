import Foundation
import PackagePlugin

enum PluginUtils {
    struct ValidatedInputs {
        let schemaFiles: [URL]
        let config: URL?
        let outputDirectory: URL
        let arguments: [String]
        let tool: PluginContext.Tool
    }

    /// Validates the inputs and returns the necessary values to run a plugin.
    static func validateInputs(
        pluginWorkDirectory: URL,
        tool: (String) throws -> PluginContext.Tool,
        sourceFiles: FileList,
        sourceDirectory: URL,
        targetName: String,
        pluginSource: PluginSource
    ) throws -> ValidatedInputs {
        // Find the config file, if present
        let configFile = findConfigFile(in: sourceFiles)

        // Create output directory for generated files
        let outputDirectory = pluginWorkDirectory

        var arguments: [String] = []

        // Pass the target's source directory for fallback schema discovery
        arguments += ["--source-directory", sourceDirectory.path()]

        // Pass output directory
        arguments += ["--output-directory", outputDirectory.path]

        // Pass config file if found
        if let configURL = configFile {
            arguments += ["--config", configURL.path]
        }

        let inputFiles = try commandInputFiles(
            in: sourceFiles,
            sourceDirectory: sourceDirectory,
            configFile: configFile
        )

        let tool = try tool("GraphQLGenerator")

        return ValidatedInputs(schemaFiles: inputFiles, config: configFile, outputDirectory: outputDirectory, arguments: arguments, tool: tool)
    }

    /// Finds the generator config file in the target's source files, if present.
    private static func findConfigFile(in sourceFiles: FileList) -> URL? {
        let configs = sourceFiles.map(\.url).filter {
            Self.supportedConfigFiles.contains($0.lastPathComponent)
        }
        return configs.first
    }

    /// Returns all files whose contents can affect generated output.
    private static func commandInputFiles(
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
    private static func configuredSchemaPaths(in configFile: URL) throws -> [String]? {
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

    private static func unquote(_ value: String) -> String {
        guard value.count >= 2,
            let first = value.first,
            let last = value.last,
            (first == "\"" && last == "\"") || (first == "'" && last == "'")
        else {
            return value
        }
        return String(value.dropFirst().dropLast())
    }

    private static func resolveSchemaFiles(_ paths: [String], relativeTo baseURL: URL) throws -> [URL] {
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

    /// The source of a plugin generator invocation.
    enum PluginSource: String, Codable {
        /// BuildTool plugin
        case build
        /// Command plugin.
        case command
    }


    /// Supported config file names in the target's source directory.
    private static let supportedConfigFiles: Set<String> = [
        "graphql-generator-config.yaml",
        "graphql-generator-config.yml",
    ]
    
    private static let schemaExtensions: Set<String> = ["graphql", "gql"]
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

enum PluginError: Swift.Error, Equatable, CustomStringConvertible, LocalizedError {
    case incompatibleTarget(name: String)
    case generatorFailure(targetName: String)
    case noTargetsMatchingTargetNames([String])
    case noTargetsGenerated(targetNames: [String])

    var description: String {
        switch self {
        case .incompatibleTarget(let name):
            return "Incompatible target called '\(name)'. Only Swift source targets can be used with the GraphQL Generator plugin."
        case .generatorFailure(let targetName):
            return "The generator failed to generate GraphQL Swift files for target '\(targetName)'."
        case .noTargetsMatchingTargetNames(let targetNames):
            return "Found no targets with names \(targetNames.joined(separator: ", "))."
        case .noTargetsGenerated(let targetNames):
            return "No targets from inputs \(targetNames.joined(separator: ", ")) were generated."
        }
    }

    var errorDescription: String? { description }
}
