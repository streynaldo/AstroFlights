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

class STLGameState: ObservableObject, Identifiable {
    
    // MARK: - Published Properties for SwiftUI View
    @Published var score: Int = 0
    @Published var health: Int = 5
    @Published var currentWord: String = ""
    @Published var currentLetterIndex: Int = 0
    @Published var isGameOver: Bool = false
    @Published var isPaused: Bool = false
    @Published var isCountingDown: Bool = false
    
    // MARK: - Callbacks for View
    var onWordCompleted: (() -> Void)?
    var onNewHighScore: (() -> Void)?
    
    // MARK: - Private Properties
    private var wordList: [String]
    private var currentWordIndexInList: Int = -1
    private var personalHighScore: Int
    private var reportedAchievements: Set<String> = []
    private var isWordOnScreen: Bool = false // Variabel kontrol kunci
    
    init(words: [String]) {
        self.wordList = words.shuffled()
        self.personalHighScore = UserDefaults.standard.integer(forKey: "personalHighScore_STL")
    }
    
    // MARK: - Game Flow
    func startGame() {
        resetGame()
    }
    
    func resetGame() {
        score = 0
        health = 5
        currentWordIndexInList = -1
        isGameOver = false
        isPaused = false
        isCountingDown = false
        reportedAchievements.removeAll()
        nextWord()
    }
    
    private func nextWord() {
        guard !isGameOver else { return }
        
        currentWordIndexInList += 1
        if currentWordIndexInList >= wordList.count {
            print("Congratulations! You've completed all words.")
            endGame()
            return
        }
        
        currentWord = wordList[currentWordIndexInList]
        currentLetterIndex = 0
        isWordOnScreen = true // Tandai bahwa kata baru seharusnya ada di layar
    }
    
    private func endGame() {
        if !isGameOver {
            isGameOver = true
            isWordOnScreen = false
            print("Game Over! Final Score: \(score).")
            NotificationCenter.default.post(name: .didSTLGameOver, object: self)
        }
    }
    
    // MARK: - Game Actions
    
    func correctLetterShot(gameKitManager: GameKitManager) {
        currentLetterIndex += 1
        
        if currentLetterIndex >= currentWord.count {
            score += 25
            checkRealtimeAchievements(for: gameKitManager, currentScore: score)
            onWordCompleted?()
            
            isWordOnScreen = false // Kata sudah tidak aktif lagi
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.nextWord()
            }
        }
    }
    
    func incorrectLetterShot() {
        score = max(0, score - 10)
    }
    
    func obstacleMissedOrHitPlayer() {
        health -= 1
        if health <= 0 {
            health = 0
            endGame()
        }
    }
    
    func wordMissed() {
        // HANYA panggil jika kita memang mengharapkan ada kata di layar
        guard !isGameOver, isWordOnScreen else { return }
        
        health -= 1
        isWordOnScreen = false // Kata sudah dianggap hilang
        
        if health <= 0 {
            health = 0
            endGame()
            return
        }
        
        // Langsung lanjut ke kata berikutnya setelah penalti
        nextWord()
    }
    
    // MARK: - GameKit & Achievements
    
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
    
    func submitFinalScoreToLeaderboard(for manager: GameKitManager) {
        manager.submitScore(score, to: "sort_the_letters_leaderboard")
    }
    
    private func saveHighScoreToDevice() {
        UserDefaults.standard.set(self.personalHighScore, forKey: "personalHighScore_STL")
    }
}
