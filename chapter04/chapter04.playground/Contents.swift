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

// MARK: - Finding values

example(of: "first(where:)") {
    let numbers = (1...9).publisher
    
    numbers
        .print("numbers")
        .first(where: { $0 % 2 == 0 })
        .sink(receiveCompletion: { print("Completed with: \($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "last(where:)") {
    let numbers = PassthroughSubject<Int, Never>()
    
    numbers
        .last(where: { $0 % 2 == 0 })
        .sink(receiveCompletion: { print("Completed with: \($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    numbers.send(1)
    numbers.send(2)
    numbers.send(3)
    numbers.send(4)
    numbers.send(5)
    numbers.send(completion: .finished)
}

// MARK: - Dropping values

example(of: "dropFirst") {
    let numbers = (1...10).publisher
    
    numbers
        .dropFirst(8)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "drop(while:)") {
    let numbers = (1...8).publisher
    
    numbers
        .drop(while: {
            print("x")
            return $0 % 5 != 0
        })
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "drop(untilOutputFrom:)") {
    let isReady = PassthroughSubject<Void, Never>()
    let taps = PassthroughSubject<Int, Never>()
    
    taps
        .drop(untilOutputFrom: isReady)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    (1...5).forEach { n in
        taps.send(n)
        
        if n == 3 {
            isReady.send()
        }
    }
}

// MARK: - Limiting values

example(of: "prefix") {
    let numbers = (1...10).publisher
    
    numbers
        .print("numbers")
        .prefix(2)
        .sink(receiveCompletion: { print("Completed with: \($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "prefix(while:)") {
    let numbers = (1...10).publisher
    
    numbers
        .print("numbers")
        .prefix(while: { $0 < 3 })
        .sink(receiveCompletion: { print("Completed with: \($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "prefix(untilOutputFrom:)") {
    let isReady = PassthroughSubject<Void, Never>()
    let taps = PassthroughSubject<Int, Never>()
    
    taps
        .print("numbers")
        .prefix(untilOutputFrom: isReady)
        .sink(receiveCompletion: { print("Completed with: \($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    (1...5).forEach { n in
        taps.send(n)
        
        if n == 2 {
            isReady.send()
        }
    }
}

// MARK: - Challenge: Filter all the things
example(of: "Challenge") {
    let numbers = (1...100).publisher
    
    numbers
        .dropFirst(50)
        .prefix(20)
        .filter { $0 % 2 == 0 }
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

