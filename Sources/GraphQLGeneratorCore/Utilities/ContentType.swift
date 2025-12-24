import Foundation

/// A simple stub for ContentType - we don't need the full implementation for GraphQL
public struct ContentType {
    public let lowercasedTypeSubtypeAndParameters: String
    public let originallyCasedType: String
    public let originallyCasedSubtype: String
    public let lowercasedParameterPairs: [String]
}

extension String {
    var uppercasingFirstLetter: String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
