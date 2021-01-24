import Foundation

extension UInt64: Collection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { 64 }
    public func index(after i: Int) -> Int {
        i + 1
    }
    public subscript(index: Int) -> Bool {
        return (self & (1 << index)) > 0
    }
    
    var bits: String {
        map { $0 ? "1" : "0" }.joined()
    }
    
    static let even: UInt64 = (0..<64).reduce(0, { result, bit in
        (bit % 2 == 0) ? result | (1 << bit) : result
    })
    
    static let odd = ~even
}
