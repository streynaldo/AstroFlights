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
    @ObservedObject var gameKitManager: GameKitManager // Properti ini perlu diinisialisasi
    
    @State private var scene: STLGameScene
    @State private var showSuccessAnimation = false
    
    // DIUBAH: Tambahkan gameKitManager ke parameter init
    init(gameState: STLGameState, gameKitManager: GameKitManager) {
        self.gameState = gameState
        self.gameKitManager = gameKitManager // Inisialisasi properti ini
        
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
            
            // UI tidak perlu diubah
            VStack {
                HStack {
                    Text("Score: \(gameState.score)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Lives: \(gameState.lives)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                
                Text("Target: \(gameState.currentWord)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(10)
                    .padding(.bottom, 50)
                
                Spacer()
            }
            .padding()
            
            // DIITAMBAHKAN: Tampilkan animasi "SUCCESS" di atas segalanya
            if showSuccessAnimation {
                Text("KATA SELESAI!")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(10) // Pastikan di paling depan
            }
        }
        .onAppear(perform: {
            // Setup callback saat view muncul
            gameState.onWordCompleted = {
                // Mainkan haptic sukses
                HapticsManager.shared.trigger(.success)
                
                // Mainkan suara sukses
                scene.run(SKAction.playSoundFileNamed("success_sound.mp3", waitForCompletion: false))
                
                // Tampilkan animasi, lalu sembunyikan setelah sesaat
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
        })
        // DIITAMBAHKAN: Deteksi saat game over
        .onChange(of: gameState.isGameOver) { _, isOver in
            if isOver {
                // Panggil fungsi untuk submit skor dan cek achievement
                gameState.checkAchievementsAndSubmitScore(for: gameKitManager, finalScore: gameState.score)
            }
        }
    }
}

#Preview {
    let sampleGameState = STLGameState(words: ["PREVIEW", "EXAMPLE"])
    // DIUBAH: Tambahkan instance GameKitManager untuk preview
    let sampleGameKitManager = GameKitManager()
    
    // Masukkan kedua parameter ke GameView
    STLGameView(gameState: sampleGameState, gameKitManager: sampleGameKitManager)
}
