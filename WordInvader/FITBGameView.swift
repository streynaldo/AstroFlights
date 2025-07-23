//
//  ContentView.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import SwiftUI
import SpriteKit

struct FITBGameView: View {
    @StateObject private var gameKitManager = GameKitManager()
    @ObservedObject var gameManager = GameManager.shared
    
    var scene: FITBGameScene {
        let scene = FITBGameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .fill
        scene.gameKitManager = gameKitManager
        return scene
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            if !gameManager.isGameOver {
                VStack {
                    HStack(spacing: 16) {
                        VStack {
                            Text("SCORE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
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
                        
                        VStack {
                            Text("WORD")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
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
                        
                        VStack {
                            Text("HP")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                            Text("\(gameManager.health)")
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundColor(.red)
                                .shadow(color: .black, radius: 2, x: 2, y: 2)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.red, lineWidth: 2)
                        )
                        .cornerRadius(4)
                    }
                    Spacer()
                }
                .padding(.top, 50)
            }
            if gameManager.isGameOver {
                VStack(spacing: 20) {
                    Text("GAME OVER")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.red)
                        .shadow(color: .white, radius: 2, x: 2, y: 2)
                    
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
                    
                    Text("PRESS PLAY AGAIN TO RESTART")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                    
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
            NotificationCenter.default.addObserver(forName: .didFITBGameOver, object: nil, queue: .main) { _ in
                gameManager.submitFinalScoreToLeaderboard(for: gameKitManager)
            }
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
}
