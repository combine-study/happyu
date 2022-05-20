import Foundation
import Combine

// MARK: - Support Code
var subscriptions = Set<AnyCancellable>()

func example(of description: String,
             action: () -> Void) {
    print("\n——— Example of:", description, "———")
    action()
}

// MARK: - Prepending
example(of: "prepend(Output...)") {
  let publisher = [3, 4].publisher // 여기까지 3,4

  publisher
    .prepend(1, 2) // 추가되어서 1,2,3,4
    .prepend(-1, 0) // 추가되어서 -1,0,1,2,3,4
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "prepend(Sequence)") {
  let publisher = [5, 6, 7].publisher // 여기까지 5,6,7
  
  publisher
    .prepend([3, 4]) // 추가되어서 3,4,5,6,7
    .prepend(Set(1...2)) // 추가되어서 2,1,3,4,5,6,7 <Set은 순서가 없음>
    .prepend(stride(from: 6, to: 11, by: 2)) // 추가되어서 6,8,10,2,1,3,4,5,6,7
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "prepend(Publisher)") {
  let publisher1 = [3, 4].publisher // 여기까지 3,4
  let publisher2 = [1, 2].publisher
  
  publisher1
    .prepend(publisher2) // 추가되어서 1,2,3,4
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "prepend(Publisher) #2") {
  let publisher1 = [3, 4].publisher
  let publisher2 = PassthroughSubject<Int, Never>()
  
  publisher1
    .prepend(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

  publisher2.send(1)
  publisher2.send(2)
  publisher2.send(completion: .finished)
}

// MARK: - Appending
example(of: "append(Output...)") {
  let publisher = [1].publisher // 여기까지 1

  publisher
    .append(2, 3) // 추가되어서 1,2,3
    .append(4) // 추가되어서 1,2,3,4
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "append(Output...) #2") {
  let publisher = PassthroughSubject<Int, Never>()

  publisher
    .append(3, 4)
    .append(5)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
  
    
  publisher.send(1)
  publisher.send(2)
  publisher.send(completion: .finished)
}

example(of: "append(Sequence)") {
  let publisher = [1, 2, 3].publisher
    
  publisher
    .append([4, 5])
    .append(Set([6, 7]))
    .append(stride(from: 8, to: 11, by: 2))
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "append(Publisher)") {
  let publisher1 = [1, 2].publisher
  let publisher2 = [3, 4].publisher
  
  publisher1
    .append(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

// MARK: - Advanced Combining
example(of: "switchToLatest") {
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<Int, Never>()
  let publisher3 = PassthroughSubject<Int, Never>()

  let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()

  publishers
    .switchToLatest()
    .sink(
        receiveCompletion: { _ in print("Completed!") },
        receiveValue: { print($0) }
    )
    .store(in: &subscriptions)

  publishers.send(publisher1)
  publisher1.send(1)
  publisher1.send(2)

  publishers.send(publisher2)
  publisher1.send(3)
  publisher2.send(4)
  publisher2.send(5)

  publishers.send(publisher3)
  publisher2.send(6)
  publisher3.send(7)
  publisher3.send(8)
  publisher3.send(9)

  publisher3.send(completion: .finished)
  publishers.send(completion: .finished)
}
