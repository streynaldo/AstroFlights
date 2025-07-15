//
//  GameState.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import Foundation
import SwiftUI

extension Notification.Name {
    static let didGameOver = Notification.Name("didGameOver")
}

class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var lives: Int = 50
    var isGameOver: Bool = false
    @Published var currentWord: String = ""
    @Published var currentLetterIndex: Int = 0
    weak var scene: GameScene?
    var onWordCompleted: (() -> Void)?
    var onNewHighScore: (() -> Void)?
    private var wordList: [String]
    private var currentWordIndexInList: Int = -1
    private var personalHighScore: Int = 0
    
    init(words: [String]) {
        self.wordList = words.shuffled()
        self.personalHighScore = UserDefaults.standard.integer(forKey: "personalHighScore")
    }
    
    private func gameOver() {
        if !isGameOver {
            isGameOver = true
            NotificationCenter.default.post(name: .didGameOver, object: self)
        }
    }
    
    func startGame() {
        skipToNextWord()
    }
    
    func skipToNextWord() {
        guard !isGameOver else { return }
        currentWordIndexInList += 1
        if currentWordIndexInList >= wordList.count { gameOver(); return }
        currentWord = wordList[currentWordIndexInList]
        currentLetterIndex = 0
        scene?.spawnNextWord()
    }
    
    func incorrectAction() {
        lives -= 1
        if lives <= 0 { gameOver() }
    }
    
    func correctLetterShot() {
        currentLetterIndex += 1
        if currentLetterIndex >= currentWord.count {
            score += 10000
            onWordCompleted?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.skipToNextWord() }
        }
    }
    
    func checkAchievementsAndSubmitScore(for manager: GameKitManager, finalScore: Int) {
        manager.submitScore(finalScore, to: "wordinvaders_main_leaderboard")
        if finalScore >= 100 { manager.reportAchievement(identifier: "achievement_score_100") }
        if finalScore >= 1000 { manager.reportAchievement(identifier: "achievement_legendary_score") }
        if finalScore > self.personalHighScore {
            self.personalHighScore = finalScore
            manager.reportAchievement(identifier: "achievement_personal_best")
            onNewHighScore?()
            saveHighScoreToDevice()
        }
    }
    
    private func saveHighScoreToDevice() {
        UserDefaults.standard.set(self.personalHighScore, forKey: "personalHighScore")
    }
}
