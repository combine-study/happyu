import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "Create a Blackjack card dealer") {
    let dealtHand = PassthroughSubject<Hand, HandError>()
    
    func deal(_ cardCount: UInt) {
        var deck = cards
        var cardsRemaining = 52
        var hand = Hand()
        
        for _ in 0 ..< cardCount {
            let randomIndex = Int.random(in: 0 ..< cardsRemaining)
            hand.append(deck[randomIndex])
            deck.remove(at: randomIndex)
            cardsRemaining -= 1
        }
        
        // Add code to update dealtHand here
        if hand.points > 21 {
            dealtHand.send(completion: .failure(.busted))
        } else {
            dealtHand.send(hand)
        }
    }
    
    // Add subscription to dealtHand here
    _ = dealtHand
        .sink(receiveCompletion: {
            // 실패의 경우
            if case let .failure(error) = $0 {
                print(error)
            }
        }, receiveValue: { hand in
            print(hand.cardString, "for", hand.points, "points")
        })
    
    deal(3) // 플레이그라운드를 실행할 때마다 3장의 카드를 처리
    // 블랙잭의 실제 게임에서는 처음에 두 장의 카드를 받은 다음
    // 21이 되거나 버스트될 때까지<21을 초과할때까지> 추가카드<블랙잭에서 히트라고 함>를 받을지 결정
}
