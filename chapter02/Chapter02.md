
# Chapter 2: Publishers & Subscribers

## Hello Publisher

`Publisher` 프로토콜은 시간이 지남에 따라 하나 이상의 `Subscriber`에게 값 시퀀스를 전송할 수 있는 유형에 대한 요구 사항을 정의합니다

publisher를 구독한다는 아이디어는 `NotificationCenter`가 특정 이벤트에 관심을 표시한 다음 새 **이벤트가 발생할 때마다 비동기식으로 알림**을 받는 개념과 비슷합니다.

publisher는 두 가지 종류의 이벤트를 내보냅니다.

1.  요소라고도 하는 값.
2.  완료 이벤트.

게시자는 0개 이상의 값을 내보낼 수 있지만 하나의 완료 이벤트(`completion event` or `Error`)만 내보낼 수 있습니다. publisher가 완료 이벤트를 내보내면 완료되어 더 이상 이벤트를 내보낼 수 없습니다.

## Hello Subscriber

`Subscriber`는 `publisher`로부터 입력을 받을 수 있는 형식에 대한 요구 사항을 정의하는 프로토콜입니다.

-   `sink` / `assign`

### Subscribing with sink(_:_:)

싱크 연산자는 실제로 두 개의 클로저를 제공합니다. 하나는 완료 이벤트(성공 또는 실패) 수신을 처리하고 다른 하나는 수신 값을 처리합니다.

```swift
func example(of description: String,
             action: () -> Void) {
    print("\\n——— Example of:", description, "———")
    action()
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
}

```

```html
——— Example of: Just ———
Received value Hello world!
Received completion finished

```

### Subscribing with assign(to:on:)

assign(to:on:) 연산자를 사용하면 수신된 값을 개체의 KVO 호환 속성에 할당할 수 있습니다.

```swift
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
        .assign(to: \\.value, on: object)
}

```

```html
——— Example of: assign(to:on:) ———
Hello
world!

```

<aside> 💡 이후의 chapter들에서 assign(to:on:)은 레이블, 텍스트 보기, 체크박스 및 기타 UI 구성요소에 직접 값을 할당할 수 있기 때문에 **UIKit 또는 AppKit 앱에서 작업할 때 특히 유용**하다는 것을 알게 될 것입니다.

</aside>

## Republishing with assign(to:)

`@Published` 속성 래퍼로 표시된 다른 속성을 통해 publisher 방출한 값을 _republish_하는 데 사용할 수 있는 _assign_ 연산자 변수를 만들 수 있습니다.

```swift
example(of: "assign(to:)") {
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
    
    // 3) &를 사용하여 속성에 대한 inout 참조를 나타냅니다.
    (0..<10).publisher
        .assign(to: &object.$value)
}

```

```html
——— Example of: assign(to:) ———
0 0 1 2 3 4 5 6 7 8 9

```

`**assign(to:)` 연산자는 내부적으로 수명 주기를 관리하고 @Published 속성이 초기화 해제될 때 구독을 취소하기 때문에 AnyCancellable 토큰을 반환하지 않습니다.**

assign(to:on:)을 사용하면?

```swift
class MyObject {
    @Published var word: String = ""
    var subscriptions = Set<AnyCancellable>()
    init() {
        ["A", "B", "C"].publisher
            .assign(to: \\.word, on: self)
            .store(in: &subscriptions)
    }
}

```

→ assign(to: \.word, on: self)을 사용하고 AnyCancellable을 저장하면 **강한순환참조**가 됩니다.

**assign(to:on:)을 assign(to: &$word)로 바꾸면 이 문제가 방지됩니다.**

## Hello Cancellable

subscriber가 작업을 마치고 더 이상 publisher로부터 값을 받고 싶지 않으면 구독을 취소하여 리소스를 확보하고 네트워크 호출과 같은 해당 활동이 발생하지 않도록 하는 것이 좋습니다.

구독은 완료되면 구독을 취소할 수 있는 "cancellation token"인 AnyCancellable 인스턴스를 반환합니다.

`AnyCancellable`은 해당 목적을 위해 `cancel()` 메서드가 필요한 `Cancellable` **프로토콜을 채택**합니다.

deinitialized되면 `AnyCancellable`인스턴스 가 `cancel` 을 \자동으로 호출 됩니다.

`Subscription` 프로토콜이 `Cancellable`에서 상속되기 때문에 구독에서 `cancel()`를 호출할 수 있습니다.

```swift
protocol Subscription : Cancellable, CustomCombineIdentifierConvertible

```

