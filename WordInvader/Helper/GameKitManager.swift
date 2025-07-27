//
//  GameKitManager.swift
//  WordInvaders
//
//  Created by Louis Fernando on 10/07/25.
//

import Foundation
import GameKit
import SwiftUI

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let playerName: String
    let score: String
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let isCompleted: Bool
    let points: Int
    let image: UIImage?
}

final class GameKitManager: NSObject, ObservableObject, GKGameCenterControllerDelegate {
    
    @Published var isAuthenticated = GKLocalPlayer.local.isAuthenticated
    @Published var leaderboardEntries = [LeaderboardEntry]()
    @Published var achievements = [Achievement]()
    
    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] vc, error in
            if let viewController = vc {
                self?.getRootViewController()?.present(viewController, animated: true)
                return
            }
            if let error = error {
                print("GameKit Auth Error: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
        }
    }
    
    func fetchLeaderboardEntries(id: String) async {
        guard isAuthenticated else { return }
        
        await MainActor.run {
            self.leaderboardEntries.removeAll()
        }
        
        do {
            guard let leaderboard = (try await GKLeaderboard.loadLeaderboards(IDs: [id])).first else {
                print("Error: Leaderboard with ID \(id) not found.")
                return
            }
            
            let (_, allScores, _) = try await leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 100))
            
            let finalEntries: [LeaderboardEntry] = allScores.map { entry in
                LeaderboardEntry(rank: entry.rank, playerName: entry.player.displayName, score: entry.formattedScore)
            }
            
            await MainActor.run {
                self.leaderboardEntries = finalEntries
            }
        } catch {
            print("Error fetching leaderboard entries: \(error.localizedDescription)")
        }
    }
    
    func fetchAchievements(filterBy keyword: String? = nil) async {
        guard isAuthenticated else { return }
        
        await MainActor.run {
            self.achievements.removeAll()
        }
        
        do {
            let allAchievementDescriptions = try await GKAchievementDescription.loadAchievementDescriptions()
            let playerAchievements = try await GKAchievement.loadAchievements()
            
            let playerProgress: [String: GKAchievement] = playerAchievements.reduce(into: [:]) { result, achievement in
                result[achievement.identifier] = achievement
            }
            
            var fetchedAchievements: [Achievement] = try await withThrowingTaskGroup(of: Achievement?.self, returning: [Achievement].self) { group in
                for desc in allAchievementDescriptions {
                    group.addTask {
                        if let keyword = keyword, !desc.identifier.contains(keyword) {
                            return nil
                        }
                        
                        let image = try? await desc.loadImage()
                        let isCompleted = playerProgress[desc.identifier]?.isCompleted ?? false
                        return Achievement(id: desc.identifier, title: desc.title, description: isCompleted ? desc.achievedDescription : desc.unachievedDescription, isCompleted: isCompleted, points: desc.maximumPoints, image: image)
                    }
                }
                
                var results = [Achievement]()
                for try await achievement in group {
                    if let achievement = achievement {
                        results.append(achievement)
                    }
                }
                return results
            }
            
            let desiredOrder: [String]
            if keyword == "sort_the_letters" {
                desiredOrder = [
                    "100_score_sort_the_letters",
                    "1000_score_sort_the_letters",
                    "new_personal_record_sort_the_letters"
                ]
            } else {
                desiredOrder = [
                    "100_score_fill_in_the_blank",
                    "1000_score_fill_in_the_blank",
                    "new_personal_record_fill_in_the_blank"
                ]
            }
            
            fetchedAchievements.sort { ach1, ach2 in
                guard let firstIndex = desiredOrder.firstIndex(of: ach1.id) else {
                    return false
                }
                guard let secondIndex = desiredOrder.firstIndex(of: ach2.id) else {
                    return true
                }
                return firstIndex < secondIndex
            }
            
            await MainActor.run {
                self.achievements = fetchedAchievements
            }
        } catch {
            print("Error fetching achievements: \(error.localizedDescription)")
        }
    }
    
    func submitScore(_ score: Int, to leaderboardID: String) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Error submitting score: \(error.localizedDescription)")
            } else {
                print("Score \(score) submitted to \(leaderboardID) successfully.")
            }
        }
    }
    
    func reportAchievement(identifier: String) {
        guard isAuthenticated else { return }
        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = 100.0
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Error reporting achievement: \(error.localizedDescription)")
            } else {
                print("Achievement \(identifier) reported.")
            }
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first?.rootViewController
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
