//
//  GameScene.swift
//  Jump
//
//  Created by Andrew Tsukuda on 7/3/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

import SpriteKit
import GameplayKit

enum GameSceneState {
    case active, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Declare GameScene objects
    
    private var player: Player!
    private var roundLabel: SKLabelNode! = SKLabelNode()
    private var round: Int = 1
    private var canJump: Bool = true
    private var jumping: Bool = false
    var scorpion: Scorpion = Scorpion()
    
    var platform1 : Platform! = Platform()
    var platform2 : Platform! = Platform()
    var platform3 : Platform! = Platform()
    var platform4 : Platform! = Platform()
    
    
    
    // Create Timing Variables
    var jumpTimer: CFTimeInterval = 0
    let jumpTime: Double = 0.2
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */

    var characterSpeed: CGFloat = 150

    private var gameState: GameSceneState = .active
    private var characterOrientation: characterOrientationState = .bottom
    
    override func didMove(to view: SKView) {
        // Connect variables to code
        player = childNode(withName: "//player") as! Player
        
        self.addChild(scorpion)
        // Create Physics Body for frame
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody?.categoryBitMask = 2
        self.physicsBody?.contactTestBitMask = 4294967295
        self.physicsBody?.collisionBitMask = 1
        self.physicsBody?.restitution = 0.2
        physicsWorld.contactDelegate = self
        
        createObjects()
        beginningAnimation()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        
        /* Checks to see if game is running */
        if gameState != .active { return }
        
        /* Checks if player is on the ground */
        if canJump && jumpTimer <= jumpTime {
            
            if player.orientation == .bottom {
                /* Apply vertical impulse */
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 12.5))
            }
            
            if player.orientation == .right {
                /* Apply vertical impulse */
                player.physicsBody?.applyImpulse(CGVector(dx: -12.5, dy: 0))
            }
            
