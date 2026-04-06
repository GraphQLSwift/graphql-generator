import Testing

@testable import GraphQLGeneratorCore

@Suite
struct IndentTests {
    @Test func singleLine() {
        #expect("abc".indent(1, includeFirst: false) == "abc")
        #expect("abc".indent(1, includeFirst: true) == "    abc")
        #expect("abc".indent(2, includeFirst: true) == "        abc")
    }

    @Test func multiLine() {
        #expect(
            """
            abc
            def
            """.indent(1, includeFirst: false)
                == """
                abc
                    def
                """
        )
        #expect(
            """
            abc
            def
            """.indent(1, includeFirst: true)
                == """
                    abc
                    def
                """
        )
    }
}
