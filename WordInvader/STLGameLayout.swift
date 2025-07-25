//
//  ContentView.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import SwiftUI
import SwiftData

struct STLGameLayout: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var wordDataManager: WordDataManager?
    @State private var isGameActive = false
    @State private var gameState: STLGameState?
    
    @StateObject private var gameKitManager = GameKitManager()

    
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
                            .font(.system(size: 48, weight: .bold, design: .rounded))
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
    
    private func setupWordDataManager() {
        let manager = WordDataManager(modelContext: modelContext)
        wordDataManager = manager
    }
    
    private func getWordsFromDataManager() -> [String] {
        guard let manager = wordDataManager else {
            print("WordDataManager not initialized!")
            return []
        }
        
        // Ambil semua kata dari SwiftData
        let descriptor = FetchDescriptor<Word>()
        do {
            let allWords = try modelContext.fetch(descriptor)
            return allWords.map { $0.text.uppercased() }
        } catch {
            print("Failed to fetch words: \(error)")
            return []
        }
    }
    
    private func startGame() {
        if wordDataManager == nil {
            setupWordDataManager()
        }
        let words = getWordsFromDataManager()
        guard !words.isEmpty else {
            print("No words found!")
            return
        }
        self.gameState = STLGameState(words: words)
        print("Starting game with \(words.count) words.")
        self.isGameActive = true
    }
}
