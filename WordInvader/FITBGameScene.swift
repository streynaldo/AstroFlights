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
    let gameManager = GameManager.shared
    
    var currentTask: WordTask!
    var currentGameSession: GameSession!
    var score : Int = 0
    
    var isResetting = false
    
    let shootSound = SKAction.playSoundFileNamed("shoot.mp3", waitForCompletion: false)
    let explosionSound = SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false)
    let wrongSound = SKAction.playSoundFileNamed("wrong.mp3", waitForCompletion: false)
    
    let spaceshipIdle = SKTexture(imageNamed: "spaceship_idle")
    let spaceshipLeft = SKTexture(imageNamed: "spaceship_left")
    let spaceshipRight = SKTexture(imageNamed: "spaceship_right")
    
    var onNewHighScore: (() -> Void)?
    private var personalHighScore: Int = (UserDefaults.standard.integer(forKey: "personalHighScore_FITB") != 0) ? UserDefaults.standard.integer(forKey: "personalHighScore_FITB") : 0
    
    var obstacleSpeed : CGFloat = 8
    
    var backgroundMusic: SKAudioNode?
    
    override func didMove(to view: SKView) {
        // Inisialisasi BGM
        if let musicURL = Bundle.main.url(forResource: "bgm", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            backgroundMusic?.autoplayLooped = true
            addChild(backgroundMusic!)
        }
        
        currentGameSession = GameSession()
        
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1  // Pastikan di belakang semua node
        background.size = size     // Atur agar full screen
        
        addChild(background)
        
        // Spaceship setup...
        spaceship = SKSpriteNode(imageNamed: "spaceship_idle")
        spaceship.size = CGSize(width: 60, height: 70)
        spaceship.position = CGPoint(x: size.width / 2, y: 100)
        addChild(spaceship)
        
        // 🚨 Ini WAJIB 🚨
        physicsWorld.contactDelegate = self
        
        // physics body ke spaceship
        spaceship.physicsBody = SKPhysicsBody(rectangleOf: spaceship.size)
        spaceship.physicsBody?.isDynamic = false // Supaya spaceship gak kena gravity
        spaceship.physicsBody?.categoryBitMask = 0x1 << 2 // 🚀 spaceship = kategori 2
        spaceship.physicsBody?.contactTestBitMask = 0x1 << 1 // bisa kontak dengan obstacle
        spaceship.physicsBody?.collisionBitMask = 0
        
        let floorNode = SKNode()
        floorNode.position = CGPoint(x: size.width / 2, y: 0) // dasar screen
        floorNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 10))
        floorNode.physicsBody?.isDynamic = false
        floorNode.physicsBody?.categoryBitMask = 0x1 << 3 // FLOOR = kategori 3
        floorNode.physicsBody?.contactTestBitMask = 0x1 << 1 // obstacle = kategori 1
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
                gameManager.health -= 10
                if gameManager.health <= 0 {
                    resetGame(isGameOver: true)
                    return
                }
            }
            
            currentTask = nil
            trySpawnIfClear() // langsung spawn kata baru
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
            run(explosionSound)
            HapticsManager.shared.trigger(.error)
            createExplosion(at: spaceship.position)
            letterNode?.removeFromParent() // hapus obstacle yang kena
            //            NABRAK MINUS HP
            gameManager.health -= 10
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
                run(explosionSound)
                HapticsManager.shared.impact(style: .medium)
                hit.removeFromParent()
                gameManager.currentTaskText = task.display
                
                if task.isComplete {
                    // Mark word as used in SwiftData
                    wordDataManager.markWordAsUsed(task.word)
                    
                    // Update both game session and game manager
                    gameManager.score += 50
                    score += 50
                    currentGameSession.score += 50
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
            // SELALU kurangi HP kalau huruf SALAH atau decoy
            run(wrongSound)
            HapticsManager.shared.trigger(.error)
            gameManager.health -= 5
            if gameManager.health <= 0 {
                resetGame(isGameOver: true)
            }
        }
        
        // Decoy tetap jalan kalau salah huruf
    }
    
    func removeRemainingLettersWithExplosions() {
        let letterNodes = children.filter { node in
            node.name?.hasPrefix("letter_") == true
        }
        
        for (index, letterNode) in letterNodes.enumerated() {
            // Stagger the explosions slightly for visual effect
            let delay = Double(index) * 0.1
            
            run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    self.createExplosion(at: letterNode.position)
                    self.run(self.explosionSound)
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
        guard !gameManager.isGameOver && !isPaused else { return }
        if let touch = touches.first {
            previousTouchPosition = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameManager.isGameOver && !isPaused else { return }
        guard let touch = touches.first,
              let previousPosition = previousTouchPosition else { return }
        
        let currentPosition = touch.location(in: self)
        let deltaX = currentPosition.x - previousPosition.x
        
        spaceship.position.x += deltaX
        
        if deltaX > 0 {
            // Gerak ke kanan
            spaceship.texture = spaceshipRight
        } else if deltaX < 0 {
            // Gerak ke kiri
            spaceship.texture = spaceshipLeft
        } else {
            // Tidak bergerak, idle
            spaceship.texture = spaceshipIdle
        }
        
        // Clamp kiri-kanan
        spaceship.position.x = max(spaceship.size.width / 2, spaceship.position.x)
        spaceship.position.x = min(size.width - spaceship.size.width / 2, spaceship.position.x)
        
        previousTouchPosition = currentPosition
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameManager.isGameOver && !isPaused else { return }
        previousTouchPosition = nil
        spaceship.texture = spaceshipIdle
        fireBullet()
        run(shootSound)
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
        
        // Hitung pengurang dari score
        let speedUpFactor = floor(Double(gameManager.score / 100) * 0.5)
        
        // Hitung durasi final, clamp ke minimum misalnya 3 detik
        obstacleSpeed = max(4.0, obstacleSpeed - speedUpFactor)
        
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
        print("Overlay: \(currentTask.display)")
    }
    
    private func createNewTask(with word: Word) {
        let wordText = word.text.uppercased()
        let blanksCount = min(Int.random(in: 1...2), wordText.count)
        let blankIndexes = Array(0..<wordText.count).shuffled().prefix(blanksCount)
        currentTask = WordTask(word: word, blanks: Array(blankIndexes))
        
        print("New Word: \(currentTask.word.text), blanks at: \(currentTask.blankIndexes)")
    }
    
    
    func fireBullet() {
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.size = CGSize(width: 10, height: 10)
        bullet.position = CGPoint(x: spaceship.position.x, y: spaceship.position.y + spaceship.size.height / 2 + 10)
        bullet.name = "bullet"
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        bullet.physicsBody?.categoryBitMask = 0x1 << 0 // kategori peluru
        bullet.physicsBody?.contactTestBitMask = 0x1 << 1 // bisa kontak dengan obstacle
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.velocity = CGVector(dx: 0, dy: 400)
        bullet.physicsBody?.affectedByGravity = false
        
        addChild(bullet)
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
            
            // Hapus node setelah efek selesai
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
        gameManager.score = 0
        score = 0
        gameManager.health = 100
        gameManager.isGameOver = false
        isResetting = false
        
        // Create new game session
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
                
                gameManager.isGameOver = true
                gameManager.currentTaskText = "Game Over!"
                
                // Show stats
                let stats = wordDataManager.getGameStats()
                print("Game Stats - Total Games: \(stats.totalGames), Best Score: \(stats.bestScore), Average: \(stats.averageScore)")
            } else {
                gameManager.isGameOver = false
                gameManager.currentTaskText = ""
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
                        self.gameManager.health = 100
                        self.isResetting = false
                    }
                ]))
            } else {
                // Reset for new game
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
    
    func stopBGM() {
        backgroundMusic?.run(SKAction.stop())
    }
    
    func playBGM() {
        backgroundMusic?.run(SKAction.play())
    }
    
    func checkAchievementsAndSubmitScore(for manager: GameKitManager, finalScore: Int) {
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
            print("New personal high score: \(finalScore)")
        }
    }
    
    private func saveHighScoreToDevice() {
        UserDefaults.standard.set(self.personalHighScore, forKey: "personalHighScore_STL")
    }
    
    func randomMotivation() -> String {
        let messages = [
            "Keep practicing and beat your high score!",
            "You got this, Captain!",
            "Never give up, pilot! Try again!",
            "Your spaceship needs you!",
            "One more try! Show them who's boss!"
        ]
        return messages.randomElement() ?? ""
    }
    
    // Add these methods to your FITBGameScene class

    func pauseGame() {
        isPaused = true
        // Pause all actions
        for child in children {
            child.isPaused = true
        }
        // Pause physics
        physicsWorld.speed = 0
    }

    func resumeGame() {
        isPaused = false
        // Resume all actions
        for child in children {
            child.isPaused = false
        }
        // Resume physics
        physicsWorld.speed = 1
    }

    // Update your existing methods to check pause state
    override func update(_ currentTime: TimeInterval) {
        if isPaused { return }
        
        // Your existing update logic
        // ...
    }
}
