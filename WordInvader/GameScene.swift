//
//  GameScene.swift
//  WordInvader
//
//  Created by Stefanus Reynaldo on 09/07/25.
//

import SpriteKit

class GameScene: SKScene {
    
    var spaceship: SKSpriteNode!
    var previousTouchPosition: CGPoint?
    
    let wordGenerator = WordGenerator()
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // Spaceship
        spaceship = SKSpriteNode(color: .blue, size: CGSize(width: 60, height: 30))
        spaceship.position = CGPoint(x: size.width / 2, y: 100)
        addChild(spaceship)
        
        // Pasang tap gesture
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapRecognizer)
        
        startSpawningObstacles()
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
    }
    
    func startSpawningObstacles() {
        let spawn = SKAction.run { [weak self] in
            self?.spawnObstacleRow()
        }
        let wait = SKAction.wait(forDuration: 2.5) // spawn baris baru tiap 2.5 detik
        let sequence = SKAction.sequence([spawn, wait])
        let repeatForever = SKAction.repeatForever(sequence)
        run(repeatForever)
    }
    
    
    func spawnObstacleRow() {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        let totalObstacles = 5
        let spacing = size.width / CGFloat(totalObstacles + 1)
        let yStart = size.height + 40
        guard let word = wordGenerator.randomWord(ofLength: 5)?.uppercased() else {
            print("No word found")
            return
        }
        print("Spawning word: \(word)")
        
        
        for i in 0..<totalObstacles {
            // Huruf random
            let randomChar = letters.randomElement()!
            
            // Node huruf
            let letterNode = SKLabelNode(text: String(randomChar))
            letterNode.fontSize = 40
            letterNode.fontColor = .white
            
            // Bungkus ke obstacle node
            let obstacle = SKNode()
            obstacle.name = "letter_\(randomChar)"
            obstacle.addChild(letterNode)
            
            // X = spacing * (i+1)
            let xPos = spacing * CGFloat(i + 1)
            
            obstacle.position = CGPoint(x: xPos, y: yStart)
            
            addChild(obstacle)
            
            // Jalan ke bawah
            let moveDown = SKAction.moveBy(x: 0, y: -size.height - 80, duration: 4.0)
            let remove = SKAction.removeFromParent()
            obstacle.run(SKAction.sequence([moveDown, remove]))
        }
    }
    
    
    
    @objc func handleTap() {
        fireBullet()
    }
    
    func fireBullet() {
        let bullet = SKShapeNode(circleOfRadius: 5)
        bullet.fillColor = .yellow
        bullet.position = CGPoint(x: spaceship.position.x, y: spaceship.position.y + spaceship.size.height / 2 + 10)
        addChild(bullet)
        
        let moveUp = SKAction.moveBy(x: 0, y: size.height, duration: 1.0)
        let remove = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([moveUp, remove]))
    }
}
