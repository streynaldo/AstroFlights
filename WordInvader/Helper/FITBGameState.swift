//
//  GameManager.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import Foundation
import SpriteKit

class FITBGameState : ObservableObject {
    static let shared = FITBGameState()
    
    @Published var score: Int = 0
    @Published var health: Int = 5
    @Published var streak: Int = 0
    @Published var isGameOver: Bool = false
    @Published var currentTaskText: String = ""
    @Published var isCountingDown: Bool = false
    
    // Achievement reporting (if needed)
    @Published var reportedAchievements: Set<String> = []

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
    
    func randomMotivation() -> String {
        let messages = [
            "Keep practicing and beat your high score!",
            "You got this, Captain!",
            "Never give up, pilot! Try again!",
            "Your spaceship needs you!",
            "One more try! Show them who's boss!"
        ]
        return messages.randomElement() ?? ""
    }

    func resetForNewGame() {
        reset()
        reportedAchievements.removeAll()
    }

    func checkAchievementsAndSubmitScore(for manager: GameKitManager, finalScore: Int, onNewHighScore: (() -> Void)? = nil) {
        manager.submitScore(finalScore, to: "fill_in_the_blank_leaderboard")
        if finalScore >= 100 {
            manager.reportAchievement(identifier: "100_score_fill_in_the_blank")
            reportedAchievements.insert("100_score_fill_in_the_blank")
        }
        if finalScore >= 1000 {
            manager.reportAchievement(identifier: "1000_score_fill_in_the_blank")
            reportedAchievements.insert("1000_score_fill_in_the_blank")
        }
        let personalHighScoreKey = "personalHighScore_FITB"
        let previousHigh = UserDefaults.standard.integer(forKey: personalHighScoreKey)
        if finalScore > previousHigh {
            UserDefaults.standard.set(finalScore, forKey: personalHighScoreKey)
            manager.reportAchievement(identifier: "new_personal_record_fill_in_the_blank")
            reportedAchievements.insert("new_personal_record_fill_in_the_blank")
            onNewHighScore?()
        }
    }
}
