
# Chapter06: **Time Manipulation Operators**

반응형 프로그램밍의 핵심 아이디어는 시간이 지남에 따라 비동기 이벤트 흐름을 모델링하는 것이다.

이와 관련하여, Combine 프레임워크는 시간을 처리할 수 있는 다양한 operator를 제공합니다.

combine과 같은 프레임워크를 사용할 때의 큰 이점 중 하나가 값 시퀀스의 시간 차원을 쉽고 간편하게 관리할 수 있다는 것입니다.

## Shifting time

가장 기본적인 시간 조작 연산자는 게시자의 값을 지연시켜 실제 발생한 값보다 나중에 값을 볼 수 있도록 합니다.

### delay(for:tolerance:scheduler:options)

upstream Publisher가 값을 방출할 때마다 값을 잠시 유지한 다음 사용자가 지정한 스케줄러에서 요청한 delay 후에 값을 내보냄

```swift
let valuesPerSecond = 1.0 // 값을 내보내는 주기
let delayInSeconds = 1.5 // 지연하는 초

let sourcePublisher = PassthroughSubject<Date, Never>()

let delayedPublisher = sourcePublisher.delay(
                                                for: .seconds(delayInSeconds), 
                                                scheduler: DispatchQueue.main
                                            )

let subscription = Timer
  .publish(every: 1.0 / valuesPerSecond, on: .main, in: .common)
  .autoconnect() // 즉시 시작
  .subscribe(sourcePublisher) // sourcePublisher subject를 통해 방출되는 값을 공급

// TimelineView는 Sources/Views.swift에 있는 코드로 타이머의 값을 표시할 타임라인을 보여줍니다.
let sourceTimeline = TimelineView(title: "Emitted values (\\(valuesPerSecond) per sec.):")
let delayedTimeline = TimelineView(title: "Delayed values (with a \\(delayInSeconds)s delay):")

let view = VStack(spacing: 50) {
  sourceTimeline
  delayedTimeline
}

PlaygroundPage.current.liveView = UIHostingController(rootView: view.frame(width: 375, height: 600))

// publisher들을 각각 타임라인에 연결하여 이벤트를 표시합니다.
sourcePublisher.displayEvents(in: sourceTimeline)
delayedPublisher.displayEvents(in: delayedTimeline)

```

위 코드는 라이브 뷰에서 볼 수 있도록 한 코드입니다.

<img width="207" alt="스크린샷_2022-06-02_오전_12 33 20" src="https://user-images.githubusercontent.com/50395024/171462001-d5fc7d7c-f332-47af-a876-aa4a34c184c8.png">

라이브뷰에서 보면 위와 같이 나오는데

원 안에 숫자는 실제 내용이 아닌 방출된 값의 수를 나타냅니다.

## **Collecting values**

특정 상황에서는 지정된 시간 간격으로 publisher에서 값을 수집(collecting)해야 할 수 있습니다.

짧은 기간에 걸쳐 값 그룹을 평균화하고 평균을 출력하려는 경우 등등.. 에서 유용하게 쓰일 수 있는 버퍼링의 한 형태입니다.

```swift
let valuesPerSecond = 1.0
let collectTimeStride = 4
let collectMaxCount = 2

let sourcePublisher = PassthroughSubject<Date, Never>()

// collectTimeStride 간격 동안 수신되는 값을 수집하는 collected publisher
let collectedPublisher = sourcePublisher
    .collect(.byTime(DispatchQueue.main, .seconds(collectTimeStride)))
    .flatMap { dates in dates.publisher } // 개별 값으로 분해하고 즉시 방출됩니다. 
// collectedPublisher와 비슷하지만 받을 수 있는 최대 개수가 있음(collectMaxCount)
let collectedPublisher2 = sourcePublisher
    .collect(.byTimeOrCount(DispatchQueue.main, .seconds(collectTimeStride), collectMaxCount))
    .flatMap { dates in dates.publisher }

let subscription = Timer
    .publish(every: 1.0 / valuesPerSecond, on: .main, in: .common)
    .autoconnect()
    .subscribe(sourcePublisher)

let sourceTimeline = TimelineView(title: "Emitted values:")
let collectedTimeline = TimelineView(title: "Collected values (every \\(collectTimeStride)s):")
let collectedTimeline2 = TimelineView(title: "Collected values (at most \\(collectMaxCount) every \\(collectTimeStride)s):")

let view = VStack(spacing: 40) {
    sourceTimeline
    collectedTimeline
    collectedTimeline2
}

PlaygroundPage.current.liveView = UIHostingController(rootView: view.frame(width: 375, height: 600))

sourcePublisher.displayEvents(in: sourceTimeline)
collectedPublisher.displayEvents(in: collectedTimeline)
collectedPublisher2.displayEvents(in: collectedTimeline2)

```