<aside> 💡 플레이그라운드에서 구독의 반환 값을 무시하는 것도 괜찮습니다(예: _ = just.sink...). 주의 사항: 전체 프로젝트에 구독을 저장하지 않으면 프로그램 흐름이 생성된 범위를 종료하는 즉시 구독이 취소됨

</aside>

## **진행 상황 이해**

<img width="357" alt="스크린샷_2022-05-07_오전_1 33 54" src="https://user-images.githubusercontent.com/50395024/167467250-47b39e03-c7a1-44b4-a2f9-c4b03c9be772.png">

1.  `Subscriber`가 `Publisher`를 구독합니다.
    
2.  `Publisher`는 구독을 생성하고 `Subscriber`에게 제공합니다.
    
3.  `Subscriber`가 값을 요청합니다.
    
4.  `Publisher`가 값을 보냅니다.
    
5.  `Publisher`가 완료를 보냅니다.
    

```swift
public protocol Publisher {
    // 1
    associatedtype Output
    // 2
    associatedtype Failure : Error
    // 4: subscribe(_:) 구현은 receive(subscriber:)을 호출하여 Subscriber를 게시자에 Publisher합니다.
    // 즉, 구독을 만듭니다.
    func receive<S>(subscriber: S)
    where S: Subscriber,
          Self.Failure == S.Failure,
          Self.Output == S.Input
}
extension Publisher {
    // 3: Subscriber는 Publisher에 대한 subscribe(_:)를 호출하여 연결합니다.
    public func subscribe<S>(_ subscriber: S)
    where S : Subscriber,
          Self.Failure == S.Failure,
          Self.Output == S.Input
}

```

```swift
public protocol Subscriber: CustomCombineIdentifierConvertible {
    // 1
    associatedtype Input
    // 2
    associatedtype Failure: Error
    // 3: 게시자는 구독자에 대해 receive(subscription:)를 호출하여 구독을 제공합니다.
    func receive(subscription: Subscription)
    // 4: 게시자는 구독자에서 receive(_:)을 호출하여 방금 게시한 새 값을 보냅니다.
    func receive(_ input: Self.Input) -> Subscribers.Demand
    // 5: 게시자는 구독자에 대해 receive(completion:)을 호출하여 정상적으로 또는 오류로 인해 값 생성을 완료했음을 알립니다.
    func receive(completion: Subscribers.Completion<Self.Failure>)
}

```

Publisher와 Subscriber 간의 연결은 구독(`Subscription`)입니다.

```swift
public protocol Subscription: Cancellable,
                              CustomCombineIdentifierConvertible {
    func request(_ demand: Subscribers.Demand)
}

```

## ****Creating a custom subscriber****

```swift
example(of: "Custom Subscriber") {
    // 1
    let publisher = (1...6).publisher
    
    // 2
    final class IntSubscriber: Subscriber {
        // 3
        typealias Input = Int
        typealias Failure = Never
        // 4: 게시자가 호출하는 receive(subscription:)로 시작하는 필수 메서드를 구현합니다. 그리고 그 메서드에서 구독자가 구독 시 최대 3개의 값을 수신할 의향이 있음을 지정하는 구독에서 .request(_:)를 호출합니다.
        func receive(subscription: Subscription) {
            subscription.request(.max(3))
        }
        
        // 5: 수신된 각 값을 인쇄하고 구독자가 수요를 조정하지 않을 것임을 나타내는 .none을 반환합니다. .none은 .max(0)과 같습니다.
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            return .none
        }
        
        // 6
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }
    
    let subscriber = IntSubscriber()
    publisher.subscribe(subscriber)
}

```

```swift
——— Example of: Custom Subscriber ———
Received value 1
Received value 2
Received value 3

```

여기에서 완료 이벤트를 받지 못했다 문구를 프린트 하지 않을 것을 알 수 있다.

Publisher에게 유한한 수의 값이 있고 .max(3)의 수요를 지정했기 때문입니다.

위의 5번의 return 값을 .none 대신 .unlimited나 .max(1)로 바뀌어 보면

```swift
——— Example of: Custom Subscriber ———
Received value 1
Received value 2
Received value 3
Received value 4
Received value 5
Received value 6
Received completion finished

```

이처럼 나오는 것을 알 수 있다.

이벤트를 수신할 때마다 최대값을 0을 불러와 멈추게 하던 .none 대신 멈추지 않고 늘리도록 지정하기 때문입니다. 그리고 이렇게 완료를 할 수 있음으로 “Received completion finished”가 프린트 되는 것을 알 수 있다.

