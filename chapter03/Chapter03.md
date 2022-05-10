
# Chapter 03: Transforming Operators

## ❖ 참고

이제 operator를 설명할때 그림이 많이 나올 것입니다.

이 그림을 **marble diagram**이라고 합니다.

### 보는 법

**윗줄: upstream publisher**

**상자: 연산자**

아래 줄: **구독자 / 더 구체적으로 말하면 연산자가 upstream publisher로부터 오는 값을 조작한 후 구독자가 받게 되는 것**

(아래줄은 업스트림 게시자로부터 출력을 수신하고 작업을 수행하고 해당 값을 다운스트림으로 보내는 또 다른 연산자일 수도 있습니다.)

----------

transforming operator: publisher가 제공하는 값을 구독자가 사용할 수 있는 형식으로 조작하기 위해 사용

Swift 표준 라이브러리의 map 및 flatMap과 같은 연산자와 연관이 있음

## **Operators are publishers**

각 Combine Operator는 게시자를 반환합니다.

일반적으로 Publisher은 upstream 이벤트를 수신하여 조작한 다음 조작된 이벤트 downstream을 소비자에게 보냅니다.

## Collecting values

### collect()

_collect_ 연산자는 게시자의 **개별 값** 스트림을 **단일 배열로 변환**하는 편리한 방법을 제공합니다.

<img width="294" alt="스크린샷_2022-05-10_오전_4 45 47" src="https://user-images.githubusercontent.com/50395024/167577545-dff5c673-d882-4f6d-907d-5e3702901427.png">

```swift
example(of: "collect") {
    ["A", "B", "C", "D", "E"].publisher
        .collect(2) // 파라미터에 값이 없으면 기본적으로 하나로 묶임, 파라미터: 각 배열의 개수 제한
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

```

```swift
——— Example of: collect ———
["A", "B"]
["C", "D"]
["E"]
finished

```

## Mapping values

### map(_:)

publisher가 내보낸 값에 대해 작동한다는 점을 제외하면 Swift의 표준 지도와 동일하게 작동

<img width="337" alt="스크린샷_2022-05-10_오전_4 55 48" src="https://user-images.githubusercontent.com/50395024/167577547-fecb5d9d-1aa4-4741-9dcb-941cb4a031fe.png">

```swift
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

```

```swift
——— Example of: map ———
one hundred twenty-three
four
fifty-six

```

### Mapping key paths

mpa 연산자에는 키 경로를 사용하여 값의 1개, 2개, 3개의 속성에 매핑할 수 있는 세 가지 버전도 포함되어 있습니다.

-   map<T>(_:_)_
-   _map<T0, T1>(__: _:_)_
-   _map<T0, T1, T2>(_: _: _:_)

T는 주어진 키 경로에서 찾은 값의 유형을 나타냅니다

### tryMap(_:)

**map을 포함한 여러 연산자에는 throwing 클로저를 사용하는 try 접두사 상대가 있습니다.**

**오류가 발생하면 연산자는 해당 오류를 다운스트림으로 내보냅니다.**

```swift
example(of: "tryMap") {
    Just("Directory name that does not exist")
    // 파일 내용을 읽어오도록 시도함 <예제에서 파일이름은 없는 파일임>
        .tryMap { try FileManager.default.contentsOfDirectory(atPath: $0) }
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

```

```swift
——— Example of: tryMap ———
failure( ... Directory name that does not exist... )

```

## Flattening publishers

### flatMap(maxPublishers:_:)

**upstream publisher에서 사용자가 지정한 최대 publisher 수까지 모든 요소를 새 publisher로 변환합니다.**

Combine에서 flatMap의 **일반적인 사용 사례는** 한 publisher가 내보낸 요소를 publisher를 반환하는 메서드에 전달하고 궁극적으로 **두 번째 게시자가 내보낸 요소를 구독**하려는 경우입니다.

<img width="366" alt="스크린샷_2022-05-10_오후_3 39 14" src="https://user-images.githubusercontent.com/50395024/167577548-7854d338-f441-48b8-8150-27c83747f35c.png">

flatMap은 p1,p2,p3 3개의 publisher를 받습니다.

flatMap은 P1, P2의 publisher의 `value`를 방출하지만, max가 2이기 때문에 P3은 무시합니다.

```swift
example(of: "flatMap") { // 마블 다이어그램을 설명하기 위한 예제
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

```

```swift
——— Example of: flatMap2 ———
1
2
4
5

```

```swift
example(of: "flatMap") { // 책에서 나온 예제
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

```

```swift
——— Example of: flatMap ———
Hello, World!

```

이처럼 flatMap은 수신된 모든 게시자의 출력을 단일 publisher로 평면화합니다.

downstream에서 내보내는 단일 publisher를 업데이트하기 위해 보내는 만큼 **많은 publisher를 버퍼링하므로 메모리 문제가 발생할 수 있습니다.**

> 개인적 추론

이처럼 publisher들을 저장하고 publisher의 수량을 넘으면 받지 않고 publisher중간에 다른 값이 오면 또 그 값을 받아야 함으로 메모리 문제가 있다고 하는 것이 아닐까 예상함

## Replacing upstream output

위의 예제에서 선택적 문자열을 생성하고 nil-coalescing 연산자(??)를 사용하여 nil 값을 nil이 아닌 값으로 바꿉니다.

combine은 이러한 과정을 해주는 연산자가 있습니다.

### replaceNil(with:)

<img width="407" alt="스크린샷_2022-05-10_오후_4 15 52" src="https://user-images.githubusercontent.com/50395024/167577550-8b03253b-afdf-4a62-b63c-2eea7873cd61.png">

```swift
example(of: "replaceNil") {
    // 1
    ["A", nil, "C"].publisher
        .eraseToAnyPublisher()
        .replaceNil(with: "-") // 2
        .sink(receiveValue: { print($0) }) // 3
        .store(in: &subscriptions)
}

```

```swift
——— Example of: replaceNil ———
A
-
C

```

여기서 주의할 점은 combine에서는 다른 것들과 달리 `eraseToAnyPublisher()`를 하지 않으면 `Optional<String>`가 나오는 버그가 있습니다.

이에 관련한 포럼을 확인하세요. → [링크](https://forums.swift.org/t/unexpected-behavior-of-replacenil-with/40800)

### replaceEmpty(with:)

publisher가 값을 내보내지 않고 완료하는 경우 replaceEmpty(with:) 연산자를 사용하여 값을 바꾸거나 실제로 삽입할 수 있습니다.

<img width="340" alt="스크린샷_2022-05-10_오후_4 28 17" src="https://user-images.githubusercontent.com/50395024/167577551-b2119940-4dd7-4eb9-b0d3-fa7cae5d8b9d.png">

```swift
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

```

```swift
——— Example of: replaceEmpty(with:) ———
1
finished

```

## Incrementally transforming output

### scan(_: _:)
<img width="374" alt="스크린샷_2022-05-10_오후_4 38 05" src="https://user-images.githubusercontent.com/50395024/167577553-1b0bc756-8c52-4a38-8a5f-09f9d82dfdca.png">

```swift
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

```

```swift
——— Example of: scan ———
60
65
61
68
63
53

```
