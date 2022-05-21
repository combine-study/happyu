
# Chapter 5: Combining Operators

  

이 장에서는 연산자 결합에 대해 배우게 됩니다. 이 연산자 집합을 사용하면 서로 다른 게시자가 내보낸 이벤트를 결합하고 결합 코드에서 의미 있는 데이터 조합을 만들 수 있습니다.

  

결합이 왜 유용한가? 사용자 이름, 암호 및 확인란과 같은 사용자로부터 여러 개의 입력을 받은 양식을 생각해 보십시오. 단일 게시자를 구성하는 데 필요한 모든 정보를 포함하려면 이러한 서로 다른 데이터를 결합해야 합니다. 이처럼 많은 곳에서 쓰일 수 있습니다.

  

## Prepending

  

Publisher의 시작 부분에 값을 추가하는 연산자 그룹과 함께 천천히 시작하겠습니다.

  

### ****prepend(Output...)****

  

![스크린샷_2022-05-20_오후_4 42 32](https://user-images.githubusercontent.com/50395024/169494474-a83f42f5-7510-40fe-bbc4-6c66a5432426.png)

  

```swift

// MARK: - Prepending

example(of: "prepend(Output...)") {

let publisher = [3, 4].publisher // 여기까지 3,4

  

publisher

.prepend(1, 2) // 추가되어서 1,2,3,4

.prepend(-1, 0) // 추가되어서 -1,0,1,2,3,4

.sink(receiveValue: { print($0) })

.store(in: &subscriptions)

}

```

  

```swift

——— Example of: prepend(Output...) ———

-1

0

1

2

3

4

```

  

### ****prepend(Sequence)****

  

![스크린샷_2022-05-20_오후_4 55 32](https://user-images.githubusercontent.com/50395024/169494482-6ea1f30c-f8a2-4321-a9dd-6185ab4c5d5b.png)


  

```swift

example(of: "prepend(Sequence)") {

let publisher = [5, 6, 7].publisher // 여기까지 5,6,7

publisher

.prepend([3, 4]) // 추가되어서 3,4,5,6,7

.prepend(Set(1...2)) // 추가되어서 2,1,3,4,5,6,7 <Set은 순서가 없음>

.prepend(stride(from: 6, to: 11, by: 2)) // 추가되어서 6,8,10,2,1,3,4,5,6,7

.sink(receiveValue: { print($0) })

.store(in: &subscriptions)

}

```

  

```swift

——— Example of: prepend(Sequence) ———

6

8

10

2

1

3

4

5

6

7

```

  

위와 비슷하지만 시퀀스를 준수하는 개체를 입력으로 받아들인다는 차이점이 있습니다

  

ex) Array or Set

  

Set: 순서가 없기 때문에 위와 같은 경우에서 1,2 가 될 수도 2,1가 될 수도 있습니다.

  

stride: from-to까지의 숫자 중에서 by의 간격으로 추가 됩니다.

  

### ****prepend(Publisher)****

  

![스크린샷_2022-05-20_오후_5 38 24](https://user-images.githubusercontent.com/50395024/169494485-eae52870-6262-46fd-831b-de244c1ee082.png)

  

```swift

example(of: "prepend(Publisher)") {

let publisher1 = [3, 4].publisher

let publisher2 = PassthroughSubject<Int, Never>()

publisher1

.prepend(publisher2)

.sink(receiveValue: { print($0) })

.store(in: &subscriptions)

  

publisher2.send(1)

publisher2.send(2)

}

```

  

```swift

——— Example of: prepend(Publisher...) ———

1

2

```

  

publisher2에서 값이 먼저 방출 된 후에 publisher1에서 값이 방출됩니다.

  

위의 예제에서 publisher2의 값이 끝난줄 알 수 없기 때문에 publisher1의 값이 방출되지 않는 것을 볼 수 있습니다.

  

```swift

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

```

  

```swift

——— Example of: prepend(Publisher...) ———

1

2

3

4

```

  

## ****Appending****

  

prepend 연산자와 유사하게 append(Output...), append(Sequence), append(Publisher)가 있으며 prepend와는 다르게 앞에 추가 되지 않고 뒤에 추가되도록 작동합니다.

  

### ****append(Output...)****

  

![스크린샷_2022-05-20_오후_5 47 23](https://user-images.githubusercontent.com/50395024/169494489-929278ae-0b3d-41fe-98e2-8a6ec7c7287c.png)

  

`append`는 prepend와 다르게 각 append가 upstream이 (.finished 이벤트로) 완료되기를 기다린 후 추가하는 작업을 해야합니다.

  

****즉, 이전 publisher가 모든 값을 내보낸 것을 combine이 알 수 없기 때문에 upstream은 완료되거나 추가되지 않아야 합니다.****

  

```swift

example(of: "append(Output...)") {

let publisher = [1].publisher // 여기까지 1

  

publisher

.append(2, 3) // 추가되어서 1,2,3

.append(4) // 추가되어서 1,2,3,4

.sink(receiveValue: { print($0) })

.store(in: &subscriptions)

}

```

  

```swift

——— Example of: append(Output...) ———

1

2

3

4

```

  

추가되지 않기 때문에 정상적으로 작동하며

  

```swift

example(of: "append(Output...) #2") {

let publisher = PassthroughSubject<Int, Never>()

  

publisher

.append(3, 4)

.append(5)

.sink(receiveValue: { print($0) })

.store(in: &subscriptions)

publisher.send(1)

publisher.send(2)

}

```

  

```swift

——— Example of: append(Output...) #2 ———

1

2

```

  

추가되었으나 완료가 되지 않아 정상적으로 작동하지 않습니다.

```swift
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

```

```swift
——— Example of: append(Output...) #2 ———
1
2
3
4
5

```

### **append(Sequence)**

![스크린샷_2022-05-22_오전_12 44 12](https://user-images.githubusercontent.com/50395024/169661718-e5ae4680-656d-406f-bfaa-4b68a3d7b00e.png)

```swift
example(of: "append(Sequence)") {
  let publisher = [1].publisher // 여기까지 1
    
  publisher
    .append([2, 3]) // 추가되어 1,2,3
    .append(Set([4, 5])) // 추가되어 1,2,3,5,4 (set임으로 1,2,3,4,5가 될 수 있음)
    .append(stride(from: 6, to: 9, by: 2)) // 추가되어 1,2,3,5,4,6,8
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

```

```swift
——— Example of: append(Sequence) ———
1
2
3
5
4
6
8

```

### **append(Publisher)**

![스크린샷_2022-05-22_오전_12 49 24](https://user-images.githubusercontent.com/50395024/169661720-be9c3bf4-6415-4ba1-96c1-a2109f67a092.png)

```swift
example(of: "append(Publisher)") {
  let publisher1 = [1, 2].publisher
  let publisher2 = [3, 4].publisher
  
  publisher1
    .append(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

```

```swift
——— Example of: append(Publisher) ———
1
2
3
4

```

## **Advanced combining**

### **switchToLatest**

switchToLatest는 복잡하지만 유용하게 쓰일 것 입니다.

![스크린샷_2022-05-22_오전_12 57 00](https://user-images.githubusercontent.com/50395024/169661722-f13808a0-3831-4df9-a6ff-de5f9bb44573.png)

```swift
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
    

        // 아래 코드들이 없으면 Completed!가 프린트되지 않음
    publisher3.send(completion: .finished)
    publishers.send(completion: .finished)
}

```

```swift
——— Example of: switchToLatest ———
1
2
4
5
7
8
9
Completed!

```

이것이 실제 앱에서 유용한 이유를 잘 모르겠다면 다음 시나리오를 고려해 보십시오.

사용자가 네트워크 요청을 트리거하는 버튼을 누릅니다. → 직후에 사용자는 버튼을 다시 누르면 두 번째 네트워크 요청이 트리거됩니다.

여기서 중요한 점은 다른 네트워크 요청이 들어오게 되면 이전에 요청을 제거하고 최신 요청만 진행하고 싶다는 것 입니다.

이와 같은 경우를 예시로 알아봅시다.

```swift
example(of: "switchToLatest - Network Request") {
    let url = URL(string: "<https://source.unsplash.com/random>")!
    // Unsplash의 공용 API에서 임의 이미지를 가져오기 위해 네트워크 요청을 수행하는 getImage() 함수
    func getImage() -> AnyPublisher<UIImage?, Never> {
        URLSession.shared
            .dataTaskPublisher(for: url)
            .map { data, _ in UIImage(data: data) }
            .print("image")
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
        
    let taps = PassthroughSubject<Void, Never>()
    taps
        .map { _ in getImage() } 
                // 버튼을 누르면 getImage()를 호출하여 임의의 이미지에 대한 새 네트워크 요청에 탭을 매핑
                // 이는 기본적으로 Publisher<Void, Never>를 Publisher<Publisher<UIImage?, Never>, Never>로 변환합니다.
        .switchToLatest() // 한 publisher만 값을 내보내고 나머지 구독은 자동으로 취소
        .sink(receiveValue: { _ in })
        .store(in: &subscriptions)
    
    taps.send() // 처음 탭하여 이미지 가져옴
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // 3초 뒤에 탭하여 새로운 이미지를 가져옴
        taps.send()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) { // 두번째 탭한 뒤 0.1초 뒤에 탭하여 새로운 이미지를 가져옴
        taps.send()
    }
}

```

```swift
——— Example of: switchToLatest - Network Request ———
image: receive subscription: (DataTaskPublisher)
image: request unlimited
image: receive value: (Optional(<UIImage:0x6000000fd0e0 anonymous {1080, 1620} renderingMode=automatic>))
image: receive finished
image: receive subscription: (DataTaskPublisher)
image: request unlimited
image: receive cancel
image: receive subscription: (DataTaskPublisher)
image: request unlimited
image: receive value: (Optional(<UIImage:0x6000000e02d0 anonymous {1080, 1619} renderingMode=automatic>))
image: receive finished

```

두 번째와 세 번째 탭 사이의 간격이 10분의 1초에 불과하기 때문에 실제로 두 개의 이미지만 가져올 수 있습니다.

두번째 탭을 한 후 사진을 가져오기 전에 새 요청으로 전환되어 자동으로 두번째 구독을 취소하기 떄문입니다.

따라서 위에서 두번째 구독 후 이미지 대신 `image: receive cancel`이 된 것을 볼 수 있습니다.

따라서 탭을 세번했지만 UIImage가 총 두개만 보이게 되는 것입니다.

팁: 아래 사진 속 오른쪽 파란 버튼을 눌러 바뀌어 가는 사진을 볼 수 있습니다.

![스크린샷_2022-05-22_오전_1 34 18](https://user-images.githubusercontent.com/50395024/169661723-742cdbfd-6362-4a1c-93d1-099db1ee7fe6.png)

또는

![스크린샷_2022-05-22_오전_1 39 01](https://user-images.githubusercontent.com/50395024/169661725-d8534633-f342-4d03-9e9a-962c7f567dee.png)

value history를 눌러 이전 사진을 볼 수도 있습니다.

### **merge(with:)**

동일한 유형의 publisher을 합쳐 배출하는 값을 중간중간 끼워 넣는 연산자입니다.

![스크린샷_2022-05-22_오전_1 42 39](https://user-images.githubusercontent.com/50395024/169661726-e1d79631-3595-4d69-88f9-26e29debc851.png)

### **combineLatest**

combineLatest는 여러 게시자를 결합할 수 있는 또 다른 연산자입니다. 또한 다양한 가치 유형의 게시자를 결합할 수 있으며, 이는 매우 유용할 수 있습니다.

그러나 모든 publisher에서 배출된 값을 인터리브하는 대신, 어느 publisher가 값을 방출할 때마다 `모든 publisher의 최신 값을 가진 튜플을 방출`한다.

combineLatest를 결합하기 위해 모든 publisher는 combineLatest 자체에서 값을 하나 이상 내보내야 합니다.

![스크린샷_2022-05-22_오전_1 45 53](https://user-images.githubusercontent.com/50395024/169661727-e076ac00-13e9-4e66-8582-1309a7bffbcf.png)

```swift
example(of: "combineLatest") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    
    publisher1
        .combineLatest(publisher2)
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { print("P1: \\($0), P2: \\($1)") }
        )
        .store(in: &subscriptions)
    
    publisher1.send(1) // 아직 publisher2의 값이 없기 때문에 combine될 수 없음
    publisher1.send(2)
    
    publisher2.send("a") // 모든 publisher에서 최소 하나의 값이 배출 되었음으로 모든 publisher에서 최신의 값이 combine됨
    publisher2.send("b")
    
    publisher1.send(3)
    
    publisher2.send("c")
    
    publisher1.send(completion: .finished)
    publisher2.send(completion: .finished)
}

```

```swift
——— Example of: combineLatest ———
P1: 2, P2: a
P1: 2, P2: b
P1: 3, P2: b
P1: 3, P2: c
Completed

```

### **zip**

이 연산자는 동일한 인덱스의 쌍이 되는 값의 튜플을 내보내는 연산자입니다.

따라서 같은 인덱스의 값이 배출되기를 기다린 다음 두 publisher를 새 값이 방출될 때마다 같은 인덱스의 값이 있다면 튜플을 내보냅니다.

![스크린샷_2022-05-22_오전_1 51 45](https://user-images.githubusercontent.com/50395024/169661729-63bfb5ce-bca5-4e5b-81af-e6afe0bb52dc.png)

```swift
example(of: "zip") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    
    publisher1
        .zip(publisher2)
        .sink(
            receiveCompletion: { _ in print("Completed") },
            receiveValue: { print("P1: \\($0), P2: \\($1)") }
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

```

```swift
——— Example of: zip ———
P1: 1, P2: a
P1: 2, P2: b
P1: 3, P2: c
Completed

```
