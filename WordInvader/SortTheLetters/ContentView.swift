//
//  ContentView.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // Ambil SwiftData context dari environment
    @Environment(\.modelContext) private var modelContext
    // Query untuk mengambil semua kata dari database
    @Query private var words: [WordItem]
    
    // State untuk mengontrol apakah game sedang berjalan
    @State private var isGameActive = false
    // State untuk menyimpan game state object
    @State private var gameState: GameState?
    
    // DIITAMBAHKAN: StateObject untuk GameKitManager
    @StateObject private var gameKitManager = GameKitManager()
    
    var body: some View {
        ZStack {
            if isGameActive, let gameState = gameState {
                // Jika game aktif, tampilkan GameView
                // DIUBAH: Tambahkan parameter gameKitManager di sini
                GameView(gameState: gameState, gameKitManager: gameKitManager)
                    .onChange(of: gameState.isGameOver) { _, isOver in
                        if isOver {
                            isGameActive = false
                        }
                    }
            } else {
                // Tampilkan Menu Utama atau Layar Game Over
                VStack(spacing: 20) {
                    Text("Word Invaders")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    
                    if let finalScore = gameState?.score {
                        Text("Game Over!\nFinal Score: \(finalScore)")
                            .font(.title)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: startGame) {
                        Text(gameState == nil ? "Start Game" : "Play Again")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    
                    // DIITAMBAHKAN: Tombol untuk Leaderboard
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
        .onAppear(perform: gameKitManager.authenticatePlayer) // Otentikasi saat app muncul
    }
    
    private func startGame() {
        // Ambil teks dari WordItem
        let wordStrings = words.map { $0.text }
        guard !wordStrings.isEmpty else {
            print("No words found in the database!")
            return
        }
        
        // Buat instance GameState baru dan mulai game
        self.gameState = GameState(words: wordStrings)
        self.isGameActive = true
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WordItem.self, inMemory: true)
}