`.byTime` : collectTimeStride 간격 동안 수신되는 값을 수집하는 collected publisher를 만들 수 있고

`.byTimeOrCount` : 지정한시간 또는 수집할 이벤트의 Max를 정해줘서 둘중 하나라도 만족한다면 값이 게시됩니다.

** flatMap은 일련의 값을 게시자로 변화하여 시퀀스의 모든 값을 개별 값으로 즉시 내보내는 collection의 publisher extension를 사용합니다. **

<img width="207" alt="스크린샷_2022-06-02_오전_12 33 20" src="https://user-images.githubusercontent.com/50395024/171462009-8ae15998-4324-4d3f-9c9c-c838356d55f3.png">

## **Holding off on events**

사용자 인터페이스를 코딩할 때 텍스트 필드를 자주 처리합니다. Combine을 사용하여 텍스트 필드 내용을 작업에 연결하는 것은 일반적인 작업입니다. 예를 들어 텍스트 필드에 입력된 항목과 일치하는 항목 목록을 반환하는 검색 URL 요청을 보낼 수 있습니다.

그러나 물론 사용자가 문자를 입력할 때마다 요청을 보내는 것은 원하지 않습니다! **사용자가 잠시 타이핑이 끝났을 때만** 타이핑된 텍스트를 선택할 수 있는 일종의 메커니즘이 필요합니다.

Combine은 여기서 당신을 도울 수 있는 두 가지 연산자(debounce와 throttle)를 제공합니다.

### **Debounce**

아래는 "Hello World"라는 단어를 타이핑하는 사용자의 시뮬레이션을 테스트 하기 위한 코드입니다.

```swift
let subject = PassthroughSubject<String, Never>()

let debounced = subject
  .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
    // debounce하기 위해 여러 번 subscribe할 예정입니다.
    // 결과의 일관성을 보장하려면 share()를 사용하여 단일 구독 지점을 만들어 모든 구독자에게 동일한 결과를 동시에 보여주는 debounce를 만듭니다.
  .share()

let subjectTimeline = TimelineView(title: "Emitted values")
let debouncedTimeline = TimelineView(title: "Debounced values")

let view = VStack(spacing: 100) {
  subjectTimeline
  debouncedTimeline
}

PlaygroundPage.current.liveView = UIHostingController(rootView: view.frame(width: 375, height: 600))

subject.displayEvents(in: subjectTimeline)
debounced.displayEvents(in: debouncedTimeline)

let subscription1 = subject
  .sink { string in
        // deltaTime은 Sources/DeltaTime.swift에 정의된 동적 전역 변수이며 
        // 플레이그라운드가 실행되기 시작한 이후의 시간 차이를 포맷합니다.
    print("+\\(deltaTime)s: Subject emitted: \\(string)")
  }

let subscription2 = debounced
  .sink { string in
    print("+\\(deltaTime)s: Debounced emitted: \\(string)")
  }

public let typingHelloWorld: [(TimeInterval, String)] = [
  (0.0, "H"),
  (0.1, "He"),
  (0.2, "Hel"),
  (0.3, "Hell"),
  (0.5, "Hello"),
    (0.6, "Hello "),
  (2.0, "Hello W"),
  (2.1, "Hello Wo"),
  (2.2, "Hello Wor"),
  (2.4, "Hello Worl"),
  (2.5, "Hello World")
]

subject.feed(with: typingHelloWorld)

```

이제 출력을 보도록 하자

```swift
+0.0s: Subject emitted: H
+0.1s: Subject emitted: He
+0.2s: Subject emitted: Hel
+0.3s: Subject emitted: Hell
+0.5s: Subject emitted: Hello
+0.6s: Subject emitted: Hello 
+1.6s: Debounced emitted: Hello 
+2.2s: Subject emitted: Hello W
+2.2s: Subject emitted: Hello Wo
+2.4s: Subject emitted: Hello Wor
+2.4s: Subject emitted: Hello Worl
+2.5s: Subject emitted: Hello World
+3.5s: Debounced emitted: Hello World

```

1초 동안 대기하도록 Debounced를 구성했음으로 1.6초에서 가장 최근에 수신된 값을 방출합니다.

타이핑이 2.7초에 끝나고 1초 후에 3.7초에 바운스 킥이 끝나는 마지막 순간도 마찬가지다.

<aside> 💡 한 가지 주의해야 할 점은 Publisher의 완성이다. publisher가 마지막 값을 내보낸 직후에 완료하지만 Debounced에 대해 구성된 시간이 경과하기 전에 완료하면 Debounced된 publisher에 마지막 값이 표시되지 않습니다!

