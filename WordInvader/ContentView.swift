//
//  ContentView.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//
import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameManager = GameManager.shared
    
    var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: 400, height: 800)
        scene.scaleMode = .resizeFill
        return scene
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            VStack {
                Text(gameManager.currentTaskText)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                
                Spacer()
            }
            .padding(.top, 50)
        }
        
    }
}
