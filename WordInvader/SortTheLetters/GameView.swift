//
//  GameView.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var gameKitManager: GameKitManager
    
    @State private var scene: GameScene?
    @State private var showSuccessAnimation = false
    @State private var showHighScoreAnimation = false
    
    var body: some View {
        ZStack {
            if let gameScene = scene {
                SpriteView(scene: gameScene)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            VStack {
                HStack {
                    Text("Score: \(gameState.score)")
                        .font(.headline).foregroundColor(.white)
                    Spacer()
                    Text("Lives: \(gameState.lives)")
                        .font(.headline).foregroundColor(.white)
                }
                .padding(.horizontal)
                
                TargetWordView(
                    targetWord: gameState.currentWord,
                    highlightedUntilIndex: gameState.currentLetterIndex
                )
                
                Spacer()
            }
            .padding()
            
            if showSuccessAnimation {
                Text("KATA SELESAI!")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity)).zIndex(10)
            }
            
            if showHighScoreAnimation {
                Text("REKOR BARU!")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(.yellow).shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 3)
                    .transition(.scale.combined(with: .opacity)).zIndex(11)
            }
        }
        .onAppear {
            if scene == nil {
                let newScene = GameScene(size: UIScreen.main.bounds.size)
                newScene.scaleMode = .aspectFill
                newScene.gameState = gameState
                gameState.scene = newScene
                self.scene = newScene
            }
            setupCallbacks()
            gameState.startGame()
        }
    }
    
    private func setupCallbacks() {
        gameState.onWordCompleted = { [weak scene] in
            guard let scene = scene else { return }
            HapticsManager.shared.trigger(.success)
            scene.run(SKAction.playSoundFileNamed("success_sound.mp3", waitForCompletion: false))
            withAnimation(.spring()) { showSuccessAnimation = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut) { showSuccessAnimation = false }
            }
        }
        
        gameState.onNewHighScore = {
            HapticsManager.shared.impact(style: .heavy)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showHighScoreAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut) { showHighScoreAnimation = false }
                }
            }
        }
    }
}

#Preview {
    let sampleGameState = GameState(words: ["PREVIEW", "EXAMPLE"])
    let sampleGameKitManager = GameKitManager()
    GameView(gameState: sampleGameState, gameKitManager: sampleGameKitManager)
}
