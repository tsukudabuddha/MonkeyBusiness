//
//  Gem.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/24/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

import SpriteKit

class Gem: SKSpriteNode {
    
    
    
    init() {
        let texture = SKTexture(imageNamed: "gem-1")
        let color = UIColor.clear
        let size = texture.size()
        
        // Call the designated initializer
        super.init(texture: texture, color: color, size: size)
        
        run(SKAction(named: "gemIdle")!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