</aside>

### **Throttle**

```swift
let throttleDelay = 1.0

let subject = PassthroughSubject<String, Never>()

let throttled = subject
  .throttle(for: .seconds(throttleDelay), scheduler: DispatchQueue.main, latest: false)
  .share()

let subjectTimeline = TimelineView(title: "Emitted values")
let throttledTimeline = TimelineView(title: "Throttled values")

let view = VStack(spacing: 100) {
  subjectTimeline
  throttledTimeline
}

PlaygroundPage.current.liveView = UIHostingController(rootView: view.frame(width: 375, height: 600))

subject.displayEvents(in: subjectTimeline)
throttled.displayEvents(in: throttledTimeline)

let subscription1 = subject
  .sink { string in
    print("+\\(deltaTime)s: Subject emitted: \\(string)")
  }

let subscription2 = throttled
  .sink { string in
    print("+\\(deltaTime)s: Throttled emitted: \\(string)")
  }

subject.feed(with: typingHelloWorld)

```

위 코드는 .debounce를 .throttle로 변경한 거 외에는 다른것이 없는 코드입니다.

liveView를 보아도 크게 다른 것을 찾기 힘들 수도 있습니다.

하지만 어떤 일이 일어나고 있는지 디버그 콘솔에서 찾을 수 있습니다.

```swift
+0.0s: Subject emitted: H
+0.0s: Throttled emitted: H
+0.1s: Subject emitted: He
+0.2s: Subject emitted: Hel
+0.3s: Subject emitted: Hell
+0.5s: Subject emitted: Hello
+0.6s: Subject emitted: Hello
+1.0s: Throttled emitted: He
+2.2s: Subject emitted: Hello W
+2.2s: Subject emitted: Hello Wo
+2.2s: Subject emitted: Hello Wor
+2.4s: Subject emitted: Hello Worl
+2.7s: Subject emitted: Hello World
+3.0s: Throttled emitted: Hello W

```

-   subject가 첫번째 값을 방출하면 throttle이 즉시 relay되며 바로 값을 방출합니다.
-   1.0초마다 값을 보내 달라고 했음으로 1.0초 뒤에 값을 방출함
-   2.2초 후에 입력이 재개됩니다. 이 때 throttle은 아무것도 방출하지 않았음을 알 수 있습니다. publisher로부터 새 값이 수신되지 않았기 때문입니다.
-   입력이 완료된 후 3.0초에서 스로틀이 다시 작동합니다.
-   throttle은 지정된 간격 동안 대기한 다음 해당 간격 동안 수신한 값 중 첫 번째 또는 가장 최근의 값을 방출합니다. 일시정지는 신경 안 써요.

latest를 true로 바꾸면 어떤 일이 발생하는지 알아보기 위해 코드를 변경해봅시다.

```swift
let throttled = subject
  .throttle(for: .seconds(throttleDelay), scheduler: DispatchQueue.main, latest: true)
  .share()

```

```swift
+0.0s: Subject emitted: H
+0.0s: Throttled emitted: H
+0.1s: Subject emitted: He
+0.2s: Subject emitted: Hel
+0.3s: Subject emitted: Hell
+0.5s: Subject emitted: Hello
+0.6s: Subject emitted: Hello
+1.0s: Throttled emitted: Hello // 이전에는 He
+2.0s: Subject emitted: Hello W
+2.3s: Subject emitted: Hello Wo
+2.3s: Subject emitted: Hello Wor
+2.6s: Subject emitted: Hello Worl
+2.6s: Subject emitted: Hello World
+3.0s: Throttled emitted: Hello World // 이전에는 Hello W

```

출력되는 시간은 동일 하지만, 가장 빠른 값이 아닌 가장 최근의 값이 시간 창에 표시됩니다.

## **Timing out**

이 시간 조작 연산자의 다음 단계는 시간 제한입니다. 이것의 주된 목적은 실제 타이머를 시간 초과 조건과 의미적으로 구별하는 것이다. 따라서 Timing out 연산자가 실행되면 publisher가 `완료`되거나 사용자가 지정한 `오류`가 발생합니다. **두 경우 모두 publisher가 종료**됩니다.

```swift
enum TimeoutError: Error {
  case timedOut
}

let subject = PassthroughSubject<Void, TimeoutError>()

// 5초로 타임 아웃 제한
let timedOutSubject = subject.timeout(.seconds(5), scheduler: DispatchQueue.main, customError: { .timedOut })

let timeline = TimelineView(title: "Button taps")

let view = VStack(spacing: 100) {
  Button(action: { subject.send() }) {
    Text("5초 이내에 누르세요.")
  }
  timeline
}

PlaygroundPage.current.liveView = UIHostingController(rootView: view.frame(width: 375, height: 600))

timedOutSubject.displayEvents(in: timeline)

```

