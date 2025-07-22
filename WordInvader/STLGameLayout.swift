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
    
    var body: some View {
        ZStack {
            if isGameActive, let currentGameState = gameState {
                STLGameView(gameState: currentGameState, gameKitManager: gameKitManager)
            } else {
                VStack(spacing: 20) {
                    Text("Word Invaders")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    
                    if let finishedGameState = gameState, finishedGameState.isGameOver {
                        Text("Game Over!\nFinal Score: \(finishedGameState.score)")
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Button(action: startGame) {
                        Text(gameState == nil || gameState!.isGameOver ? "Start Game" : "Play Again")
                            .font(.title).fontWeight(.bold).padding()
                            .background(Color.blue).foregroundColor(.white).cornerRadius(15)
                    }
                    .disabled(wordDataManager == nil) // Disable jika wordDataManager belum ready
                    
                    if gameKitManager.isAuthenticated {
                        Button(action: gameKitManager.showLeaderboard) {
                            HStack {
                                Image(systemName: "list.number")
                                Text("Papan Skor")
                            }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            gameKitManager.authenticatePlayer()
            setupWordDataManager()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didSTLGameOver)) { notification in
            if let finishedGame = notification.object as? STLGameState, self.gameState === finishedGame {
                finishedGame.checkAchievementsAndSubmitScore(
                    for: gameKitManager,
                    finalScore: finishedGame.score
                )
                self.isGameActive = false
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
