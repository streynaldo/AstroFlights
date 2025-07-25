import SpriteKit

class ShootingManager {
    static let shootSound = SKAction.playSoundFileNamed("shoot.mp3", waitForCompletion: false)

    static func createBullet(position: CGPoint, size: CGSize = CGSize(width: 15, height: 25), zPosition: CGFloat = 9, velocity: CGVector = CGVector(dx: 0, dy: 400),
                            categoryBitMask: UInt32, contactTestBitMask: UInt32, collisionBitMask: UInt32, usesPreciseCollisionDetection: Bool = true) -> SKSpriteNode {
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.size = size
        bullet.position = position
        bullet.name = "bullet"
        bullet.zPosition = zPosition
        bullet.physicsBody = SKPhysicsBody(rectangleOf: size)
        bullet.physicsBody?.categoryBitMask = categoryBitMask
        bullet.physicsBody?.contactTestBitMask = contactTestBitMask
        bullet.physicsBody?.collisionBitMask = collisionBitMask
        bullet.physicsBody?.usesPreciseCollisionDetection = usesPreciseCollisionDetection
        bullet.physicsBody?.velocity = velocity
        bullet.physicsBody?.affectedByGravity = false
        return bullet
    }
}
