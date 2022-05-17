
# **Chapter 04: Filtering Operators**

Publisher가 내보낸 값이나 이벤트를 제한하고 일부만 사용하려는 경우에 필요한 Operator

이 장의 대부분의 연산자는 filter vs tryFilter와 같이 try 접두사와 평행을 이룹니다.

try가 throwing 클로저를 제공하고 클로저 내에서 throw하는 모든 오류는 발생된 오류와 함께 publisher를 종료합니다. 이런 차이점 외에는 다른 것이 없기에 우리는 try는 생략하고 설명할것입니다.

## **Filtering basics**

### filter(_:)

이 연산자는 Bool을 반환할 것으로 예상되는 클로저를 사용합니다.

<img width="387" alt="스크린샷_2022-05-17_오전_11 54 26" src="https://user-images.githubusercontent.com/50395024/168735671-7e37ed32-b0d2-4a71-8420-fb288167e8d2.png">

```swift
example(of: "filter") {
    let numbers = (1...10).publisher
    numbers
        .filter { $0.isMultiple(of: 3) }
        .sink(receiveValue: { n in
            print("\\(n) is a multiple of 3!")
        })
        .store(in: &subscriptions)
}

```

```swift
——— Example of: filter ———
3 is a multiple of 3!
6 is a multiple of 3!
9 is a multiple of 3!

```

동일한 값을 연속적으로 내보내는 Publisher에서 과도한 동일한 값을 무시하는 연산자도 제공합니다.

이 연산자에 인수를 제공할 필요가 없다는 점에 유의하세요

### removeDuplicates()

removeDuplicates는 문자열을 포함하여 Equatable을 준수하는 모든 값에 대해 자동으로 작동합니다.

<img width="333" alt="스크린샷_2022-05-17_오전_11 55 08" src="https://user-images.githubusercontent.com/50395024/168735674-1bce20da-d7db-4b30-891e-a5c9d8e78a19.png">

만약 Equatable을 준수하지 않는다면 Bool값을 반환하는 조건이 들어간 클로저를 제공

```swift
example(of: "removeDuplicates") {
    let words = "hey hey there! want to listen to mister mister ?"
        .components(separatedBy: " ")
        .publisher
    words
        .removeDuplicates()
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

```

```swift
——— Example of: removeDuplicates ———
hey
there!
want
to
listen
to
mister
?

```

## **Compacting and ignoring**

### compactMap(_:)

map기능을 하면서 nil을 filtering 해주는 operator

<img width="335" alt="스크린샷_2022-05-17_오전_11 56 13" src="https://user-images.githubusercontent.com/50395024/168735675-2f91d641-af18-44a9-bdda-fdadd94c6a6e.png">

```swift
example(of: "compactMap") {
    let strings = ["a", "1.24", "3", "def", "45", "0.23"].publisher
    strings
        .compactMap { Float($0) }
        .sink(receiveValue: {
            print($0)
        })
        .store(in: &subscriptions)
}

```

```swift
——— Example of: compactMap ———
1.24
3.0
45.0
0.23

```

### ignoreOutput()

publisher가 값 내보내기를 완료했다는 사실만 알면 되고 실제 값이 무엇인지는 중요하지 않을때 쓰는 operator도 제공합니다.

<img width="334" alt="스크린샷_2022-05-17_오전_11 57 46" src="https://user-images.githubusercontent.com/50395024/168735677-e8edb876-29ce-42c2-8e53-9266e4168dd7.png">

```swift
example(of: "ignoreOutput") {
    let numbers = (1...10_000).publisher
    
    numbers
        .ignoreOutput()
        .sink(receiveCompletion: { print("Completed with: \\($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

```

```swift
——— Example of: ignoreOutput ———
Completed with: finished

```

## **Finding values**

### .first(where:)

`.first(where:)`은 `lazy`하기 때문에 입력한 조건과 일치하는 값을 찾을 때까지 필요한 만큼만 있으면 됩니다

일치하는 항목을 찾는 즉시 구독을 취소하고 완료합니다.

<img width="350" alt="스크린샷_2022-05-17_오후_12 41 27" src="https://user-images.githubusercontent.com/50395024/168735685-5627a91c-0a1c-400a-8e82-c676dc7cb934.png">

```swift
example(of: "first(where:)") {
  let numbers = (1...9).publisher
  
  numbers
    .print("numbers")
    .first(where: { $0 % 2 == 0 })
    .sink(receiveCompletion: { print("Completed with: \\($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
}

```

```swift
——— Example of: first(where:) ———
numbers: receive subscription: (1...9)
numbers: request unlimited
numbers: receive value: (1)
numbers: receive value: (2)
numbers: receive cancel
2 // 실제 sink를 통해 넘어온 값
Completed with: finished

```

위에서 .print("numbers") 코드를 통하여 보여지듯이

처음 조건에 맞는 값이 나온다면 즉시 cancel됩니다.

### last(where:)

<img width="394" alt="스크린샷_2022-05-17_오후_12 50 43" src="https://user-images.githubusercontent.com/50395024/168735688-25050a0f-9b5d-42cc-b288-c03cd4403877.png">

.first(where:)와 반대로, `last(where:)` 연산자는 **Publisher가 일치하는 값이 발견되었는지 여부를 알기 위해 방출 값을 완료하기**를 기다려야 합니다.

**따라서 업스트림은 유한해야 합니다.**

