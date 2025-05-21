import SwiftSyntax

class SomeOrAnyTypeSyntaxEraseRewriter: SyntaxRewriter {
    override func visit(_ node: SomeOrAnyTypeSyntax) -> TypeSyntax {
        return node.constraint
    }
}
