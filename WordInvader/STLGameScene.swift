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
    case player   = 0b1      // 1
    case bullet   = 0b10     // 2
    case obstacle = 0b100    // 4
}

class STLGameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameState: STLGameState?
    private var player: SKSpriteNode!
    private var lastTouchLocation: CGPoint?
    var previousTouchPosition: CGPoint?
    
    let shootSound = SKAction.playSoundFileNamed("shoot.mp3", waitForCompletion: false)
    let explosionSound = SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false)
    let wrongSound = SKAction.playSoundFileNamed("wrong.mp3", waitForCompletion: false)
    
    let spaceshipIdle = SKTexture(imageNamed: "spaceship_idle")
    let spaceshipLeft = SKTexture(imageNamed: "spaceship_left")
    let spaceshipRight = SKTexture(imageNamed: "spaceship_right")
    
    var obstacleSpeed: CGFloat = 8
    
    private var backgroundMusic: SKAudioNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        setupPlayer()
        setupAudio()
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        
        if gameState.isWordOnScreen && !children.contains(where: { $0.name == "obstacle" }) {
            print("Word missed! Skipping to the next one.")
            gameState.skipToNextWord()
        }
    }
    
    private func setupAudio() {
        if let musicURL = Bundle.main.url(forResource: "bgm", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            if let backgroundMusic = backgroundMusic {
                backgroundMusic.autoplayLooped = true
                addChild(backgroundMusic)
            }
        }
    }
    
    func cleanupScene() {
        print("Cleaning up the scene.")
        
        backgroundMusic?.run(SKAction.stop())
        backgroundMusic?.removeFromParent()
        backgroundMusic = nil
        
        self.removeAllActions()
        self.removeAllChildren()
    }
    
    private func setupPlayer() {
        player = SKSpriteNode(imageNamed: "spaceship_idle")
        player.size = CGSize(width: 60, height: 70)
        player.position = CGPoint(x: size.width / 2, y: 100)
        player.name = "player"
        
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.player.rawValue
        player.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle.rawValue
        player.physicsBody?.collisionBitMask = PhysicsCategory.none.rawValue
        
        addChild(player)
    }
    
    func spawnNextWord() {
        spawnWordRow()
    }
    
    private func spawnWordRow() {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        let word = gameState.currentWord
        guard !word.isEmpty else { return }
        
        let shuffledLetters = Array(word).shuffled()
        let spacing = size.width / CGFloat(shuffledLetters.count + 1)
        let speedUpFactor = floor(Double(gameState.score / 100) * 0.5)
        obstacleSpeed = max(4.0, obstacleSpeed - speedUpFactor)
        
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
        
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.size = CGSize(width: 15, height: 25)
        bullet.position = player.position
        bullet.name = "bullet"
        
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.categoryBitMask = PhysicsCategory.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle.rawValue
        bullet.physicsBody?.collisionBitMask = PhysicsCategory.none.rawValue
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        
        let moveAction = SKAction.moveTo(y: size.height + 50, duration: 1.5)
        let removeAction = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([moveAction, removeAction]))
        
        addChild(bullet)
        
        run(shootSound)
        HapticsManager.shared.impact(style: .light)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            previousTouchPosition = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let previousPosition = previousTouchPosition else { return }
        let location = touch.location(in: self)
        
        player.position.x = location.x
        
        let deltaX = location.x - previousPosition.x
        
        if deltaX > 0 {
            player.texture = spaceshipRight
        } else if deltaX < 0 {
            player.texture = spaceshipLeft
        } else {
            player.texture = spaceshipIdle
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousTouchPosition = nil
        player.texture = spaceshipIdle
        shoot()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        shoot()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
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
            
            let maxLifetime = emitter.particleLifetime + (emitter.particleLifetimeRange / 2)
            let wait = SKAction.wait(forDuration: TimeInterval(maxLifetime))
            let remove = SKAction.removeFromParent()
            
            addChild(emitter)
            emitter.run(SKAction.sequence([wait, remove]))
        }
    }
    
    private func bulletDidHitObstacle(bullet: SKNode, obstacle: SKNode) {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        guard let letterInBox = obstacle.userData?["letter"] as? Character else { return }
        
        let targetLetterIndex = gameState.currentLetterIndex
        guard targetLetterIndex < gameState.currentWord.count else {
            bullet.removeFromParent()
            return
        }
        let targetLetter = Array(gameState.currentWord)[targetLetterIndex]
        
        createExplosion(at: obstacle.position)
        bullet.removeFromParent()
        
        if letterInBox == targetLetter {
            gameState.correctLetterShot()
            obstacle.removeFromParent()
            run(explosionSound)
            HapticsManager.shared.impact(style: .medium)
        } else {
            gameState.incorrectAction()
            HapticsManager.shared.trigger(.error)
            run(wrongSound)
            
            let shake = SKAction.sequence([
                SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                SKAction.moveBy(x: -20, y: 0, duration: 0.1),
                SKAction.moveBy(x: 10, y: 0, duration: 0.05)
            ])
            obstacle.run(shake)
        }
    }
    
    private func playerDidHitObstacle(obstacle: SKNode) {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        
        let obstacleYPosition = obstacle.position.y
        self.children.filter { $0.name == "obstacle" && abs($0.position.y - obstacleYPosition) < 1 }.forEach { node in
            createExplosion(at: node.position)
            node.removeFromParent()
        }
        
        gameState.skipToNextWord()
        
        HapticsManager.shared.trigger(.error)
        run(explosionSound)
    }
}
