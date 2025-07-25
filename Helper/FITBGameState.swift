import Foundation
import SpriteKit

class FITBGameState: ObservableObject {
    static let shared = FITBGameState()
    
    var score: Int = 0
    var health: Int = 5
    var isGameOver: Bool = false
    var currentTaskText: String = ""
    @Published var isCountingDown: Bool = false
    
    private init() {}
    
    // Modularized logic from FITBGameScene
    func updateScore(by value: Int) {
        score += value
        if score < 0 { score = 0 }
    }
    
    func updateHealth(by value: Int) {
        health += value
        if health < 0 { health = 0 }
        if health > 5 { health = 5 }
    }
    
    func reset() {
        score = 0
        health = 5
        isGameOver = false
        currentTaskText = ""
    }
    
    func setGameOver() {
        isGameOver = true
    }
    
    func setCurrentTaskText(_ text: String) {
        currentTaskText = text
    }
}
