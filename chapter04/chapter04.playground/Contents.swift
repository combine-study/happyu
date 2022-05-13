import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()
// MARK: - Filtering basics
example(of: "filter") {
    let numbers = (1...10).publisher
    numbers
        .filter { $0.isMultiple(of: 3) }
        .sink(receiveValue: { n in
            print("\(n) is a multiple of 3!")
        })
        .store(in: &subscriptions)
}

example(of: "removeDuplicates") {
    let words = "hey hey there! want to listen to mister mister ?"
        .components(separatedBy: " ")
        .publisher
    words
        .removeDuplicates()
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// MARK: - Compacting and ignoring
example(of: "compactMap") {
    let strings = ["a", "1.24", "3", "def", "45", "0.23"].publisher
    strings
        .compactMap { Float($0) }
        .sink(receiveValue: {
            print($0)
        })
        .store(in: &subscriptions)
}

example(of: "ignoreOutput") {
    let numbers = (1...10_000).publisher
    
    numbers
        .ignoreOutput()
        .sink(receiveCompletion: { print("Completed with: \($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

// MARK: - Support Code
func example(of description: String,
             action: () -> Void) {
    print("\n——— Example of:", description, "———")
    action()
}

struct Coordinate {
    public let x: Int
    public let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

func quadrantOf(x: Int, y: Int) -> String {
    var quadrant = ""
    
    switch (x, y) {
    case (1..., 1...):
        quadrant = "1"
    case (..<0, 1...):
        quadrant = "2"
    case (..<0, ..<0):
        quadrant = "3"
    case (1..., ..<0):
        quadrant = "4"
    default:
        quadrant = "boundary"
    }
    
    return quadrant
}

