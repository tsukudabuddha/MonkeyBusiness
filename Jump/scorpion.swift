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
        
        self.run(SKAction(named: "Scorpion")!)
        
        position = CGPoint(x: 305, y: 290)
        run(SKAction(named: "Rotate")!)
        
        self.orientation = .right
        
        
    }
    
    func movement(frameWidth:CGFloat, frameHeight: CGFloat) {
        if self.orientation == .right {
            if self.xScale == -1{
                self.position.y -= 1
            } else if self.xScale == 1 {
                self.position.y += 1
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
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not yet been implemented")
    }
}
