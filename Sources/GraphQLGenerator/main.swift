import Foundation
import ArgumentParser
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

        // Validate input files exist
        for filePath in schemaFiles {
            let fileURL = URL(fileURLWithPath: filePath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw ValidationError("Schema file not found: \(filePath)")
            }
        }

        // Create output directory if it doesn't exist
        let outputURL = URL(fileURLWithPath: outputDirectory)
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        if verbose {
            print("Parsing schema files...")
        }

        // Parse schema files
        let parser = SchemaParser()
        let schema = try parser.parseSchemaFiles(schemaFiles)

        if verbose {
            print("Schema parsed successfully")
            print("Generating Swift code...")
        }

        // Generate code
        let generator = CodeGenerator(schema: schema)
        let generatedFiles = try generator.generate()

        // Write generated files
        for (filename, content) in generatedFiles {
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
