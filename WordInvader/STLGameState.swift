//
//  GameState.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import Foundation
import SwiftUI

extension Notification.Name {
    static let didSTLGameOver = Notification.Name("didSTLGameOver")
}

class STLGameState: ObservableObject {
    
    @Published var score: Int = 0
    @Published var lives: Int = 5
    @Published var currentWord: String = ""
    @Published var currentLetterIndex: Int = 0
    
    var isWordOnScreen: Bool = false
    var isGameOver: Bool = false
    
    weak var scene: STLGameScene?
    var onWordCompleted: (() -> Void)?
    var onNewHighScore: (() -> Void)?
    
    private var wordList: [String]
    private var currentWordIndexInList: Int = -1
    private var personalHighScore: Int = 0
    
    private var reportedAchievements: Set<String> = []
    
    init(words: [String]) {
        self.wordList = words.shuffled()
        self.personalHighScore = UserDefaults.standard.integer(forKey: "personalHighScore_STL")
    }
    
    private func gameOver() {
        if !isGameOver {
            isGameOver = true
            isWordOnScreen = false
            
            scene?.cleanupScene()
            
            NotificationCenter.default.post(name: .didSTLGameOver, object: self)
            print("Game Over! Final Score: \(score). Notification sent.")
        }
    }
    
    func startGame() {
        nextWord()
    }
    
    private func nextWord() {
        guard !isGameOver else { return }
        
        currentWordIndexInList += 1
        if currentWordIndexInList >= wordList.count {
            print("Congratulations! You've completed all words.")
            gameOver()
            return
        }
        
        currentWord = wordList[currentWordIndexInList]
        currentLetterIndex = 0
        
        isWordOnScreen = true
        scene?.spawnNextWord()
    }
    
    func correctLetterShot(gameKitManager: GameKitManager) {
        currentLetterIndex += 1
        
        if currentLetterIndex >= currentWord.count {
            isWordOnScreen = false
            
            score += 25
            
            checkRealtimeAchievements(for: gameKitManager, currentScore: score)
            scene?.showCoinRewardEffect()
            
            onWordCompleted?()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.nextWord()
            }
        }
    }
    
    func skipToNextWord() {
        if isWordOnScreen {
            lives -= 1
        }
        
        isWordOnScreen = false
        
        if lives <= 0 {
            lives = 0
            gameOver()
        } else {
            DispatchQueue.main.async {
                self.nextWord()
            }
        }
    }
    
    func incorrectAction() {
        score -= 10
        if score < 0 {
            score = 0
        }
    }
    
    private func checkRealtimeAchievements(for manager: GameKitManager, currentScore: Int) {
        let score100ID = "100_score_sort_the_letters"
        if currentScore >= 100 && !reportedAchievements.contains(score100ID) {
            manager.reportAchievement(identifier: score100ID)
            reportedAchievements.insert(score100ID)
        }
        
        let score1000ID = "1000_score_sort_the_letters"
        if currentScore >= 1000 && !reportedAchievements.contains(score1000ID) {
            manager.reportAchievement(identifier: score1000ID)
            reportedAchievements.insert(score1000ID)
        }
        
        let personalBestID = "new_personal_record_sort_the_letters"
        if currentScore > self.personalHighScore {
            self.personalHighScore = currentScore
            
            if !reportedAchievements.contains(personalBestID) {
                manager.reportAchievement(identifier: personalBestID)
                reportedAchievements.insert(personalBestID)
            }
            
            onNewHighScore?()
            saveHighScoreToDevice()
        }
    }
    
    func submitFinalScoreToLeaderboard(for manager: GameKitManager, finalScore: Int) {
        manager.submitScore(finalScore, to: "sort_the_letters_leaderboard")
    }
    
    private func saveHighScoreToDevice() {
        UserDefaults.standard.set(self.personalHighScore, forKey: "personalHighScore_STL")
    }
}
