import Foundation
import GraphQL

/// Encodes a SWAPI type and ID into a Relay Node ID. This is the base64-encoded string `<type>:<id>`
/// - Parameters:
///   - type: The SWAPI type of the resource
///   - id: The SWAPI id of the resource
/// - Returns: The Relay ID of the resouce
func encodeID(type: SwapiResource.Type, id: any StringProtocol) -> String {
    let idData = "\(type.type.rawValue):\(id)".data(using: .utf8)!
    return idData.base64EncodedString()
}

/// Decodes a Relay ID into the SWAPI type and ID
/// - Parameter string: The Relay ID of the resouce
/// - Returns: A tuple containing the SWAPI type and ID of the resource
func decodeID(_ string: String) -> (type: SwapiResourceType, id: String) {
    let typeAndId = String(data: Data(base64Encoded: string)!, encoding: .utf8)!
    let split = typeAndId.split(separator: ":")
    return (SwapiResourceType(rawValue: String(split.first!))!, String(split.last!))
}

/// Given a SWAPI resource url, extract the resource ID
func urlToID(_ url: String) -> String {
    return String(url.split(separator: "/").last!)
}

struct PageInfo: GraphQLGenerated.PageInfo {
    let hasNextPage: Bool
    let hasPreviousPage: Bool
    let startCursor: String?
    let endCursor: String?

    func hasNextPage(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Bool {
        return hasNextPage
    }

    func hasPreviousPage(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Bool {
        return hasPreviousPage
    }

    func startCursor(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return startCursor
    }

    func endCursor(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return endCursor
    }
}

/// A generalized Relay connection.
struct Connection<T: GraphQLGenerated.Node>: Sendable {
    let pageInfo: PageInfo
    let edges: [Edge<T>]
    let totalCount: Int

    /// Create a connection by passing a total list of the available IDs in order.
    init(ids: [String], after: String?, first: Int?, before: String?, last: Int?) {
        guard !ids.isEmpty else {
            pageInfo = PageInfo(
                hasNextPage: false,
                hasPreviousPage: false,
                startCursor: nil,
                endCursor: nil
            )
            edges = []
            totalCount = 0
            return
        }

        var startIndex = 0
        var endIndex = ids.count - 1
        if let after {
            ids.firstIndex { after < $0 }.map { startIndex = $0 }
        }
        if let before {
            ids.lastIndex { $0 < before }.map { endIndex = $0 }
        }
        if let first {
            endIndex = min(startIndex + first, endIndex)
        }
        if let last {
            startIndex = max(endIndex - last, startIndex)
        }
        let pageIds = ids[startIndex ... endIndex]

        pageInfo = PageInfo(
            hasNextPage: endIndex < ids.count - 1,
            hasPreviousPage: startIndex > 0,
            startCursor: ids[startIndex],
            endCursor: ids[endIndex]
        )
        edges = pageIds.map { Edge<T>(cursor: $0) }
        totalCount = ids.count
    }

    func pageInfo(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> any GraphQLGenerated.PageInfo {
        return pageInfo
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [Edge<T>]? {
        return edges
    }

    func totalCount(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return totalCount
    }
}

extension Connection:
    GraphQLGenerated.FilmsConnection,
    GraphQLGenerated.PersonFilmsConnection,
    GraphQLGenerated.PlanetFilmsConnection,
    GraphQLGenerated.SpeciesFilmsConnection,
    GraphQLGenerated.StarshipFilmsConnection,
    GraphQLGenerated.VehicleFilmsConnection
    where T: GraphQLGenerated.Film
{
    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.FilmsEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.PersonFilmsEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.PlanetFilmsEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.SpeciesFilmsEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.StarshipFilmsEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.VehicleFilmsEdge]? {
        return edges
    }

    func films(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Film]? {
        return try await nodes(context: context, info: info)
    }

    private func nodes(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Film]? {
        var nodes = [GraphQLGenerated.Film]()
        for edge in edges {
            if let node = try await edge.node(context: context, info: info) {
                nodes.append(node)
            }
        }
        return nodes
    }
}

extension Connection:
    GraphQLGenerated.PeopleConnection,
    GraphQLGenerated.FilmCharactersConnection,
    GraphQLGenerated.PlanetResidentsConnection,
    GraphQLGenerated.SpeciesPeopleConnection,
    GraphQLGenerated.StarshipPilotsConnection,
    GraphQLGenerated.VehiclePilotsConnection
    where T: GraphQLGenerated.Person
{
    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.PeopleEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.FilmCharactersEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.PlanetResidentsEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.SpeciesPeopleEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.StarshipPilotsEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.VehiclePilotsEdge]? {
        return edges
    }

    func people(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Person]? {
        return try await nodes(context: context, info: info)
    }

    func characters(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Person]? {
        return try await nodes(context: context, info: info)
    }

    func residents(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Person]? {
        return try await nodes(context: context, info: info)
    }

    func pilots(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Person]? {
        return try await nodes(context: context, info: info)
    }

    private func nodes(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Person]? {
        var nodes = [GraphQLGenerated.Person]()
        for edge in edges {
            if let node = try await edge.node(context: context, info: info) {
                nodes.append(node)
            }
        }
        return nodes
    }
}

extension Connection:
    GraphQLGenerated.PlanetsConnection,
    GraphQLGenerated.FilmPlanetsConnection
    where T: GraphQLGenerated.Planet
{
    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.PlanetsEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.FilmPlanetsEdge]? {
        return edges
    }

    func planets(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Planet]? {
        return try await nodes(context: context, info: info)
    }

    private func nodes(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Planet]? {
        var nodes = [GraphQLGenerated.Planet]()
        for edge in edges {
            if let node = try await edge.node(context: context, info: info) {
                nodes.append(node)
            }
        }
        return nodes
    }
}

extension Connection:
    GraphQLGenerated.SpeciesConnection,
    GraphQLGenerated.FilmSpeciesConnection
    where T: GraphQLGenerated.Species
{
    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.SpeciesEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.FilmSpeciesEdge]? {
        return edges
    }

