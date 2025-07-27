//
//  GameScene.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import SpriteKit
import GameplayKit

enum PhysicsCategory: UInt32 {
    case none     = 0
    case player   = 0b1
    case bullet   = 0b10
    case obstacle = 0b100
}

class STLGameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameState: STLGameState?
    var gameKitManager: GameKitManager?
    private var player: SKSpriteNode!
    var previousTouchPosition: CGPoint?
    private var windAnimation: SKAction?
    private var isSpawningWord = false
    private var parallaxManager: ParallaxBackgroundManager?
    
    private let soundManager = SoundManager.shared
    
    let spaceshipIdle = SKTexture(imageNamed: "spaceship_idle")
    let spaceshipLeft = SKTexture(imageNamed: "spaceship_left")
    let spaceshipRight = SKTexture(imageNamed: "spaceship_right")
    
    var obstacleSpeed: CGFloat = 8
    private let shootingManager = ShootingManager.self
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(named: "background_color") ?? .black
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        // Initialize parallax manager and setup background
        parallaxManager = ParallaxBackgroundManager(scene: self)
        parallaxManager?.setupParallaxBackground()
        parallaxManager?.setupFallingWindEffect()
        
        setupPlayer()
        soundManager.playBGM(named: "bgm.mp3", on: self)
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        
        // Cek jika tidak ada obstacle dan belum sedang spawning
        if !isSpawningWord && gameState.isWordOnScreen && !children.contains(where: { $0.name == "obstacle" }) {
            gameState.skipToNextWord()
        }
        
        // Use parallax manager instead of local method
        parallaxManager?.moveBackgroundStrip(speed: 0.6)
    }
    
    func showCoinRewardEffect() {
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 100)
        coin.size = CGSize(width: 80, height: 80)
        coin.zPosition = 15
        coin.alpha = 0.0
        coin.setScale(0.0)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        let sequence = SKAction.sequence([.group([fadeIn, scaleUp]), scaleDown, wait, fadeOut, .removeFromParent()])
        
        coin.run(sequence)
        soundManager.playSoundEffect(named: "success_sound.mp3", on: self)
        addChild(coin)
    }
    
    private func showBrokenHeartEffect(at position: CGPoint) {
        let brokenHeart = SKSpriteNode(imageNamed: "broken_heart")
        brokenHeart.position = position
        brokenHeart.size = CGSize(width: 60, height: 60)
        brokenHeart.zPosition = 15
        brokenHeart.alpha = 0.0
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let wait = SKAction.wait(forDuration: 0.5)
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        
        let group = SKAction.group([moveUp, fadeOut])
        let sequence = SKAction.sequence([fadeIn, wait, group, .removeFromParent()])
        
        brokenHeart.run(sequence)
        soundManager.playSoundEffect(named: "wrong.mp3", on: self)
        addChild(brokenHeart)
    }
    
    private func setupPlayer() {
        player = SpaceshipFactory.createSpaceship(position: CGPoint(x: size.width / 2, y: 100))
        player.size = CGSize(width: 60, height: 70)
        player.name = "player"
        player.zPosition = 10
        SpaceshipFactory.setSpaceshipPhysics(
            player,
            categoryBitMask: PhysicsCategory.player.rawValue,
            contactTestBitMask: PhysicsCategory.obstacle.rawValue,
            collisionBitMask: PhysicsCategory.none.rawValue
        )
        addChild(player)
    }
    
    func cleanupScene() {
        soundManager.stopBGM()
        self.removeAllActions()
        self.removeAllChildren()
    }
    
    func spawnNextWord() {
            isSpawningWord = true
            spawnWordRow()
            // Reset flag setelah delay singkat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isSpawningWord = false
            }
        }
    private func spawnWordRow() {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        let word = gameState.currentWord
        guard !word.isEmpty else { return }
        
        let shuffledLetters = Array(word).shuffled()
        let spacing = size.width / CGFloat(shuffledLetters.count + 1)
        
        // Perbaiki perhitungan speed - semakin tinggi score, semakin cepat
        let baseSpeed: CGFloat = 8.0
        let speedIncrease = CGFloat(gameState.score / 100) * 0.5
        obstacleSpeed = baseSpeed + speedIncrease
        
        for (index, letter) in shuffledLetters.enumerated() {
            let xPos = spacing * CGFloat(index + 1)
            createLetterObstacle(letter: letter, position: CGPoint(x: xPos, y: size.height + 50), duration: obstacleSpeed)
        }
    }
    
    private func createLetterObstacle(letter: Character, position: CGPoint, duration: CGFloat) {
        let randNumber = Int.random(in: 1...3)
        let box = SKSpriteNode(imageNamed: "rock\(randNumber)")
        box.size = CGSize(width: 50, height: 50)
        box.position = position
        box.name = "obstacle"
        box.zPosition = 8
        
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = String(letter)
        label.fontSize = 26
        label.verticalAlignmentMode = .center
        box.addChild(label)
        
        box.userData = ["letter": letter]
        box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
        box.physicsBody?.categoryBitMask = PhysicsCategory.obstacle.rawValue
        box.physicsBody?.contactTestBitMask = PhysicsCategory.player.rawValue | PhysicsCategory.bullet.rawValue
        box.physicsBody?.collisionBitMask = PhysicsCategory.none.rawValue
        
        let moveAction = SKAction.moveTo(y: -50, duration: duration)
        let removeAction = SKAction.removeFromParent()
        box.run(SKAction.sequence([moveAction, removeAction]))
        addChild(box)
    }
    
    private func shoot() {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        let bullet = shootingManager.createBullet(
            position: player.position,
            size: CGSize(width: 15, height: 25),
            zPosition: 9,
            velocity: CGVector(dx: 0, dy: 400),
            categoryBitMask: PhysicsCategory.bullet.rawValue,
            contactTestBitMask: PhysicsCategory.obstacle.rawValue,
            collisionBitMask: PhysicsCategory.none.rawValue
        )
        addChild(bullet)
        soundManager.playSoundEffect(named: "shoot.mp3", on: self)
        HapticsManager.shared.impact(style: .light)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        if let touch = touches.first {
            previousTouchPosition = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        guard let touch = touches.first, let previousPosition = previousTouchPosition else { return }
        let currentPosition = touch.location(in: self)
        let deltaX = currentPosition.x - previousPosition.x
        player.position.x += deltaX
        if deltaX > 0 {
            player.texture = spaceshipRight
        } else if deltaX < 0 {
            player.texture = spaceshipLeft
        } else {
            player.texture = spaceshipIdle
        }
        let halfPlayerWidth = player.size.width / 2
        player.position.x = max(halfPlayerWidth, player.position.x)
        player.position.x = min(self.size.width - halfPlayerWidth, player.position.x)
        previousTouchPosition = currentPosition
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        previousTouchPosition = nil
        player.texture = spaceshipIdle
        shoot()
        soundManager.playSoundEffect(named: "shoot.mp3", on: self)
        HapticsManager.shared.impact(style: .light)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousTouchPosition = nil
        player.texture = spaceshipIdle
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody, secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA; secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB; secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask == PhysicsCategory.bullet.rawValue && secondBody.categoryBitMask == PhysicsCategory.obstacle.rawValue {
            if let bulletNode = firstBody.node, let obstacleNode = secondBody.node {
                bulletDidHitObstacle(bullet: bulletNode, obstacle: obstacleNode)
            }
        }
        
        if firstBody.categoryBitMask == PhysicsCategory.player.rawValue && secondBody.categoryBitMask == PhysicsCategory.obstacle.rawValue {
            if let obstacleNode = secondBody.node {
                playerDidHitObstacle(obstacle: obstacleNode)
            }
        }
    }
    
    private func createExplosion(at position: CGPoint) {
        if let emitter = SKEmitterNode(fileNamed: "Explosion.sks") {
            emitter.position = position
            addChild(emitter)
            let wait = SKAction.wait(forDuration: TimeInterval(emitter.particleLifetime + emitter.particleLifetimeRange / 2))
            emitter.run(SKAction.sequence([wait, .removeFromParent()]))
        }
    }
    
    private func bulletDidHitObstacle(bullet: SKNode, obstacle: SKNode) {
        guard let gameState = gameState, let gameKitManager = gameKitManager, !gameState.isGameOver, let letterInBox = obstacle.userData?["letter"] as? Character else { return }
        
        let targetLetterIndex = gameState.currentLetterIndex
        guard targetLetterIndex < gameState.currentWord.count else {
            bullet.removeFromParent(); return
        }
        let targetLetter = Array(gameState.currentWord)[targetLetterIndex]
        
        createExplosion(at: obstacle.position)
        bullet.removeFromParent()
        
        if letterInBox == targetLetter {
            gameState.correctLetterShot(gameKitManager: gameKitManager)
            obstacle.removeFromParent()
//            run(explosionSound)
            soundManager.playSoundEffect(named: "explosion.mp3", on: self)
            HapticsManager.shared.impact(style: .medium)
        } else {
            gameState.incorrectAction()
            HapticsManager.shared.trigger(.error)
//            run(wrongSound)
            soundManager.playSoundEffect(named: "wrong.mp3", on: self)
            
            showBrokenHeartEffect(at: obstacle.position)
            
            let shake = SKAction.sequence([
                .moveBy(x: 10, y: 0, duration: 0.05),
                .moveBy(x: -20, y: 0, duration: 0.1),
                .moveBy(x: 10, y: 0, duration: 0.05)
            ])
            obstacle.run(shake)
        }
    }
    
    private func playerDidHitObstacle(obstacle: SKNode) {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        
        // Hanya meledakkan dan menghapus obstacle yang tertabrak langsung
        createExplosion(at: obstacle.position)
        obstacle.removeFromParent()
        
        showBrokenHeartEffect(at: obstacle.position)
        
        HapticsManager.shared.trigger(.error)
//        run(explosionSound)
        soundManager.playSoundEffect(named: "explosion.mp3", on: self)
    }
}
