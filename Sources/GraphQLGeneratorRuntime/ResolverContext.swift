import Foundation

/// Protocol for resolver context that can be passed to resolver functions
/// Implement this protocol to provide dependencies and services to resolvers
public protocol ResolverContext {
    // Add common context properties here
    // For example:
    // var currentUser: User? { get }
    // var database: Database { get }
    // var cache: Cache { get }
}

/// A basic empty context implementation
public struct EmptyResolverContext: ResolverContext {
    public init() {}
}
