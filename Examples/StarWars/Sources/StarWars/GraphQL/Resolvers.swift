import AsyncHTTPClient
import Foundation
import GraphQL
import GraphQLGeneratorRuntime

struct GraphQLContext {
    /// A client for fetching SWAPI data. Since the data is not expected to change, this client may be shared
    /// across context instances, which are typically created fresh for every GraphQL query.
    let client: SwapiClient
}

struct Resolvers: GraphQLGenerated.Resolvers {
    typealias Query = Root
}

struct Root: GraphQLGenerated.Root {
    static func allFilms(after: String?, first: Int?, before: String?, last: Int?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.FilmsConnection)? {
        let allIDs = try await context.client.getAllIDs(type: Film.self)
        return Connection<Film>(ids: allIDs, after: after, first: first, before: before, last: last)
    }

    static func film(id: String?, filmID: String?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Film)? {
        if let filmID {
            return try await context.client.get(type: Film.self, id: filmID)
        } else if let id {
            let (_, itemID) = decodeID(id)
            return try await context.client.get(type: Film.self, id: itemID)
        } else {
            return nil
        }
    }

    static func allPeople(after: String?, first: Int?, before: String?, last: Int?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.PeopleConnection)? {
        let allIDs = try await context.client.getAllIDs(type: Person.self)
        return Connection<Person>(ids: allIDs, after: after, first: first, before: before, last: last)
    }

    static func person(id: String?, personID: String?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Person)? {
        if let personID {
            return try await context.client.get(type: Person.self, id: personID)
        } else if let id {
            let (_, itemID) = decodeID(id)
            return try await context.client.get(type: Person.self, id: itemID)
        } else {
            return nil
        }
    }

    static func allPlanets(after: String?, first: Int?, before: String?, last: Int?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.PlanetsConnection)? {
        let allIDs = try await context.client.getAllIDs(type: Planet.self)
        return Connection<Planet>(ids: allIDs, after: after, first: first, before: before, last: last)
    }

    static func planet(id: String?, planetID: String?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Planet)? {
        if let planetID {
            return try await context.client.get(type: Planet.self, id: planetID)
        } else if let id {
            let (_, itemID) = decodeID(id)
            return try await context.client.get(type: Planet.self, id: itemID)
        } else {
            return nil
        }
    }

    static func allSpecies(after: String?, first: Int?, before: String?, last: Int?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.SpeciesConnection)? {
        let allIDs = try await context.client.getAllIDs(type: Species.self)
        return Connection<Species>(ids: allIDs, after: after, first: first, before: before, last: last)
    }

    static func species(id: String?, speciesID: String?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Species)? {
        if let speciesID {
            return try await context.client.get(type: Species.self, id: speciesID)
        } else if let id {
            let (_, itemID) = decodeID(id)
            return try await context.client.get(type: Species.self, id: itemID)
        } else {
            return nil
        }
    }

    static func allStarships(after: String?, first: Int?, before: String?, last: Int?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.StarshipsConnection)? {
        let allIDs = try await context.client.getAllIDs(type: Starship.self)
        return Connection<Starship>(ids: allIDs, after: after, first: first, before: before, last: last)
    }

    static func starship(id: String?, starshipID: String?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Starship)? {
        if let starshipID {
            return try await context.client.get(type: Starship.self, id: starshipID)
        } else if let id {
            let (_, itemID) = decodeID(id)
            return try await context.client.get(type: Starship.self, id: itemID)
        } else {
            return nil
        }
    }

    static func allVehicles(after: String?, first: Int?, before: String?, last: Int?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.VehiclesConnection)? {
        let allIDs = try await context.client.getAllIDs(type: Vehicle.self)
        return Connection<Vehicle>(ids: allIDs, after: after, first: first, before: before, last: last)
    }

    static func vehicle(id: String?, vehicleID: String?, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Vehicle)? {
        if let vehicleID {
            return try await context.client.get(type: Vehicle.self, id: vehicleID)
        } else if let id {
            let (_, itemID) = decodeID(id)
            return try await context.client.get(type: Vehicle.self, id: itemID)
        } else {
            return nil
        }
    }

