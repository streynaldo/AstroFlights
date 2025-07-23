//
//  GameManager.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import Foundation
import SwiftUI

class GameManager: ObservableObject {
    static let shared = GameManager()
    
    @Published var currentTaskText: String = ""
    @Published var score: Int = 0
    @Published var health: Int = 100
    @Published var isGameOver: Bool = false
    
    private var reportedAchievements: Set<String> = []
    private var personalHighScore: Int
    
    var onNewHighScore: (() -> Void)?
    
    private init() {
        self.personalHighScore = UserDefaults.standard.integer(forKey: "personalHighScore_FITB")
    }
    
    func checkRealtimeAchievements(for manager: GameKitManager) {
        let score100ID = "100_score_fill_in_the_blank"
        if score >= 100 && !reportedAchievements.contains(score100ID) {
            manager.reportAchievement(identifier: score100ID)
            reportedAchievements.insert(score100ID)
        }
        
        let score1000ID = "1000_score_fill_in_the_blank"
        if score >= 1000 && !reportedAchievements.contains(score1000ID) {
            manager.reportAchievement(identifier: score1000ID)
            reportedAchievements.insert(score1000ID)
        }
        
        let personalBestID = "new_personal_record_fill_in_the_blank"
        if score > self.personalHighScore {
            self.personalHighScore = score
            
            if !reportedAchievements.contains(personalBestID) {
                manager.reportAchievement(identifier: personalBestID)
                reportedAchievements.insert(personalBestID)
            }
            
            onNewHighScore?()
            saveHighScoreToDevice()
        }
    }
    
    func submitFinalScoreToLeaderboard(for manager: GameKitManager) {
        manager.submitScore(score, to: "fill_in_the_blank_leaderboard")
    }
    
    private func saveHighScoreToDevice() {
        UserDefaults.standard.set(self.personalHighScore, forKey: "personalHighScore_FITB")
    }
    
    func resetForNewGame() {
        score = 0
        health = 100
        isGameOver = false
        currentTaskText = ""
        reportedAchievements.removeAll()
    }
}
