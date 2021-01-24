import Foundation

extension UInt64 {
    func indices(offset: Int) -> [Int] {
        //TODO: make efficient
        return Array(self).enumerated().filter { $0.element }.map { $0.offset + offset }
    }
}

extension Data {
    func parseCSV() -> [[Range<Int>]] {
        // take 64 byte because we'll feed into simd 256
        assert(count >= 64)
        return withUnsafeBytes { buf in
            var inQuotes = false
            var commas: [Int] = []
            var newlines: [Int] = []
            for chunkStart in stride(from: 0, to: count, by: 64) {
                let chunkEnd = chunkStart + 64
                var chunk: UnsafeRawBufferPointer!
                if chunkEnd > count {
                    var tmp = Data(count: 64)
                    chunk = tmp.withUnsafeMutableBytes { writeable in
                        copyBytes(to: writeable, from: chunkStart..<count)
                        return UnsafeRawBufferPointer(writeable)
                    }
                } else {
                    chunk = UnsafeRawBufferPointer(rebasing: buf[chunkStart..<chunkEnd])
                }
                let (commaMask, newLineMask) = chunk.parseCSVChunk(inQuotes: &inQuotes)
                let commaIndices = commaMask.indices(offset: chunkStart)
                let newlineIndices = newLineMask.indices(offset: chunkStart)
                commas.append(contentsOf: commaIndices)
                newlines.append(contentsOf: newlineIndices)
            }
            var result: [[Range<Int>]] = []
            var currentLine: [Range<Int>] = []
            
            var previousOffset = 0
            for comma in commas {
                while let n = newlines.first, comma > n {
                    newlines.removeFirst()
                    currentLine.append(previousOffset..<n)
                    result.append(currentLine)
                    currentLine = []
                    previousOffset = n + 1
                }
                currentLine.append(previousOffset..<comma)
                previousOffset = comma + 1
            }
            currentLine.append(previousOffset..<count)
            result.append(currentLine)
            return result
        }
    }
    
    func parseXML() {
        assert(count >= 64)
        let chunk = self[0..<64]
        chunk.withUnsafeBytes { buf in
            buf.parseXMLChunk()
        }
    }
}