## Hello Future

Just를 사용하여 구독자에게 단일 값을 내보내고 완료하는 게시자를 만들 수 있는 것과 마찬가지로

`Future`를 사용하여 **단일 결과를 비동기적으로 생성한 다음 완료**할 수 있습니다.

```swift
example(of: "Future") {
    func futureIncrement(
        integer: Int,
        afterDelay delay: TimeInterval) -> Future<Int, Never> {
            return Future<Int, Never> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    promise(.success(integer + 1))
                }
            }
    }
}

```

위 코드는 지연 후 받아온 (정수+1)하기 위한 promise 함수를 실행하는 것입니다.

**`Future`는 하나의 가치를 만들어내고 끝내거나 실패하는 publisher입니다.**

값이나 오류를 사용할 수 있을 때 클로저를 호출하여 이를 수행하는 것입니다. 해당 클로저는 말 그대로 약속입니다.

Future의 공식 문서를 보면

```swift
final public class Future<Output, Failure> : Publisher where Failure: Error {
    public typealias Promise = (Result<Output, Failure>) -> Void
    ...
}

```

**Promise는 Future에서 발행한 단일 값 또는 오류를 포함하는 Result를 수신하는 클로저에 대한 유형 별칭입니다.**

```swift
func futureIncrement(
    integer: Int,
    afterDelay delay: TimeInterval) -> Future<Int, Never> {
        return Future<Int, Never> { promise in
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

```

```swift
2
finished

```

몇가지 코드를 추가하며 실행해 본다면

```swift
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

```

```swift
Original
2
finished
Second 2
Second finished

```

Original 코드는 구독이 발생하기 직전에 print하게 되고

두 번째 구독도 +1을 하지 않고 동일한 값인 2를 받습니다.

`Future`는 promise를 다시 실행하지 않습니다. 대신 출력을 공유하거나 재생합니다.

<aside> 💡 Just와 초반에 비교되었는데 단일 결과를 비동기적으로 생성후 완료한다는 점이 비슷하지만 에러타입이 항산 NEVER인 Just와 달리 에러타입이 정해져 있지 않고 **Future은 일반적으로 Publisher의 처리를 sink 라는 구독을 형태로 많이 처리하게 되는데 이 때 클로저를 전달하는 과정에서 콜백 기반의 completion 핸들러를 사용하게 되는데 Futrue를 통하여 더욱 깔끔한 코드 작성이 가능해진다는 장점이 있다.**

</aside>

## Hello Subject

Subject**는 combine subscriber에게 Combine이 아닌 명령형 코드를 전송할 수 있도록 중개자 역할을 하는 publisher의 일종입니다.**

공식 문서: Subject는 외부 호출자가 요소를 게시할 수 있도록 메서드를 노출하는 Publisher입니다.

<img width="584" alt="스크린샷_2022-05-09_오전_2 49 44" src="https://user-images.githubusercontent.com/50395024/167467264-b543a0f0-b672-4370-96ac-ba30ac08d19b.png">

아직 Subject가 뭘 하는지 이해할 수 없지만 아래에서 예를 통해 본 후 다시 설명하겠습니다.

`PassthroughSubject`를 사용하면 **`send(_:)` 를 통해 필요에 따라 새로운 값을 게시**할 수 있습니다.

모든 publisher와 마찬가지로, 사전에 방출할 수 있는 값 및 오류타입을 선언해야합니다.

구독자는 passthroughsubject를 구독하려면 input, failure타입을 일치 시켜야합니다.

```swift
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
    // -- 위의 코드까지는 오류 형을 정의하고 수신된 값에 따라 수요를 조정하는 것 외에 새로운 것은 없습니다. --

    let subscriber = StringSubscriber()
    
    let subject = PassthroughSubject<String, MyError>()
    // subject를 통해 subscriber를 구독합니다.
    subject.subscribe(subscriber)
    // 싱크를 사용하여 다른 구독을 생성합니다.
    let subscription = subject
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
    subscription.cancel()
    subject.send("Still there?")
}

```

```swift
——— Example of: PassthroughSubject ———
Received value (sink) Hello
Received value Hello
Received value (sink) World
Received value World
Received value Still there?

```

싱크를 사용한 구독을 취소했음으로 “Received value (sink) Still there?”은 나오지 않은 것을 볼 수 있습니다.

이제 아래 코드를 추가해보자

```swift
subject.send(completion: .finished)
subject.send("How about another one?")

```

