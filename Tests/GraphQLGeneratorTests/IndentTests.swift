@testable import GraphQLGeneratorCore
import Testing

@Suite
struct IndentTests {
    @Test func singleLine() async throws {
        #expect("abc".indent(1, includeFirst: false) == "abc")
        #expect("abc".indent(1, includeFirst: true) == "    abc")
        #expect("abc".indent(2, includeFirst: true) == "        abc")
    }

    @Test func multiLine() async throws {
        #expect(
            """
            abc
            def
            """.indent(1, includeFirst: false)
            ==
            """
            abc
                def
            """
        )
        #expect(
            """
            abc
            def
            """.indent(1, includeFirst: true)
            ==
            """
                abc
                def
            """
        )
    }
}
