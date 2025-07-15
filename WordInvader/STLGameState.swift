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
    @Published var lives: Int = 100
    var isGameOver: Bool = false
    @Published var currentWord: String = ""
    @Published var currentLetterIndex: Int = 0
    
    var isWordOnScreen: Bool = false
    
    weak var scene: STLGameScene?
    var onWordCompleted: (() -> Void)?
    var onNewHighScore: (() -> Void)?
    
    private var wordList: [String]
    private var currentWordIndexInList: Int = -1
    private var personalHighScore: Int = 0
    
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
    
    func correctLetterShot() {
        currentLetterIndex += 1
        
        if currentLetterIndex >= currentWord.count {
            isWordOnScreen = false
            
            score += 50
            onWordCompleted?()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.nextWord()
            }
        }
    }
    
    func skipToNextWord() {
        if isWordOnScreen {
            lives -= 10
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
        lives -= 5
        if lives <= 0 {
            lives = 0
            gameOver()
        }
    }
    
    func checkAchievementsAndSubmitScore(for manager: GameKitManager, finalScore: Int) {
        manager.submitScore(finalScore, to: "wordinvaders_main_leaderboard")
        
        if finalScore >= 100 {
            manager.reportAchievement(identifier: "achievement_score_100")
        }
        if finalScore >= 1000 {
            manager.reportAchievement(identifier: "achievement_legendary_score")
        }
        
        if finalScore > self.personalHighScore {
            self.personalHighScore = finalScore
            manager.reportAchievement(identifier: "achievement_personal_best")
            onNewHighScore?()
            saveHighScoreToDevice()
            print("New personal high score: \(finalScore)")
        }
    }
    
    private func saveHighScoreToDevice() {
        UserDefaults.standard.set(self.personalHighScore, forKey: "personalHighScore_STL")
    }
}