```swift
——— Example of: PassthroughSubject ———
Received value Hello
Received value (sink) Hello
Received value World
Received value (sink) World
Received value Still there?
Received completion finished

```

두 번째 subscriber는 subjects가 값을 보내기 직전에 completion event를 받았기 때문에 "How about another one"라는 메시지를 받지 못합니다.

첫 번째 subscriber는 구독이 이전에 취소되었기 때문에 완료 이벤트 또는 값을 수신하지 않습니다.

— 이 부분 이해가 가지 않음 전에 구독 취소한건 두번째 subscriber인데... —

완료 코드 앞에 아래 코드를 추가한다면

```swift
subject.send(completion: .failure(MyError.test))

```

```swift
Received value (sink) Hello
Received value Hello
Received value (sink) World
Received value World
Received value Still there?
Received completion failure(combineTest.(unknown context at $10000aec0).(unknown context at $10000b258).(unknown context at $10000b294).MyError.test)

```

예상하듯 failure가 적용 되었음을 알 수 있습니다.

이처럼 PassthroughSubject를 사용하여 값을 전달하는 것은 `명령형 코드`를 Combine의 `선언적 세계`에 연결하는 한 가지 방법입니다.

또한 여기서 PassthrounghSubject의 공식 문서를 보면

> A subject that broadcasts elements to downstream subscribers.

라고 되어 있는데 여태 우리는 subject에 send로 명령하면 구독한 곳에서 모두 명령이 실행되었던것을 생각하면 어떤 느낌인지 알 수 있을 것입니다.

때로는 명령형 코드에서 Publisher의 현재 값을 보고 싶을 수도 있습니다. 이를 위해 적절한 subject인 `CurrentValueSubject`가 있습니다.

각 구독을 값으로 저장하는 대신 AnyCancellable 컬렉션에 여러 구독을 저장할 수 있습니다.

그러면 컬렉션이 deinitializes되기 직전에 컬렉션에 추가된 각 구독이 자동으로 취소됩니다.

PassthrounghSubject**와 달리 현재** Publisher**에 언제든지 값을 요청할 수 있습니다.**

또한 Current Value Subject**에서 send(_:)를 호출하는 것은 새 값을 보내는 한 가지 방법일 뿐이고, 다른 식으로 값을 보내는 방법이 있습니다.**

value property에 새로운 값을 할당하는 것입니다.

```swift
example(of: "CurrentValueSubject") {
    var subscriptions = Set<AnyCancellable>()
    let subject = CurrentValueSubject<Int, Never>(0)
    
    subject
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions) // subscriptions Set에 구독을 저장
    
    subject.send(1)
    subject.send(2)
    print("CurrentValue : \\(subject.value)") // 현재 값을 요청
    subject.value = 3 // value property에 새로운 값을 할당
    print("CurrentValue : \\(subject.value)")
}

```

```swift
——— Example of: CurrentValueSubject ———
0
1
2
CurrentValue : 2
3
CurrentValue : 3

```

위에서 AnyCancellable 컬랙션에 여러 구독을 저장하여 deinitializes 되기 직전에 컬랙션에 저장된 구독이 해지 된다고 설명했는데 이를 알아보기 위한 코드를 “subject.value = 3” 위에 추가하보겠습니다.

```swift
subject
  .print("log ") // 모든 publishing 이벤트를 콘솔에 로그를 남기게 함
  .sink(receiveValue: { print("Second subscription:", $0) })
  .store(in: &subscriptions)

```

```swift
——— Example of: CurrentValueSubject ———
0
1
2
CurrentValue : 2
log : receive subscription: (CurrentValueSubject)
log : request unlimited
log : receive value: (2)
Second subscription: 2
3
log : receive value: (3)
Second subscription: 3
CurrentValue : 3
log : receive cancel

```

receive cancel 이벤트는 subscriptions set(Set<AnyCancellable>() 컬랙션)가 이 예제의 범위 내에 정의되어 있으므로 deinitializes시 포함된 구독을 취소하기 때문에 나타납니다.

cancel이 자동으로 된다면 완료가 이미 되었다면 어떻게 될까요? .finished를 테스트 해보겠습니다.

여기서 value property에 값을 할당한것처럼 아래 코드처럼 완료코드를 할당할 수 있을 까요? 아니요 불가능합니다.

```swift
subject.value = .finished // error

```

기존처럼 send(_:)를 맨 아래에 추가하여 완료를 테스트 해봅시다.

