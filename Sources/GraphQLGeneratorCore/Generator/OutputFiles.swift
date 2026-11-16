/// The name of a Swift file emitted by the generator.
enum OutputFileName: String, Hashable, CaseIterable, Sendable {
    case buildGraphQLSchema = "BuildGraphQLSchema.swift"
    case graphQLRawSDL = "GraphQLRawSDL.swift"
    case graphQLTypes = "GraphQLTypes.swift"
}
