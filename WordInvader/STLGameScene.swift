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
    private var player: SKSpriteNode!
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
        
        setupParallaxBackground()
        setupFallingWindEffect()
        setupPlayer()
        setupAudio()
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        
        if gameState.isWordOnScreen && !children.contains(where: { $0.name == "obstacle" }) {
            gameState.skipToNextWord()
        }
        
        moveBackgroundStrip(speed: 0.6)
    }
    
    private func setupFallingWindEffect() {
        let createWindParticle = SKAction.run { [weak self] in
            self?.spawnWindParticle()
        }
        let wait = SKAction.wait(forDuration: 0.08, withRange: 0.1)
        
        let sequence = SKAction.sequence([createWindParticle, wait])
        let repeatForever = SKAction.repeatForever(sequence)
        
        run(repeatForever, withKey: "windSpawner")
    }
    
    private func spawnWindParticle() {
        let windImageNumber = Int.random(in: 1...4)
        let windNode = SKSpriteNode(imageNamed: "spaceship_wind_\(windImageNumber)")
        
        let randomX = CGFloat.random(in: 0...size.width)
        windNode.position = CGPoint(x: randomX, y: self.size.height + 100)
        
        windNode.size = CGSize(width: 3, height: 60)
        
        windNode.alpha = CGFloat.random(in: 0.2...0.5)
        windNode.zRotation = 0
        windNode.zPosition = 5
        
        let destinationY = -100.0
        let randomDuration = TimeInterval.random(in: 2.0...3.0)
        let moveAction = SKAction.moveTo(y: destinationY, duration: randomDuration)
        
        let removeAction = SKAction.removeFromParent()
        windNode.run(SKAction.sequence([moveAction, removeAction]))
        
        addChild(windNode)
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
    
    private func moveBackgroundStrip(speed: CGFloat) {
        self.enumerateChildNodes(withName: "parallax_strip") { (node, stop) in
            node.position.y -= speed
            if node.position.y < -self.size.height {
                node.position.y += self.size.height * 2
            }
        }
    }
    
    
    private func setupAudio() {
        if let musicURL = Bundle.main.url(forResource: "bgm", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            if let bgm = backgroundMusic {
                bgm.autoplayLooped = true
                addChild(bgm)
            }
        }
    }
    
    private func setupPlayer() {
        player = SKSpriteNode(imageNamed: "spaceship_idle")
        player.size = CGSize(width: 60, height: 70)
        player.position = CGPoint(x: size.width / 2, y: 100)
        player.name = "player"
        player.zPosition = 10
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.player.rawValue
        player.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle.rawValue
        player.physicsBody?.collisionBitMask = PhysicsCategory.none.rawValue
        addChild(player)
    }
    
    func cleanupScene() {
        backgroundMusic?.run(SKAction.stop())
        backgroundMusic?.removeFromParent()
        backgroundMusic = nil
        self.removeAllActions()
        self.removeAllChildren()
    }
    
    func spawnNextWord() { spawnWordRow() }
    
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
        
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.size = CGSize(width: 15, height: 25)
        bullet.position = player.position
        bullet.name = "bullet"
        bullet.zPosition = 9
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
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        player.position.x = location.x
        
        let halfPlayerWidth = player.size.width / 2
        player.position.x = max(halfPlayerWidth, player.position.x)
        player.position.x = min(self.size.width - halfPlayerWidth, player.position.x)
        
        if let previousPos = previousTouchPosition {
            let deltaX = location.x - previousPos.x
            if deltaX > 1 { // Beri sedikit threshold
                player.texture = spaceshipRight
            } else if deltaX < -1 {
                player.texture = spaceshipLeft
            } else {
                player.texture = spaceshipIdle
            }
        }
        previousTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        player.texture = spaceshipIdle
        if let startPos = previousTouchPosition, let endPos = touches.first?.location(in: self) {
            let distance = hypot(endPos.x - startPos.x, endPos.y - startPos.y)
            if distance < 10 {
                shoot()
            }
        }
        previousTouchPosition = nil
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
        guard let gameState = gameState, !gameState.isGameOver, let letterInBox = obstacle.userData?["letter"] as? Character else { return }
        
        let targetLetterIndex = gameState.currentLetterIndex
        guard targetLetterIndex < gameState.currentWord.count else {
            bullet.removeFromParent(); return
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
                .moveBy(x: 10, y: 0, duration: 0.05),
                .moveBy(x: -20, y: 0, duration: 0.1),
                .moveBy(x: 10, y: 0, duration: 0.05)
            ])
            obstacle.run(shake)
        }
    }
    
    private func playerDidHitObstacle(obstacle: SKNode) {
        guard let gameState = gameState, !gameState.isGameOver else { return }
        
        let yPos = obstacle.position.y
        self.children.filter { $0.name == "obstacle" && abs($0.position.y - yPos) < 1 }.forEach { node in
            createExplosion(at: node.position)
            node.removeFromParent()
        }
        
        gameState.skipToNextWord()
        HapticsManager.shared.trigger(.error)
        run(explosionSound)
    }
}
