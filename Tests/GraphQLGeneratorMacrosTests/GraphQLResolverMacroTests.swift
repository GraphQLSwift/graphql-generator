import GraphQLGeneratorMacrosBackend
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class GraphQLResolverMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "graphQLResolver": GraphQLResolverMacro.self,
    ]

    func testSimpleField() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                let id: String
            }
            """,
            expandedSource: """
            struct User {
                let id: String

                func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return id
                }
            }
            """,
            macros: testMacros
        )
    }

    func testMultipleFields() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                let id: String

                @graphQLResolver
                let name: String

                @graphQLResolver
                let age: Int?
            }
            """,
            expandedSource: """
            struct User {
                let id: String

                func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return id
                }
                let name: String

                func name(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return name
                }
                let age: Int?

                func age(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> Int? {
                    return age
                }
            }
            """,
            macros: testMacros
        )
    }

    func testFieldWithCustomName() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver(name: "emailAddress")
                let email: String
            }
            """,
            expandedSource: """
            struct User {
                let email: String

                func emailAddress(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return email
                }
            }
            """,
            macros: testMacros
        )
    }

    func testMixedNamedAndUnnamedFields() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                let id: String

                @graphQLResolver(name: "fullName")
                let name: String
            }
            """,
            expandedSource: """
            struct User {
                let id: String

                func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return id
                }
                let name: String

                func fullName(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return name
                }
            }
            """,
            macros: testMacros
        )
    }

    func testOptionalTypes() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                let email: String?
            }
            """,
            expandedSource: """
            struct User {
                let email: String?

                func email(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String? {
                    return email
                }
            }
            """,
            macros: testMacros
        )
    }

    func testArrayTypes() {
        assertMacroExpansion(
            """
            struct Query {
                @graphQLResolver
                let users: [User]
            }
            """,
            expandedSource: """
            struct Query {
                let users: [User]

                func users(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> [User] {
                    return users
                }
            }
            """,
            macros: testMacros
        )
    }

    func testCustomScalarTypes() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                let email: GraphQLScalars.EmailAddress
            }
            """,
            expandedSource: """
            struct User {
                let email: GraphQLScalars.EmailAddress

                func email(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> GraphQLScalars.EmailAddress {
                    return email
                }
            }
            """,
            macros: testMacros
        )
    }

    func testExistentialTypes() {
        assertMacroExpansion(
            """
            struct Query {
                @graphQLResolver
                let user: (any User)?
            }
            """,
            expandedSource: """
            struct Query {
                let user: (any User)?

                func user(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> (any User)? {
                    return user
                }
            }
            """,
            macros: testMacros
        )
    }

    func testVarProperties() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                var name: String
            }
            """,
            expandedSource: """
            struct User {
                var name: String

                func name(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return name
                }
            }
            """,
            macros: testMacros
        )
    }

    func testErrorOnMissingTypeAnnotation() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                let id = "123"
            }
            """,
            expandedSource: """
            struct User {
                let id = "123"
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@graphQLResolver requires a stored property (let/var) with an explicit type annotation",
                    line: 2,
                    column: 5
                ),
            ],
            macros: testMacros
        )
    }

    func testErrorOnNonProperty() {
        assertMacroExpansion(
            """
            @graphQLResolver
            func someFunction() {}
            """,
            expandedSource: """
            func someFunction() {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@graphQLResolver can only be applied to properties",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }

    func testComputedProperty() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                var name: String {
                    get {
                        return "Test"
                    }
                }
            }
            """,
            expandedSource: """
            struct User {
                var name: String {
                    get {
                        return "Test"
                    }
                }

                func name(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return name
                }
            }
            """,
            macros: testMacros
        )
    }

    func testThrowingComputedProperty() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                var id: String {
                    get throws {
                        try property.getID()
                    }
                }
            }
            """,
            expandedSource: """
            struct User {
                var id: String {
                    get throws {
                        try property.getID()
                    }
                }

                func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return try id
                }
            }
            """,
            macros: testMacros
        )
    }

    func testAsyncComputedProperty() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                var id: String {
                    get async {
                        await property.getID()
                    }
                }
            }
            """,
            expandedSource: """
            struct User {
                var id: String {
                    get async {
                        await property.getID()
                    }
                }

                func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return await id
                }
            }
            """,
            macros: testMacros
        )
    }

    func testThrowingAsyncComputedProperty() {
        assertMacroExpansion(
            """
            struct User {
                @graphQLResolver
                var id: String {
                    get async throws {
                        try await property.getID()
                    }
                }
            }
            """,
            expandedSource: """
            struct User {
                var id: String {
                    get async throws {
                        try await property.getID()
                    }
                }

                func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
                    return try await id
                }
            }
            """,
            macros: testMacros
        )
    }
}
