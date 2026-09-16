import ArgumentParser
import Foundation
import GraphQLGeneratorCore
import Yams

@main
struct GraphQLGeneratorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "graphql-generator",
        abstract: "Generate Swift code from GraphQL schema files",
        version: "0.1.0"
    )

    @Option(
        name: .long,
        help: "Target source directory"
    )
    var sourceDirectory: String

    @Option(name: .shortAndLong, help: "Output directory for generated files")
    var outputDirectory: String

    @Option(
        name: .shortAndLong,
        help: "Path to a YAML configuration file (graphql-generator-config.yaml)"
    )
    var config: String?

    @Flag(name: .long, help: "Enable verbose logging")
    var verbose: Bool = false

    private static let schemaExtensions: Set<String> = ["graphql", "gql"]

    mutating func run() throws {
        if verbose {
            print("GraphQL Generator starting...")
            print("Source directory: \(sourceDirectory)")
            print("Config: \(config ?? "none")")
            print("Output directory: \(outputDirectory)")
        }

        // Resolve schema file paths
        let resolvedSchemaFiles = try resolveSchemaFiles()

        if verbose {
            print("Schema files: \(resolvedSchemaFiles)")
        }

        guard !resolvedSchemaFiles.isEmpty else {
            throw ValidationError(
                "No schema files found. Either specify schemas in your config file or add .graphql/.gql files to your target's source directory."
            )
        }

        for filePath in resolvedSchemaFiles {
            let fileURL = URL(fileURLWithPath: filePath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw ValidationError("Schema file not found: \(filePath)")
            }
        }

        let outputURL = URL(fileURLWithPath: outputDirectory)
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        if verbose {
            print("Parsing schema files...")
        }
        var combinedSource = ""
        for filePath in resolvedSchemaFiles {
            let url = URL(fileURLWithPath: filePath)
            let content = try String(contentsOf: url, encoding: .utf8)
            combinedSource += content + "\n"
        }

        let generator = CodeGenerator()
        let files = try generator.generate(source: combinedSource)

        for (filename, content) in files {
            let fileURL = outputURL.appendingPathComponent(filename)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            if verbose {
                print("Generated: \(fileURL.path)")
            }
        }

        if verbose {
            print("Code generation complete!")
        }
    }

    /// Resolves the schema file paths. If the config file specifies `schemas`, each entry is resolved relative to
    /// `sourceDirectory` and directories are expanded recursively. Otherwise, falls back to scanning
    /// `sourceDirectory` recursively for `.graphql` and `.gql` files.
    private mutating func resolveSchemaFiles() throws -> [String] {
        // If a config file was provided with a `schemas` key, use it
        var configSchemas: [String]? = nil
        if let configPath = config {
            let generatorConfig = try YAMLDecoder().decode(
                GeneratorConfig.self,
                from: Data(contentsOf: URL(fileURLWithPath: configPath))
            )
            configSchemas = generatorConfig.schemas
        }
        // Otherwise, recursively scan the source directory itself
        let schemaPaths = configSchemas ?? ["./"]

        let fileManager = FileManager.default
        let sourceURL = URL(fileURLWithPath: sourceDirectory)
        var schemaFiles: Set<String> = []

        for path in schemaPaths {
            let resolvedURL = sourceURL.appendingPathComponent(path).standardizedFileURL
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: resolvedURL.path, isDirectory: &isDirectory)
            else {
                throw ValidationError(
                    "Schema path not found: \(path) (resolved to \(resolvedURL.path))"
                )
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
                    schemaFiles.insert(fileURL.standardizedFileURL.path)
                }
            } else {
                schemaFiles.insert(resolvedURL.path)
            }
        }

        return schemaFiles.sorted()
    }
}
