//
//  ContentView.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var words: [WordItem]
    
    @State private var gameState: GameState?
    @State private var isShowingGameView = false
    
    @StateObject private var gameKitManager = GameKitManager()
    
    var body: some View {
        ZStack {
            if isShowingGameView, let currentGameState = gameState {
                GameView(gameState: currentGameState, gameKitManager: gameKitManager)
            } else {
                VStack(spacing: 20) {
                    Text("Word Invaders")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    
                    if let finishedGameState = gameState {
                        Text("Game Over!\nFinal Score: \(finishedGameState.score)")
                            .font(.title)
                            .multilineTextAlignment(.center)
                    }
                    Button(action: startGame) {
                        Text(gameState == nil ? "Start Game" : "Play Again")
                            .font(.title).fontWeight(.bold).padding()
                            .background(Color.blue).foregroundColor(.white).cornerRadius(15)
                    }
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
        .onAppear(perform: gameKitManager.authenticatePlayer)
        .onReceive(NotificationCenter.default.publisher(for: .didGameOver)) { _ in
            if let finishedGame = self.gameState {
                Task {
                    finishedGame.checkAchievementsAndSubmitScore(
                        for: gameKitManager,
                        finalScore: finishedGame.score
                    )
                }
            }
            self.isShowingGameView = false
        }
    }
    
    private func startGame() {
        let wordStrings = words.map { $0.text }
        guard !wordStrings.isEmpty else { return }
        self.gameState = GameState(words: wordStrings)
        self.isShowingGameView = true
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WordItem.self, inMemory: true)
}
