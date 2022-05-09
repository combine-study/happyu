
# Chapter 1: Hello, Combine!

이 책의 목표 : Combine 프레임워크에 대해 설명하고, 이벤트 저치에 대한 선언적 프로그래밍을 설명

-   combine - 이벤트에 따른 코드를 체인으로 연결하여 처리 할 수 있음
    
    (delegate callback, completion handler closure로 하던 것과는 다른 방식임<가독성이 좋음>)
    

## Asynchronous programming

UIKit과 같은 프레임워크는 **다중 스레드 언어**임

```swift
--- Thread 1 ---
begin
    var name = "Tom"
    print(name)
--- Thread 2 ---
    name = "Billy Bob"
--- Thread 1 ---
    name += " Harding"
    print(name)
end

```

각 코드가 다른 코어에서 동시에 실행된다면 어떤 코드가 먼저 공유 상태를 수정하는지 알기 어려움

→ **프로그램을 실행할 때마다 다른 결과를 볼 수 있습니다**

## Foundation and UIKit/AppKit

**대부분의 일반적인 코드는 일부 작업을 비동기식으로 수행하고 모든 UI 이벤트는 본질적으로 비동기식이므로 전체 앱 코드가 실행될 순서를 가정하는 것은 불가능합니다.**

아래와 같은 방식으로 비동기 프로그래밍을 하는 것이 가능하지만, 여러 종류의 비동기 API를 사용하게 된다

<img width="376" alt="스크린샷_2022-04-29_오후_3 27 16" src="https://user-images.githubusercontent.com/50395024/166291388-f7e65771-c226-45d5-b674-ccf4a252148e.png">

`Combine`은 비동기 코드를 설계하고 작성하기 위해 Swift 생태계에 **공통의** 고급 언어를 도입합니다.

Apple은 Combine을 다른 프레임워크에도 통합했음으로 <Timer, NotificationCenter 및 Core Data와 같은 Core Framework>는 이미 해당언어를 사용합니다.

또한, **SwiftUI**(UI프레임워크)를 Combine과 쉽게 통합하도록 디자인하였습니다.

<img width="339" alt="스크린샷_2022-05-02_오후_2 32 01" src="https://user-images.githubusercontent.com/50395024/166291396-6153ff4b-2499-4368-859d-31cf345d14d0.png">

## Combine basics

세가지 핵심요소

-   publishers
-   operators
-   subscribers

## Publishers

`Publishers`는 `subscribers`와 같은 이해관계자들에게 시간지남에 따른 값을 방출하는 역할을 함

publisher가 방출할 수 있는 이벤트:

-   publisher의 generic `Output type`
-   `successful completion`
-   publisher의 `Failure type`

<img width="459" alt="스크린샷_2022-05-02_오후_6 45 08" src="https://user-images.githubusercontent.com/50395024/166291404-37627e77-5b27-40aa-b6de-2824b45fd14b.png">

delegate를 추가, 완료 callback을 삽입과 같은 처리 방법을 찾는 대신 Publisher를 사용하면 됨

Publisher의 가장 좋은 기능 중 하나는 **오류 처리 기능이 내장**되어 있다는 것

Publisher protocol은 위의 다이어그램에서 볼 수 있듯이 아래의 2개의 `generic` 타입을 가짐

-   `Publisher.Output`: _Int_ 타입의 Publisher의 경우 _String_ 또는 _Date_ 값을 내보낼 수 없습니다.
-   `Publisher.Failure`: 실패할 경우 Publisher가 던질 수 있는 오류 유형 (위의 다이어그램과 같은 never - 절대 실패할 수 없는 경우)

## Operators

동일한 Publisher 또는 새 Publisher를 반환하는 Publisher protocol에 선언된 메서드입니다.

**여러 연산자를 차례로 호출하여 효과적으로 chaining할 수 있기 때문에 매우 유용합니다.**

<img width="464" alt="스크린샷_2022-05-02_오후_8 38 55" src="https://user-images.githubusercontent.com/50395024/166291405-31178c39-87e1-448b-b6ac-70f63fe8667a.png">

## Subscribers

구독자는 일반적으로 방출된 출력 또는 완료 이벤트로 "무언가"를 수행합니다.

<img width="396" alt="스크린샷_2022-05-02_오후_8 41 42" src="https://user-images.githubusercontent.com/50395024/166291406-fc2771e9-f7c3-48d7-a2bf-d304c311ab98.png">