    func species(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Species]? {
        return try await nodes(context: context, info: info)
    }

    private func nodes(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Species]? {
        var nodes = [GraphQLGenerated.Species]()
        for edge in edges {
            if let node = try await edge.node(context: context, info: info) {
                nodes.append(node)
            }
        }
        return nodes
    }
}

extension Connection:
    GraphQLGenerated.StarshipsConnection,
    GraphQLGenerated.FilmStarshipsConnection,
    GraphQLGenerated.PersonStarshipsConnection
    where T: GraphQLGenerated.Starship
{
    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.StarshipsEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.FilmStarshipsEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.PersonStarshipsEdge]? {
        return edges
    }

    func starships(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Starship]? {
        return try await nodes(context: context, info: info)
    }

    private func nodes(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Starship]? {
        var nodes = [GraphQLGenerated.Starship]()
        for edge in edges {
            if let node = try await edge.node(context: context, info: info) {
                nodes.append(node)
            }
        }
        return nodes
    }
}

extension Connection:
    GraphQLGenerated.VehiclesConnection,
    GraphQLGenerated.FilmVehiclesConnection,
    GraphQLGenerated.PersonVehiclesConnection
    where T: GraphQLGenerated.Vehicle
{
    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.VehiclesEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.FilmVehiclesEdge]? {
        return edges
    }

    func edges(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.PersonVehiclesEdge]? {
        return edges
    }

    func vehicles(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Vehicle]? {
        return try await nodes(context: context, info: info)
    }

    private func nodes(context: GraphQLContext, info: GraphQL.GraphQLResolveInfo) async throws -> [any GraphQLGenerated.Vehicle]? {
        var nodes = [GraphQLGenerated.Vehicle]()
        for edge in edges {
            if let node = try await edge.node(context: context, info: info) {
                nodes.append(node)
            }
        }
        return nodes
    }
}

struct Edge<T: GraphQLGenerated.Node>: Sendable {
    let cursor: String

    func cursor(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return cursor
    }
}

extension Edge:
    GraphQLGenerated.FilmsEdge,
    GraphQLGenerated.PersonFilmsEdge,
    GraphQLGenerated.PlanetFilmsEdge,
    GraphQLGenerated.SpeciesFilmsEdge,
    GraphQLGenerated.StarshipFilmsEdge,
    GraphQLGenerated.VehicleFilmsEdge
    where T: GraphQLGenerated.Film
{
    func node(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Film)? {
        let (_, id) = decodeID(cursor)
        return try await context.client.get(type: Film.self, id: id)
    }
}

extension Edge:
    GraphQLGenerated.PeopleEdge,
    GraphQLGenerated.FilmCharactersEdge,
    GraphQLGenerated.PlanetResidentsEdge,
    GraphQLGenerated.SpeciesPeopleEdge,
    GraphQLGenerated.StarshipPilotsEdge,
    GraphQLGenerated.VehiclePilotsEdge
    where T: GraphQLGenerated.Person
{
    func node(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Person)? {
        let (_, id) = decodeID(cursor)
        return try await context.client.get(type: Person.self, id: id)
    }
}

extension Edge:
    GraphQLGenerated.PlanetsEdge,
    GraphQLGenerated.FilmPlanetsEdge
    where T: GraphQLGenerated.Planet
{
    func node(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Planet)? {
        let (_, id) = decodeID(cursor)
        return try await context.client.get(type: Planet.self, id: id)
    }
}

extension Edge:
    GraphQLGenerated.SpeciesEdge,
    GraphQLGenerated.FilmSpeciesEdge
    where T: GraphQLGenerated.Species
{
    func node(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Species)? {
        let (_, id) = decodeID(cursor)
        return try await context.client.get(type: Species.self, id: id)
    }
}

extension Edge:
    GraphQLGenerated.StarshipsEdge,
    GraphQLGenerated.FilmStarshipsEdge,
    GraphQLGenerated.PersonStarshipsEdge
    where T: GraphQLGenerated.Starship
{
    func node(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Starship)? {
        let (_, id) = decodeID(cursor)
        return try await context.client.get(type: Starship.self, id: id)
    }
}

extension Edge:
    GraphQLGenerated.VehiclesEdge,
    GraphQLGenerated.FilmVehiclesEdge,
    GraphQLGenerated.PersonVehiclesEdge
    where T: GraphQLGenerated.Vehicle
{
    func node(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Vehicle)? {
        let (_, id) = decodeID(cursor)
        return try await context.client.get(type: Vehicle.self, id: id)
    }
}
