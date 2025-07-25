//
//  ParallaxBackgroundManager.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 24/07/25.
//

import SpriteKit

class ParallaxBackgroundManager {
    private weak var scene: SKScene?
    private var stripCount: Int = 2
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    func setupParallaxBackground() {
        guard let scene = scene else { return }
        for i in 0..<stripCount {
            let strip = createCompleteParallaxStrip(scene: scene)
            strip.position = CGPoint(x: 0, y: scene.size.height * CGFloat(i))
            strip.name = "parallax_strip"
            scene.addChild(strip)
        }
    }
    
    func moveBackgroundStrip(speed: CGFloat) {
        guard let scene = scene else { return }
        scene.enumerateChildNodes(withName: "parallax_strip") { (node, _) in
            node.position.y -= speed
            if node.position.y < -scene.size.height {
                node.position.y += scene.size.height * CGFloat(self.stripCount)
            }
        }
    }
    
    private func createCompleteParallaxStrip(scene: SKScene) -> SKNode {
        let container = SKNode()
        var occupiedFrames = [CGRect]()
        placeAssets(on: container, scene: scene, textureNames: ["galaxy"], count: 2, zPosition: -9, occupiedFrames: &occupiedFrames)
        placeAssets(on: container, scene: scene, textureNames: ["cloud_1", "cloud_2", "cloud_3"], count: 4, zPosition: -8, occupiedFrames: &occupiedFrames)
        placeAssets(on: container, scene: scene, textureNames: ["cloud_4", "cloud_5", "cloud_6"], count: 4, zPosition: -8, occupiedFrames: &occupiedFrames)
        placeStars(on: container, scene: scene, count: 50, zPosition: -7)
        return container
    }
    
    private func placeStars(on container: SKNode, scene: SKScene, count: Int, zPosition: CGFloat) {
        for _ in 0..<count {
            let starNumber = Int.random(in: 1...5)
            let star = SKSpriteNode(imageNamed: "star_\(starNumber)")
            star.position = CGPoint(x: .random(in: 0...scene.size.width), y: .random(in: 0...scene.size.height))
            star.setScale(.random(in: 0.05...0.15))
            star.alpha = .random(in: 0.4...1.0)
            star.zPosition = zPosition
            let fadeDuration = TimeInterval.random(in: 0.4...0.8)
            let waitDuration = TimeInterval.random(in: 1.0...1.5)
            let fadeOut = SKAction.fadeAlpha(to: .random(in: 0.1...0.4), duration: fadeDuration)
            let waitWhileDim = SKAction.wait(forDuration: waitDuration / 2)
            let fadeIn = SKAction.fadeAlpha(to: .random(in: 0.6...0.8), duration: fadeDuration)
            let waitWhileBright = SKAction.wait(forDuration: waitDuration)
            let sequence = SKAction.sequence([fadeOut, waitWhileDim, fadeIn, waitWhileBright])
            let twinkle = SKAction.repeatForever(sequence)
            star.run(twinkle)
            container.addChild(star)
        }
    }
    
    private func placeAssets(on container: SKNode, scene: SKScene, textureNames: [String], count: Int, zPosition: CGFloat, occupiedFrames: inout [CGRect]) {
        for _ in 0..<count {
            guard let textureName = textureNames.randomElement() else { continue }
            let node = SKSpriteNode(imageNamed: textureName)
            guard let texture = node.texture else { continue }
            let aspectRatio = texture.size().height / texture.size().width
            let nodeWidth = scene.size.width * CGFloat.random(in: 0.25...0.50)
            node.size = CGSize(width: nodeWidth, height: nodeWidth * aspectRatio)
            var attempts = 0
            var positionIsSafe = false
            while !positionIsSafe && attempts < 20 {
                let xPos = CGFloat.random(in: 0...scene.size.width)
                let yPos = CGFloat.random(in: 0...scene.size.height)
                node.position = CGPoint(x: xPos, y: yPos)
                let nodeFrameWithPadding = node.frame.insetBy(dx: -20, dy: -20)
                positionIsSafe = !occupiedFrames.contains { $0.intersects(nodeFrameWithPadding) }
                attempts += 1
            }
            if positionIsSafe {
                occupiedFrames.append(node.frame)
                node.zPosition = zPosition
                container.addChild(node)
            }
        }
    }
    
    func setupFallingWindEffect() {
        guard let scene = scene else { return }
        let windSpawnAction = SKAction.run { [weak self] in
            self?.spawnWindParticle()
        }
        let wait = SKAction.wait(forDuration: 0.2, withRange: 0.1)
        let sequence = SKAction.sequence([windSpawnAction, wait])
        let repeatAction = SKAction.repeatForever(sequence)
        scene.run(repeatAction, withKey: "windEffect")
    }

    private func spawnWindParticle() {
        guard let scene = scene else { return }
        let randomNumber = Int.random(in: 1...4)
        let wind = SKSpriteNode(imageNamed: "spaceship_wind_\(randomNumber)")
        // Wind strip vertikal, tidak dimiringkan
        let width = CGFloat.random(in: 3...7)
        let height = CGFloat.random(in: scene.size.height * 0.18...scene.size.height * 0.28)
        wind.size = CGSize(width: width, height: height)
        wind.alpha = CGFloat.random(in: 0.18...0.28)
        wind.zPosition = 5
        // Posisi X random, Y mulai dari atas layar
        let xPos = CGFloat.random(in: 0...(scene.size.width - width))
        wind.position = CGPoint(x: xPos, y: scene.size.height + height)
        wind.zRotation = 0 // Tidak dimiringkan
        scene.addChild(wind)
        let duration = CGFloat.random(in: 0.7...1.2)
        let move = SKAction.moveBy(x: 0, y: -(scene.size.height + height * 2), duration: TimeInterval(duration))
        let fade = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([move, fade, remove])
        wind.run(sequence)
    }
}
