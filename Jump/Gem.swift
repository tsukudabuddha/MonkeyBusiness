//
//  Gem.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/24/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

import SpriteKit

class Gem: SKSpriteNode {
    
    var gemValue: Int = 1
    var canSpawn: Bool = true
    
    
    
    init() {
        let texture = SKTexture(imageNamed: "gem-1")
        let color = UIColor.clear
        let size = CGSize(width: 18, height: 16)
        
        // Call the designated initializer
        super.init(texture: texture, color: color, size: size)
        
        run(SKAction(named: "gemIdle")!)
      
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 1
        physicsBody?.categoryBitMask = 1
        physicsBody?.isDynamic = false
        
        position = CGPoint(x: -50, y: -50)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func onContact() {
        physicsBody?.contactTestBitMask = 0
        let collectionAnimation = SKAction(named: "itemCollection")!
        let hide = SKAction.fadeOut(withDuration: 0)
        let seq = SKAction.sequence([collectionAnimation, hide])
        run(seq)
        
        gemValue = 0
        
    }
    
    func reset() {
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 1
        physicsBody?.categoryBitMask = 1
        physicsBody?.isDynamic = false
        run(SKAction.fadeIn(withDuration: 0))
        gemValue = 1
    }
    
}
