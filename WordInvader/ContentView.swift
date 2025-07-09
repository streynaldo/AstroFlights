//
//  ContentView.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//
import SwiftUI
import SpriteKit

struct ContentView: View {
    var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: 400, height: 800)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        Text("Hello, World!")
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}
