import GraphQL
@testable import GraphQLGeneratorCore
import Testing

@Suite
struct TypeGeneratorTests {
    @Test func enumType() async throws {
        let actual = try TypeGenerator().generateEnum(
            for: .init(
                name: "Foo",
                description: "foo",
                values: [
                    "foo": .init(
                        value: .string("foo"),
                        description: "foo",
                    ),
                    "bar": .init(
                        value: .string("bar"),
                        description: "bar",
                    )
                ]
            )
        )
        #expect(
            actual == """
            /// foo
            public enum Foo: String, Codable, Sendable {
                /// foo
                case foo = "foo"
                /// bar
                case bar = "bar"
            }

            """
        )
    }

    @Test func objectType() async throws {
        let actual = try TypeGenerator().generateTypeProtocol(
            for: .init(
                name: "Foo",
                description: "Foo",
                fields: [
                    "foo": .init(
                        type: GraphQLNonNull(GraphQLString),
                        description: "foo"
                    ),
                    "bar": .init(
                        type: GraphQLString,
                        description: "bar",
                        args: [
                            "foo": .init(
                                type: GraphQLNonNull(GraphQLString),
                                description: "foo",
                            ),
                            "bar": .init(
                                type: GraphQLString,
                                description: "bar",
                                defaultValue: .string("bar"),
                            ),
                        ]
                    )
                ]
            )
        )
        #expect(
            actual == """
            /// Foo
            public protocol FooProtocol: Sendable {
                /// foo
                public func foo(context: ResolverContext, info: GraphQLResolveInfo) async throws -> String

                /// bar
                public func bar(foo: String, bar: String?, context: ResolverContext, info: GraphQLResolveInfo) async throws -> String?

            }

            """
        )
    }

}
