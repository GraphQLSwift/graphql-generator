import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Macro implementation for `@graphQLResolver`
///
/// This peer macro generates a GraphQL resolver method that returns the property value.
public struct GraphQLResolverMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate that this is attached to a property
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            throw MacroError.notAttachedToProperty
        }

        // Validate that it's a stored property (has 'let' or 'var')
        guard varDecl.bindingSpecifier.tokenKind == .keyword(.let) ||
            varDecl.bindingSpecifier.tokenKind == .keyword(.var)
        else {
            throw MacroError.invalidPropertyDeclaration
        }

        // Extract the property name and type
        guard let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
              let type = binding.typeAnnotation?.type
        else {
            throw MacroError.invalidPropertyDeclaration
        }

        let propertyName = identifier.text
        let propertyType = type.trimmedDescription

        // Set argument defaults
        var graphQLFieldName = propertyName

        // Override if arguments are provided
        if case let .argumentList(arguments) = node.arguments {
            if let nameArg = arguments.first(where: { $0.label?.text == "name" }) {
                guard
                    let fieldName = nameArg.expression.as(StringLiteralExprSyntax.self)?
                    .segments.first?.as(StringSegmentSyntax.self)?.content.text
                else {
                    // Invalid name argument
                    throw MacroError.invalidArguments
                }
                graphQLFieldName = fieldName
            }
        }

        // Generate the resolver method
        let resolverMethod: DeclSyntax = """
        func \(raw: graphQLFieldName)(context: GraphQLContext, info: GraphQLResolveInfo) async throws -> \(raw: propertyType) {
            return \(raw: propertyName)
        }
        """

        return [resolverMethod]
    }
}

/// Errors that can occur during macro expansion
enum MacroError: Error, CustomStringConvertible {
    case notAttachedToProperty
    case invalidPropertyDeclaration
    case invalidArguments

    var description: String {
        switch self {
        case .notAttachedToProperty:
            return "@graphQLResolver can only be applied to properties"
        case .invalidPropertyDeclaration:
            return "@graphQLResolver requires a stored property (let/var) with an explicit type annotation"
        case .invalidArguments:
            return "@graphQLResolver accepts either no arguments or a 'name' string argument"
        }
    }
}

/// Compiler plugin that provides the GraphQLGeneratorMacros
@main
struct GraphQLGeneratorMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GraphQLResolverMacro.self,
    ]
}
