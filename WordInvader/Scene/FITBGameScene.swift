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
    
    var wordDataManager : WordDataManager! = nil
    let gameManager = FITBGameState.shared
    
    var currentTask: WordTask!
    var currentGameSession: GameSession!
    
    var isResetting = false
    
    private let soundManager = SoundManager.shared
    
    let spaceshipIdle = SKTexture(imageNamed: "spaceship_idle")
    let spaceshipLeft = SKTexture(imageNamed: "spaceship_left")
    let spaceshipRight = SKTexture(imageNamed: "spaceship_right")
    
    var onNewHighScore: (() -> Void)?
    private var personalHighScore: Int = (UserDefaults.standard.integer(forKey: "personalHighScore_FITB") != 0) ? UserDefaults.standard.integer(forKey: "personalHighScore_FITB") : 0
    
    var obstacleSpeed : CGFloat = 10
    
    var isCountingDown = false
    private var isCountdownActive = false
    
    private var parallaxManager: ParallaxBackgroundManager?
    private let shootingManager = ShootingManager.self
    
    override func didMove(to view: SKView) {
        // Inisialisasi BGM
        soundManager.playBGM(named: "fitbbgm.mp3", on: self)
        currentGameSession = GameSession()
        
        // Initialize parallax manager and setup background
        parallaxManager = ParallaxBackgroundManager(scene: self)
        parallaxManager?.setupParallaxBackground()
        parallaxManager?.setupFallingWindEffect()
        
        setupSpaceship()
        
        // 🚨 Ini WAJIB 🚨
        physicsWorld.contactDelegate = self
        
        let floorNode = SKNode()
        floorNode.position = CGPoint(x: size.width / 2, y: 0)
        floorNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 10))
        floorNode.physicsBody?.isDynamic = false
        floorNode.physicsBody?.categoryBitMask = 0x1 << 3
        floorNode.physicsBody?.contactTestBitMask = 0x1 << 1
        floorNode.physicsBody?.collisionBitMask = 0
        addChild(floorNode)
        
        spawnObstacleRow()
    }
    
    func configure(with wordDataManager: WordDataManager) {
        self.wordDataManager = wordDataManager
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Jangan proses kalau sedang reset
        if isResetting { return }
        
        var letterNode: SKNode?
        var bulletNode: SKNode?
        var spaceshipHit = false
        var floorHit = false
        
        if contact.bodyA.categoryBitMask == 0x1 << 3 || contact.bodyB.categoryBitMask == 0x1 << 3 {
            floorHit = true
        }
        
        if floorHit {
            if contact.bodyA.node?.name?.hasPrefix("letter_") == true {
                letterNode = contact.bodyA.node
            } else if contact.bodyB.node?.name?.hasPrefix("letter_") == true {
                letterNode = contact.bodyB.node
            }
            
            if let hit = letterNode {
                hit.removeFromParent()
            }
            
            // Kalo node kelewat minus hp
            if let task = currentTask, !task.isComplete {
                gameManager.updateScore(by: -25)
                if gameManager.score <= 0 {
                    gameManager.score = 0
                }
                gameManager.streak = 0
                
                // Set task as complete to prevent reset when new obstacles are created
                currentTask = nil
                
                // Check if game should end
                if gameManager.health <= 0 {
                    resetGame(isGameOver: true)
                    return
                }
            }
            
            // Only spawn new obstacles if game is still active
            if !isResetting && gameManager.health > 0 {
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run { [weak self] in
                        self?.trySpawnIfClear()
                    }
                ]))
            }
            return
        }
        
        
        // Spaceship collision
        if contact.bodyA.node == spaceship || contact.bodyB.node == spaceship {
            spaceshipHit = true
        }
        if contact.bodyA.node?.name?.hasPrefix("letter_") == true {
            letterNode = contact.bodyA.node
        } else if contact.bodyB.node?.name?.hasPrefix("letter_") == true {
            letterNode = contact.bodyB.node
        }
        
        if spaceshipHit && letterNode != nil {
//            run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
            soundManager.playSoundEffect(named: "explosion.mp3", on: self)
            HapticsManager.shared.trigger(.error)
            createExplosion(at: spaceship.position)
            letterNode?.removeFromParent()
            gameManager.updateHealth(by: -1)
            gameManager.streak = 0
            print("Spaceship hit! Health: \(gameManager.health)")
            if gameManager.health <= 0 {
                resetGame(isGameOver: true)
            }
        }
        
        
        // Bullet vs letter
        if contact.bodyA.node?.name == "bullet" {
            bulletNode = contact.bodyA.node
        } else if contact.bodyB.node?.name == "bullet" {
            bulletNode = contact.bodyB.node
        }
        // Pastikan letterNode ketemu (cari lagi kalau belum)
        if letterNode == nil {
            if contact.bodyA.node?.name?.hasPrefix("letter_") == true {
                letterNode = contact.bodyA.node
            } else if contact.bodyB.node?.name?.hasPrefix("letter_") == true {
                letterNode = contact.bodyB.node
            }
        }
        
        guard let hit = letterNode,
              let bullet = bulletNode,
              let name = hit.name,
              hit.parent != nil else {
            return
        }
        
        bullet.removeFromParent()
        
        let letter = name.replacingOccurrences(of: "letter_", with: "").first!
        
        if let task = currentTask, task.remainingLetters.contains(letter) {
            // BENAR
            task.fill(letter: letter)
            createExplosion(at: hit.position)
//            soundManager.playSoundEffect(named: "explosion.mp3", on: self)
            HapticsManager.shared.impact(style: .medium)
            hit.removeFromParent()
            gameManager.currentTaskText = task.display
            if task.isComplete {
                gameManager.streak += 1
                if gameManager.streak % 3 == 0 {
                    gameManager.updateHealth(by: 1)
                    print("Streak! Health increased to \(gameManager.health)")
                }
                // Mark word as used in SwiftData
                wordDataManager.markWordAsUsed(task.word)
                
                // Update both game session and game manager
                gameManager.updateScore(by: 25)
                currentGameSession.wordsCompleted += 1
                
                currentTask = nil
                gameManager.currentTaskText = "Good Job"
                
                removeRemainingLettersWithExplosions()
                
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.0),
                    SKAction.run { [weak self] in
                        self?.trySpawnIfClear()
                    }
                ]))
            }
        } else {
            //SALAH
            createExplosion(at: hit.position)
            let shake = SKAction.sequence([
                .moveBy(x: 10, y: 0, duration: 0.05),
                .moveBy(x: -20, y: 0, duration: 0.1),
                .moveBy(x: 10, y: 0, duration: 0.05)
            ])
            hit.run(shake)
            
            soundManager.playSoundEffect(named: "wrong.mp3", on: self)
//            showBrokenHeartEffect(at: hit.position)
            HapticsManager.shared.trigger(.error)
            gameManager.updateScore(by: -10)
            gameManager.streak = 0
            if gameManager.score <= 0 {
                gameManager.score = 0
            }
        }
        
        // Decoy tetap jalan kalau salah huruf
    }
    
    private func setupSpaceship() {
        let position = CGPoint(x: size.width / 2, y: 100)
        spaceship = SpaceshipFactory.createSpaceship(position: position)
        SpaceshipFactory.setSpaceshipPhysics(
            spaceship,
            categoryBitMask: 0x1 << 2,
            contactTestBitMask: 0x1 << 1,
            collisionBitMask: 0
        )
        addChild(spaceship)
    }
    
    func removeRemainingLettersWithExplosions() {
        let letterNodes = children.filter { node in
            node.name?.hasPrefix("letter_") == true
        }
        for (index, letterNode) in letterNodes.enumerated() {
            let delay = Double(index) * 0.1
            run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    self.createExplosion(at: letterNode.position)
                    self.soundManager.playSoundEffect(named: "explosion.mp3", on: self)
                    letterNode.removeFromParent()
                }
            ]))
        }
    }
    
    
    func trySpawnIfClear() {
        if isResetting { return } // Stop kalau reset sedang jalan
        
        let stillHasObstacles = children.contains { node in
            node.name?.hasPrefix("letter_") == true
        }
        
        if stillHasObstacles {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    self?.trySpawnIfClear()
                }
            ]))
        } else {
            spawnObstacleRow()
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameManager.isGameOver && !isPaused && !isCountingDown else { return }
        if let touch = touches.first {
            previousTouchPosition = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameManager.isGameOver && !isPaused && !isCountingDown else { return }
        guard let touch = touches.first,
              let previousPosition = previousTouchPosition else { return }
        
        let currentPosition = touch.location(in: self)
        let deltaX = currentPosition.x - previousPosition.x
        
        spaceship.position.x += deltaX
        
        if deltaX > 0 {
            spaceship.texture = spaceshipRight
        } else if deltaX < 0 {
            spaceship.texture = spaceshipLeft
        } else {
            spaceship.texture = spaceshipIdle
        }
        
        spaceship.position.x = max(spaceship.size.width / 2, spaceship.position.x)
        spaceship.position.x = min(size.width - spaceship.size.width / 2, spaceship.position.x)
        
        previousTouchPosition = currentPosition
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameManager.isGameOver && !isPaused && !isCountingDown else { return }
        previousTouchPosition = nil
        spaceship.texture = spaceshipIdle
        fireBullet()
        soundManager.playSoundEffect(named: "shoot.mp3", on: self)
        HapticsManager.shared.impact(style: .light)
    }
    
    
    func spawnObstacleRow() {
        // Generate new word task using SwiftData
        if currentTask == nil || currentTask.isComplete {
            guard let word = wordDataManager.getRandomWord() else {
                // Reset word usage if no words available
                wordDataManager.resetWordUsage()
                guard let resetWord = wordDataManager.getRandomWord() else {
                    print("No words found even after reset")
                    return
                }
                createNewTask(with: resetWord)
                return
            }
            
            createNewTask(with: word)
        }
        
        // 🚫 Batasi obstacles target max 4 huruf (biar decoy max 5 total)
        var obstacles = Array(currentTask.remainingLetters.prefix(4))
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        while obstacles.count < 5 {
            let random = letters.randomElement()!
            if !obstacles.contains(random) {
                obstacles.append(random)
            }
        }
        
        obstacles.shuffle()
        
        let totalObstacles = obstacles.count
        let spacing = size.width / CGFloat(totalObstacles + 1)
        let yStart = size.height + 40
        
        // Hitung pengurang dari score - fix type mismatch
        let speedUpFactor = CGFloat(gameManager.score / 100) * 0.5
        
        // Hitung durasi final, clamp ke minimum misalnya 3 detik
        obstacleSpeed = max(4.5, obstacleSpeed - speedUpFactor)
        
        for (i, letter) in obstacles.enumerated() {
            let randNumber = Int.random(in: 1...3)
            
            // 🔡 Buat huruf retro
            let letterNode = SKLabelNode(text: String(letter))
            letterNode.fontSize = 32
            letterNode.fontColor = .green // atau .white
            letterNode.fontName = "Courier-Bold"
            letterNode.horizontalAlignmentMode = .center
            letterNode.verticalAlignmentMode = .center
            
            let boxNode = SKSpriteNode(imageNamed: "rock\(randNumber)")
            boxNode.size = CGSize(width: 50, height: 50)
            
            let obstacle = SKNode()
            obstacle.name = "letter_\(letter)"
            obstacle.addChild(boxNode)
            obstacle.addChild(letterNode)
            
            letterNode.position = .zero
            boxNode.position = .zero
            
            let xPos = spacing * CGFloat(i + 1)
            obstacle.position = CGPoint(x: xPos, y: yStart)
            
            addChild(obstacle)
            
            // ⚡️ Durasi gerak dipercepat agar Node nggak numpuk
            let moveDown = SKAction.moveBy(x: 0, y: -size.height - 80, duration: obstacleSpeed)
            
            let check = SKAction.run { [weak self] in
                guard let self = self else { return }
                if let task = self.currentTask, !task.isComplete, !self.isResetting {
                    print("⚠️ Belum selesai, RESET")
                    self.isResetting = true
                    self.resetGame()
                }
            }
            
            let remove = SKAction.removeFromParent()
            obstacle.run(SKAction.sequence([moveDown, check, remove]))
            setupObstaclePhysics(obstacle)
        }
        
        // 📝 Update overlay kata
        gameManager.currentTaskText = currentTask.display
        print("Overlay: \(gameManager.currentTaskText)")
    }
    
    private func createNewTask(with word: Word) {
        let wordText = word.text.uppercased()
        let blanksCount = min(Int.random(in: 1...2), wordText.count)
        let blankIndexes = Array(0..<wordText.count).shuffled().prefix(blanksCount)
        currentTask = WordTask(word: word, blanks: Array(blankIndexes))
        
        print("New Word: \(currentTask.word.text), blanks at: \(currentTask.blankIndexes)")
    }
    
    
    private func fireBullet() {
        let bullet = shootingManager.createBullet(
            position: CGPoint(x: spaceship.position.x, y: spaceship.position.y + spaceship.position.y + 10),
            size: CGSize(width: 10, height: 10),
            zPosition: 9,
            velocity: CGVector(dx: 0, dy: 400),
            categoryBitMask: 0x1 << 0, // kategori peluru
            contactTestBitMask: 0x1 << 1, // bisa kontak dengan obstacle
            collisionBitMask: 0
        )
        addChild(bullet)
        run(ShootingManager.shootSound)
    }
    
    func setupObstaclePhysics(_ obstacle: SKNode) {
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 50, height: 50))
        obstacle.physicsBody?.categoryBitMask = 0x1 << 1 // obstacle = kategori 1
        obstacle.physicsBody?.contactTestBitMask = (0x1 << 0) | (0x1 << 2) | (0x1 << 3) // bullet, spaceship, floor
        obstacle.physicsBody?.collisionBitMask = 0
        obstacle.physicsBody?.affectedByGravity = false
    }
    
    func createExplosion(at position: CGPoint) {
        if let explosion = SKEmitterNode(fileNamed: "Explosion.sks") {
            explosion.position = position
            addChild(explosion)
            soundManager.playSoundEffect(named: "explosion.mp3", on: self)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { explosion.removeFromParent() }
            ]))
        }
    }
    func startNewGame() {
        // Clear obstacles
        for child in children {
            if child.name?.hasPrefix("letter_") == true {
                child.removeAllActions()
                child.removeFromParent()
            }
        }
        
        playBGM()
        obstacleSpeed = 8
        gameManager.resetForNewGame()
        isResetting = false
        currentGameSession = GameSession()
        currentTask = nil
        spawnObstacleRow()
    }
    
    func resetGame(isGameOver: Bool = false) {
        guard !isResetting else { return }
        isResetting = true
        
        if isGameOver {
            // Save game session to SwiftData
            currentGameSession.duration = Date().timeIntervalSince(currentGameSession.dateStarted)
            wordDataManager.saveGameSession(currentGameSession)
            
            gameManager.setGameOver()
            gameManager.setCurrentTaskText("Game Over!")
            
            // Show stats
            let stats = wordDataManager.getGameStats()
//            print("Game Stats - Total Games: \(stats.totalGames), Best Score: \(stats.bestScore), Average: \(stats.averageScore)")
        } else {
            gameManager.isGameOver = false
            gameManager.setCurrentTaskText("")
        }
        
        // Bersihkan obstacles
        for child in children {
            if child.name?.hasPrefix("letter_") == true {
                child.removeAllActions()
                child.removeFromParent()
            }
        }
        
        if isGameOver {
            NotificationCenter.default.post(name: .didFITBGameOver, object: self)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    stopBGM()
                    self.gameManager.health = 5
                    self.isResetting = false
                }
            ]))
        } else {
            gameManager.reset()
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    self?.isResetting = false
                    self?.spawnObstacleRow()
                    self?.playBGM()
                }
            ]))
        }
    }
    
    func stopBGM() {
        soundManager.stopBGM()
    }
    
    func playBGM() {
        soundManager.resumeBGM()
    }
    
    func checkAchievementsAndSubmitScore(for manager: GameKitManager, finalScore: Int) {
        gameManager.checkAchievementsAndSubmitScore(for: manager, finalScore: finalScore, onNewHighScore: onNewHighScore)
    }
    
    private func saveHighScoreToDevice() {
        UserDefaults.standard.set(self.personalHighScore, forKey: "personalHighScore_FITB")
    }
    
    func randomMotivation() -> String {
        return gameManager.randomMotivation()
    }
    
    // Add these methods to your FITBGameScene class
    
    func pauseGame() {
        // Jangan pause kalau sedang countdown
        if isCountingDown { return }
        
        isPaused = true
        // Pause all actions
        for child in children {
            child.isPaused = true
        }
        // Pause physics
        physicsWorld.speed = 0
        
        // Tambahkan pause overlay
        let pauseOverlay = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.5), size: size)
        pauseOverlay.position = CGPoint(x: size.width/2, y: size.height/2)
        pauseOverlay.zPosition = 999
        pauseOverlay.name = "pauseOverlay"
        addChild(pauseOverlay)
    }
    
    func resumeGame() {
        startCountdown()
    }
    
    private func startCountdown() {
        removePauseOverlay()
        isCountingDown = true
        gameManager.isCountingDown = true
        isCountdownActive = true
        self.isPaused = false // Pastikan SKAction countdown tetap berjalan
        physicsWorld.speed = 0
        for child in children {
            if child.name?.hasPrefix("letter_") == true || child.name == "player" {
                child.isPaused = true
            }
        }
        
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
        isCountingDown = false
        gameManager.isCountingDown = false
        isCountdownActive = false
        isPaused = false
        // Resume all actions including obstacles
        for child in children {
            child.isPaused = false
        }
        // Resume physics
        physicsWorld.speed = 1
    }
    
    private func removePauseOverlay() {
        childNode(withName: "pauseOverlay")?.removeFromParent()
    }
    
    // Update your existing methods to check pause state
    override func update(_ currentTime: TimeInterval) {
        if isPaused || isCountdownActive { return }
        
        // Use parallax manager instead of local method
        parallaxManager?.moveBackgroundStrip(speed: 0.6)
    }
    
    private func showBrokenHeartEffect(at position: CGPoint) {
        let brokenHeart = SKSpriteNode(imageNamed: "broken_heart")
        brokenHeart.position = position
        brokenHeart.size = CGSize(width: 60, height: 60)
        brokenHeart.zPosition = 15 // Paling depan
        brokenHeart.alpha = 0.0
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let wait = SKAction.wait(forDuration: 0.5)
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        
        let group = SKAction.group([moveUp, fadeOut])
        let sequence = SKAction.sequence([fadeIn, wait, group, .removeFromParent()])
        
        brokenHeart.run(sequence)
        addChild(brokenHeart)
    }
    
    
}
