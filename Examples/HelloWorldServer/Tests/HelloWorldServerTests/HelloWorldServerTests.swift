import GraphQL
import Testing

@testable import HelloWorldServer

@Suite
struct HelloWorldServerTests {
    @Test func query() async throws {
        let schema = try buildGraphQLSchema(resolvers: Resolvers.self)
        let context = Context(
            users: ["1" : .init(id: "1", name: "John", email: "john@example.com", age: 18, role: .user)],
            posts: ["1" : .init(id: "1", title: "Foo", content: "bar", authorId: "1")]
        )
        #expect(
            try await graphql(
                schema: schema,
                request: """
                {
                    posts {
                        id
                        title
                        content
                        author {
                            id
                            name
                            email
                            age
                            role
                        }
                    }
                }
                """,
                context: context
            ) == .init(
                data: [
                    "posts": [
                        [
                            "id": "1",
                            "title": "Foo",
                            "content": "bar",
                            "author": [
                                "id": "1",
                                "name": "John",
                                "email": "john@example.com",
                                "age": 18,
                                "role": "USER"
                            ]
                        ]
                    ]
                ]
            )
        )
    }

    @Test func mutation() async throws {
        let schema = try buildGraphQLSchema(resolvers: Resolvers.self)
        let context = Context(
            users: [:],
            posts: [:]
        )
        #expect(
            try await graphql(
                schema: schema,
                request: """
                mutation {
                    upsertUser(userInfo: {id: "2", name: "Jane", email: "jane@example.com"}) {
                        id
                        name
                        email
                        age
                        role
                    }
                }
                """,
                context: context
            ) == .init(
                data: [
                    "upsertUser": [
                        "id": "2",
                        "name": "Jane",
                        "email": "jane@example.com",
                        "age": nil,
                        "role": nil
                    ]
                ]
            )
        )
    }
}
