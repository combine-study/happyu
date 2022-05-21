import UIKit
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
    let publisher = [1].publisher // 여기까지 1
    
    publisher
        .append([2, 3]) // 추가되어 1,2,3
        .append(Set([4, 5])) // 추가되어 1,2,3,5,4 (set임으로 1,2,3,4,5가 될 수 있음)
        .append(stride(from: 6, to: 9, by: 2)) // 추가되어 1,2,3,5,4,6,8
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
    
    // 다른 PassthroughSubject을 허용하는 두 번째 PassthroughSubject을 만듭니다.
    // 예를 들어 publisher1, publisher2 또는 publisher3을 통해 전송할 수 있습니다.
    let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()
    
    // publisher의 switchToLatest를 사용하십시오. 이제 게시자 제목을 통해 다른 게시자를 보낼 때마다 새 게시자로 전환하고 이전 구독을 취소합니다.
    publishers
        .switchToLatest()
        .sink(
            receiveCompletion: { _ in print("Completed!") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
    
    // publisher1을 publishers로 보낸 값 1,2를 publisher1로 보냅니다.
    publishers.send(publisher1)
    publisher1.send(1)
    publisher1.send(2)
    
    // publisher2를 publishers로 보냈음으로 publisher1에 대한 구독을 취소합니다
    // 따라서 값 3는 무시됩니다.
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

//example(of: "switchToLatest - Network Request") {
//    let url = URL(string: "https://source.unsplash.com/random")!
//    // Unsplash의 공용 API에서 임의 이미지를 가져오기 위해 네트워크 요청을 수행하는 getImage() 함수
//    func getImage() -> AnyPublisher<UIImage?, Never> {
//        URLSession.shared
//            .dataTaskPublisher(for: url)
//            .map { data, _ in UIImage(data: data) }
//            .print("image")
//            .replaceError(with: nil)
//            .eraseToAnyPublisher()
//    }
//
//
//    let taps = PassthroughSubject<Void, Never>()
//    taps
//        .map { _ in getImage() }
//                // 버튼을 누르면 getImage()를 호출하여 임의의 이미지에 대한 새 네트워크 요청에 탭을 매핑
//                // 이는 기본적으로 Publisher<Void, Never>를 Publisher<Publisher<UIImage?, Never>, Never>로 변환합니다.
//        .switchToLatest() // 한 publisher만 값을 내보내고 나머지 구독은 자동으로 취소
//        .sink(receiveValue: { _ in })
//        .store(in: &subscriptions)
//
//    taps.send() // 처음 탭하여 이미지 가져옴
//    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // 3초 뒤에 탭하여 새로운 이미지를 가져옴
//        taps.send()
//    }
//    DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) { // 두번째 탭한 뒤 0.1초 뒤에 탭하여 새로운 이미지를 가져옴
//        taps.send()
//    }
//}

example(of: "merge(with:)") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<Int, Never>()
    
    publisher1
        .merge(with: publisher2)
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { print($0) }
        )
        .store(in: &subscriptions)
    
    publisher1.send(1)
    publisher1.send(2)
    
    publisher2.send(3)
    
    publisher1.send(4)
    
    publisher2.send(5)
    
    publisher1.send(completion: .finished)
    publisher2.send(completion: .finished)
}

example(of: "combineLatest") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    
    publisher1
        .combineLatest(publisher2)
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { print("P1: \($0), P2: \($1)") }
        )
        .store(in: &subscriptions)
    
    publisher1.send(1)
    publisher1.send(2)
    
    publisher2.send("a")
    publisher2.send("b")
    
    publisher1.send(3)
    
    publisher2.send("c")
    
    publisher1.send(completion: .finished)
    publisher2.send(completion: .finished)
}

example(of: "zip") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    
    publisher1
        .zip(publisher2)
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { print("P1: \($0), P2: \($1)") }
        )
        .store(in: &subscriptions)
    
    publisher1.send(1)
    publisher1.send(2)
    publisher2.send("a")
    publisher2.send("b")
    publisher1.send(3)
    publisher2.send("c")
    publisher2.send("d")
    
    publisher1.send(completion: .finished)
    publisher2.send(completion: .finished)
}
