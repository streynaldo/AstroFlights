import SpriteKit

class SpaceshipFactory {
    static func createSpaceship(position: CGPoint, size: CGSize = CGSize(width: 60, height: 70), name: String = "player", zPosition: CGFloat = 10) -> SKSpriteNode {
        let spaceship = SKSpriteNode(imageNamed: "spaceship_idle")
        spaceship.size = size
        spaceship.position = position
        spaceship.name = name
        spaceship.zPosition = zPosition
        
        spaceship.physicsBody = SKPhysicsBody(rectangleOf: size)
        spaceship.physicsBody?.isDynamic = false
        // Category, contact, and collision bitmasks should be set by the caller as needed
        return spaceship
    }
    
    static func setSpaceshipPhysics(_ spaceship: SKSpriteNode, categoryBitMask: UInt32, contactTestBitMask: UInt32, collisionBitMask: UInt32) {
        spaceship.physicsBody?.categoryBitMask = categoryBitMask
        spaceship.physicsBody?.contactTestBitMask = contactTestBitMask
        spaceship.physicsBody?.collisionBitMask = collisionBitMask
    }
}