5초 미만의 간격으로 버튼을 계속 누르십시오. 시간 초과가 발생하지 않기 때문에 게시자가 완료되지 않습니다.

하지만 5초 동안 버튼을 누르지 않으면 timeOutSubject에서 오류가 발생합니다.

customError: { .timedOut } 가 있기 때문입니다. 이 코드가 없다면 오류가 나지 않고 완료가 됩니다.

<img width="248" alt="스크린샷_2022-06-02_오전_12 59 16" src="https://user-images.githubusercontent.com/50395024/171462016-d47d7f44-ceb5-4a19-9adc-eee3a809c5d9.png">

## **Measuring time**

**Measuring time** 연산자는 게시자가 방출한 두 연속 값 사이의 경과 시간을 확인해야 할 때 사용하는 도구입니다.

```swift
let subject = PassthroughSubject<String, Never>()

let measureSubject = subject.measureInterval(using: DispatchQueue.main)
let measureSubject2 = subject.measureInterval(using: RunLoop.main)

let subjectTimeline = TimelineView(title: "Emitted values")
let measureTimeline = TimelineView(title: "Measured values")

let view = VStack(spacing: 100) {
  subjectTimeline
  measureTimeline
}

PlaygroundPage.current.liveView = UIHostingController(rootView: view.frame(width: 375, height: 600))

subject.displayEvents(in: subjectTimeline)
measureSubject.displayEvents(in: measureTimeline)
measureSubject2.displayEvents(in: measureTimeline)

let subscription1 = subject.sink {
  print("+\\(deltaTime)s: Subject emitted: \\($0)")
}

let subscription2 = measureSubject.sink {
    // DispatchQueue.main는 간격 기준이 나노초임으로 1_000_000_000.0로 나눔
  print("+\\(deltaTime)s: Measure emitted: \\(Double($0.magnitude) / 1_000_000_000.0)")
}

let subscription3 = measureSubject2.sink {
  print("+\\(deltaTime)s: Measure2 emitted: \\($0)")
}

subject.feed(with: typingHelloWorld)

```

```swift
+0.0s: Measure emitted: 0.030181064
+0.0s: Subject emitted: H
+0.0s: Measure2 emitted: Stride(magnitude: 0.0305100679397583)
+0.1s: Measure emitted: 0.07847896
+0.1s: Subject emitted: He
+0.1s: Measure2 emitted: Stride(magnitude: 0.07814502716064453)
+0.2s: Measure emitted: 0.10745932
+0.2s: Subject emitted: Hel
+0.2s: Measure2 emitted: Stride(magnitude: 0.1075890064239502)
+0.3s: Measure emitted: 0.113350511
+0.3s: Subject emitted: Hell
+0.3s: Measure2 emitted: Stride(magnitude: 0.11326396465301514)
+0.5s: Measure emitted: 0.203994834
+0.5s: Subject emitted: Hello
+0.5s: Measure2 emitted: Stride(magnitude: 0.20398294925689697)
+0.6s: Measure emitted: 0.122805685
+0.6s: Subject emitted: Hello 
+0.6s: Measure2 emitted: Stride(magnitude: 0.1229710578918457)
+2.2s: Measure emitted: 1.543190019
+2.2s: Subject emitted: Hello W
+2.2s: Measure2 emitted: Stride(magnitude: 1.5430189371109009)
+2.2s: Measure emitted: 0.000271571
+2.2s: Subject emitted: Hello Wo
+2.2s: Measure2 emitted: Stride(magnitude: 0.00017309188842773438)
+2.4s: Measure emitted: 0.215582344
+2.4s: Subject emitted: Hello Wor
+2.4s: Measure2 emitted: Stride(magnitude: 0.21571195125579834)
+2.4s: Measure emitted: 0.000310677
+2.4s: Subject emitted: Hello Worl
+2.4s: Measure2 emitted: Stride(magnitude: 0.00022101402282714844)
+2.7s: Measure emitted: 0.320437637
+2.7s: Subject emitted: Hello World
+2.7s: Measure2 emitted: Stride(magnitude: 0.3204820156097412)

```

측정을 위해 사용하는 스케줄러는 정말로 개인의 취향에 따라 다릅니다. 일반적으로 모든 항목에 대해 Dispatch Queue를 사용하는 것이 좋습니다. 하지만 그건 네 개인적인 선택이야!
