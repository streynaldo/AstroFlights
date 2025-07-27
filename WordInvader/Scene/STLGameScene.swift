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
    case floor    = 0b1000
}

class STLGameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    weak var gameState: STLGameState?
    weak var gameKitManager: GameKitManager?
    
    private var player: SKSpriteNode!
    private var previousTouchPosition: CGPoint?
    private var parallaxManager: ParallaxBackgroundManager?
    
    private let soundManager = SoundManager.shared
    private let shootingManager = ShootingManager.self
    
    private let spaceshipIdle = SKTexture(imageNamed: "spaceship_idle")
    private let spaceshipLeft = SKTexture(imageNamed: "spaceship_left")
    private let spaceshipRight = SKTexture(imageNamed: "spaceship_right")
    
    private var activeWord = ""
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        parallaxManager = ParallaxBackgroundManager(scene: self)
        parallaxManager?.setupParallaxBackground()
        parallaxManager?.setupFallingWindEffect()
        
        setupPlayer()
        setupFloor()
        
        soundManager.playBGM(named: "bgm.mp3", on: self)
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let gameState = gameState, !gameState.isGameOver, !gameState.isPaused, !gameState.isCountingDown else { return }
        
        parallaxManager?.moveBackgroundStrip(speed: 0.6)
        
        if activeWord != gameState.currentWord {
            spawnCurrentWord()
        }
        
        if !children.contains(where: { $0.name == "obstacle" }) {
            gameState.wordMissed()
        }
    }
    
    func cleanupScene() {
        soundManager.stopBGM()
        self.removeAllActions()
        self.removeAllChildren()
    }
    
    // MARK: - Setup Methods
    private func setupPlayer() {
        player = SpaceshipFactory.createSpaceship(position: CGPoint(x: size.width / 2, y: 100))
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
    
    private func setupFloor() {
        let floorNode = SKNode()
        floorNode.position = CGPoint(x: size.width / 2, y: -50)
        floorNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 10))
        floorNode.physicsBody?.isDynamic = false
        floorNode.physicsBody?.categoryBitMask = PhysicsCategory.floor.rawValue
        floorNode.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle.rawValue
        floorNode.physicsBody?.collisionBitMask = 0
        addChild(floorNode)
    }
    
    // MARK: - Spawning Logic
    func spawnCurrentWord() {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        
        activeWord = gameState.currentWord
        
        children.filter({ $0.name == "obstacle" }).forEach { $0.removeFromParent() }
        
        let word = activeWord
        guard !word.isEmpty else { return }
        
        let shuffledLetters = Array(word).shuffled()
        let spacing = size.width / CGFloat(shuffledLetters.count + 1)
        
        let baseSpeed: CGFloat = 8.0
        let speedDecrease = CGFloat(gameState.score / 100) * 0.5
        let duration = max(3.0, baseSpeed - speedDecrease)
        
        for (index, letter) in shuffledLetters.enumerated() {
            let xPos = spacing * CGFloat(index + 1)
            createLetterObstacle(letter: letter, position: CGPoint(x: xPos, y: size.height + 50), duration: duration)
        }
    }
    
    private func createLetterObstacle(letter: Character, position: CGPoint, duration: CGFloat) {
        let randNumber = Int.random(in: 1...3)
        let box = SKSpriteNode(imageNamed: "rock\(randNumber)")
        box.size = CGSize(width: 50, height: 50)
        box.position = position
        box.name = "obstacle"
        box.zPosition = 8
        
        let label = SKLabelNode(fontNamed: "VTF MisterPixel")
        label.text = String(letter)
        label.fontSize = 26
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        box.addChild(label)
        
        box.userData = ["letter": letter]
        box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
        box.physicsBody?.categoryBitMask = PhysicsCategory.obstacle.rawValue
        box.physicsBody?.contactTestBitMask = PhysicsCategory.player.rawValue | PhysicsCategory.bullet.rawValue | PhysicsCategory.floor.rawValue
        box.physicsBody?.collisionBitMask = PhysicsCategory.none.rawValue
        
        let moveAction = SKAction.moveTo(y: -100, duration: duration)
        let removeAction = SKAction.removeFromParent()
        box.run(SKAction.sequence([moveAction, removeAction]))
        addChild(box)
    }
    
    private func removeAllObstaclesWithExplosion() {
        for child in children where child.name == "obstacle" {
            createExplosion(at: child.position)
            child.removeFromParent()
        }
    }
    
    // MARK: - Player Actions
    private func shoot() {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        let bullet = shootingManager.createBullet(
            position: CGPoint(x: player.position.x, y: player.position.y + 30),
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
    
    // MARK: - Physics Contact
    func didBegin(_ contact: SKPhysicsContact) {
        guard let gameState = gameState, !gameState.isPaused, !gameState.isCountingDown else { return }
        
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch contactMask {
        case PhysicsCategory.bullet.rawValue | PhysicsCategory.obstacle.rawValue:
            let bulletNode = contact.bodyA.categoryBitMask == PhysicsCategory.bullet.rawValue ? contact.bodyA.node : contact.bodyB.node
            let obstacleNode = contact.bodyA.categoryBitMask == PhysicsCategory.obstacle.rawValue ? contact.bodyA.node : contact.bodyB.node
            if let bullet = bulletNode, let obstacle = obstacleNode {
                bulletDidHitObstacle(bullet: bullet, obstacle: obstacle)
            }
            
        case PhysicsCategory.player.rawValue | PhysicsCategory.obstacle.rawValue:
            let obstacleNode = contact.bodyA.categoryBitMask == PhysicsCategory.obstacle.rawValue ? contact.bodyA.node : contact.bodyB.node
            if let obstacle = obstacleNode {
                playerDidHitObstacle(obstacle: obstacle)
            }
            
        case PhysicsCategory.floor.rawValue | PhysicsCategory.obstacle.rawValue:
            let obstacleNode = contact.bodyA.categoryBitMask == PhysicsCategory.obstacle.rawValue ? contact.bodyA.node : contact.bodyB.node
            obstacleNode?.removeFromParent()
            
        default:
            break
        }
    }
    
    private func bulletDidHitObstacle(bullet: SKNode, obstacle: SKNode) {
        guard let gameState = gameState, let gameKitManager = gameKitManager, !gameState.isGameOver, let letterInBox = obstacle.userData?["letter"] as? Character else { return }
        
        let targetLetterIndex = gameState.currentLetterIndex
        guard targetLetterIndex < gameState.currentWord.count else {
            bullet.removeFromParent()
            return
        }
        let targetLetter = Array(gameState.currentWord)[targetLetterIndex]
        
        createExplosion(at: obstacle.position)
        bullet.removeFromParent()
        
        if letterInBox == targetLetter {
            gameState.correctLetterShot(gameKitManager: gameKitManager)
            obstacle.removeFromParent()
            HapticsManager.shared.impact(style: .medium)
            
            if gameState.currentLetterIndex >= gameState.currentWord.count {
                removeAllObstaclesWithExplosion()
            }
        } else {
            gameState.incorrectLetterShot()
            showBrokenHeartEffect(at: obstacle.position)
            HapticsManager.shared.trigger(.error)
            
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
        
        createExplosion(at: player.position)
        obstacle.removeFromParent()
        
        gameState.obstacleMissedOrHitPlayer()
        showBrokenHeartEffect(at: player.position)
        HapticsManager.shared.trigger(.error)
    }
    
    // MARK: - Pause and Resume Logic
    
    func pauseGame() {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        
        self.physicsWorld.speed = 0
        
        for node in children where node.name == "obstacle" {
            node.isPaused = true
        }
        
        soundManager.stopBGM()
        gameState.isPaused = true
    }
    
    func resumeGame() {
        guard let gameState = gameState else { return }
        
        soundManager.playBGM(named: "bgm.mp3", on: self)
        gameState.isPaused = false
        startCountdown()
    }
    
    private func startCountdown() {
        guard let gameState = gameState else { return }
        
        gameState.isCountingDown = true
        
        // Buat countdown overlay
        let countdownOverlay = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.7), size: size)
        countdownOverlay.position = CGPoint(x: size.width/2, y: size.height/2)
        countdownOverlay.zPosition = 1000
        countdownOverlay.name = "countdownOverlay"
        addChild(countdownOverlay)
        
        // Buat label countdown
        let countdownLabel = SKLabelNode(text: "3")
        countdownLabel.fontSize = 80
        countdownLabel.fontColor = .white
        countdownLabel.fontName = "Born2bSporty FS"
        countdownLabel.horizontalAlignmentMode = .center
        countdownLabel.verticalAlignmentMode = .center
        countdownLabel.position = .zero
        countdownLabel.name = "countdownLabel"
        countdownOverlay.addChild(countdownLabel)
        
        // Animasi countdown 3, 2, 1, GO!
        let countdown3 = SKAction.run {
            countdownLabel.text = "3"
            countdownLabel.setScale(0.5)
            countdownLabel.run(SKAction.scale(to: 1.0, duration: 0.3))
        }
        
        let countdown2 = SKAction.run {
            countdownLabel.text = "2"
            countdownLabel.setScale(0.5)
            countdownLabel.run(SKAction.scale(to: 1.0, duration: 0.3))
        }
        
        let countdown1 = SKAction.run {
            countdownLabel.text = "1"
            countdownLabel.setScale(0.5)
            countdownLabel.run(SKAction.scale(to: 1.0, duration: 0.3))
        }
        
        let countdownGo = SKAction.run {
            countdownLabel.text = "GO!"
            countdownLabel.fontColor = .green
            countdownLabel.setScale(0.5)
            countdownLabel.run(SKAction.scale(to: 1.2, duration: 0.3))
        }
        
        let actualResume = SKAction.run { [weak self] in
            self?.performActualResume()
        }
        
        let removeOverlay = SKAction.run {
            countdownOverlay.removeFromParent()
        }
        
        // Jalankan sequence countdown
        let countdownSequence = SKAction.sequence([
            countdown3,
            SKAction.wait(forDuration: 1.0),
            countdown2,
            SKAction.wait(forDuration: 1.0),
            countdown1,
            SKAction.wait(forDuration: 1.0),
            countdownGo,
            SKAction.wait(forDuration: 0.5),
            actualResume,
            removeOverlay,
        ])
        
        run(countdownSequence)
    }
    
    private func performActualResume() {
        guard let gameState = gameState else { return }
        
        self.physicsWorld.speed = 1
        
        for node in children where node.name == "obstacle" {
            node.isPaused = false
        }
        
        gameState.isCountingDown = false
    }
    
    // MARK: - Effects & Touches
    private func createExplosion(at position: CGPoint, silent: Bool = false) {
        if let emitter = SKEmitterNode(fileNamed: "Explosion.sks") {
            emitter.position = position
            addChild(emitter)
            if !silent {
                soundManager.playSoundEffect(named: "explosion.mp3", on: self)
            }
            let wait = SKAction.wait(forDuration: 0.5)
            emitter.run(SKAction.sequence([wait, .removeFromParent()]))
        }
    }
    
    private func showBrokenHeartEffect(at position: CGPoint) {
        let brokenHeart = SKSpriteNode(imageNamed: "broken_heart")
        brokenHeart.position = position
        brokenHeart.size = CGSize(width: 60, height: 60)
        brokenHeart.zPosition = 15
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let wait = SKAction.wait(forDuration: 0.5)
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        brokenHeart.run(SKAction.sequence([fadeIn, wait, .group([moveUp, fadeOut]), .removeFromParent()]))
        soundManager.playSoundEffect(named: "wrong.mp3", on: self)
        addChild(brokenHeart)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let gameState = gameState, !gameState.isGameOver, !gameState.isPaused, !gameState.isCountingDown else { return }
        if let touch = touches.first {
            previousTouchPosition = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let gameState = gameState, !gameState.isGameOver, !gameState.isPaused, !gameState.isCountingDown else { return }
        guard let touch = touches.first, let previousPosition = previousTouchPosition else { return }
        let currentPosition = touch.location(in: self)
        let deltaX = currentPosition.x - previousPosition.x
        player.position.x += deltaX
        if deltaX > 0 { player.texture = spaceshipRight }
        else if deltaX < 0 { player.texture = spaceshipLeft }
        else { player.texture = spaceshipIdle }
        player.position.x = max(player.size.width / 2, player.position.x)
        player.position.x = min(size.width - player.size.width / 2, player.position.x)
        previousTouchPosition = currentPosition
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let gameState = gameState, !gameState.isGameOver, !gameState.isPaused, !gameState.isCountingDown else { return }
        previousTouchPosition = nil
        player.texture = spaceshipIdle
        shoot()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousTouchPosition = nil
        player.texture = spaceshipIdle
    }
}
