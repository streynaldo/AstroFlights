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
    @StateObject private var gameManager = GameManager.shared
    @Environment(\.modelContext) private var modelContext
    
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
                                .font(.system(size: 28, weight: .black, design: .monospaced))
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
//                            Text("WORD")
//                                .font(.system(size: 12, weight: .bold, design: .monospaced))
//                                .foregroundColor(.cyan)
//                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                            Text(gameManager.currentTaskText)
                                .font(.system(size: 28, weight: .black, design: .monospaced))
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
                VStack(spacing: 30) {
                    Text("PAUSED")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2, x: 2, y: 2)
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            togglePause()
                        }) {
                            Text("RESUME")
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 40)
                                .background(Color.green)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: .white, radius: 0, x: 3, y: 3)
                        }
                        
//                        Button(action: {
//                            restartGame()
//                        }) {
//                            Text("RESTART")
//                                .font(.system(size: 20, weight: .black, design: .monospaced))
//                                .foregroundColor(.black)
//                                .padding(.vertical, 12)
//                                .padding(.horizontal, 40)
//                                .background(Color.yellow)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 0)
//                                        .stroke(Color.white, lineWidth: 2)
//                                )
//                                .shadow(color: .white, radius: 0, x: 3, y: 3)
//                        }
                    }
                }
                .padding(40)
                .background(Color.black.opacity(0.9).ignoresSafeArea())
            }
            
            if gameManager.isGameOver {
                VStack(spacing: 20) {
                    // GAME OVER TITLE
                    Text("GAME OVER")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.red)
                        .shadow(color: .white, radius: 2, x: 2, y: 2)
                    
                    // FINAL SCORE
                    VStack(spacing: 8) {
                        Text("SCORE")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                        
                        Text("\(gameManager.score)")
                            .font(.system(size: 64, weight: .black, design: .monospaced))
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
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                    
                    // PLAY AGAIN BUTTON
                    Button(action: {
                        scene.startNewGame()
                    }) {
                        Text("PLAY AGAIN")
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 40)
                            .background(Color.green)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: .white, radius: 0, x: 3, y: 3)
                    }
                }
                .padding(40)
                .background(Color.black.opacity(0.95).ignoresSafeArea())
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
                    finalScore: finishedGame.score
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
        scene.isPaused = isPaused
        
        if isPaused {
            scene.pauseGame()
        } else {
            scene.resumeGame()
        }
    }
    
    private func restartGame() {
        isPaused = false
        scene.isPaused = false
        scene.startNewGame()
    }
}

#Preview {
    FITBGameView()
        .preferredColorScheme(.dark)
}
