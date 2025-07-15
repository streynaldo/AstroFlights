//
//  GameKitManager.swift
//  WordInvaders
//
//  Created by Louis Fernando on 10/07/25.
//

import Foundation
import GameKit
import SwiftUI

final class GameKitManager: NSObject, ObservableObject, GKGameCenterControllerDelegate {
    
    @Published var isAuthenticated = GKLocalPlayer.local.isAuthenticated
    
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
    
    func submitScore(_ score: Int, to leaderboardID: String) {
        guard isAuthenticated else {
            print("Player not authenticated. Cannot submit score.")
            return
        }
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
    
    func showLeaderboard() {
        guard isAuthenticated else { return }
        let gameCenterVC = GKGameCenterViewController(state: .leaderboards)
        gameCenterVC.gameCenterDelegate = self
        getRootViewController()?.present(gameCenterVC, animated: true)
    }
    
    private func getRootViewController() -> UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first?.rootViewController
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