    static func node(id: String, context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Node)? {
        let (type, itemID) = decodeID(id)
        switch type {
        case .films:
            return try await context.client.get(type: Film.self, id: itemID)
        case .people:
            return try await context.client.get(type: Person.self, id: itemID)
        case .planets:
            return try await context.client.get(type: Planet.self, id: itemID)
        case .species:
            return try await context.client.get(type: Species.self, id: itemID)
        case .starships:
            return try await context.client.get(type: Starship.self, id: itemID)
        case .vehicles:
            return try await context.client.get(type: Vehicle.self, id: itemID)
        }
    }
}

extension Film: GraphQLGenerated.Film {
    var id: String {
        return encodeID(type: Film.self, id: urlToID(url))
    }

    func title(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return title
    }

    func episodeID(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return episode_id
    }

    func openingCrawl(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return opening_crawl
    }

    func director(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return director
    }

    func producers(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [String]? {
        return producer.split(separator: ",").map { String($0) }
    }

    func releaseDate(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return release_date
    }

    func created(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return created
    }

    func edited(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return edited
    }

    func id(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }

    func speciesConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.FilmSpeciesConnection)? {
        let filteredIDs = species.map { encodeID(type: Film.self, id: urlToID($0)) }
        return Connection<Species>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func starshipConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.FilmStarshipsConnection)? {
        let filteredIDs = starships.map { encodeID(type: Starship.self, id: urlToID($0)) }
        return Connection<Starship>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func vehicleConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.FilmVehiclesConnection)? {
        let filteredIDs = vehicles.map { encodeID(type: Vehicle.self, id: urlToID($0)) }
        return Connection<Vehicle>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func characterConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.FilmCharactersConnection)? {
        let filteredIDs = characters.map { encodeID(type: Person.self, id: urlToID($0)) }
        return Connection<Person>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func planetConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.FilmPlanetsConnection)? {
        let filteredIDs = planets.map { encodeID(type: Planet.self, id: urlToID($0)) }
        return Connection<Planet>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }
}

extension Person: GraphQLGenerated.Person {
    var id: String {
        return encodeID(type: Person.self, id: urlToID(url))
    }

    func name(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return name
    }

    func birthYear(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return birth_year
    }

    func eyeColor(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return eye_color
    }

    func gender(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return gender
    }

    func hairColor(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return hair_color
    }

    func height(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return Int(height)
    }

    func mass(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(mass)
    }

    func skinColor(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return skin_color
    }

    func homeworld(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Planet)? {
        try await context.client.get(type: Planet.self, id: urlToID(homeworld))
    }