```swift
example(of: "last(where:)") {
  let numbers = PassthroughSubject<Int, Never>()
  
  numbers
    .last(where: { $0 % 2 == 0 })
    .sink(receiveCompletion: { print("Completed with: \\($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  numbers.send(1)
  numbers.send(2)
  numbers.send(3)
  numbers.send(4)
  numbers.send(5)
  numbers.send(completion: .finished)
}

```

```swift
——— Example of: last(where:) ———
4
Completed with: finished

```

## **Dropping values**

Dropping은 두 번째 게시자가 게시를 시작할 때까지 한 게시자의 값을 무시하거나 스트림 시작 시 특정 양의 값을 무시하려는 경우에 사용합니다.

### dropFirst

dropFirst 연산자는 카운트 매개 변수(누락된 경우 기본값 1)를 사용합니다.

publisher는 내보낸 값에서 처음부터 카운트 만큼 무시한 후에만 publisher의 값 전달을 시작합니다.

<img width="309" alt="스크린샷_2022-05-17_오후_1 41 53" src="https://user-images.githubusercontent.com/50395024/168735679-18f16b5d-4b7f-4717-923a-c5d37a7a2b48.png">

```swift
example(of: "dropFirst") {
  let numbers = (1...10).publisher
  
  numbers
    .dropFirst(8)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

```

```swift
——— Example of: dropFirst ———
9
10

```

### drop(while:)

해석 그대로 클로저의 조건에 맞는 값이 나올때까지 제거하는 것입니다.

<img width="321" alt="스크린샷_2022-05-17_오후_1 57 08" src="https://user-images.githubusercontent.com/50395024/168735680-20dac336-adc3-486a-855a-ab9c58e2d397.png">

```swift
example(of: "drop(while:)") {
  let numbers = (1...8).publisher
  
  numbers
    .drop(while: {
      return $0 % 5 != 0
    })
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

```

```swift
——— Example of: drop(while:) ———
5
6
7
8

```

### drop(untilOutputFrom:)

사용자가 버튼을 누르고 있지만 isReady publisher가 결과를 출력할 때까지 모든 탭을 무시하려고 하는 상황과 같습니다.

두 번째 게시자가 값을 출력하기 시작할 때까지 게시자가 내보내는 모든 값을 건너뛰어 두 게시자 간의 관계를 생성합니다.

<img width="328" alt="스크린샷_2022-05-17_오후_2 01 44" src="https://user-images.githubusercontent.com/50395024/168735683-156d8a09-7f19-4bd0-a083-30ba7ecce850.png">

```swift
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

```

```swift
——— Example of: drop(untilOutputFrom:) ———
4
5

```

## **Limiting values**

`prefix`는 위의 drop과 반대입니다. 전에는 앞에 것들을 무시했지만 prefix는 원하는 부분까지만 받고 뒤의 값을 무시하는 것입니다.

또한 first(where:)과 마찬가지고 **lazy하게 작동**합니다. 즉, 원하는 값까지만 받고 종료하게 됩니다.

(여기서는 prefix(where:)에서 써있었는데 모두 다 그렇게 작동하는 것 같아 맨 위에 적음. 아니면 수정 예정)
<img width="346" alt="스크린샷_2022-05-17_오후_2 11 26" src="https://user-images.githubusercontent.com/50395024/168735684-cfedd702-6c8d-4017-aba0-f3b6d7dbe1b7.png">

```swift
example(of: "prefix") {
  let numbers = (1...10).publisher
  
  numbers
        .print("numbers")
    .prefix(2)
    .sink(receiveCompletion: { print("Completed with: \\($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
}

```

```swift
——— Example of: prefix ———
numbers: receive subscription: (1...10)
numbers: request unlimited
numbers: receive value: (1)
1
numbers: receive value: (2)
2
numbers: receive cancel
Completed with: finished

```
</br></br>
<img width="333" alt="스크린샷 2022-05-17 오후 2 33 29" src="https://user-images.githubusercontent.com/50395024/168736297-4e0bbbcc-6d7f-442d-b6ed-6d4241b7b4b5.png">

```swift
example(of: "prefix(while:)") {
  let numbers = (1...10).publisher
  
  numbers
        .print("numbers")
    .prefix(while: { $0 < 3 })
    .sink(receiveCompletion: { print("Completed with: \\($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
}

```

```swift
——— Example of: prefix(while:) ———
numbers: receive subscription: (1...10)
numbers: request unlimited
numbers: receive value: (1)
1
numbers: receive value: (2)
2
numbers: receive value: (3)
numbers: receive cancel
Completed with: finished

```

</br></br>
<img width="352" alt="스크린샷 2022-05-17 오후 2 33 48" src="https://user-images.githubusercontent.com/50395024/168736340-994392f3-0f15-453d-bb10-19066b46c6ce.png">

```swift
example(of: "prefix(untilOutputFrom:)") {
  let isReady = PassthroughSubject<Void, Never>()
  let taps = PassthroughSubject<Int, Never>()
  
  taps
        .print("numbers")
    .prefix(untilOutputFrom: isReady)
    .sink(receiveCompletion: { print("Completed with: \\($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  (1...5).forEach { n in
    taps.send(n)
    
    if n == 2 {
      isReady.send()
    }
  }
}

```

```swift
——— Example of: prefix(untilOutputFrom:) ———
numbers: receive subscription: (PassthroughSubject)
numbers: request unlimited
numbers: receive value: (1)
1
numbers: receive value: (2)
2
numbers: receive cancel
Completed with: finished

```
