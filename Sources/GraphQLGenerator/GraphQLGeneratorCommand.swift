import ArgumentParser
import Foundation
import GraphQLGeneratorCore

@main
struct GraphQLGeneratorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "graphql-generator",
        abstract: "Generate Swift code from GraphQL schema files",
        version: "0.1.0"
    )

    @Argument(help: "GraphQL schema files to process (.graphql or .gql)")
    var schemaFiles: [String]

    @Option(name: .shortAndLong, help: "Output directory for generated files")
    var outputDirectory: String

    @Flag(name: .long, help: "Enable verbose logging")
    var verbose: Bool = false

    mutating func run() throws {
        if verbose {
            print("GraphQL Generator starting...")
            print("Schema files: \(schemaFiles)")
            print("Output directory: \(outputDirectory)")
        }

        for filePath in schemaFiles {
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
        for filePath in schemaFiles {
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
}