    func filmConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.PersonFilmsConnection)? {
        let filteredIDs = films.map { encodeID(type: Film.self, id: urlToID($0)) }
        return Connection<Film>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func species(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Species)? {
        guard let firstSpecies = species?.first else {
            return nil
        }
        return try await context.client.get(type: Species.self, id: urlToID(firstSpecies))
    }

    func starshipConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.PersonStarshipsConnection)? {
        let filteredIDs = starships.map { encodeID(type: Starship.self, id: urlToID($0)) }
        return Connection<Starship>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func vehicleConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.PersonVehiclesConnection)? {
        let filteredIDs = vehicles.map { encodeID(type: Vehicle.self, id: urlToID($0)) }
        return Connection<Vehicle>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func created(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return created
    }

    func edited(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return edited
    }

    func id(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
}

extension Planet: GraphQLGenerated.Planet {
    var id: String {
        return encodeID(type: Planet.self, id: urlToID(url))
    }

    func name(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return name
    }

    func diameter(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return Int(diameter)
    }

    func rotationPeriod(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return Int(rotation_period)
    }

    func orbitalPeriod(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return Int(orbital_period)
    }

    func gravity(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return gravity
    }

    func population(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(population)
    }

    func climates(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [String]? {
        return climate.split(separator: ",").map { String($0) }
    }

    func terrains(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [String]? {
        return terrain.split(separator: ",").map { String($0) }
    }

    func surfaceWater(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(surface_water)
    }

    func residentConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.PlanetResidentsConnection)? {
        let filteredIDs = residents?.map { encodeID(type: Person.self, id: urlToID($0)) } ?? []
        return Connection<Person>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func filmConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.PlanetFilmsConnection)? {
        let filteredIDs = films?.map { encodeID(type: Film.self, id: urlToID($0)) } ?? []
        return Connection<Film>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func created(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return created
    }

    func edited(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return edited
    }

    func id(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
}

extension Species: GraphQLGenerated.Species {
    var id: String {
        return encodeID(type: Species.self, id: urlToID(url))
    }

    func name(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return name
    }

    func classification(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return classification
    }

    func designation(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return designation
    }

    func averageHeight(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(average_height)
    }

    func averageLifespan(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return Int(average_lifespan)
    }

    func eyeColors(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [String]? {
        return eye_colors.split(separator: ",").map { String($0) }
    }

    func hairColors(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [String]? {
        return hair_colors.split(separator: ",").map { String($0) }
    }

    func skinColors(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [String]? {
        return skin_colors.split(separator: ",").map { String($0) }
    }

    func language(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return language
    }

    func homeworld(context: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.Planet)? {
        return try await context.client.get(type: Planet.self, id: urlToID(homeworld))
    }

    func personConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.SpeciesPeopleConnection)? {
        let filteredIDs = people.map { encodeID(type: Person.self, id: urlToID($0)) }
        return Connection<Person>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func filmConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.SpeciesFilmsConnection)? {
        let filteredIDs = films?.map { encodeID(type: Film.self, id: urlToID($0)) } ?? []
        return Connection<Film>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func created(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return created
    }

    func edited(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return edited
    }

    func id(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
}

extension Starship: GraphQLGenerated.Starship {
    var id: String {
        return encodeID(type: Starship.self, id: urlToID(url))
    }

    func name(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return name
    }

    func model(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return model
    }

    func starshipClass(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return starship_class
    }

    func manufacturers(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [String]? {
        return manufacturer.split(separator: ",").map { String($0) }
    }

    func costInCredits(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(cost_in_credits)
    }

    func length(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(length)
    }

    func crew(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return crew
    }

    func passengers(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return passengers
    }

    func maxAtmospheringSpeed(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return Int(max_atmosphering_speed)
    }

    func hyperdriveRating(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(hyperdrive_rating)
    }

    func mglt(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return Int(MGLT)
    }

    func cargoCapacity(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(cargo_capacity)
    }

    func consumables(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return consumables
    }

    func pilotConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.StarshipPilotsConnection)? {
        let filteredIDs = pilots.map { encodeID(type: Person.self, id: urlToID($0)) }
        return Connection<Person>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func filmConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.StarshipFilmsConnection)? {
        let filteredIDs = films.map { encodeID(type: Film.self, id: urlToID($0)) }
        return Connection<Film>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func created(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return created
    }

    func edited(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return edited
    }

    func id(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
}

extension Vehicle: GraphQLGenerated.Vehicle {
    var id: String {
        return encodeID(type: Vehicle.self, id: urlToID(url))
    }

    func name(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return name
    }

    func model(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return model
    }

    func vehicleClass(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return vehicle_class
    }

    func manufacturers(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> [String]? {
        return manufacturer.split(separator: ",").map { String($0) }
    }

    func costInCredits(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(cost_in_credits)
    }

    func length(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(length)
    }

    func crew(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return crew
    }

    func passengers(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return passengers
    }

    func maxAtmospheringSpeed(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Int? {
        return Int(max_atmosphering_speed)
    }

    func cargoCapacity(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> Double? {
        return Double(cargo_capacity)
    }

    func consumables(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return consumables
    }

    func pilotConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.VehiclePilotsConnection)? {
        let filteredIDs = pilots.map { encodeID(type: Person.self, id: urlToID($0)) }
        return Connection<Person>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func filmConnection(after: String?, first: Int?, before: String?, last: Int?, context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> (any GraphQLGenerated.VehicleFilmsConnection)? {
        let filteredIDs = films.map { encodeID(type: Film.self, id: urlToID($0)) }
        return Connection<Film>(ids: filteredIDs, after: after, first: first, before: before, last: last)
    }

    func created(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return created
    }

    func edited(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String? {
        return edited
    }

    func id(context _: GraphQLContext, info _: GraphQL.GraphQLResolveInfo) async throws -> String {
        return id
    }
}