            if player.orientation == .top {
                /* Apply vertical impulse */
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -12.5))
            }
            
            if player.orientation == .left {
                /* Apply vertical impulse */
                player.physicsBody?.applyImpulse(CGVector(dx: 12.5, dy: 0))
            }
            player.physicsBody?.affectedByGravity = false
            
        }
        
        jumping = true
        
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameState == .gameOver { return }
        
        
        playerMovement()
        
        scorpion.movement(frameWidth: self.frame.width, frameHeight: self.frame.height)
        
        if jumping {
            /* Update spawn touch timer */
            jumpTimer += fixedDelta
        }
        
        if jumpTimer > jumpTime{
            player.physicsBody?.affectedByGravity = true
            jumping = false
            
        }

    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        /* Physics contact delegate implementation */
        /* Get references to the bodies invloved in the collision */
        let contactA: SKPhysicsBody = contact.bodyA
        let contactB: SKPhysicsBody = contact.bodyB
        
        /* Get references to the phyiscs body parent SKSpriteNode */
        let nodeA = contactA.node! //as! SKSpriteNode
        let nodeB = contactB.node!//as! SKSpriteNode
        
        if nodeA.name == "player" {
            self.canJump = true
        }
        
        if nodeB.name == "player" {
            self.canJump = true
        }
        
        
        // TODO: Create player touching scorpion death or kill
        if nodeA.name == "player" {
            if nodeB.physicsBody?.contactTestBitMask == 2 {
                checkScorpion(scorpion: nodeB as! Scorpion)
            }
        }
        
        if nodeA.physicsBody?.contactTestBitMask == 2 {
            if nodeB.name == "player" {
                checkScorpion(scorpion: nodeA as! Scorpion)
            }
        }

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Checks to see if game is running */
        if gameState != .active { return }
        
        player.physicsBody?.affectedByGravity = true
        jumping = false
        jumpTimer = 0
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        /* Runs when objects stop being in contact */
        
        /* Get references to the bodies invloved in the collision */
        let contactA: SKPhysicsBody = contact.bodyA
        let contactB: SKPhysicsBody = contact.bodyB
        
        /* Get references to the phyiscs body parent */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if nodeA.name == "player" && (nodeB.name == "ground" || nodeB.name == "") {
            self.canJump = false
        }
        
        if nodeB.name == "player" && (nodeA.name == "ground" || nodeA.name == "") {
            self.canJump = false
        }

    }

    
    // Make a Class method to load levels
    class func level() -> GameScene? {
        guard let scene = GameScene(fileNamed: "GameScene") else {
            return nil
        }
        scene.scaleMode = .aspectFit
        return scene
        
    }
    
    
    // MARK: Player Auto Run and calls spawnObstacles()
    func playerMovement() {
        /* Called if player is on bottom of screen */
        if player.orientation == .bottom {
            
            player.physicsBody?.velocity.dx = characterSpeed
            //print(player.position)
            if player.position.x > self.frame.width - 60 {
                
                /* Change Gravity so right is down */
                self.physicsWorld.gravity.dx = 9.8
                self.physicsWorld.gravity.dy = 0
                
                /* Change player orientation to work with new gravity */
                player.orientation = .right
                player.run(SKAction(named: "Rotate")!)
                
            }
        }
        
        /* Called if the player is on right-side of screen */
        if player.orientation == .right {
            
            player.physicsBody?.velocity.dy = characterSpeed
            //print(player.position)
            if player.position.y > self.frame.height - 50 {
                
                /* Change Gravity so top is down */
                self.physicsWorld.gravity.dx = 0
                self.physicsWorld.gravity.dy = 9.8
                
                /* Change player orientation to work with new gravity */
                player.orientation = .top
                player.run(SKAction(named: "Rotate")!)
                
                spawnObstacles(orientation: player.orientation)
                
            }
            
        }
        
        /* Called if the player is on top of screen */
        if player.orientation == .top {
            
            player.physicsBody?.velocity.dx = -1 * characterSpeed
            //print(player.position)
            if player.position.x < 0 {
                
                /* Change Gravity so left is down */
                self.physicsWorld.gravity.dx = -9.8
                self.physicsWorld.gravity.dy = 0
                
                /* Change player orientation to work with new gravity */
                player.orientation = .left
                player.run(SKAction(named: "Rotate")!)
            }
            
        }
        
        /* Called if the player is on left-side of screen */
        if player.orientation == .left {
            
            player.physicsBody?.velocity.dy = -1 * characterSpeed
            //print(player.position)
            if player.position.y < 10 {
                
                /* Change Gravity so bottom is down */
                self.physicsWorld.gravity.dx = 0
                self.physicsWorld.gravity.dy = -9.8
                
                /* Change player orientation to work with new gravity */
                player.orientation = .bottom
                player.run(SKAction(named: "Rotate")!)
                
                spawnObstacles(orientation: player.orientation)
                roundChecker()
                
           }
        }

    }
    
    func spawnObstacles(orientation: characterOrientationState) {
        switch orientation {
        case .bottom:
            /* Remove old platforms */
            platform1.removeFromParent()
            platform2.removeFromParent()
            platform3.removeFromParent()
            platform4.removeFromParent()
            
            /* Position new platforms */
            platform1.position = CGPoint(x: 275, y: 400)
            platform2.position = CGPoint(x: 275, y: 300)
            platform3.position = CGPoint(x: 275, y: 200)
            platform4.position = CGPoint(x: 275, y: 100)
            
            /* Flip platforms */
            platform1.xScale = platform1.xScale * -1
            platform2.xScale = platform2.xScale * -1
            platform3.xScale = platform3.xScale * -1
            platform4.xScale = platform4.xScale * -1
            
            /* Add platform to scene */
            self.addChild(platform1)
            self.addChild(platform2)
            self.addChild(platform3)
            self.addChild(platform4)

        case .top:
            
            /* Remove old platforms */
            platform1.removeFromParent()
            platform2.removeFromParent()
            platform3.removeFromParent()
            platform4.removeFromParent()
            
            /* position new platforms */
            platform1.position = CGPoint(x: 45, y: 500)
            platform2.position = CGPoint(x: 45, y: 450)
            platform3.position = CGPoint(x: 45, y: 300)
            platform4.position = CGPoint(x: 45, y: 150)
            
            /* Flip platforms */
            platform1.xScale = platform1.xScale * -1
            platform2.xScale = platform2.xScale * -1
            platform3.xScale = platform3.xScale * -1
            platform4.xScale = platform4.xScale * -1
            
            /* Add new platforms */
            self.addChild(platform1)
            self.addChild(platform2)
            self.addChild(platform3)
            self.addChild(platform4)
            
        default:
            break

        }
    }
    
    func roundChecker() {
        print("Scorpions alive: \(Scorpion.totalAlive)")
        if Scorpion.totalAlive == 0 {
            round += 1
            roundLabel.text = "Round \(round)"
            roundLabel.run(SKAction(named: "RoundLabel")!)
            
            
        }
    }
    
    func beginningAnimation() {
        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
        player.run(SKAction(named: "beginAnimationMonkey")!)
        player.run(SKAction(named: "Run")!)
        roundLabel.run(SKAction(named: "RoundLabel")!)
        scorpion.run(SKAction(named: "Scorpion")!)
    }
    
    func createObjects() {
        /* Initialize roundLabel object */
        roundLabel.position = CGPoint(x: (self.frame.width / 2), y: (self.frame.height / 2))
        roundLabel.text = "Round \(round)"
        self.addChild(roundLabel)
    }
    
    func spawnEnemy() {
        /* Create scorpion object */
        let scorpion = Scorpion()
        scorpion.movement(frameWidth: self.frame.width, frameHeight: self.frame.height)
        
    }
    
    
    // TODO: check scorpion relation to player
    func checkScorpion(scorpion: Scorpion) {
        
        switch player.orientation {
        case .right:
            if player.position.x + 33 < scorpion.position.x {
                scorpion.die()
                
                /* Player jumps off enemy */
                player.physicsBody?.applyImpulse(CGVector(dx: -1, dy: 0))
                
            } else {
                gameOver()
            }
        case .left:
            if player.position.x - 10 > scorpion.position.x {
                scorpion.die()
                
                /* Player jumps off enemy */
                player.physicsBody?.applyImpulse(CGVector(dx: 1, dy: 0))
            } else {
                gameOver()
            }
        default:
            break
        }
    }
    
    func gameOver() {
        /* Set gamestate to gameOver */
        gameState = .gameOver
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        player.removeAllActions()
        player.run(SKAction.colorize(with: UIColor.red, colorBlendFactor: 1.0, duration: 0.50))
    }
    
    
    

}















