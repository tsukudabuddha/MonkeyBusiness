//
//  Spikes.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/27/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

import SpriteKit

class Spikes: SKSpriteNode {
    
    
    init() {
        let texture = SKTexture(imageNamed: "spikes")
        let color = UIColor.clear
        let size = texture.size()
        
        // Call the designated initializer
        super.init(texture: texture, color: color, size: size)
        
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 2
        physicsBody?.categoryBitMask = 1
        physicsBody?.isDynamic = false
        
        position = CGPoint(x: -50, y: -50)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
