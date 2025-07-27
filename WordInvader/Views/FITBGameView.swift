//
//  ContentView.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//
import SwiftUI
import SpriteKit
import SwiftData

struct FITBGameView: View {
    @ObservedObject private var gameManager = FITBGameState.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var scene = FITBGameScene(size: CGSize(width: 400, height: 800))
    @StateObject private var gameKitManager = GameKitManager()
    @State private var wordDataManager: WordDataManager?
    @State private var isPaused = false
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            if !gameManager.isGameOver {
                VStack {
                    // TOP ROW: SCORE, WORD, PAUSE BUTTON
                    HStack(spacing: 16) {
                        // SCORE BOX
                        HStack {
                            Image("coin")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                            Text("\(gameManager.score)")
                                .font(.custom("VTF MisterPixel", size: 28))
                                .fontWeight(.black)
                                .foregroundColor(.yellow)
                                .shadow(color: .black, radius: 2, x: 2, y: 2)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.green, lineWidth: 2)
                        )
                        .cornerRadius(4)
                        
                        // CURRENT WORD
                        VStack {
                            Text(gameManager.currentTaskText == "" ? "GET READY!" : gameManager.currentTaskText)
                                .font(.custom("VTF MisterPixel", size: 28))
                                .fontWeight(.black)
                                .tracking(5)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 2, y: 2)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .minimumScaleFactor(0.5)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.cyan, lineWidth: 2)
                        )
                        .cornerRadius(4)
                        .frame(maxWidth: .infinity)
                        
                        // PAUSE BUTTON
                        Button(action: {
                            togglePause()
                        }) {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .cornerRadius(4)
                        }
                        .disabled(gameManager.isCountingDown)
                    }
                    
                    // HEALTH HEARTS DISPLAY (CENTER BELOW)
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { heartIndex in
                            Image(heartIndex <= gameManager.health ? "fullheart" : "deadheart")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                        }
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal)
            }
            
            // PAUSE OVERLAY
            if isPaused && !gameManager.isGameOver {
                ZStack {
                    // Layer 1: Background semi-transparan yang menutupi seluruh layar
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    VStack(spacing: 30) {
                        Text("PAUSED")
                            .font(.custom("VTF MisterPixel", size: 48))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 2, y: 2)
                        
                        VStack(spacing: 20) {
                            Button(action: {
                                togglePause()
                            }) {
                                Text("RESUME")
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
                                gameManager.setGameOver()
                                scene.checkAchievementsAndSubmitScore(for: gameKitManager, finalScore: gameManager.score)
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
                    .overlay(Rectangle().stroke(Color.white.opacity(0.7), lineWidth: 2)) // Border untuk box
                    
                }
                
            }
            
            if gameManager.isGameOver {
                ZStack {
                    // Layer 1: Background semi-transparan yang menutupi seluruh layar
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        // GAME OVER TITLE
                        Text("GAME OVER")
                            .font(.custom("VTF MisterPixel", size: 48))
                            .fontWeight(.black)
                            .foregroundColor(.red)
                            .shadow(color: .white, radius: 2, x: 2, y: 2)
                        
                        // FINAL SCORE
                        VStack(spacing: 8) {
                            Text("SCORE")
                                .font(.custom("VTF MisterPixel", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text("\(gameManager.score)")
                                .font(.custom("VTF MisterPixel", size: 64))
                                .fontWeight(.black)
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
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                        
                        // PLAY AGAIN BUTTON
                        Button(action: {
                            scene.startNewGame()
                            isPaused = false
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
                    .padding(40)
                    .background(Color.black) // Latar belakang hitam pekat untuk box pop-up
                    .overlay(Rectangle().stroke(Color.red.opacity(0.7), lineWidth: 2)) // Border untuk box
                }
            }
        }
        .onAppear {
            gameKitManager.authenticatePlayer()
            setupWordDataManager()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didFITBGameOver)) { notification in
            if let finishedGame = notification.object as? FITBGameScene, self.gameManager.isGameOver == true {
                finishedGame.checkAchievementsAndSubmitScore(
                    for: gameKitManager,
                    finalScore: self.gameManager.score,
                )
            }
        }
    }
    
    private func setupWordDataManager() {
        let manager = WordDataManager(modelContext: modelContext)
        wordDataManager = manager
        scene.configure(with: manager)
    }
    
    private func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            scene.pauseGame()
        } else {
            scene.resumeGame()
        }
    }
    
    private func restartGame() {
        isPaused = false
        scene.startNewGame()
    }
}

#Preview {
    FITBGameView()
        .preferredColorScheme(.dark)
}
