import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "collect") {
    ["A", "B", "C", "D", "E"].publisher
        .collect(2)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "map") {
    // 각 숫자를 철자화 함
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    [123, 4, 56].publisher
        .map {
            formatter.string(for: NSNumber(integerLiteral: $0)) ?? ""
        }
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "mapping key paths") {
    let publisher = PassthroughSubject<Coordinate, Never>()
    
    publisher
        .map(\.x, \.y)
        .sink(receiveValue: { x, y in
            print(
                "The coordinate at (\(x), \(y)) is in quadrant",
                quadrantOf(x: x, y: y)
            )
        })
        .store(in: &subscriptions)
    
    publisher.send(Coordinate(x: 10, y: -8))
    publisher.send(Coordinate(x: 0, y: 5))
}

example(of: "tryMap") {
    Just("Directory name that does not exist")
    // 파일 내용을 읽어오도록 시도함 <예제에서 파일이름은 없는 파일임>
        .tryMap { try FileManager.default.contentsOfDirectory(atPath: $0) }
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "flatMap") {
    // 문자 코드들을 배열로 받아 문자열로 변경후 AnyPublisher에 담아 반환
    func decode(_ codes: [Int]) -> AnyPublisher<String, Never> {
        Just(
            codes
                .compactMap { code in
                    guard (32...255).contains(code) else { return nil }
                    return String(UnicodeScalar(code) ?? " ")
                }
                .joined()
        )
        // 기능에 대한 반환 유형과 일치하도록 하기 위함
            .eraseToAnyPublisher()
    }
    
    [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
        .publisher
        .collect()
        .flatMap(decode)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "flatMap2") {
    struct Input {
        let num: CurrentValueSubject<Int, Never>
    }
    let input01 = Input(num: .init(1))
    let input02 = Input(num: .init(2))
    let input03 = Input(num: .init(3))
    
    let subject = PassthroughSubject<Input, Never>()
    
    let cancellable = subject
        .flatMap(maxPublishers: .max(2)) { $0.num }
        .sink { print($0) }
    
    subject.send(input01)
    subject.send(input02)
    subject.send(input03)
    
    input01.num.send(4)
    input02.num.send(5)
}

example(of: "replaceNil") {
    ["A", nil, "C"].publisher
        .eraseToAnyPublisher()
        .replaceNil(with: "-")
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    ["A", nil, "C"].publisher
        .replaceNil(with: "-")
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "replaceEmpty(with:)") {
    // 1
    let empty = Empty<Int, Never>()
    
    // 2
    empty
        .replaceEmpty(with: 1)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "scan") {
    var dailyGainLoss: Int { .random(in: -10...10) }
    
    let august2019 = (0..<6)
        .map { _ in dailyGainLoss }
        .publisher
    
    august2019
    // 초기값 50에 이전값과 받아온 값을 가지고 연산하게 됨
        .scan(50) { latest, current in
            max(0, latest + current)
        }
        .sink(receiveValue: { print($0) })
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

