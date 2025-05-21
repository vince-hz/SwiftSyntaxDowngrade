import SwiftSyntax

class IfLetCompleteRewriter: SyntaxRewriter {
    override func visit(_ node: OptionalBindingConditionSyntax) -> OptionalBindingConditionSyntax {
        if let _ = node.initializer {
            return node
        }
        let identifier = node.pattern.description
//    print(node)
        var newNode = node
        let isEndWithSpace = node.trailingTrivia == .space
        let initialValue = ExprSyntax(stringLiteral: identifier)
        let i = InitializerClauseSyntax(
            equal: .equalToken(leadingTrivia: isEndWithSpace ? [] : .space, trailingTrivia: .space),
            value: initialValue
        )
        newNode.initializer = i
//    print(newNode)
        return newNode
    }
}
