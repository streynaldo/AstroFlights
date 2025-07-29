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
                    .ignoresSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Menu Overlay
                    VStack(spacing: 40) {
                        Spacer()
                        
                        // GAME TITLE
                        Image("game_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300, maxHeight: 150)
//                            .padding(.top, 20)
//                            .padding(.bottom, 20)
    
                        // GAME MODE SELECTION
                        VStack(spacing: 30) {
                            Text("CHOOSE YOUR BATTLE MODE, CAPTAIN!").font(.custom("VTF MisterPixel", size: 16)).foregroundColor(.white)
                            
                            VStack(spacing: 20) {
                                // FILL IN THE BLANKS BUTTON
                                Button(action: {
                                    FITBGameState.shared.reset()
                                    showFITBGame = true
                                }) {
                                    MenuButtonContent(title: "FILL IN THE BLANKS", subtitle: "Complete missing letters", bgname: "fitb_gamemode_button")
                                }
                                
                                // SHOOT THE LETTERS BUTTON
                                Button(action: startGameSTL) {
                                    MenuButtonContent(title: "SHOOT THE LETTERS", subtitle: "Spell words by shooting", bgname: "stl_gamemode_button")
                                }
                                
                                // LEADERBOARD & ACHIEVEMENTS... (tetap sama)
                                HStack{
                                    NavigationLink(destination: LeaderboardView(gameKitManager: gameKitManager, stlLeaderboardID: "sort_the_letters_leaderboard", fitbLeaderboardID: "fill_in_the_blank_leaderboard")) {
                                        Image("leaderboard_icon")
                                            .resizable()
                                            .frame(maxWidth: 140, maxHeight: 80)
                                    }
                                    NavigationLink(destination: AchievementsView(gameKitManager: gameKitManager, stlAchievementFilter: "sort_the_letters", fitbAchievementFilter: "fill_in_the_blank")) {
                                        Image("achievement_button")
                                            .resizable()
                                            .frame(maxWidth: 140, maxHeight: 80)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                    .padding(.bottom, 60)
                }
            }
            .ignoresSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    let bgname: String
    
    var body: some View {
        ZStack {
            Image(bgname)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 80)
            
            VStack(spacing: subtitle == nil ? 0 : 4) {
                Text(title)
                    .font(.custom("VTF MisterPixel", size: 18))
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .shadow(color: .white, radius: 1, x: 1, y: 1)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("VTF MisterPixel", size: 12))
                        .fontWeight(.bold)
                        .foregroundColor(.black.opacity(0.8))
                        .shadow(color: .white, radius: 0.5, x: 0.5, y: 0.5)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: 80)
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
            .modelContainer(for: [Word.self, GameSession.self], inMemory: true)
    }
}
