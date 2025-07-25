//
//  ContentView.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import SwiftUI

struct STLGameLayout: View {
    
    private var words: [String] = WordGenerator().wordList
    
    @StateObject private var gameKitManager = GameKitManager()
    
    @State private var gameState: STLGameState?
    @State private var isGameActive = false
    
    let stlLeaderboardID = "sort_the_letters_leaderboard"
    let fitbLeaderboardID = "fill_in_the_blank_leaderboard"
    
    let stlAchievementFilter = "sort_the_letters"
    let fitbAchievementFilter = "fill_in_the_blank"
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isGameActive, let activeGameState = gameState {
                    STLGameView(gameState: activeGameState, gameKitManager: gameKitManager)
                        .onDisappear {
                            Task {
                                activeGameState.submitFinalScoreToLeaderboard(for: gameKitManager, finalScore: activeGameState.score)
                            }
                        }
                } else {
                    VStack(spacing: 20) {
                        Text("Word Invaders")
                            .font(.custom("Born2bSporty FS", size: 40))
                        if let finishedGameState = gameState {
                            Text("Game Over!\nFinal Score: \(finishedGameState.score)")
                                .font(.title)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        Button(action: startGame) {
                            Text(gameState == nil ? "Start Game" : "Play Again")
                                .font(.title).fontWeight(.bold).padding()
                                .background(Color.blue).foregroundColor(.white).cornerRadius(15)
                        }
                        if gameKitManager.isAuthenticated {
                            NavigationLink(destination: LeaderboardView(gameKitManager: gameKitManager, stlLeaderboardID: stlLeaderboardID, fitbLeaderboardID: fitbLeaderboardID)) {
                                Label("Papan Skor", systemImage: "list.number")
                            }
                            
                            NavigationLink(destination: AchievementsView(gameKitManager: gameKitManager, stlAchievementFilter: stlAchievementFilter, fitbAchievementFilter: fitbAchievementFilter)) {
                                Label("Pencapaian", systemImage: "star.circle")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                gameKitManager.authenticatePlayer()
                NotificationCenter.default.addObserver(forName: .didSTLGameOver, object: nil, queue: .main) { _ in
                    isGameActive = false
                }
            }
        }
    }
    
    private func startGame() {
        guard !words.isEmpty else {
            print("No words found!")
            return
        }
        
        self.gameState = STLGameState(words: words)
        self.isGameActive = true
    }
}
