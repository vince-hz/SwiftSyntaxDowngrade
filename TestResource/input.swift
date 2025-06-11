fileprivate typealias ClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void

class Test{
    var a: Int?
    var b: Int?
    func foo(para: Result<Int, Error>) {
        guard let a, let b else { return }
        if let self  {
            return
        }
    }
}