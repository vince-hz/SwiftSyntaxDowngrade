# SwiftSynctaxDowngrade

This is a tool to downgrade Swift syntax from Swift 5.9 to Swift 5.3.

## Usage

``` swift
let url = URL(fileURLWithPath: "path/to/your/file.swift")
let result = convert(url)
try! SourceFilePrinter.writeToFile(syntax: result, path: url.path)
```