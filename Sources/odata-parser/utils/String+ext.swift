import Foundation

extension String {
    var key: String {
        return padding(toLength: 20, withPad: " ", startingAt: 0)
    }
}
