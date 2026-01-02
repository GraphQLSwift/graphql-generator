import GraphQL
@testable import GraphQLGeneratorCore
import Testing

@Suite
struct TypeGeneratorTests {
    let generator = GraphQLTypesGenerator()

    // MARK: - Enum Tests

    @Test func generateEnum() async throws {
        let actual = try generator.generateEnum(
            for: .init(
                name: "Foo",
                description: "foo",
                values: [
                    "foo": .init(
                        value: .string("foo"),
                        description: "foo"
                    ),
                    "bar": .init(
                        value: .string("bar"),
                        description: "bar"
                    ),
                    "baz": .init(
                        value: .string("baz")
                    ),
                ]
            )
        )
        #expect(
            actual == """

            /// foo
            enum Foo: String, Codable, Sendable {
                /// foo
                case foo = "foo"
                /// bar
                case bar = "bar"
                case baz = "baz"
            }
            """
        )
    }

    @Test func generateInputStruct() throws {
        let inputType = try GraphQLInputObjectType(
            name: "CreateUserInput",
            description: "Input for creating a new user",
            fields: [
                "name": InputObjectField(
                    type: GraphQLNonNull(GraphQLString),
                    description: "User's full name"
                ),
                "email": InputObjectField(
                    type: GraphQLNonNull(GraphQLString)
                ),
                "age": InputObjectField(
                    type: GraphQLInt,
                    description: "User's age"
                ),
            ]
        )

        let result = try generator.generateInputStruct(for: inputType)

        let expected = """

        /// Input for creating a new user
        struct CreateUserInput: Codable, Sendable {
            /// User's full name
            let name: String
            let email: String
            /// User's age
            let age: Int?
        }
        """

        #expect(result == expected)
    }

    @Test func generateInputStructWithRecursiveTypes() throws {
        let addressInput = try GraphQLInputObjectType(
            name: "AddressInput"
        )
        let personInput = try GraphQLInputObjectType(
            name: "PersonInput"
        )
        personInput.fields = {
            [
                "name": InputObjectField(type: GraphQLNonNull(GraphQLString)),
                "address": InputObjectField(type: addressInput),
                "friends": InputObjectField(type: GraphQLList(personInput)),
            ]
        }

        let result = try generator.generateInputStruct(for: personInput)

        let expected = """

        struct PersonInput: Codable, Sendable {
            let name: String
            let address: AddressInput?
            let friends: [PersonInput]?
        }
        """

        #expect(result == expected)
    }

    @Test func generateInputStructWithCustomScalar() throws {
        let phoneNumber: GraphQLScalarType = try GraphQLScalarType(
            name: "PhoneNumber"
        )
        let personInput = try GraphQLInputObjectType(
            name: "PersonInput"
        )
        personInput.fields = {
            [
                "cellPhone": InputObjectField(type: GraphQLNonNull(phoneNumber)),
                "homePhone": InputObjectField(type: phoneNumber),
                "familyPhones": InputObjectField(type: GraphQLList(phoneNumber)),
            ]
        }

        let result = try generator.generateInputStruct(for: personInput)

        let expected = """

        struct PersonInput: Codable, Sendable {
            let cellPhone: GraphQLScalars.PhoneNumber
            let homePhone: GraphQLScalars.PhoneNumber?
            let familyPhones: [GraphQLScalars.PhoneNumber]?
        }
        """

        #expect(result == expected)
    }

    @Test func generateInterfaceProtocol() async throws {
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
                    description: "baz",
                    args: [
                        "arg1": GraphQLArgument(
                            type: GraphQLNonNull(GraphQLString)
                        ),
                        "arg2": GraphQLArgument(
                            type: GraphQLInt
                        ),
                    ]
                ),
            ]
        )
        let actual = try GraphQLTypesGenerator().generateInterfaceProtocol(for: interfaceB)
        #expect(
            actual == """

            /// B
            protocol B: A, Sendable {
                /// foo
                func foo(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String

                /// baz
                func baz(arg1: String, arg2: Int?, context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String?

            }
            """
        )
    }

    @Test func generateTypeProtocol() async throws {
        let interfaceA = try GraphQLInterfaceType(
            name: "A",
            description: "A"
        )
        let scalar = try GraphQLScalarType(name: "Scalar")
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
                            type: GraphQLNonNull(GraphQLString)
                        ),
                        "bar": .init(
                            type: GraphQLString,
                            defaultValue: .string("bar")
                        ),
                    ]
                ),
                "baz": .init(
                    type: scalar,
                    description: "baz",
                    args: [
                        "baz": .init(
                            type: GraphQLNonNull(scalar)
                        ),
                    ]
                ),
            ],
            interfaces: [interfaceA]
        )
        let actual = try GraphQLTypesGenerator().generateTypeProtocol(
            for: typeFoo,
            unionTypeMap: [
                "Foo": [GraphQLUnionType(name: "X", types: [typeFoo])],
            ]
        )
        #expect(
            actual == """

            /// Foo
            protocol Foo: X, A, Sendable {
                /// foo
                func foo(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String

                /// bar
                func bar(foo: String, bar: String?, context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String?

                /// baz
                func baz(baz: GraphQLScalars.Scalar, context: GraphQLContext, info: GraphQLResolveInfo) async throws -> GraphQLScalars.Scalar?

            }
            """
        )
    }

    @Test func generateRootTypeProtocolForQuery() async throws {
        let bar = try GraphQLObjectType(
            name: "Bar",
            description: "bar",
            fields: [
                "foo": .init(
                    type: GraphQLString,
                    description: "foo"
                ),
            ]
        )
        let query = try GraphQLObjectType(
            name: "Query",
            fields: [
                "foo": .init(
                    type: GraphQLString,
                    description: "foo"
                ),
                "bar": .init(
                    type: bar,
                    description: "bar"
                ),
            ]
        )
        let actual = try GraphQLTypesGenerator().generateRootTypeProtocol(for: query)
        #expect(
            actual == """

            protocol Query: Sendable {
                /// foo
                static func foo(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String?

                /// bar
                static func bar(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> (any Bar)?

            }
            """
        )
    }

    @Test func generateRootTypeProtocolForMutation() throws {
        let mutationType: GraphQLObjectType = try GraphQLObjectType(
            name: "Mutation",
            description: "Mutations",
            fields: [
                "createUser": GraphQLField(
                    type: GraphQLString,
                    description: "Create a new user",
                    args: [
                        "name": GraphQLArgument(type: GraphQLNonNull(GraphQLString)),
                        "email": GraphQLArgument(type: GraphQLNonNull(GraphQLString)),
                    ]
                ),
                "deleteUser": GraphQLField(
                    type: GraphQLBoolean,
                    description: "Delete a user",
                    args: [
                        "id": GraphQLArgument(type: GraphQLNonNull(GraphQLID)),
                    ]
                ),
            ]
        )

        let result = try generator.generateRootTypeProtocol(for: mutationType)

        let expected = """

        /// Mutations
        protocol Mutation: Sendable {
            /// Create a new user
            static func createUser(name: String, email: String, context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String?

            /// Delete a user
            static func deleteUser(id: String, context: GraphQLContext, info: GraphQLResolveInfo) async throws -> Bool?

        }
        """

        #expect(result == expected)
    }

    @Test func generateRootTypeProtocolForSubscription() async throws {
        let subscription = try GraphQLObjectType(
            name: "Subscription",
            fields: [
                "watchThis": .init(
                    type: GraphQLString,
                    description: "foo",
                    args: [
                        "id": .init(
                            type: GraphQLString
                        ),
                    ]
                ),
            ]
        )
        let actual = try generator.generateRootTypeProtocol(for: subscription)
        #expect(
            actual == """

            protocol Subscription: Sendable {
                /// foo
                static func watchThis(id: String?, context: GraphQLContext, info: GraphQLResolveInfo) async throws -> AnyAsyncSequence<String?>

            }
            """
        )
    }
}
