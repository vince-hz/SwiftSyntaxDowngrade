import SwiftSyntax

var classesMembers: [String: Set<String>] = [:]
class ClassMembersCollector: SyntaxVisitor {
    func merge(value: Set<String>, to key: String) {
        if let v = classesMembers[key] {
            classesMembers[key] = value.union(v)
        } else {
            classesMembers[key] = value
        }
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let value = collectMembers(node.memberBlock)
        merge(value: value, to: node.name.text)
        return .skipChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let name = node.extendedType.as(IdentifierTypeSyntax.self)?.name.text {
            let value = collectMembers(node.memberBlock)
            merge(value: value, to: name)
        }
        return .skipChildren
    }

    private func collectMembers(_ memberBlock: MemberBlockSyntax) -> Set<String> {
        var names: Set<String> = []
        for member in memberBlock.members {
            if let variable = member.decl.as(VariableDeclSyntax.self) {
                for binding in variable.bindings {
                    if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                        names.insert(pattern.identifier.text)
                    }
                }
            }

            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                names.insert(funcDecl.name.text)
            }
        }
        return names
    }
}