```swift
subject.send(completion: .finished)

```

```swift
...
CurrentValue : 3
log : receive finished

```

완료되었으므로 더 이상 취소할 필요가 없기에 위와 같은 결과가 나옵니다.

## Dynamically adjusting demand

```swift
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
                return .max(2) // 1. 새 최대값은 4입니다(원래 최대값 2 + 새 최대값 2).
            case 3:
                return .max(1) // 2. 새로운 최대값은 5입니다(이전 4 + 새 1).
            default:
                return .none // 3. 최대값은 5로 유지됩니다(이전 4 + 새 0).
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

```

```swift
——— Example of: Dynamically adjusting Demand ———
Received value 1
Received value 2
Received value 3
Received value 4
Received value 5

```

## Type erasure

구독자가 publisher에 대한 추가적인 **세부정보에 접근할 수 없는 상태**에서 publisher로 부터 **이벤트를 수신하도록 구독**하려는 경우가있습니다.

이럴때를 위해 아래 예제를 살펴보겠습니다.

```swift
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

```

```swift
——— Example of: Type erasure ———
0

```

<img width="591" alt="스크린샷_2022-05-09_오전_4 17 56" src="https://user-images.githubusercontent.com/50395024/167467268-1ab64c5c-81f0-4919-baf1-3f54a1d6d098.png">

AnyPublisher는 Publisher 프로토콜을 준수하는 type-erased 구조체입니다.

호출자가 <추가 항목 요청과 같은 작업을 수행하기 위해> 기본 구독에 액세스할 수 없는 상태에서 구독을 취소할 수 있는 `AnyCancellable` 또한 Cancellable을 따르는 type-erased 클래스입니다.

publisher에 대해 type-erasure를 사용하는 예시중 하나는 public 및 private 쌍을 사용하여 프로퍼티가 속 한한 내부에서 private publisher에 대한 값을 보낼 수 있도록 하고, 외부 호출자는 액세스만 허용하려는 경우입니다.

AnyPublisher에는 send(_:) 연산자가 없으므로 새 값을 추가할 수 없습니다.

`EraseToAnyPublisher()` 연산자는 publisher를 AnyPublisher인스턴스로 래핑하여 AnyPublisher의 게시자가 실제로 PassthroughSubject라는 사실을 숨깁니다.

이는 Publisher 프로토콜을 특정화할 수 없기 때문입니다. (ex. Publisher<UIImage, Never>로 정의할 수 없을 때)

## Bridging Combine publishers to async/await

Future 및 Publisher를 준수하는 모든 유형에서 사용가능

```swift
example(of: "async/await") {
    let publisher = (1...3).publisher.delay(for: 2, scheduler: DispatchQueue.global())
    Task { // 새로운 비동기 작업을 생성합니다
        for await element in publisher.values { // 비동기 시퀀스를 반복
            print("Element: \(element)")
        }
        print("Completed.")
    }
}
```

```swift
——— Example of: async/await ———
Element: 1
Element: 2
Element: 3
Completed.
```

## 정리

- `publisher`는 시간이 지남에 따라 값 시퀀스를 동기 또는 비동기로 **한 명 이상의 구독자에게 전송**합니다.
- 구독자는 publisher를 구독하여 값을 받을 수 있습니다. 그러나 구독자의 입력 및 실패 유형은 publisher의 출력 및 실패 유형과 일치해야 합니다.
- publisher를 구독하는 데 사용할 수 있는 **기본 제공 연산자**는 `sink(_:_:)` 및 `assign(to:on:)`입니다.
- 구독자는 값을 받을 때마다 **값에 대한 수요를 늘릴 수 있지만 수요를 줄일 수는 없습니다.**
- 리소스를 확보하고 원치 않는 부작용을 방지하려면 완료되면 각 구독을 취소하십시오.
- 또한 **초기화 취소 시 자동 취소를 수신하도록 AnyCancellable의 인스턴스 또는 컬렉션에 구독을 저장**할 수 있습니다.
- future를 사용하여 나중에 비동기적으로 단일 값을 받습니다.
- `Subjects`는 외부 호출자가 시작 값을 포함하거나 포함하지 않고 **구독자에게 여러 값을 비동기적으로 보낼 수 있도록 하는 게시자**입니다.
- Type erasure는 호출자가 기본 유형의 추가 세부 정보에 액세스할 수 없도록 합니다.
- print() 연산자를 사용하여 모든 게시 이벤트를 콘솔에 기록하고 진행 상황을 확인할 수 있습니다.
