import Foundation
import simd_wrapper


let sample = #"""
"Plain Field","Field,with comma","With """"escaped"" quotes","Another field",without quotes
"Plain Field","Field,with comma","With """"escaped"" quotes","Another field",without quotes
"""#

let data = sample.data(using: .utf8)!

guard let xmlURL = Bundle.module.url(forResource: "sketch_metadata", withExtension: "xml"),
      let xml = try? String(contentsOf: xmlURL) else {
    preconditionFailure()
}

data.parseCSV()


let sample1 = #"""
"Plain Field","Field,with comma","With """"escaped"" quotes    ","Another field"
"""#
let dataSample1 = sample1.data(using: .utf8)!
dataSample1.parseCSV()

let sample2 = #"""
"Plain Field","Field,with comma","With """"escaped"" quotes  ","Another field"
"""#
let dataSample2 = sample2.data(using: .utf8)!
dataSample2.parseCSV()


let lines = data.parseCSV()
print(lines)
dump(lines.map({ $0.map { range in
    String(data: data[range], encoding: .utf8)!
}}))
