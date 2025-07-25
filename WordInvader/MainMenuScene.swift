//
//  MainMenuScene.swift
//  WordInvader
//
//  Created by Louis Fernando on 25/07/25.
//

import Foundation
import SpriteKit
import AVFoundation

class MainMenuScene: SKScene {
    
    private var spaceship: SKSpriteNode!
    private var backgroundMusic: SKAudioNode?
    private var windAnimation: SKAction?
    
    let spaceshipIdle = SKTexture(imageNamed: "spaceship_idle")
    let spaceshipLeft = SKTexture(imageNamed: "spaceship_left")
    let spaceshipRight = SKTexture(imageNamed: "spaceship_right")
    
    private var isMovingRight = true
    private let spaceshipSpeed: CGFloat = 100.0
    
    // Add shooting variables
    private var lastShotTime: TimeInterval = 0
    private let shootSound = SKAction.playSoundFileNamed("shoot.mp3", waitForCompletion: false)
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupSpaceship()
        //        setupAudio()
        startSpaceshipMovement()
        startRandomShooting()
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        background.size = size
        addChild(background)
        
        // Setup parallax background seperti FITBGameScene
        setupParallaxBackground()
    }
    
    private func setupParallaxBackground() {
        for i in 0...1 {
            let strip = createCompleteParallaxStrip()
            strip.position = CGPoint(x: 0, y: self.size.height * CGFloat(i))
            strip.name = "parallax_strip"
            addChild(strip)
        }
    }
    
    private func createCompleteParallaxStrip() -> SKNode {
        let container = SKNode()
        
        var occupiedFrames = [CGRect]()
        
        placeAssets(on: container, textureNames: ["spacestation"], count: 2, zPosition: -7, occupiedFrames: &occupiedFrames)
        
        placeAssets(on: container, textureNames: ["galaxy"], count: 2, zPosition: -9, occupiedFrames: &occupiedFrames)
        
        placeAssets(on: container, textureNames: ["cloud_1", "cloud_2", "cloud_3"], count: 4, zPosition: -8, occupiedFrames: &occupiedFrames)
        
        placeAssets(on: container, textureNames: ["cloud_4", "cloud_5", "cloud_6"], count: 4, zPosition: -8, occupiedFrames: &occupiedFrames)
        
        placeStars(on: container, count: 50, zPosition: -7)
        
        return container
    }
    
    private func placeStars(on container: SKNode, count: Int, zPosition: CGFloat) {
        for _ in 0..<count {
            let starNumber = Int.random(in: 1...5)
            let star = SKSpriteNode(imageNamed: "star_\(starNumber)")
            
            star.position = CGPoint(x: .random(in: 0...self.size.width), y: .random(in: 0...self.size.height))
            
            star.setScale(.random(in: 0.05...0.2))
            
            star.alpha = .random(in: 0.4...1.0)
            star.zPosition = zPosition
            container.addChild(star)
        }
    }
    
    private func placeAssets(on container: SKNode, textureNames: [String], count: Int, zPosition: CGFloat, occupiedFrames: inout [CGRect]) {
        for _ in 0..<count {
            let textureName = textureNames.randomElement()!
            let node = SKSpriteNode(imageNamed: textureName)
            
            let aspectRatio = node.texture!.size().height / node.texture!.size().width
            let nodeWidth = self.size.width * CGFloat.random(in: 0.25...0.50)
            node.size = CGSize(width: nodeWidth, height: nodeWidth * aspectRatio)
            
            var attempts = 0
            var positionIsSafe = false
            
            while !positionIsSafe && attempts < 20 {
                let xPos = CGFloat.random(in: 0...self.size.width)
                let yPos = CGFloat.random(in: 0...self.size.height)
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
    
    override func update(_ currentTime: TimeInterval) {
        moveBackgroundStrip(speed: 0.3)
        cleanupBullets()
    }
    
    private func moveBackgroundStrip(speed: CGFloat) {
        self.enumerateChildNodes(withName: "parallax_strip") { (node, stop) in
            node.position.y -= speed
            if node.position.y < -self.size.height {
                node.position.y += self.size.height * 2
            }
        }
    }
    
    private func setupSpaceship() {
        setupWindAnimation()
        
        spaceship = SKSpriteNode(imageNamed: "spaceship_idle")
        spaceship.size = CGSize(width: 60, height: 70)
        spaceship.position = CGPoint(x: size.width / 2, y: 100)
        spaceship.zPosition = 5
        
        // Wind animation
        let windNode = SKSpriteNode(texture: SKTexture(imageNamed: "spaceship_wind_1"))
        windNode.size = CGSize(width: 70, height: 75)
        windNode.position = CGPoint(x: 0, y: 3)
        windNode.zPosition = -1
        windNode.alpha = 0.35
        if let windAnimation = self.windAnimation {
            windNode.run(windAnimation)
        }
        
        spaceship.addChild(windNode)
        addChild(spaceship)
    }
    
    private func setupWindAnimation() {
        var windTextures: [SKTexture] = []
        for i in 1...4 {
            windTextures.append(SKTexture(imageNamed: "spaceship_wind_\(i)"))
        }
        windAnimation = SKAction.repeatForever(
            SKAction.animate(with: windTextures, timePerFrame: 0.1)
        )
    }
    
    private func setupAudio() {
        if let musicURL = Bundle.main.url(forResource: "bgm", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            backgroundMusic?.autoplayLooped = true
            addChild(backgroundMusic!)
        }
    }
    
    private func startSpaceshipMovement() {
        let moveAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.moveSpaceshipToDirection()
                },
                SKAction.wait(forDuration: 0.02) // Smooth movement
            ])
        )
        spaceship.run(moveAction, withKey: "movement")
    }
    
    private func moveSpaceshipToDirection() {
        let margin: CGFloat = 60
        let deltaX: CGFloat = isMovingRight ? spaceshipSpeed * 0.02 : -spaceshipSpeed * 0.02
        
        spaceship.position.x += deltaX
        
        // Update texture berdasarkan arah
        spaceship.texture = isMovingRight ? spaceshipRight : spaceshipLeft
        
        // Cek boundaries dan balik arah
        if spaceship.position.x >= size.width - margin {
            isMovingRight = false
        } else if spaceship.position.x <= margin {
            isMovingRight = true
        }
    }
    
    private func startRandomShooting() {
        let randomShootAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 1.0...2.0)), // Random interval 1-3 seconds
                SKAction.run { [weak self] in
                    self?.fireBullet()
                }
            ])
        )
        run(randomShootAction, withKey: "randomShooting")
    }
    
    private func fireBullet() {
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.size = CGSize(width: 10, height: 10)
        bullet.position = CGPoint(
            x: spaceship.position.x,
            y: spaceship.position.y + spaceship.size.height / 2 + 10
        )
        bullet.name = "bullet"
        bullet.zPosition = 4
        
        addChild(bullet)
        
        // Play shoot sound
        //        run(shootSound)
        
        // Move bullet upward
        let moveUp = SKAction.moveBy(x: 0, y: size.height + 50, duration: 3.0)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveUp, remove])
        
        bullet.run(sequence)
    }
    
    private func cleanupBullets() {
        // Remove bullets that are off screen
        children.filter { $0.name == "bullet" }.forEach { bullet in
            if bullet.position.y > size.height + 50 {
                bullet.removeFromParent()
            }
        }
    }
    
    func stopBGM() {
        backgroundMusic?.run(SKAction.stop())
    }
    
    func playBGM() {
        backgroundMusic?.run(SKAction.play())
    }
}
