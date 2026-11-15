import GraphQL
import Testing

@testable import HelloWorldServer

@Suite
struct HelloWorldServerTests {
    @Test func query() async throws {
        let schema = try buildGraphQLSchema(resolvers: Resolvers.self)
        let context = GraphQLContext(
            users: [
                "1": .init(id: "1", name: "John", age: 18, role: .user, email: "john@example.com")
            ],
            posts: ["1": .init(id: "1", title: "Foo", content: "bar", authorId: "1")]
        )
        let actual = try await graphql(
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
        )
        let expected = GraphQLResult(
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
                            "role": "USER",
                        ],
                    ]
                ]
            ]
        )
        #expect(actual == expected)
    }

    @Test func mutation() async throws {
        let schema = try buildGraphQLSchema(resolvers: Resolvers.self)
        let context = GraphQLContext(
            users: [:],
            posts: [:]
        )
        let actual = try await graphql(
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
        )
        let expected = GraphQLResult(
            data: [
                "upsertUser": [
                    "id": "2",
                    "name": "Jane",
                    "email": "jane@example.com",
                    "age": nil,
                    "role": "USER",
                ]
            ]
        )
        #expect(actual == expected)
    }

    @Test func subscription() async throws {
        let schema = try buildGraphQLSchema(resolvers: Resolvers.self)
        let context = GraphQLContext(
            users: [
                "1": .init(id: "1", name: "John", age: 18, role: .user, email: "john@example.com")
            ],
            posts: [:]
        )
        let stream = try await graphqlSubscribe(
            schema: schema,
            request: """
                subscription {
                    watchUser(id: "1") {
                        id
                        name
                        email
                        age
                        role
                    }
                }
                """,
            context: context
        ).get()

        var iterator = stream.makeAsyncIterator()

        context.triggerWatch()
        #expect(
            try await iterator.next()
                == GraphQLResult(
                    data: [
                        "watchUser": [
                            "id": "1",
                            "name": "John",
                            "email": "john@example.com",
                            "age": 18,
                            "role": "USER",
                        ]
                    ]
                )
        )

        context.triggerWatch()
        #expect(
            try await iterator.next()
                == GraphQLResult(
                    data: [
                        "watchUser": [
                            "id": "1",
                            "name": "John",
                            "email": "john@example.com",
                            "age": 18,
                            "role": "USER",
                        ]
                    ]
                )
        )
    }
    
    @Test func subscriptionUnion() async throws {
        let schema = try buildGraphQLSchema(resolvers: Resolvers.self)
        let context = GraphQLContext(
            users: [
                "user_1": .init(id: "user_1", name: "John", age: 18, role: .user, email: "john@example.com")
            ],
            posts: [
                "post_1": .init(id: "post_1", title: "Foo", content: "bar", authorId: "1")
            ]
        )
        let stream = try await graphqlSubscribe(
            schema: schema,
            request: """
                subscription {
                    watchUserOrPost(id: "post_1") {
                        ... on User {
                            id
                            name
                            email
                            age
                            role
                        }
                        ... on Post {
                            id
                            title
                            content
                        }
                    }
                }
                """,
            context: context
        ).get()

        var iterator = stream.makeAsyncIterator()

        context.triggerWatch()
        #expect(
            try await iterator.next()
                == GraphQLResult(
                    data: [
                        "watchUserOrPost": [
                            "id": "post_1",
                            "title": "Foo",
                            "content": "bar",
                        ]
                    ]
                )
        )
    }
}
