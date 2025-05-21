import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

class SourceFilePrinter {
    static func writeToFile(syntax: some SyntaxProtocol, path: String) throws {
        let output = syntax.description.hasPrefix("\n") ? String(syntax.description.dropFirst()) : syntax.description
        try output.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

func convert(_ url: URL) -> SourceFileSyntax {
    let source = try! String(contentsOf: url)
    var result = Parser.parse(source: source)
    let process = [
        SomeOrAnyTypeSyntaxEraseRewriter(),
        ImplicitSelfAddRewriter(),
        IfLetCompleteRewriter(),
    ]
    process.forEach { result = $0.visit(result) }
    return result
}

func collectMembers(_ url: URL) {
    let source = try! String(contentsOf: url)
    let result = Parser.parse(source: source)
    let collector = ClassMembersCollector(viewMode: .sourceAccurate)
    collector.walk(result)
    print(classesMembers)
}

// Change to the path where you want to convert the files.
let targetDirPath = FileManager.default.homeDirectoryForCurrentUser.path() + "SwiftSyntaxDowngrade/SwiftSyntaxDowngrade/TestResource"
let fm = FileManager.default
let files = (fm.enumerator(atPath: targetDirPath)?.allObjects ?? [])
  .compactMap { $0 as? String }
  .filter { $0.hasSuffix(".swift") }
  .map { URL(fileURLWithPath: "\(targetDirPath)/\($0)") }

files.forEach { collectMembers($0) }
files.forEach {
  let result = convert($0)
  try! SourceFilePrinter.writeToFile(syntax: result, path: $0.path)
}
