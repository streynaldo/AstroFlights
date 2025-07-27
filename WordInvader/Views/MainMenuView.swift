//
//  MainMenuView.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 23/07/25.
//

import SwiftUI
import SpriteKit
import SwiftData

struct MainMenuView: View {
    @Environment(\.modelContext) private var modelContext
    
    // State untuk mengelola game yang aktif
    @State private var activeSTLGameState: STLGameState?
    @State private var activeFITBGameState: FITBGameState?
    @State private var showFITBGame = false
    
    // Manager yang bisa dibagikan
    @StateObject private var gameKitManager = GameKitManager()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background Scene
                    SpriteView(scene: {
                        let scene = MainMenuScene()
                        scene.size = geometry.size
                        scene.scaleMode = .aspectFill
                        return scene
                    }())
                    .ignoresSafeArea()
                    
                    // Menu Overlay
                    VStack(spacing: 40) {
                        Spacer()
                        
                        // GAME TITLE
                        VStack(spacing: 10) {
                            Text("WORD").font(.custom("VTF MisterPixel", size: 48)).foregroundColor(.cyan)
                            Text("INVADERS").font(.custom("VTF MisterPixel", size: 48)).foregroundColor(.yellow)
                        }.shadow(color: .black, radius: 2, x: 2, y: 2)
                        
                        Spacer()
                        
                        // GAME MODE SELECTION
                        VStack(spacing: 30) {
                            Text("SELECT GAME MODE").font(.custom("VTF MisterPixel", size: 16)).foregroundColor(.white)
                            
                            VStack(spacing: 20) {
                                // FILL IN THE BLANKS BUTTON
                                Button(action: {
                                    FITBGameState.shared.reset()
                                    showFITBGame = true
                                }) {
                                    MenuButtonContent(title: "FILL IN THE BLANKS", subtitle: "Complete missing letters", color: .green)
                                }
                                
                                // SHOOT THE LETTERS BUTTON
                                Button(action: startGameSTL) {
                                    MenuButtonContent(title: "SHOOT THE LETTERS", subtitle: "Spell words by shooting", color: .yellow)
                                }
                                
                                // LEADERBOARD & ACHIEVEMENTS... (tetap sama)
                                NavigationLink(destination: LeaderboardView(gameKitManager: gameKitManager, stlLeaderboardID: "sort_the_letters_leaderboard", fitbLeaderboardID: "fill_in_the_blank_leaderboard")) {
                                    MenuButtonContent(title: "LEADERBOARD", subtitle: nil, color: .blue)
                                }
                                NavigationLink(destination: AchievementsView(gameKitManager: gameKitManager, stlAchievementFilter: "sort_the_letters", fitbAchievementFilter: "fill_in_the_blank")) {
                                    MenuButtonContent(title: "ACHIEVEMENTS", subtitle: nil, color: .purple)
                                }
                            }
                        }
                        Spacer()
                        
                        // RETRO FOOTER TEXT
                        Text("CHOOSE YOUR BATTLE MODE, CAPTAIN!")
                            .font(.custom("VTF MisterPixel", size:12))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                    .background(Color.black.opacity(0.7))
                }
            }
            .fullScreenCover(isPresented: $showFITBGame) {
                FITBGameView()
            }
            // Menggunakan .fullScreenCover dengan 'item' untuk STL
            .fullScreenCover(item: $activeSTLGameState) { gameState in
                STLGameView(gameState: gameState, gameKitManager: gameKitManager)
            }
        }
        .onAppear() {
            gameKitManager.authenticatePlayer()
        }
    }
    
    private func startGameSTL() {
        // 1. Inisialisasi WordDataManager dengan modelContext
        let wordDataManager = WordDataManager(modelContext: modelContext)
        
        // 2. Ambil semua kata dari SwiftData
        let words = getWordsFromDataManager(manager: wordDataManager)
        guard !words.isEmpty else {
            print("No words found in database!")
            // Opsional: Tampilkan alert kepada user
            return
        }
        
        // 3. Buat instance baru dari STLGameState
        // Ini akan memicu .fullScreenCover untuk tampil
        self.activeSTLGameState = STLGameState(words: words)
    }
    
    private func getWordsFromDataManager(manager: WordDataManager) -> [String] {
        let descriptor = FetchDescriptor<Word>()
        do {
            let allWords = try modelContext.fetch(descriptor)
            return allWords.map { $0.text.uppercased() }
        } catch {
            print("Failed to fetch words: \(error)")
            return []
        }
    }
}

// Helper View untuk konsistensi tombol menu
struct MenuButtonContent: View {
    let title: String
    let subtitle: String?
    let color: Color
    
    var body: some View {
        VStack(spacing: subtitle == nil ? 0 : 8) {
            Text(title)
                .font(.custom("VTF MisterPixel", size: 18))
                .foregroundColor(.black)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.custom("VTF MisterPixel", size: 12))
                    .foregroundColor(.black.opacity(0.8))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 30)
        .frame(maxWidth: 260)
        .background(color)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color.white, lineWidth: 2))
        .shadow(color: .white, radius: 0, x: 3, y: 3)
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
            .modelContainer(for: [Word.self, GameSession.self], inMemory: true)
    }
}
