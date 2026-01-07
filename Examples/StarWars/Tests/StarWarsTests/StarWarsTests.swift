import GraphQL
@testable import StarWars
import Testing

@Suite("display name")
struct StarWarsTests {
    @Test func film() async throws {
        let client = SwapiClient(client: .shared)

        let schema = try buildGraphQLSchema(resolvers: Resolvers.self)
        let context = GraphQLContext(client: client)
        try await print(
            graphql(
                schema: schema,
                request: """
                {
                    film(filmID: 1) {
                        title
                        planetConnection(first: 2) {
                            totalCount
                            edges {
                                node {
                                    id
                                    name
                                    diameter
                                }
                            }
                        }
                        vehicleConnection(first: 2) {
                            totalCount
                            edges {
                                node {
                                    id
                                    name
                                    costInCredits
                                }
                            }
                        }
                    }
                }
                """,
                context: context
            )
        )
    }

    @Test func allPeople() async throws {
        let client = SwapiClient(client: .shared)

        let schema = try buildGraphQLSchema(resolvers: Resolvers.self)
        let context = GraphQLContext(client: client)
        try await print(
            graphql(
                schema: schema,
                request: """
                {
                    allPeople(first: 3) {
                        totalCount
                        edges {
                            node {
                                id
                                name
                                starshipConnection {
                                    totalCount
                                    edges {
                                        node {
                                            id
                                            name
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                """,
                context: context
            )
        )
    }
}
