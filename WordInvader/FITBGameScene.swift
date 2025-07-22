//
//  GameScene.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import SpriteKit
import AVFoundation

extension Notification.Name {
    static let didFITBGameOver = Notification.Name("didFITBGameOver")
}

class FITBGameScene: SKScene, SKPhysicsContactDelegate {
    
    var spaceship: SKSpriteNode!
    var previousTouchPosition: CGPoint?
    
    let wordGenerator = WordGenerator()
    let gameManager = GameManager.shared
    
    var currentTask: WordTask!
    var score : Int = 0
    
    var isResetting = false
    
    let shootSound = SKAction.playSoundFileNamed(
        "shoot.mp3",
        waitForCompletion: false
    )
    let explosionSound = SKAction.playSoundFileNamed(
        "explosion.mp3",
        waitForCompletion: false
    )
    let wrongSound = SKAction.playSoundFileNamed(
        "wrong.mp3",
        waitForCompletion: false
    )
    
    let spaceshipIdle = SKTexture(imageNamed: "spaceship_idle")
    let spaceshipLeft = SKTexture(imageNamed: "spaceship_left")
    let spaceshipRight = SKTexture(imageNamed: "spaceship_right")
    
    var onNewHighScore: (() -> Void)?
    private var personalHighScore: Int = (UserDefaults.standard.integer(forKey: "personalHighScore_FITB") != 0) ? UserDefaults.standard.integer(
        forKey: "personalHighScore_FITB"
    ) : 0
    
    var obstacleSpeed : CGFloat = 8
    
    var backgroundMusic: SKAudioNode?
    
    override func didMove(to view: SKView) {
        if let musicURL = Bundle.main.url(
            forResource: "bgm",
            withExtension: "mp3"
        ) {
            backgroundMusic = SKAudioNode(url: musicURL)
            backgroundMusic?.autoplayLooped = true
            if let bgm = backgroundMusic {
                addChild(bgm)
            }
        }
        
        setupParallaxBackground()
        setupFallingWindEffect()
        setupSpaceship()
        
        physicsWorld.contactDelegate = self
        
        let floorNode = SKNode()
        floorNode.position = CGPoint(x: size.width / 2, y: 0)
        floorNode.physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(width: size.width, height: 10)
        )
        floorNode.physicsBody?.isDynamic = false
        floorNode.physicsBody?.categoryBitMask = 0x1 << 3
        floorNode.physicsBody?.contactTestBitMask = 0x1 << 1
        floorNode.physicsBody?.collisionBitMask = 0
        addChild(floorNode)
        
