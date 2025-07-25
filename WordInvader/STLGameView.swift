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
        initialScene.gameKitManager = gameKitManager
        
        _scene = State(initialValue: initialScene)
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
            gameState.scene = scene
            gameState.startGame()
        }
    }
    
    private var gameHud: some View {
        VStack {
            HStack(spacing: 16) {
                // SCORE BOX ala FITBGameView
                HStack {
                    Image("coin")
                        .resizable()
                        .frame(width: 24, height: 24)
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
                // CURRENT WORD ala FITBGameView (pakai TargetWordView)
                VStack {
                    if gameState.currentWord.isEmpty {
                        Text("GET READY!")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .tracking(5)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 2, y: 2)
                    } else {
                        TargetWordView(
                            targetWord: gameState.currentWord,
                            highlightedUntilIndex: gameState.currentLetterIndex
                        )
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2, x: 2, y: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.cyan, lineWidth: 2)
                )
                .cornerRadius(4)
                .frame(maxWidth: .infinity)
                // HEALTH ala FITBGameView
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { heartIndex in
                        Image(heartIndex <= gameState.lives ? "fullheart" : "deadheart")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                    }
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
    
    private var centerScreenAnimations: some View {
        ZStack {
            if showSuccessAnimation {
                Text("CORRECT WORD!")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundColor(.green)
                    .shadow(color: .black, radius: 2)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(10)
            }
        }
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
