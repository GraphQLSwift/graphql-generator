/// Generates a GraphQL resolver method for a property.
///
/// This macro reduces boilerplate by automatically generating resolver methods
/// that simply return the property value. It's designed for simple field resolution
/// where no custom logic is needed.
///
/// ## Usage
///
/// Attach this macro to a property in a type conforming to a GraphQL protocol.
/// You can use it with or without a name argument:
///
/// ```swift
/// struct User: GraphQLGenerated.User {
///     // Without name - uses property name as GraphQL field name
///     @graphQLResolver
///     let id: String
///
///     // With name - uses custom GraphQL field name
///     @graphQLResolver(name: "fullName")
///     let name: String
///
///     // Async throwing computed property - automatically adds 'try await'
///     @graphQLResolver
///     var userId: String {
///         get async throws {
///             try await user.fetchID()
///         }
///     }
/// }
/// ```
///
/// The macros above generate the following resolver methods:
///
/// ```swift
/// func id(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
///     return id
/// }
///
/// func fullName(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
///     return name
/// }
///
/// func userId(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> String {
///     return try await userId
/// }
/// ```
///
/// ## Requirements
///
/// - The property must have an explicit type annotation
/// - The property type must match the GraphQL field return type
///
/// - Parameters:
///   - name: Optional. The GraphQL field name. If omitted, the property name is used.
@attached(peer, names: arbitrary)
public macro graphQLResolver(name: String? = nil) = #externalMacro(
    module: "GraphQLGeneratorMacrosBackend",
    type: "GraphQLResolverMacro"
)
