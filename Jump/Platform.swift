//
//  Platform.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/6/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

import SpriteKit

class Platform: SKSpriteNode {
    
    init() {
        // Make a texture from an image, a color, and size
        let texture = SKTexture(imageNamed: "platformSmall")
        let color = UIColor.clear
        let size = texture.size()
        
        // Call the designated initializer
        super.init(texture: texture, color: color, size: size)
        
        // Set physics properties
        
        physicsBody = SKPhysicsBody(texture: texture,
                                    size: CGSize(width: texture.size().width,
                                                 height: texture.size().height))
        
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.pinned = true
        physicsBody?.contactTestBitMask = 1
        physicsBody?.friction = 0
        physicsBody?.restitution = 0.5
        
        /* Position the unused platforms off screen */
        position = CGPoint(x: -20, y: -20)
        

    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not yet been implemented")
    }

}
