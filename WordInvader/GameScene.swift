//
//  GameScene.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var spaceship: SKSpriteNode!
    var previousTouchPosition: CGPoint?
    
    let wordGenerator = WordGenerator()
    let gameManager = GameManager.shared
    
    var currentTask: WordTask!
    
    var isResetting = false
    
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // Spaceship setup...
        spaceship = SKSpriteNode(color: .blue, size: CGSize(width: 60, height: 30))
        spaceship.position = CGPoint(x: size.width / 2, y: 100)
        addChild(spaceship)
        
        // Gesture tap...
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
//        view.addGestureRecognizer(tapRecognizer)
        
        // 🚨 Ini WAJIB 🚨
        physicsWorld.contactDelegate = self
        
        // Tambah physics body ke spaceship
        spaceship.physicsBody = SKPhysicsBody(rectangleOf: spaceship.size)
        spaceship.physicsBody?.isDynamic = false // Supaya spaceship gak kena gravity
        spaceship.physicsBody?.categoryBitMask = 0x1 << 2 // 🚀 spaceship = kategori 2
        spaceship.physicsBody?.contactTestBitMask = 0x1 << 1 // bisa kontak dengan obstacle
        spaceship.physicsBody?.collisionBitMask = 0
        
        
        spawnObstacleRow()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var letterNode: SKNode?
        var bulletNode: SKNode?
        var spaceshipHit = false

        if contact.bodyA.node?.name?.hasPrefix("letter_") == true {
            letterNode = contact.bodyA.node
        } else if contact.bodyB.node?.name?.hasPrefix("letter_") == true {
            letterNode = contact.bodyB.node
        }

        if contact.bodyA.node?.name == "bullet" {
            bulletNode = contact.bodyA.node
        } else if contact.bodyB.node?.name == "bullet" {
            bulletNode = contact.bodyB.node
        }

        if contact.bodyA.node == spaceship || contact.bodyB.node == spaceship {
            spaceshipHit = true
        }

        if spaceshipHit && letterNode != nil {
            print("💥 Spaceship kena obstacle! Game reset.")
            resetGame()
            return
        }

        // ✅ Pastikan task masih ada
        guard let task = currentTask else { return }

        guard let hit = letterNode,
              let bullet = bulletNode,
              let name = hit.name,
              hit.parent != nil else {
            return
        }

        bullet.removeFromParent()

        let letter = name.replacingOccurrences(of: "letter_", with: "").first!

        if task.remainingLetters.contains(letter) {
            task.fill(letter: letter)
            print("Benar! \(task.display)")

            hit.removeFromParent()
            gameManager.currentTaskText = task.display

            if task.isComplete {
                print("🎉 Kata lengkap: \(task.word)")
                currentTask = nil
                gameManager.currentTaskText = ""

                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run { [weak self] in
                        self?.trySpawnIfClear()
                    }
                ]))
            }
        } else {
            print("Salah huruf — obstacle tetap turun")
        }
    }

    
    func trySpawnIfClear() {
        let stillHasObstacles = children.contains { node in
            node.name?.hasPrefix("letter_") == true
        }
        
        if !stillHasObstacles {
            print("✅ Semua obstacle habis, spawn row baru")
            spawnObstacleRow()
        } else {
            print("⏳ Masih ada obstacle, tunggu lagi...")
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    self?.trySpawnIfClear()
                }
            ]))
        }
    }
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            previousTouchPosition = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let previousPosition = previousTouchPosition else { return }
        
        let currentPosition = touch.location(in: self)
        let deltaX = currentPosition.x - previousPosition.x
        
        spaceship.position.x += deltaX
        
        // Clamp kiri-kanan
        spaceship.position.x = max(spaceship.size.width / 2, spaceship.position.x)
        spaceship.position.x = min(size.width - spaceship.size.width / 2, spaceship.position.x)
        
        previousTouchPosition = currentPosition
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousTouchPosition = nil
        fireBullet()
    }
    
    
    func spawnObstacleRow() {
        // Kalau task belum ada atau sudah selesai → generate kata baru
        if currentTask == nil || currentTask.isComplete {
            guard let word = wordGenerator.randomWord(ofLength: 5)?.uppercased() else {
                print("No word found")
                return
            }
            
            let blanksCount = Int.random(in: 1...2)
            let blankIndexes = Array(0..<word.count).shuffled().prefix(blanksCount)
            
            currentTask = WordTask(word: word, blanks: Array(blankIndexes))
            print("New Word: \(currentTask.word), blanks at: \(currentTask.blankIndexes)")
            print("Overlay: \(currentTask.display)")
        }
        
        // Huruf target
        var obstacles = currentTask.remainingLetters
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        // Tambahkan decoy agar total 5
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
        
        for (i, letter) in obstacles.enumerated() {
            let letterNode = SKLabelNode(text: String(letter))
            letterNode.fontSize = 40
            letterNode.fontColor = .white
            
            let boxSize = CGSize(width: 50, height: 50)
            let boxNode = SKShapeNode(rectOf: boxSize, cornerRadius: 8)
            boxNode.fillColor = .red
            boxNode.strokeColor = .clear
            
            let obstacle = SKNode()
            obstacle.name = "letter_\(letter)"
            obstacle.addChild(boxNode)
            obstacle.addChild(letterNode)
            
            letterNode.position = .zero
            boxNode.position = .zero
            
            let xPos = spacing * CGFloat(i + 1)
            obstacle.position = CGPoint(x: xPos, y: yStart)
            
            addChild(obstacle)
            
            let moveDown = SKAction.moveBy(x: 0, y: -size.height - 80, duration: 15)
            let check = SKAction.run { [weak self] in
                guard let self = self else { return }
                if self.currentTask != nil && !self.isResetting {
                    print("⚠️ Kata belum selesai, game direset!")
                    self.isResetting = true
                    self.resetGame()
                }
            }
            let remove = SKAction.removeFromParent()
            obstacle.run(SKAction.sequence([moveDown, check, remove]))
            setupObstaclePhysics(obstacle)
        }
        // Setelah bikin kata:
        gameManager.currentTaskText = currentTask.display // misalnya "A _ C _ E"
        print("Overlay: \(currentTask.display)")
    }
    
//    @objc func handleTap() {
//        fireBullet()
//    }
    
    func fireBullet() {
        let bullet = SKShapeNode(circleOfRadius: 5)
        bullet.fillColor = .yellow
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
        obstacle.physicsBody?.contactTestBitMask = (0x1 << 0) | (0x1 << 2) // kontak bullet & spaceship
        obstacle.physicsBody?.collisionBitMask = 0
        obstacle.physicsBody?.affectedByGravity = false
    }
    
    func resetGame() {
        guard !isResetting else { return } // Hindari double
        isResetting = true
        
        for child in children {
            if child.name?.hasPrefix("letter_") == true {
                child.removeFromParent()
            }
        }
        
        currentTask = nil
        gameManager.currentTaskText = ""
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1),
            SKAction.run { [weak self] in
                self?.isResetting = false
                self?.spawnObstacleRow()
            }
        ]))
    }
}
