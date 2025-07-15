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

    @State private var scene: STLGameScene
    @State private var showSuccessAnimation = false

    init(gameState: STLGameState, gameKitManager: GameKitManager) {
        self.gameState = gameState
        self.gameKitManager = gameKitManager

        let initialScene = STLGameScene(size: UIScreen.main.bounds.size)
        initialScene.scaleMode = .aspectFill
        initialScene.gameState = gameState

        _scene = State(initialValue: initialScene)

        gameState.scene = initialScene
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            if !gameState.isGameOver {
                VStack {
                    HStack(spacing: 16) {
                        // SCORE BOX
                        VStack {
                            Text("SCORE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                            Text("\(gameState.score)")
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

                        // CURRENT WORD BOX
                        VStack {
                            Text("WORD")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                            Text(gameState.currentWord)
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

                        // HP BOX
                        VStack {
                            Text("HP")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                            Text("\(gameState.lives)")
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
                .padding(.horizontal)
            }

            // SUCCESS ANIMATION
            if showSuccessAnimation {
                Text("KATA SELESAI!")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundColor(.green)
                    .shadow(color: .white, radius: 2, x: 2, y: 2)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .onAppear {
            gameState.onWordCompleted = {
                HapticsManager.shared.trigger(.success)
                scene.run(SKAction.playSoundFileNamed("success_sound.mp3", waitForCompletion: false))

                withAnimation(.spring()) {
                    showSuccessAnimation = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut) {
                        showSuccessAnimation = false
                    }
                }
            }

            gameState.startGame()
        }
        .onChange(of: gameState.isGameOver) { _, isOver in
            if isOver {
                gameState.checkAchievementsAndSubmitScore(for: gameKitManager, finalScore: gameState.score)
            }
        }
    }
}

#Preview {
    let sampleGameState = STLGameState(words: ["PREVIEW", "EXAMPLE"])
    let sampleGameKitManager = GameKitManager()
    STLGameView(gameState: sampleGameState, gameKitManager: sampleGameKitManager)
}
