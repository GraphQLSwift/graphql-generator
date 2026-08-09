import Foundation
import Testing

@testable import GraphQLGenerator

@Suite
struct GraphQLGeneratorCommandTests {
    @Test
    func testFallbackScanNoConfig() throws {
        let (outputDir, tmpRoot) = try runGenerator(files: [
            "schema.graphql": "type Query { hello: String! }"
        ])
        defer { try? FileManager.default.removeItem(at: tmpRoot) }

        let types = try String(contentsOf: outputDir.appendingPathComponent("GraphQLTypes.swift"))
        #expect(types.contains("protocol Query"))
    }

    @Test
    func testConfigWithExplicitSchemaPath() throws {
        let (outputDir, tmpRoot) = try runGenerator(
            files: [
                "schema.graphql": "type Query { hello: String! }",
                "ignored.graphql": "type Query { bogus: Int }",
            ],
            config: "schemas: [schema.graphql]\n"
        )
        defer { try? FileManager.default.removeItem(at: tmpRoot) }

        let types = try String(contentsOf: outputDir.appendingPathComponent("GraphQLTypes.swift"))
        #expect(types.contains("protocol Query"))
        #expect(!types.contains("bogus"))
    }

    @Test
    func testConfigWithDirectory() throws {
        let (outputDir, tmpRoot) = try runGenerator(
            files: [
                "api/users.graphql": "type User { name: String! }",
                "api/posts.graphql": "type Post { title: String! }",
                "legacy/old.graphql": "type Old { x: Int }",
            ],
            config: """
                schemas:
                  - api/
                """
        )
        defer { try? FileManager.default.removeItem(at: tmpRoot) }

        let types = try String(contentsOf: outputDir.appendingPathComponent("GraphQLTypes.swift"))
        #expect(types.contains("protocol User"))
        #expect(types.contains("protocol Post"))
        #expect(!types.contains("protocol Old"))
    }

    @Test
    func testConfigWithoutSchemasKey() throws {
        let (outputDir, tmpRoot) = try runGenerator(
            files: [
                "schema.graphql": "type Query { hello: String! }"
            ],
            config: "some_other_key: 42\n"
        )
        defer { try? FileManager.default.removeItem(at: tmpRoot) }

        let types = try String(contentsOf: outputDir.appendingPathComponent("GraphQLTypes.swift"))
        #expect(types.contains("protocol Query"))
    }

    @Test
    func testEmptySourceDirectoryThrows() throws {
        let tmpRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("graphql-gen-tests-\(UUID().uuidString)")
        let sourceDir = tmpRoot.appendingPathComponent("Sources")
        let outputDir = tmpRoot.appendingPathComponent("Generated")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpRoot) }

        #expect(throws: (any Error).self) {
            var command = try GraphQLGeneratorCommand.parseAsRoot([
                "--source-directory", sourceDir.path,
                "--output-directory", outputDir.path,
            ])
            try command.run()
        }
    }

    /// Creates a temporary source and output directory, writes the given files keyed by relative path, then runs the generator.
    /// Returns the output directory and the temp root (for cleanup via `defer`).
    private func runGenerator(
        files: [String: String] = [:],
        config: String? = nil
    ) throws -> (outputDir: URL, tmpRoot: URL) {
        let tmpRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("graphql-gen-tests-\(UUID().uuidString)")
        let sourceDir = tmpRoot.appendingPathComponent("Sources")
        let outputDir = tmpRoot.appendingPathComponent("Generated")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        for (relativePath, content) in files {
            let fileURL = sourceDir.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        var args = [
            "--source-directory", sourceDir.path,
            "--output-directory", outputDir.path,
        ]

        if let configContent = config {
            let configURL = sourceDir.appendingPathComponent("graphql-generator-config.yaml")
            try configContent.write(to: configURL, atomically: true, encoding: .utf8)
            args += ["--config", configURL.path]
        }

        var command = try GraphQLGeneratorCommand.parseAsRoot(args)
        try command.run()

        return (outputDir, tmpRoot)
    }
}
