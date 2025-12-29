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

    @Test func interfaceType() async throws {
        let interfaceA = try GraphQLInterfaceType(
            name: "A",
            description: "A"
        )
        let interfaceB = try GraphQLInterfaceType(
            name: "B",
            description: "B",
            interfaces: [
                interfaceA,
            ],
            fields: [
                "foo": .init(
                    type: GraphQLNonNull(GraphQLString),
                    description: "foo"
                ),
                "baz": .init(
                    type: GraphQLString,
                    description: "baz"
                )
            ]
        )
        let actual = try TypeGenerator().generateInterfaceProtocol(for: interfaceB)
        #expect(
            actual == """

            /// B
            public protocol BInterface: AInterface, Sendable {
                /// foo
                func foo(context: Context, info: GraphQLResolveInfo) async throws -> String

                /// baz
                func baz(context: Context, info: GraphQLResolveInfo) async throws -> String?

            }
            """
        )
    }

    @Test func objectType() async throws {
        let interfaceA = try GraphQLInterfaceType(
            name: "A",
            description: "A"
        )
        let typeFoo = try GraphQLObjectType(
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
            ],
            interfaces: [interfaceA],
        )
        let actual = try TypeGenerator().generateTypeProtocol(
            for: typeFoo,
            unionTypeMap: [
                "Foo": [GraphQLUnionType(name: "X", types: [typeFoo])]
            ]
        )
        #expect(
            actual == """

            /// Foo
            public protocol FooProtocol: XUnion, AInterface, Sendable {
                /// foo
                func foo(context: Context, info: GraphQLResolveInfo) async throws -> String

                /// bar
                func bar(foo: String, bar: String?, context: Context, info: GraphQLResolveInfo) async throws -> String?

            }
            """
        )
    }

    @Test func queryType() async throws {
        let bar = try GraphQLObjectType(
            name: "Bar",
            description: "bar",
            fields: [
                "foo": .init(
                    type: GraphQLString,
                    description: "foo",
                ),
            ]
        )
        let query = try GraphQLObjectType(
            name: "Query",
            fields: [
                "foo": .init(
                    type: GraphQLString,
                    description: "foo",
                ),
                "bar": .init(
                    type: bar,
                    description: "bar",
                )
            ]
        )
        let actual = try TypeGenerator().generateRootTypeProtocol(for: query)
        #expect(
            actual == """

            public protocol QueryProtocol: Sendable {
                /// foo
                static func foo(context: Context, info: GraphQLResolveInfo) async throws -> String?

                /// bar
                static func bar(context: Context, info: GraphQLResolveInfo) async throws -> (any BarProtocol)?

            }
            """
        )
    }


    @Test func subscriptionType() async throws {
        let subscription = try GraphQLObjectType(
            name: "Subscription",
            fields: [
                "watchThis": .init(
                    type: GraphQLString,
                    description: "foo",
                    args: [
                        "id": .init(
                            type: GraphQLString,
                        )
                    ]
                )
            ]
        )
        let actual = try TypeGenerator().generateRootTypeProtocol(for: subscription)
        #expect(
            actual == """

            public protocol SubscriptionProtocol: Sendable {
                /// foo
                static func watchThis(id: String?, context: Context, info: GraphQLResolveInfo) async throws -> AnyAsyncSequence<String?>

            }
            """
        )
    }
}
