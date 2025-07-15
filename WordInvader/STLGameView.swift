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
    @State private var showHighScoreAnimation = false
    
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
            
            gameHud
            
            centerScreenAnimations
        }
        .onAppear {
            setupCallbacks()
            gameState.startGame()
        }
    }
    
    private var gameHud: some View {
        VStack {
            HStack(spacing: 16) {
                scoreBox
                wordBox
                healthBox
            }
            Spacer()
        }
        .padding(.top, 50)
        .padding(.horizontal)
    }
    
    private var centerScreenAnimations: some View {
        ZStack {
            if showSuccessAnimation {
                Text("KATA SELESAI!")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundColor(.green)
                    .shadow(color: .black, radius: 2)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(10)
            }
            
            if showHighScoreAnimation {
                Text("REKOR BARU!")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 3)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(11)
            }
        }
    }
    
    private var scoreBox: some View {
        InfoBox(
            title: "SCORE",
            value: "\(gameState.score)",
            titleColor: .green,
            valueColor: .yellow
        )
    }
    
    private var wordBox: some View {
        VStack {
            Text("WORD")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            TargetWordView(
                targetWord: gameState.currentWord,
                highlightedUntilIndex: gameState.currentLetterIndex
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.cyan, lineWidth: 2)
        )
        .frame(maxWidth: .infinity)
    }
    
    private var healthBox: some View {
        InfoBox(
            title: "HP",
            value: "\(gameState.lives)",
            titleColor: .red,
            valueColor: .red
        )
    }
    
    private func setupCallbacks() {
        gameState.onWordCompleted = {
            HapticsManager.shared.trigger(.success)
            withAnimation(.spring()) {
                showSuccessAnimation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut) {
                    showSuccessAnimation = false
                }
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

struct InfoBox: View {
    let title: String
    let value: String
    let titleColor: Color
    let valueColor: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(titleColor)
            Text(value)
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundColor(valueColor)
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(titleColor, lineWidth: 2)
        )
    }
}

#Preview {
    let sampleGameState = STLGameState(words: ["PREVIEW", "EXAMPLE"])
    let sampleGameKitManager = GameKitManager()
    
    sampleGameState.score = 1250
    sampleGameState.lives = 85
    sampleGameState.currentWord = "EXAMPLE"
    sampleGameState.currentLetterIndex = 3
    
    return STLGameView(gameState: sampleGameState, gameKitManager: sampleGameKitManager)
}
