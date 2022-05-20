
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
