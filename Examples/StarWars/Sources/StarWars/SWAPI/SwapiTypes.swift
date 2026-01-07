/// See https://www.swapi.tech/documentation
enum SwapiResourceType: String, RawRepresentable {
    case films
    case people
    case planets
    case species
    case starships
    case vehicles
}

/// See https://www.swapi.tech/documentation
protocol SwapiResource: Codable, Sendable {
    /// Represents the sub-path used to access the resource
    static var type: SwapiResourceType { get }

    /// The URL that references this object
    var url: String { get }
}

/// See https://www.swapi.tech/documentation#films
struct Film: SwapiResource {
    static let type = SwapiResourceType.films

    let characters: [String]
    let created: String
    let director: String
    let edited: String
    let episode_id: Int
    let opening_crawl: String
    let planets: [String]
    let producer: String
    let release_date: String
    let species: [String]
    let starships: [String]
    let title: String
    let url: String
    let vehicles: [String]
}

/// See https://www.swapi.tech/documentation#people
struct Person: SwapiResource {
    static let type = SwapiResourceType.people

    let birth_year: String
    let eye_color: String
    let films: [String]
    let gender: String
    let hair_color: String
    let height: String
    let homeworld: String
    let mass: String
    let name: String
    let skin_color: String
    let created: String
    let edited: String
    let species: [String]?
    let starships: [String]
    let url: String
    let vehicles: [String]
}

/// See https://www.swapi.tech/documentation#planets
struct Planet: SwapiResource {
    static let type = SwapiResourceType.planets

    let climate: String
    let created: String
    let diameter: String
    let edited: String
    let films: [String]?
    let gravity: String
    let name: String
    let orbital_period: String
    let population: String
    let residents: [String]?
    let rotation_period: String
    let surface_water: String
    let terrain: String
    let url: String
}

/// See https://www.swapi.tech/documentation#species
struct Species: SwapiResource {
    static let type = SwapiResourceType.species

    let average_height: String
    let average_lifespan: String
    let classification: String
    let created: String
    let designation: String
    let edited: String
    let eye_colors: String
    let hair_colors: String
    let homeworld: String
    let language: String
    let name: String
    let people: [String]
    let films: [String]?
    let skin_colors: String
    let url: String
}

/// See https://www.swapi.tech/documentation#starships
struct Starship: SwapiResource {
    static let type = SwapiResourceType.starships

    let MGLT: String
    let cargo_capacity: String
    let consumables: String
    let cost_in_credits: String
    let created: String
    let crew: String
    let edited: String
    let hyperdrive_rating: String
    let length: String
    let manufacturer: String
    let max_atmosphering_speed: String
    let model: String
    let name: String
    let passengers: String
    let films: [String]
    let pilots: [String]
    let starship_class: String
    let url: String
}

/// See https://www.swapi.tech/documentation#vehicles
struct Vehicle: SwapiResource {
    static let type = SwapiResourceType.vehicles

    let cargo_capacity: String
    let consumables: String
    let cost_in_credits: String
    let created: String
    let crew: String
    let edited: String
    let length: String
    let manufacturer: String
    let max_atmosphering_speed: String
    let model: String
    let name: String
    let passengers: String
    let pilots: [String]
    let films: [String]
    let url: String
    let vehicle_class: String
}

/// A response returned from 'get all the X resources' queries
struct PageResponse: Codable {
    /// The URL of the next page
    let next: String?
    let results: [PageResult]

    struct PageResult: Codable {
        /// The ID of the resource
        let uid: String
    }
}

/// A response returned from 'get a specific X resource' queries
struct InstanceResponse<T: SwapiResource>: Codable {
    let result: InstanceResult<T>

    struct InstanceResult<U: SwapiResource>: Codable {
        let properties: U
    }
}
