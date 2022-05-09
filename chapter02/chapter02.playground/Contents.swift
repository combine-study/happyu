import Foundation
import Combine
import _Concurrency

func example(of description: String,
             action: () -> Void) {
    print("\n——— Example of:", description, "———")
    action()
}

example(of: "Subscriber") {
    // 1) 알림 이름을 만듭니다.
    let myNotification = Notification.Name("MyNotification")
    // 2) NotificationCenter의 기본 인스턴스에 액세스하고 해당 publisher(for:object:) 메서드를 호출하고 반환 값을 로컬 상수에 할당합니다.
    let center = NotificationCenter.default
    let publisher = center.publisher(for: myNotification, object: nil)
    
    // -- 여기까지만 코드를 적으면 아직 알림을 사용할 구독이 없기 때문에 게시자가 알림을 내보내지 않습니다. --
    
    // 1) publisher에서 sink를 호출하여 구독(subscription)을 만듭니다.
    let subscription = publisher
        .sink { _ in
            print("Notification received from a publisher!")
        }
    // 2) 알림을 게시합니다.
    center.post(name: myNotification, object: nil)
    center.post(name: myNotification, object: nil)
    // 3) 구독을 취소합니다.
    subscription.cancel()
    
    // cancel 되었음으로 이 이벤트는 보내지지 않음
    center.post(name: myNotification, object: nil)
}

example(of: "Just") {
    // 1) 단일 값에서 게시자를 생성할 수 있는 Just를 사용하여 게시자를 생성합니다.
    let just = Just("Hello world!")
    
    // 2) publisher에 대한 구독(subscription)을 만들고 수신된 각 이벤트에 대한 메시지를 print합니다.
    _ = just
        .sink(
            receiveCompletion: {
                print("Received completion", $0)
            },
            receiveValue: {
                print("Received value", $0)
            })
    
    _ = just
        .sink(
            receiveCompletion: {
                print("Received completion (another)", $0)
            },
            receiveValue: {
                print("Received value (another)", $0)
            })
}

example(of: "assign(to:on:)") {
    // 1
    class SomeObject {
        var value: String = "" {
            didSet {
                print(value)
            }
        }
    }
    
    // 2
    let object = SomeObject()
    
    // 3
    let publisher = ["Hello", "world!"].publisher
    
    // 4
    _ = publisher
        .assign(to: \.value, on: object)
}

example(of: "assign(to:)") {
    var disposeBag = Set<AnyCancellable>()
    // 1) @Published 속성 래퍼로 변수를 선언함으로 일반 속성으로 액세스할 수 있을 뿐만 아니라 값에 대한 Publisher를 생성합니다.
    class SomeObject {
        @Published var value = 0
    }
    
    let object = SomeObject()
    
    // 2
    object.$value
        .sink {
            print($0)
        }
        .store(in: &disposeBag)
    
    // 3) &를 사용하여 속성에 대한 inout 참조를 나타냅니다.
    (0..<10).publisher
        .assign(to: &object.$value)
}

example(of: "assign(to:on:) save AnyCancellable") {
    var disposeBag = Set<AnyCancellable>()
    class SomeObject {
        @Published var word: String = ""
        var subscriptions = Set<AnyCancellable>()
        init() {
            ["A", "B", "C"].publisher
                .assign(to: \.word, on: self)
                .store(in: &subscriptions)
        }
        
        deinit {
            print("deinit MyObject")
        }
    }
    
    let object = SomeObject()
    
    object.$word
        .sink {
            print($0)
        }
        .store(in: &disposeBag)
}


example(of: "Custom Subscriber") {
    // 1
    let publisher = (1...6).publisher
    
    // 2
    final class IntSubscriber: Subscriber {
        // 3
        typealias Input = Int
        typealias Failure = Never
        // 4
        func receive(subscription: Subscription) {
            subscription.request(.max(3))
        }
        
        // 5
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            return .unlimited
            //            return .none
        }
        
        // 6
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }
    
    let subscriber = IntSubscriber()
    publisher.subscribe(subscriber)
}