        spawnObstacleRow()
    }
    
    override func update(_ currentTime: TimeInterval) {
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
    
    private func setupSpaceship() {
        spaceship = SKSpriteNode(imageNamed: "spaceship_idle")
        spaceship.size = CGSize(width: 60, height: 70)
        spaceship.position = CGPoint(x: size.width / 2, y: 100)
        spaceship.name = "player"
        spaceship.zPosition = 10
        addChild(spaceship)
        spaceship.physicsBody = SKPhysicsBody(rectangleOf: spaceship.size)
        spaceship.physicsBody?.isDynamic = false
        spaceship.physicsBody?.categoryBitMask = 0x1 << 2
        spaceship.physicsBody?.contactTestBitMask = 0x1 << 1
        spaceship.physicsBody?.collisionBitMask = 0
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
        
        placeAssets(
            on: container,
            textureNames: ["galaxy"],
            count: 2,
            zPosition: -9,
            occupiedFrames: &occupiedFrames
        )
        placeAssets(
            on: container,
            textureNames: ["cloud_1", "cloud_2", "cloud_3"],
            count: 4,
            zPosition: -8,
            occupiedFrames: &occupiedFrames
        )
        placeAssets(
            on: container,
            textureNames: ["cloud_4", "cloud_5", "cloud_6"],
            count: 4,
            zPosition: -8,
            occupiedFrames: &occupiedFrames
        )
        placeStars(on: container, count: 50, zPosition: -7)
        
        return container
    }
    
    private func placeStars(
        on container: SKNode,
        count: Int,
        zPosition: CGFloat
    ) {
        for _ in 0..<count {
            let starNumber = Int.random(in: 1...5)
            let star = SKSpriteNode(imageNamed: "star_\(starNumber)")
            star.position = CGPoint(
                x: .random(in: 0...self.size.width),
                y: .random(in: 0...self.size.height)
            )
            star.setScale(.random(in: 0.05...0.2))
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
    
    private func placeAssets(
        on container: SKNode,
        textureNames: [String],
        count: Int,
        zPosition: CGFloat,
        occupiedFrames: inout [CGRect]
    ) {
        for _ in 0..<count {
            let textureName = textureNames.randomElement()!
            let node = SKSpriteNode(imageNamed: textureName)
            
            let aspectRatio = node.texture!.size().height / node.texture!.size().width
            let nodeWidth = self.size.width * CGFloat.random(in: 0.25...0.50)
            node.size = CGSize(
                width: nodeWidth,
                height: nodeWidth * aspectRatio
            )
            
            var attempts = 0
            var positionIsSafe = false
            
            while !positionIsSafe && attempts < 20 {
                let xPos = CGFloat.random(in: 0...self.size.width)
                let yPos = CGFloat.random(in: 0...self.size.height)
                node.position = CGPoint(x: xPos, y: yPos)
                
                let nodeFrameWithPadding = node.frame.insetBy(dx: -20, dy: -20)
                positionIsSafe = !occupiedFrames
                    .contains { $0.intersects(nodeFrameWithPadding) }
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameManager.isGameOver else { return }
        if let touch = touches.first {
            previousTouchPosition = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameManager.isGameOver else { return }
        guard let touch = touches.first else { return }
        let currentPosition = touch.location(in: self)
        
        spaceship.position.x = currentPosition.x
        
        let halfPlayerWidth = spaceship.size.width / 2
        spaceship.position.x = max(halfPlayerWidth, spaceship.position.x)
        spaceship.position.x = min(
            size.width - halfPlayerWidth,
            spaceship.position.x
        )
        
        if let previousPos = previousTouchPosition {
            let deltaX = currentPosition.x - previousPos.x
            if deltaX > 1 {
                spaceship.texture = spaceshipRight
            } else if deltaX < -1 {
                spaceship.texture = spaceshipLeft
            } else {
                spaceship.texture = spaceshipIdle
            }
        }
        previousTouchPosition = currentPosition
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameManager.isGameOver else { return }
        spaceship.texture = spaceshipIdle
        
        if let startPos = previousTouchPosition, let endPos = touches.first?.location(
            in: self
        ) {
            let distance = hypot(endPos.x - startPos.x, endPos.y - startPos.y)
            if distance < 10 {
                fireBullet()
            }
        }
        previousTouchPosition = nil
    }
    
    override func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        previousTouchPosition = nil
        spaceship.texture = spaceshipIdle
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if isResetting { return }
        
        var letterNode: SKNode?
        var bulletNode: SKNode?
        var spaceshipHit = false
        var floorHit = false
        
        if contact.bodyA.categoryBitMask == 0x1 << 3 || contact.bodyB.categoryBitMask == 0x1 << 3 {
            floorHit = true
        }
        
        if floorHit {
            if contact.bodyA.node?.name?
                .hasPrefix("letter_") == true {
                letterNode = contact.bodyA.node
            }
            else if contact.bodyB.node?.name?.hasPrefix("letter_") == true {
                letterNode = contact.bodyB.node
            }
            
            if let hit = letterNode { hit.removeFromParent() }
            
            if let task = currentTask, !task.isComplete {
                gameManager.health -= 10
                if gameManager.health <= 0 {
                    resetGame(isGameOver: true); return
                }
            }
            
            currentTask = nil
            trySpawnIfClear()
            return
        }
        
        if contact.bodyA.node == spaceship || contact.bodyB.node == spaceship {
            spaceshipHit = true
        }
        if contact.bodyA.node?.name?
            .hasPrefix("letter_") == true { letterNode = contact.bodyA.node }
        else if contact.bodyB.node?.name?.hasPrefix("letter_") == true {
            letterNode = contact.bodyB.node
        }
        
        if spaceshipHit && letterNode != nil {
            run(explosionSound)
            HapticsManager.shared.trigger(.error)
            createExplosion(at: spaceship.position)
            letterNode?.removeFromParent()
            gameManager.health -= 10
            if gameManager.health <= 0 { resetGame(isGameOver: true) }
        }
        
        if contact.bodyA.node?.name == "bullet" {
            bulletNode = contact.bodyA.node
        }
        else if contact.bodyB.node?.name == "bullet" {
            bulletNode = contact.bodyB.node
        }
        
        if letterNode == nil {
            if contact.bodyA.node?.name?
                .hasPrefix("letter_") == true {
                letterNode = contact.bodyA.node
            }
            else if contact.bodyB.node?.name?.hasPrefix("letter_") == true {
                letterNode = contact.bodyB.node
            }
        }
        
        guard let hit = letterNode, let bullet = bulletNode, let name = hit.name, hit.parent != nil else {
            return
        }
        
        bullet.removeFromParent()
        let letter = name.replacingOccurrences(of: "letter_", with: "").first!
        
        if let task = currentTask, task.remainingLetters.contains(letter) {
            task.fill(letter: letter)
            createExplosion(at: hit.position)
            run(explosionSound)
            HapticsManager.shared.impact(style: .medium)
            hit.removeFromParent()
            gameManager.currentTaskText = task.display
            
            if task.isComplete {
                gameManager.score += 50
                score += 50
                currentTask = nil
                gameManager.currentTaskText = "Good Job"
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run { [weak self] in self?.trySpawnIfClear() }
                ]))
            }
        } else {
            run(wrongSound)
            HapticsManager.shared.trigger(.error)
            gameManager.health -= 5
            if gameManager.health <= 0 { resetGame(isGameOver: true) }
        }
    }
    
    func trySpawnIfClear() {
        if isResetting { return }
        let stillHasObstacles = children.contains {
            $0.name?.hasPrefix("letter_") == true
        }
        if stillHasObstacles {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in self?.trySpawnIfClear() }
            ]))
        } else {
            spawnObstacleRow()
        }
    }
    
    func spawnObstacleRow() {
        if currentTask == nil || currentTask.isComplete {
            guard let word = wordGenerator.randomWord()?.uppercased() else {
                return
            }
            let blanksCount = min(Int.random(in: 1...2), word.count)
            let blankIndexes = Array(0..<word.count).shuffled().prefix(
                blanksCount
            )
            currentTask = WordTask(word: word, blanks: Array(blankIndexes))
        }
        
        var obstacles = Array(currentTask.remainingLetters.prefix(4))
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        while obstacles.count < 5 {
            let random = letters.randomElement()!
            if !obstacles.contains(random) { obstacles.append(random) }
        }
        obstacles.shuffle()
        
        let spacing = size.width / CGFloat(obstacles.count + 1)
        let yStart = size.height + 40
        let speedUpFactor = floor(Double(gameManager.score / 100) * 0.5)
        obstacleSpeed = max(4.0, obstacleSpeed - speedUpFactor)
        
        for (i, letter) in obstacles.enumerated() {
            let randNumber = Int.random(in: 1...3)
            let letterNode = SKLabelNode(text: String(letter))
            letterNode.fontSize = 32
            letterNode.fontColor = .green
            letterNode.fontName = "Courier-Bold"
            letterNode.horizontalAlignmentMode = .center
            letterNode.verticalAlignmentMode = .center
            
            let boxNode = SKSpriteNode(imageNamed: "rock\(randNumber)")
            boxNode.size = CGSize(width: 50, height: 50)
            
            let obstacle = SKNode()
            obstacle.name = "letter_\(letter)"
            obstacle.addChild(boxNode)
            obstacle.addChild(letterNode)
            
            let xPos = spacing * CGFloat(i + 1)
            obstacle.position = CGPoint(x: xPos, y: yStart)
            addChild(obstacle)
            
            let moveDown = SKAction.moveBy(
                x: 0,
                y: -size.height - 80,
                duration: obstacleSpeed
            )
            let check = SKAction.run { [weak self] in
                guard let self = self else { return }
                if let task = self.currentTask, !task.isComplete, !self.isResetting {
                    self.isResetting = true
                    self.resetGame()
                }
            }
            let remove = SKAction.removeFromParent()
            obstacle.run(SKAction.sequence([moveDown, check, remove]))
            setupObstaclePhysics(obstacle)
        }
        gameManager.currentTaskText = currentTask.display
    }
    
    func fireBullet() {
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.size = CGSize(width: 10, height: 10)
        bullet.position = CGPoint(
            x: spaceship.position.x,
            y: spaceship.position.y + spaceship.size.height / 2 + 10
        )
        bullet.name = "bullet"
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        bullet.physicsBody?.categoryBitMask = 0x1 << 0
        bullet.physicsBody?.contactTestBitMask = 0x1 << 1
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.velocity = CGVector(dx: 0, dy: 400)
        bullet.physicsBody?.affectedByGravity = false
        
        addChild(bullet)
    }
    
    func setupObstaclePhysics(_ obstacle: SKNode) {
        obstacle.physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(width: 50, height: 50)
        )
        obstacle.physicsBody?.categoryBitMask = 0x1 << 1
        obstacle.physicsBody?.contactTestBitMask = (0x1 << 0) | (0x1 << 2) | (
            0x1 << 3
        )
        obstacle.physicsBody?.collisionBitMask = 0
        obstacle.physicsBody?.affectedByGravity = false
    }
    
    func createExplosion(at position: CGPoint) {
        if let explosion = SKEmitterNode(fileNamed: "Explosion.sks") {
            explosion.position = position
            addChild(explosion)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { explosion.removeFromParent() }
            ]))
        }
    }
    
    func startNewGame() {
        for child in children {
            if child.name?.hasPrefix("letter_") == true {
                child.removeAllActions()
                child.removeFromParent()
            }
        }
        playBGM()
        obstacleSpeed = 8
        gameManager.score = 0
        score = 0
        gameManager.health = 100
        gameManager.isGameOver = false
        isResetting = false
        currentTask = nil
        spawnObstacleRow()
    }
    
    func resetGame(isGameOver: Bool = false) {
        guard !isResetting else { return }
        isResetting = true
        
        self.gameManager.isGameOver = isGameOver
        gameManager.currentTaskText = isGameOver ? "Game Over!" : ""
        
        for child in children {
            if child.name?.hasPrefix("letter_") == true {
                child.removeAllActions()
                child.removeFromParent()
            }
        }
        
        if isGameOver {
            NotificationCenter.default.post(
                name: .didFITBGameOver,
                object: self
            )
            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    stopBGM()
                    self.gameManager.health = 100
                    self.isResetting = false
                }
            ]))
        } else {
            gameManager.score = 0
            score = 0
            gameManager.health = 100
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    self?.isResetting = false
                    self?.spawnObstacleRow()
                }
            ]))
        }
    }
    
    func stopBGM() { backgroundMusic?.run(SKAction.stop()) }
    func playBGM() { backgroundMusic?.run(SKAction.play()) }
    
    func checkAchievementsAndSubmitScore(
        for manager: GameKitManager,
        finalScore: Int
    ) {
        manager.submitScore(finalScore, to: "wordinvaders_fitb_leaderboard")
        if finalScore >= 100 {
            manager.reportAchievement(identifier: "achievement_score_100")
        }
        if finalScore >= 1000 {
            manager.reportAchievement(identifier: "achievement_legendary_score")
        }
        if finalScore > self.personalHighScore {
            self.personalHighScore = finalScore
            manager.reportAchievement(identifier: "achievement_personal_best")
            onNewHighScore?()
            saveHighScoreToDevice()
        }
    }
    
    private func saveHighScoreToDevice() {
        UserDefaults.standard
            .set(self.personalHighScore, forKey: "personalHighScore_STL")
    }
}
