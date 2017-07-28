//
//  Banana.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/28/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

//  TODO: Use bezier path to follow for the throwing

import SpriteKit

class Banana: SKSpriteNode {
    
    var used: Bool = false
    var canSpawn: Bool = true
    
    
    
    init() {
        let texture = SKTexture(imageNamed: "banana")
        let color = UIColor.clear
        let size = texture.size()
        
        // Call the designated initializer
        super.init(texture: texture, color: color, size: size)
        
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 1
        physicsBody?.categoryBitMask = 1
        physicsBody?.isDynamic = false
        physicsBody?.affectedByGravity = false
        
        position = CGPoint(x: -50, y: -50)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func onContact() {
        physicsBody?.contactTestBitMask = 0
        
        
        let currentPosition = self.position
        let bezierPath = UIBezierPath()
        let speed: CGFloat = 100
        bezierPath.move(to: currentPosition)
        
        
        if currentPosition.x < 160 { // Left side of screen
            if currentPosition.y < 284 { // Bottom Left quadrant
                bezierPath.addLine(to: CGPoint(x: 10, y: 10))
                bezierPath.addLine(to: CGPoint(x: 10, y: 550))
                bezierPath.addLine(to: CGPoint(x: 310, y: 550))
                bezierPath.addLine(to: CGPoint(x: 310, y: 10))
                bezierPath.addLine(to: CGPoint(x: 10, y: 10))
                run(SKAction.follow(bezierPath.cgPath, speed: speed))
            } else { // Top Left
                bezierPath.addLine(to: CGPoint(x: 10, y: 550))
                bezierPath.addLine(to: CGPoint(x: 310, y: 550))
                bezierPath.addLine(to: CGPoint(x: 310, y: 10))
                bezierPath.addLine(to: CGPoint(x: 10, y: 10))
                bezierPath.addLine(to: CGPoint(x: 10, y: 550))
                run(SKAction.follow(bezierPath.cgPath, speed: speed))
            }
        } else {
            if currentPosition.y < 284 { // Bottom Right quadrant
                bezierPath.addLine(to: CGPoint(x: 310, y: 550))
                bezierPath.addLine(to: CGPoint(x: 310, y: 10))
                bezierPath.addLine(to: CGPoint(x: 10, y: 10))
                bezierPath.addLine(to: CGPoint(x: 10, y: 550))
                bezierPath.addLine(to: CGPoint(x: 310, y: 550))
                run(SKAction.follow(bezierPath.cgPath, speed: speed))
                
            } else { // Top Right
                bezierPath.addLine(to: CGPoint(x: 310, y: 10))
                bezierPath.addLine(to: CGPoint(x: 10, y: 10))
                bezierPath.addLine(to: CGPoint(x: 10, y: 550))
                bezierPath.addLine(to: CGPoint(x: 310, y: 550))
                bezierPath.addLine(to: CGPoint(x: 310, y: 10))
                run(SKAction.follow(bezierPath.cgPath, speed: speed))
            }
        }
        
        
        used = true
        
    }
    
    func reset() {
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 1
        physicsBody?.categoryBitMask = 1
        physicsBody?.isDynamic = false
        run(SKAction.fadeIn(withDuration: 0))
        used = false
    }
    
}

