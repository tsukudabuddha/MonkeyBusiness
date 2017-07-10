//
//  scorpion.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/6/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//




import SpriteKit

enum Orientation {
    case bottom, right, top, left
}

class Scorpion: SKSpriteNode {
    
    var orientation: Orientation = .right
    let enemySpeed = CGFloat(1)
    var spawned: Int = 0
    static var totalSpawned: Int = 0
    static var totalAlive: Int = 0
    var isAlive = true
    
    init() {
        // Make a texture from an image, a color, and size
        let texture = SKTexture(imageNamed: "Scorpion")
        let color = UIColor.clear
        let size = texture.size()
        
        // Call the designated initializer
        super.init(texture: texture, color: color, size: size)
        
        // Set physics properties
        
        physicsBody = SKPhysicsBody(texture: texture,
                                    size: CGSize(width: 50,
                                                 height: 50))
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.contactTestBitMask = 2
        physicsBody?.friction = 0
        physicsBody?.linearDamping = 0
        
        Scorpion.totalSpawned += 1
        Scorpion.totalAlive += 1
        
        
        self.run(SKAction(named: "Scorpion")!)
        
        run(SKAction(named: "Rotate")!)
        
        self.orientation = .right
        
        
    }
    
    func movement(frameWidth:CGFloat, frameHeight: CGFloat) {
        if self.orientation == .right {
            if self.xScale == -1{
                self.physicsBody?.velocity.dy = -50
            } else if self.xScale == 1 {
                self.physicsBody?.velocity.dy = 50
            }
            
            /* When scorpion runs into wall it turns around */
            if self.position.y < 20 {
                self.xScale = 1
            }
            
            if self.position.y > frameHeight - 20 {
                self.xScale = -1
            }
            
        }

    }
    
    func die() {
        // Checks that scorpion has not already run death function
        
        if self.isAlive {
            
            let death = SKAction(named: "Death")!
            let removeScorpion = SKAction.removeFromParent()
            let seq = SKAction.sequence([death, removeScorpion])
            self.run(seq)
            
            /* Load partcile effect */
            let particles = SKEmitterNode(fileNamed: "deathEmitter")!
            
            /* Position particles on scorpion */
            particles.position = self.position
            
            /* Add particles to the scene */
            self.parent?.addChild(particles)
            let wait = SKAction.wait(forDuration: 1)
            let removeParticles = SKAction.removeFromParent()
            let particleSeq = SKAction.sequence([wait, removeParticles])
            particles.run(particleSeq)
            
            Scorpion.totalAlive -= 1
            self.isAlive = false
        }
        
        
        
        
    }
    // TODO: Fix
    func turnAround() {
        
        if self.xScale == -1{
            if yScale == 1{
                self.xScale = xScale * -1
                self.physicsBody?.velocity.dy = 50
            } else {
                self.xScale = xScale * -1
                self.physicsBody?.velocity.dy = -50
            }
            
        } else if xScale == 1  {
            if yScale == -1 {
                self.xScale = -1 * xScale
                self.physicsBody?.velocity.dy = -50
            } else {
                self.xScale = xScale * -1
                self.physicsBody?.velocity.dy = 50
            }
            
        }
    }
    

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not yet been implemented")
    }
}