현재 Combine은 data streams 작업을 간단하게 만드는 두 가지 기본 제공 subscriber를 제공합니다.

-   `sink` : 출력 값과 완성을 수신할 코드와 함께 클로저를 제공할 수 있습니다. 거기에서 받은 이벤트로 마음이 원하는 모든 것을 할 수 있습니다.
-   `assign` : 사용자 정의 코드 없이 결과 출력을 데이터 모델 또는 UI 컨트롤의 일부 속성에 바인딩하여 키 경로를 통해 화면에 직접 데이터를 표시할 수 있습니다.

**데이터에 대한 다른 요구 사항이 있는 경우 custom subscribers를 만드는 것이 publishers를 만드는 것보다 훨씬 쉽습니다.**

## Subscriptions

`publishers`은 잠재적으로 출력을 수신할 `subscribers`가 없는 경우 값을 내보내지 않습니다.

**구독(Subscriptions)**은 고유한 사용자 지정 코드와 오류 처리를 사용하여 **비동기 이벤트 체인을 한 번만 선언하면**, 완료 후 데이터를 push하거나 pull을 하거나 call back 등을 할 필요 없이 **시스템이 모든 것을 실행하게 할 수 있다.**

구독은 사용자 제스처, 타이머 종료 등의 이벤트가 게시자 중 하나를 깨울 때마다 **비동기식으로 "실행"**됩니다.

더 좋은 점은 Combine에서 제공하는 `Cancellable` **프로토콜 덕분에 구독을 특별히 메모리 관리할 필요가 없다**는 것입니다.

시스템에서 제공하는 subscribers(sink, assign) 모두 Cancellable을 준수합니다.

즉, 구독 코드가 **Cancellable 개체를 return**합니다

## **"표준" 코드에 비해 Combine 코드의 이점은 무엇입니까?**

Combine은 비동기 코드에 다른 추상화를 추가하는 것을 목표로 합니다

Combine의 특징:

-   Combine은 시스템 수준에서 통합됩니다. 즉, Combine 자체는 공개적으로 사용할 수 없는 언어 기능을 사용하여 직접 구축할 수 없는 API를 제공합니다.
-   Combine은 Publisher 프로토콜의 메서드로 많은 일반적인 작업을 추상화하고 이미 잘 테스트되었습니다.
-   모든 비동기 작업이 동일한 인터페이스(Publisher)를 사용하면 구성 및 재사용이 매우 강력해집니다.
-   Combine의 연산자는 구성 가능성이 높습니다. 새 연산자(operators)를 생성해야 하는 경우 Combine의 나머지 부분과 즉시 plug-and-play할 것입니다.
-   Combine의 비동기 연산자는 이미 테스트되었습니다. 당신에게 남은 일은 자신의 비즈니스 로직을 테스트하는 것뿐입니다.

## App architecture

Combine은 앱을 구성하는 방법에 영향을 주는 프레임워크가 아닙니다. MVC, MVVM, VIPER 등에서 사용할 수 있습니다.

Combine 코드를 반복적이고 선택적으로 추가하여 코드베이스에서 **개선하려는 부분에서만 사용할 수 있습니다.**

**Combine과 SwiftUI를 동시에 채택한다면 이야기가 약간 다릅니다.**

**이 경우 MVC 아키텍처에서 C를 삭제하는 것이 정말 합리적입니다.**

뷰 컨트롤러는 Combine/SwiftUI 팀을 상대할 기회가 없습니다.

데이터 모델~뷰까지 반응형 프로그래밍을 사용할 때 뷰를 제어하기 위해 특별한 컨트롤러가 필요하지 않습니다.

----------

## Key points

-   Combine은 시간이 지남에 따라 **비동기 이벤트를 처리하기 위한 선언적 반응 프레임워크**입니다.
-   비동기 프로그래밍을 위한 도구 통합, 변경 가능한 상태 처리 및 플레이어의 오류 처리와 같은 기존 문제를 해결하는 것을 목표로 합니다.
-   Combine은 시간 경과에 따라 이벤트를 내보내는 `publishers`, 업스트림 이벤트를 비동기식으로 처리 및 조작하는 `operators`, 결과를 소비하고 유용한 작업을 수행하는 `subscribers`의 세 가지 주요 유형을 중심으로 이루어집니다.
