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

enum EnemyType {
    case scorpion, snake, cobra, opossum
}

class Enemy: SKSpriteNode {
    
    var orientation: Orientation = .bottom
    let enemySpeed = CGFloat(1)
    var spawned: Int = 0
    var canContact: Bool = true
    var pointValue: Int = 25
    
    private var collisionNoise: SKAction!
    
    
    var type: EnemyType = .snake {
        didSet {
            switch type {
            case .snake:
                self.texture = SKTexture(imageNamed: "snake-1")
                break
            case .scorpion:
                self.texture = SKTexture(imageNamed: "Scorpion")
                break
            default:
                break
            } 
        }
    }
    
    static var totalSpawned: Int = 0
    static var totalAlive: Int = 0
    static var totalPointValue: Int = 0
    
    var isAlive = true
    
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */
    
    var turnTimer: CFTimeInterval = 0

    init(round: Int) {
        // Make a texture from an image, a color, and size
        var random = arc4random_uniform(UInt32(10))
        var texture = SKTexture()
        switch GameScene.theme {
        case .monkey:
            if round < 3 && random == 0 {
                random = 1
            }
            if random == 0 {
                texture = SKTexture(imageNamed: "king-cobra-2")
                self.pointValue = 50
                type = .cobra
            } else if random > 4{
                texture = SKTexture(imageNamed: "Scorpion")
                type = .scorpion
            } else {
                texture = SKTexture(imageNamed: "snake-1")
                type = .snake
            }
            
        case .fox:
            texture = SKTexture(imageNamed: "opossum-1")
            type = .opossum
        }
        let color = UIColor.clear
        var size = texture.size()
        
        if texture == SKTexture(imageNamed: "king-cobra-2") {
            size = CGSize(width: size.width - 5, height: size.height - 5)
        }
        
        // Call the designated initializer
        super.init(texture: texture, color: color, size: size)
        
        // Set physics properties
       
        physicsBody = SKPhysicsBody(rectangleOf: texture.size())
        
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.contactTestBitMask = 2
        physicsBody?.friction = 0
        physicsBody?.linearDamping = 0
        
        /* Instantiate Pickuo Sound */
        collisionNoise = SKAction.playSoundFileNamed("collisionNoise", waitForCompletion: false)
        
        Enemy.totalSpawned += 1
        Enemy.totalAlive += 1
        
        switch GameScene.theme {
        case .monkey:
            switch type {
            case .cobra:
                self.run(SKAction(named: "cobraMovement")!)
            case .snake:
                self.run(SKAction(named: "snakeMovement")!)
            case .scorpion:
                self.run(SKAction(named: "Scorpion")!)
            default:
                break
            }
        case .fox:
            self.run(SKAction(named: "opposumMovement")!)
        }
        
        Enemy.totalPointValue += pointValue
        
        run(SKAction(named: "Rotate")!)
        
        
    }
    
    func die() {
        // Checks that scorpion has not already run death function
        
        /* Pins animation to death spot then makes it so player cannot touch it */
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.categoryBitMask = 0
        self.physicsBody?.pinned = true
        
        let death = SKAction(named: "enemyDeath")!
        let removeScorpion = SKAction.removeFromParent()
        let seq = SKAction.sequence([death, removeScorpion])
        self.run(seq)
        
        if !MainMenu.isMuted { // If isMuted  = false
            run(collisionNoise)
        }
        
        
        Enemy.totalPointValue -= pointValue
        Enemy.totalAlive -= 1
        self.isAlive = false
    
        
    }
    
    func turnAround() {
        
        self.physicsBody?.velocity.dy = 0
        
        if orientation == .right {
            if self.xScale == -1{
                
                self.xScale = 1
                self.physicsBody?.velocity.dy = 50
                
            } else if xScale == 1  {
                self.xScale = -1
                self.physicsBody?.velocity.dy = -50
            }
        } else if orientation == .left{
            if self.xScale == -1 {
                xScale = 1
                physicsBody?.velocity.dy = -50
                
            } else if xScale == 1 {
                xScale = -1
                physicsBody?.velocity.dy = 50
            }
        }
        
    }
    

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not yet been implemented")
    }
}
