import SwiftSyntax

class ImplicitSelfAddRewriter: SyntaxRewriter {
    private var memberNames: Set<String> = []

    // Code block.
    private var blockStack: [AbsolutePosition] = []
    private var currentBlockNode: AbsolutePosition? { blockStack.last }
    private var blockVariables: [AbsolutePosition: [String]] = [:]

    // If let.
    private var currentStmtNode: AbsolutePosition?
    private var stmtVariables: [AbsolutePosition: [String]] = [:]

    // Closure.
    private var closureStack: [AbsolutePosition] = []
    private var currentClosureNode: AbsolutePosition? { closureStack.last }
    var inClosure: Bool { !closureStack.isEmpty }
    private var closureVariables: [AbsolutePosition: [String]] = [:]

    // Func parameter
    private var funcParameters: [AbsolutePosition: [String]] = [:]

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        memberNames = classesMembers[node.name.text] ?? []
        let result = super.visit(node)
        memberNames.removeAll()
        return result
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        if let name = node.extendedType.as(IdentifierTypeSyntax.self)?.name.text {
            memberNames = classesMembers[name] ?? []
        } else {
            memberNames = []
        }
        let result = super.visit(node)
        memberNames = []
        return result
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        let params = node.signature.parameterClause.parameters.map(\.firstName.text)
        funcParameters[node.position] = params
        defer {
            funcParameters.removeValue(forKey: node.position)
        }
        return super.visit(node)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let params = node.signature.parameterClause.parameters.map(\.firstName.text)
        funcParameters[node.position] = params
        defer {
            funcParameters.removeValue(forKey: node.position)
        }
        return super.visit(node)
    }

    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
        blockStack.append(node.position)
        blockVariables[node.position] = []
        print("Enter block", node, currentNonMemberVariables)
        let result = super.visit(node)
        blockStack.removeLast()
        blockVariables[node.position] = nil
        print("Leave block", node, currentNonMemberVariables)
        return result
    }

    override func visit(_ node: ExpressionStmtSyntax) -> StmtSyntax {
        stmtVariables[node.position] = []
        currentStmtNode = node.position
        print("Enter stmt", node, currentNonMemberVariables)
        let result = super.visit(node)
        stmtVariables[node.position] = nil
        currentStmtNode = nil
        print("Leave stmt", node, currentNonMemberVariables)
        return result
    }

    var currentNonMemberVariables: [String] {
        blockVariables.values.flatMap { $0 } + stmtVariables.values.flatMap { $0 } + closureVariables.values.flatMap { $0 } + funcParameters.values.flatMap { $0 }
    }

    override func visit(_ node: IdentifierPatternSyntax) -> PatternSyntax {
        if let currentStmtNode, var items = stmtVariables[currentStmtNode] {
            items.append(node.identifier.text)
            stmtVariables[currentStmtNode] = items
        } else if let currentBlockNode, var items = blockVariables[currentBlockNode] {
            items.append(node.identifier.text)
            blockVariables[currentBlockNode] = items
        } else if let currentClosureNode, var items = closureVariables[currentClosureNode] {
            items.append(node.identifier.text)
            closureVariables[currentClosureNode] = items
        }
        return super.visit(node)
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        closureStack.append(node.position)
        if let parameter = node.signature?.parameterClause {
            switch parameter {
            case let .parameterClause(paramClause):
                let values = paramClause.parameters.map(\.firstName.text)
                closureVariables[node.position] = values
            case let .simpleInput(params):
                let values = params.map(\.name.text)
                closureVariables[node.position] = values
            }
        } else {
            closureVariables[node.position] = []
        }
        print("Enter closure", node, currentNonMemberVariables)
        defer {
            closureStack.removeLast()
            closureVariables.removeValue(forKey: node.position)
            print("Leave closure", node, currentNonMemberVariables)
        }
        return super.visit(node)
    }

    var isSelfMemberAccess = false
    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        var decl: DeclReferenceExprSyntax?
        if let a = node.base?.as(DeclReferenceExprSyntax.self) {
            decl = a
        } else if let a = node.base?.as(OptionalChainingExprSyntax.self)?.expression.as(DeclReferenceExprSyntax.self) {
            decl = a
        }
        if decl?.baseName.text == "self" {
            let wasMemberAccess = isSelfMemberAccess
            isSelfMemberAccess = true
            defer { isSelfMemberAccess = wasMemberAccess }
            return super.visit(node)
        }
        return super.visit(node)
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        if
            inClosure,
            !isSelfMemberAccess,
            !currentNonMemberVariables.contains(node.baseName.text),
            memberNames.contains(node.baseName.text)
        {
            let newDecl = DeclReferenceExprSyntax(
                leadingTrivia: nil,
                baseName: node.baseName.trimmed
            )
            let newNode = ExprSyntax(MemberAccessExprSyntax(
                leadingTrivia: node.baseName.leadingTrivia,
                base: ExprSyntax("self"),
                period: .periodToken(),
                declName: newDecl,
                trailingTrivia: node.trailingTrivia
            ))
            return newNode
        }
        return .init(node)
    }
}
