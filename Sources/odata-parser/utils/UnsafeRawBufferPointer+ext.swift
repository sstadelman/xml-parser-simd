import Foundation
import simd_wrapper


extension UInt8 {
    static let quote = "\"".utf8.first!
    static let comma = ",".utf8.first!
    static let newline = "\n".utf8.first!
    static let openAngleBr = "<".utf8.first!
    static let closeAngleBr = ">".utf8.first!
    
}



extension UnsafeRawBufferPointer {
    func parseCSVChunk(inQuotes: inout Bool) -> (commas: UInt64, newlines: UInt64) {
        assert(count == 64)
        let input = self.baseAddress!.assumingMemoryBound(to: UInt8.self)

        // MARK: 1: get all quote marks
        let quotes = cmp_mask_against_input(input, .quote)
//        print("quotes".key, quotes.bits)
        // MARK: 2: find all the starts of quote sequences
        // take the same sequence, and shift by 1 to the left (right, visually)
        // invert
        // take bitwise AND
        // results in a bitmask that ONLY has 1's where a quote sequence starts (does not solve trailing)
        let quoteStarts = ~(quotes << 1) & quotes
//        print("quoteStarts".key, quoteStarts.bits)
        // MARK: 3:  deal with even-length sequences of quotes which are not useful
        // if quotestart begins at even position, and ends at even position, we have an odd # of quotes
        // same for quoteStarts on odd positions
        // consider even quote starts
        // take bitmask of 101010101..., bitwise AND with quoteStarts
        let evenStarts = quoteStarts & .even
//        print("evenStarts".key, evenStarts.bits)
        
        let oddStarts = quoteStarts & .odd
//        print("oddStarts".key, oddStarts.bits)
        
        // MARK: 4:  we are looking for particular end quotes which indicate odd-length sequences
        // take original quote bitmask AND with even starts
        // results in carryover at locations which are the ends of the quote sequences with even starts
        // ends are always 1 *past*
        // (result is still a little polluted)
        // So we *again* invert the original bitmask and perform an AND.  Results that all bits which
        // were set in the original bitmask are now guaranteed to be zero.  This gives us only the cleaned up
        // evenStarts
        
        var endsOfEvenStarts = evenStarts &+ quotes
        endsOfEvenStarts &= ~quotes
//        print("endsOfEvenStarts".key, endsOfEvenStarts.bits)
        
        // since we are only interested in ends which indicate an odd-length sequence, we use the
        // `odd` bitmask, and do bitwise AND.  This results in only the ends which are on an odd index
        
        let oddLengthEndsOfEvenStarts = endsOfEvenStarts & .odd
//        print("oddLenEndsOfEvenStarts".key, oddLengthEndsOfEvenStarts.bits)

        
        var (endsOfOddStarts, overflow) = quotes.addingReportingOverflow(oddStarts)
        endsOfOddStarts &= ~quotes
//        print("endsOfOddStarts".key, endsOfOddStarts.bits)
        
        let oddLengthEndsOfOddStarts = endsOfOddStarts & .even
//        print("oddLenEndsOfOddStarts".key, oddLengthEndsOfOddStarts.bits)
        
        let endsOfOddLengths = oddLengthEndsOfEvenStarts | oddLengthEndsOfOddStarts
//        print("endsOfOddLengths".key, endsOfOddLengths.bits)
        
        // MARK: 5: want to have a mask of all bits between the 1's (to get the strings)
        // we can use that mask to see which commas are inside a string, and which are control
        // use a sequence of 1's, and do 'carryless multiply'
        // start at least significant bit, walk until you hit a 1, then keep writing 1's until you hit 1
        // neglect all the carryovers.  available as a special instruction
        
        // results in mask where first character in the string begins sequence of 1's, last 1 is the endIndex
        // (last 1 is not included)
        var stringMask = carryless_multiply(endsOfOddLengths, ~0)
        if inQuotes {
            stringMask = ~stringMask
        }
//        print("stringMask".key, stringMask.bits)
        
        let commas = cmp_mask_against_input(input, .comma)
        let controlCommas = commas & ~stringMask

        let newLines = cmp_mask_against_input(input, .newline)
        let controlNewLines = newLines & ~stringMask
        
        inQuotes = (stringMask[63] && !overflow) || (overflow && !stringMask[63])
        return (controlCommas, controlNewLines)
    }
    
    
    func parseXMLChunk() {
        assert(count == 64)
        // todo
    }
}
