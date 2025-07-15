//
//  GameState.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import Foundation

class STLGameState: ObservableObject {
    @Published var score: Int = 0
    @Published var lives: Int = 100
    @Published var isGameOver: Bool = false
    @Published var currentWord: String = ""
    @Published var currentLetterIndex: Int = 0
    
    // Tambahkan properti untuk referensi ke scene
    weak var scene: STLGameScene?
    
    private var wordList: [String]
    private var currentWordIndexInList: Int = -1
    
    // DIITAMBAHKAN: Closure untuk memberitahu view/scene bahwa kata telah selesai
    var onWordCompleted: (() -> Void)?
    
    // Properti untuk menyimpan high score lokal
    private var personalHighScore: Int {
        get { UserDefaults.standard.integer(forKey: "personalHighScore") }
        set { UserDefaults.standard.set(newValue, forKey: "personalHighScore") }
    }
    
    init(words: [String]) {
        self.wordList = words.shuffled()
    }
    
    func startGame() {
        // Fungsi ini dipanggil dari ContentView untuk memulai game
        // setelah scene siap.
        nextWord()
    }
    
    private func nextWord() {
        guard !isGameOver else { return }
        
        currentWordIndexInList += 1
        if currentWordIndexInList >= wordList.count {
            // Semua kata sudah selesai, akhiri game sebagai pemenang
            print("Congratulations! You've completed all words.")
            gameOver()
            return
        }
        
        currentWord = wordList[currentWordIndexInList]
        currentLetterIndex = 0
        
        // Panggil scene untuk memunculkan baris kata baru
        scene?.spawnNextWord()
    }
    
    func correctLetterShot() {
        currentLetterIndex += 1
        
        if currentLetterIndex >= currentWord.count {
            score += 50
            
            // DIITAMBAHKAN: Panggil closure saat kata selesai
            onWordCompleted?()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.nextWord()
            }
        }
    }
    
    // Fungsi baru jika pemain menabrak rintangan
    func skipToNextWord() {
        lives -= 10 // Beri penalti karena menabrak
        if lives <= 0 {
            gameOver()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.nextWord()
        }
    }
    
    func incorrectAction() {
        lives -= 5
        if lives <= 0 {
            gameOver()
        }
    }
    
    private func gameOver() {
        if !isGameOver {
            isGameOver = true
            print("Game Over! Final Score: \(score)")
        }
    }
    
    // Fungsi untuk memeriksa skor dan melaporkan achievement
    func checkAchievementsAndSubmitScore(for manager: GameKitManager, finalScore: Int) {
        // 1. Kirim skor akhir ke leaderboard
        manager.submitScore(finalScore, to: "wordinvaders_main_leaderboard")
        
        // 2. Cek achievement skor tertentu
        if finalScore >= 100 {
            manager.reportAchievement(identifier: "achievement_score_100")
        }
        if finalScore >= 1000 {
            manager.reportAchievement(identifier: "achievement_legendary_score")
        }
        
        // 3. Cek apakah ini rekor pribadi baru
        if finalScore > personalHighScore {
            personalHighScore = finalScore
            manager.reportAchievement(identifier: "achievement_personal_best")
            print("New personal high score: \(finalScore)")
        }
    }
}
