# Chapter 03: **Filtering Operators**

Publisher가 내보낸 값이나 이벤트를 제한하고 일부만 사용하려는 경우에 필요한 Operator

이 장의 대부분의 연산자는 filter vs tryFilter와 같이 try 접두사와 평행을 이룹니다. 

try가 throwing 클로저를 제공하고 클로저 내에서 throw하는 모든 오류는 발생된 오류와 함께 publisher를 종료합니다. 이런 차이점 외에는 다른 것이 없기에 우리는 try는 생략하고 설명할것입니다.

## **Filtering basics**

이 연산자는 Bool을 반환할 것으로 예상되는 클로저를 사용합니다.

![스크린샷 2022-05-13 오전 11.01.30.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/32cef4ce-ecc9-43d4-b733-b9ac7ae92f1f/스크린샷_2022-05-13_오전_11.01.30.png)

```swift
example(of: "filter") {
  let numbers = (1...10).publisher
  numbers
    .filter { $0.isMultiple(of: 3) }
    .sink(receiveValue: { n in
      print("\(n) is a multiple of 3!")
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

![스크린샷 2022-05-13 오전 11.22.36.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/8442c71d-96aa-4607-84a5-1f6ac5338646/스크린샷_2022-05-13_오전_11.22.36.png)

이 연산자에 인수를 제공할 필요가 없다는 점에 유의하세요

removeDuplicates는 문자열을 포함하여 Equatable을 준수하는 모든 값에 대해 자동으로 작동합니다.

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

map기능을 하면서 nil을 filtering 해주는 operator

![스크린샷 2022-05-13 오전 11.21.57.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/fa64cdfd-7830-4822-908b-ad66cd4c51a4/스크린샷_2022-05-13_오전_11.21.57.png)

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

publisher가 값 내보내기를 완료했다는 사실만 알면 되고 실제 값이 무엇인지는 중요하지 않을때 쓰는 operator도 제공합니다.
![스크린샷 2022-05-13 오전 11.22.13.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/5e095771-b1fe-4a77-a1c2-76beea832338/스크린샷_2022-05-13_오전_11.22.13.png)

```swift
example(of: "ignoreOutput") {
    let numbers = (1...10_000).publisher
    
    numbers
        .ignoreOutput()
        .sink(receiveCompletion: { print("Completed with: \($0)") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}
```

```swift
——— Example of: ignoreOutput ———
Completed with: finished
```
