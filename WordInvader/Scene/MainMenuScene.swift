//
//  MainMenuScene.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 23/07/25.
//

import SpriteKit
import AVFoundation

class MainMenuScene: SKScene {
    
    private var spaceship: SKSpriteNode!
    private var backgroundMusic: SKAudioNode?
    private var windAnimation: SKAction?
    private var parallaxManager: ParallaxBackgroundManager?
    
    let spaceshipIdle = SKTexture(imageNamed: "spaceship_idle")
    let spaceshipLeft = SKTexture(imageNamed: "spaceship_left")
    let spaceshipRight = SKTexture(imageNamed: "spaceship_right")
    
    private var isMovingRight = true
    private let spaceshipSpeed: CGFloat = 100.0
    
    // Add shooting variables
    private var lastShotTime: TimeInterval = 0
    private let shootSound = SKAction.playSoundFileNamed("shoot.mp3", waitForCompletion: false)
    
    override func didMove(to view: SKView) {
        parallaxManager = ParallaxBackgroundManager(scene: self)
        parallaxManager?.setupParallaxBackground()
        parallaxManager?.setupFallingWindEffect()
        setupSpaceship()
        setupAudio()
        startSpaceshipMovement()
        startRandomShooting()
    }
    
    private func setupSpaceship() {
        setupWindAnimation()
        
        spaceship = SKSpriteNode(imageNamed: "spaceship_idle")
        spaceship.size = CGSize(width: 60, height: 70)
        spaceship.position = CGPoint(x: size.width / 2, y: 100)
        spaceship.zPosition = 5

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
        if let musicURL = Bundle.main.url(forResource: "mainmenu", withExtension: "mp3") {
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
    
    private func moveBackgroundStrip(speed: CGFloat) {
        parallaxManager?.moveBackgroundStrip(speed: speed)
    }
    
    override func update(_ currentTime: TimeInterval) {
        moveBackgroundStrip(speed: 0.3)
        cleanupBullets()
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
