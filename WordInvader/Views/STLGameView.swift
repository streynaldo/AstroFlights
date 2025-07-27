//
//  GameView.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import SwiftUI
import SpriteKit

struct STLGameView: View {
    
    
    @ObservedObject var gameState: STLGameState
    @ObservedObject var gameKitManager: GameKitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var scene: STLGameScene
    
    init(gameState: STLGameState, gameKitManager: GameKitManager) {
        self.gameState = gameState
        self.gameKitManager = gameKitManager
        
        let initialScene = STLGameScene(size: UIScreen.main.bounds.size)
        initialScene.scaleMode = .aspectFill
        initialScene.gameState = gameState
        initialScene.gameKitManager = gameKitManager
        
        _scene = State(initialValue: initialScene)
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            // Tampilkan UI hanya jika game belum berakhir
            if !gameState.isGameOver {
                gameHud
            }
            
            // Tampilkan overlay Pause jika game dijeda dan belum game over
            if gameState.isPaused && !gameState.isGameOver {
                pauseOverlay
            }
            
            // Tampilkan overlay Game Over jika game berakhir
            if gameState.isGameOver {
                gameOverOverlay
            }
        }
        .onAppear {
            gameState.startGame()
        }
        .onChange(of: gameState.currentWord) {
            scene.spawnCurrentWord()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didSTLGameOver)) { _ in
            gameState.submitFinalScoreToLeaderboard(for: gameKitManager)
        }
    }
    
    // MARK: - Game HUD View
    private var gameHud: some View {
        VStack {
            HStack(spacing: 16) {
                // ... (SCORE BOX tetap sama)
                HStack {
                    Image("coin")
                        .resizable().frame(width: 24, height: 24)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                    Text("\(gameState.score)")
                        .font(.custom("VTF MisterPixel", size: 28))
                        .foregroundColor(.yellow)
                        .shadow(color: .black, radius: 2, x: 2, y: 2)
                }
                .padding(8)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.green, lineWidth: 2))
                
                // ... (CURRENT WORD DISPLAY tetap sama)
                TargetWordView(
                    targetWord: gameState.currentWord,
                    highlightedUntilIndex: gameState.currentLetterIndex
                )
                .padding(8)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.cyan, lineWidth: 2))
                .frame(maxWidth: .infinity)
                
                // TOMBOL PAUSE BARU
                Button(action: {
                    scene.pauseGame()
                }) {
                    Image(systemName: gameState.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 2))
                }
                .disabled(gameState.isCountingDown) // Nonaktifkan saat countdown
            }
            
            // ... (HEALTH HEARTS tetap sama)
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Image(index < gameState.health ? "fullheart" : "deadheart")
                        .resizable().frame(width: 24, height: 24)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                }
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(.top, 50)
        .padding(.horizontal)
    }
    
    // MARK: - Pause Overlay (MODIFIED)
    private var pauseOverlay: some View {
        ZStack {
            // Layer 1: Background semi-transparan yang menutupi seluruh layar
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Layer 2: Konten pop-up
            VStack(spacing: 30) {
                Text("PAUSED")
                    .font(.custom("VTF MisterPixel", size: 48))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 2, y: 2)
                
                VStack(spacing: 20) {
                    Button(action: {
                        scene.resumeGame()
                    }) {
                        Text("RESUME")
                            .font(.custom("VTF MisterPixel", size: 24))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: 220)
                            .background(Color.green)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                    }
                    
                    Button(action: {
                        gameState.submitFinalScoreToLeaderboard(for: gameKitManager)
                        dismiss()
                    }) {
                        Text("MAIN MENU")
                            .font(.custom("VTF MisterPixel", size: 24))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: 220)
                            .background(Color.red)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                    }
                }
            }
            .padding(40)
            .background(Color.black) // Latar belakang hitam pekat untuk box pop-up
            .overlay(Rectangle().stroke(Color.white.opacity(0.7), lineWidth: 2)) // Border untuk box
        }
    }
    
    // MARK: - Game Over Overlay (MODIFIED)
    private var gameOverOverlay: some View {
        ZStack {
            // Layer 1: Background semi-transparan yang menutupi seluruh layar
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // Layer 2: Konten pop-up
            VStack(spacing: 20) {
                // GAME OVER TITLE
                Text("GAME OVER")
                    .font(.custom("VTF MisterPixel", size: 48))
                    .foregroundColor(.red)
                    .shadow(color: .white, radius: 2, x: 2, y: 2)
                
                // FINAL SCORE
                VStack(spacing: 8) {
                    Text("SCORE")
                        .font(.custom("VTF MisterPixel", size: 24))
                        .foregroundColor(.green)
                    
                    Text("\(gameState.score)")
                        .font(.custom("VTF MisterPixel", size: 64))
                        .foregroundColor(.yellow)
                        .shadow(color: .black, radius: 4, x: 2, y: 2)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green, lineWidth: 4)
                )
                
                // RETRO MOTIVATION TEXT
                Text("PRESS PLAY AGAIN TO RESTART")
                    .font(.custom("VTF MisterPixel", size: 14))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1, x: 1, y: 1)
                
                // ACTION BUTTONS
                VStack(spacing: 15) {
                    Button(action: {
                        gameState.resetGame()
                    }) {
                        Text("PLAY AGAIN")
                            .font(.custom("VTF MisterPixel", size: 20))
                            .fontWeight(.black)
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .frame(maxWidth: 220)
                            .background(Color.green)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: .white, radius: 0, x: 3, y: 3)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("MAIN MENU")
                            .font(.custom("VTF MisterPixel", size: 20))
                            .fontWeight(.black)
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .frame(maxWidth: 220)
                            .background(Color.red)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: .white, radius: 0, x: 3, y: 3)
                    }
                }
            }
            .padding(40)
            .background(Color.black) // Latar belakang hitam pekat untuk box pop-up
            .overlay(Rectangle().stroke(Color.red.opacity(0.7), lineWidth: 2)) // Border untuk box
        }
    }
}

struct TargetWordView: View {
    let targetWord: String
    let highlightedUntilIndex: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(targetWord.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.custom("VTF MisterPixel", size: 28))
                    .tracking(5)
                    .foregroundColor(index < highlightedUntilIndex ? .yellow : .white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 2, y: 2)
                    .transition(.opacity)
            }
        }
    }
}
