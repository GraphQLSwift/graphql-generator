import AsyncDataLoader
import AsyncHTTPClient
import Foundation
import GraphQL

/// A caching client for accessing the public SWAPI.
///
/// See https://www.swapi.tech/documentation
struct SwapiClient {
    let client: HTTPClient
    let decoder = JSONDecoder()
    private let rootUrl = "https://swapi.tech/api/"

    /// A dataloader that caches each response from the API. We can use this cross-client
    /// cross-request because we don't expect the data to change.
    private let dataLoader: DataLoader<String, HTTPClient.Response>

    init(client: HTTPClient) {
        self.client = client
        dataLoader = DataLoader<String, HTTPClient.Response> { urls in
            // Retrieve the URLs in parallel
            await withTaskGroup { group in
                var results: [DataLoaderValue<HTTPClient.Response>] = urls.map { _ in
                    .failure(GraphQLError(message: "Index must be populated"))
                }
                for (index, url) in urls.enumerated() {
                    group.addTask {
                        let result: Result<HTTPClient.Response, any Error>
                        do {
                            let response = try await client.get(url: url).get()
                            result = .success(response)
                        } catch {
                            result = .failure(error)
                        }
                        return (index, result)
                    }
                }
                for await result in group {
                    results[result.0] = switch result.1 {
                    case let .success(response):
                        .success(response)
                    case let .failure(error):
                        .failure(error)
                    }
                }
                return results
            }
        }
    }

    func get<T: SwapiResource>(type: T.Type, id: String) async throws -> T? {
        let instance = try await get(url: "\(rootUrl)/\(type.type.rawValue)/\(id)", as: InstanceResponse<T>.self)
        return instance?.result.properties
    }

    func getAllIDs<T: SwapiResource>(type: T.Type) async throws -> [String] {
        var nextUrl: String? = "\(rootUrl)/\(type.type.rawValue)"
        var ids = [String]()
        while let url = nextUrl {
            guard let page = try await get(url: url, as: PageResponse.self) else {
                break
            }
            for result in page.results {
                ids.append(result.uid)
            }
            nextUrl = page.next
        }
        return ids.map {
            encodeID(type: T.self, id: $0)
        }.sorted()
    }

    private func get<T: Codable>(url: String, as _: T.Type) async throws -> T? {
        let response = try await dataLoader.load(key: url)
        switch response.status {
        case .ok:
            break
        case .notFound:
            return nil
        default:
            throw GraphQLError(message: "Failed with HTTP status \(response.status) at \(url)")
        }
        guard let body = response.body else {
            throw GraphQLError(message: "No body found from response at \(url)")
        }
        return try JSONDecoder().decode(T.self, from: body)
    }
}