example(of: "Future") {
    func futureIncrement(
        integer: Int,
        afterDelay delay: TimeInterval) -> Future<Int, Never> {
            return Future<Int, Never> { promise in
                print("Original") // 추가된 코드
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    promise(.success(integer + 1))
                }
            }
        }
    var subscriptions = Set<AnyCancellable>()
    let future = futureIncrement(integer: 1, afterDelay: 3)
    future
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
    // 추가된 코드
    future
        .sink(receiveCompletion: { print("Second", $0) },
              receiveValue: { print("Second", $0) })
        .store(in: &subscriptions)
    
}

example(of: "PassthroughSubject") {
    enum MyError: Error {
        case test
    }
    
    final class StringSubscriber: Subscriber {
        typealias Input = String
        typealias Failure = MyError
        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }
        func receive(_ input: String) -> Subscribers.Demand {
            print("Received value", input)
            return input == "World" ? .max(1) : .none
        }
        func receive(completion: Subscribers.Completion<MyError>) {
            print("Received completion", completion)
        }
    }
    
    let subscriber = StringSubscriber()
    
    let subject = PassthroughSubject<String, MyError>()
    // subject를 통해 subscriber를 구독합니다.
    subject.subscribe(subscriber)
    // 싱크를 사용하여 다른 구독을 생성합니다.
    let subscription2 = subject
        .sink(
            receiveCompletion: { completion in
                print("Received completion (sink)", completion)
            },
            receiveValue: { value in
                print("Received value (sink)", value)
            }
        )
    subject.send("Hello")
    subject.send("World")
    // 싱크를 사용한 구독을 취소함
    subscription2.cancel()
    subject.send("Still there?")
    subject.send(completion: .failure(MyError.test))
    subject.send(completion: .finished)
    subject.send("How about another one?")
}

example(of: "CurrentValueSubject") {
    var subscriptions = Set<AnyCancellable>()
    let subject = CurrentValueSubject<Int, Never>(0)
    
    subject
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions) // subscriptions Set에 구독을 저장
    
    subject.send(1)
    subject.send(2)
    print("CurrentValue : \(subject.value)") // 현재 값을 요청
    
    subject
        .print("log ") // 모든 publishing 이벤트를 콘솔에 로그를 남기게 함
        .sink(receiveValue: { print("Second subscription:", $0) })
        .store(in: &subscriptions)
    
    
    subject.value = 3 // value property에 새로운 값을 할당
    print("CurrentValue : \(subject.value)")
    
    subject.send(completion: .finished)
}

example(of: "Dynamically adjusting Demand") {
    final class IntSubscriber: Subscriber {
        typealias Input = Int
        typealias Failure = Never
        
        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }
        
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            
            switch input {
            case 1:
                return .max(2) // 1
            case 3:
                return .max(1) // 2
            default:
                return .none // 3
            }
        }
        
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }
    
    let subscriber = IntSubscriber()
    
    let subject = PassthroughSubject<Int, Never>()
    
    subject.subscribe(subscriber)
    
    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)
    subject.send(5)
    subject.send(6)
}

example(of: "Type erasure") {
    var subscriptions = Set<AnyCancellable>()
    let subject = PassthroughSubject<Int, Never>()
    // 해당 subject에서 유형이 지워진 publisher를 만듭니다.
    let publisher = subject.eraseToAnyPublisher()
    
    publisher
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    subject.send(0)
}

example(of: "async/await") {
    let publisher = (1...3).publisher.delay(for: 2, scheduler: DispatchQueue.global())
    Task { // 새로운 비동기 작업을 생성합니다
        for await element in publisher.values { // 비동기 시퀀스를 반복
            print("Element: \(element)")
        }
        print("Completed.")
    }
}
