//
//  GameScene.swift
//  Jump
//
//  Created by Andrew Tsukuda on 7/3/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

// TODO: Jump on top to kill scorpion
//             -> by using didbegin contact, check location of monkey in relation to scorpion

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
    private var isTouchingGround: Bool = true
    var scorpion: Scorpion = Scorpion()
    
    
    
    // Create Timing Variables
    var spawnTimer: CFTimeInterval = 0
    let spawnTime: Double = 1.25
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */

    var characterSpeed: CGFloat = 2

    let scrollSpeed: CGFloat = 100

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
        physicsWorld.contactDelegate = self
        
        createObjects()
        beginningAnimation()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* Checks to see if game is running */
        if gameState != .active { return }
        
        /* Checks if player is on the ground */
        if isTouchingGround {
            
            if player.orientation == .bottom {
                /* Apply vertical impulse */
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            }
            
            if player.orientation == .right {
                /* Apply vertical impulse */
                player.physicsBody?.applyImpulse(CGVector(dx: -15, dy: 0))
            }
            
            if player.orientation == .top {
                /* Apply vertical impulse */
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -15))
            }
            
            if player.orientation == .left {
                /* Apply vertical impulse */
                player.physicsBody?.applyImpulse(CGVector(dx: 15, dy: 0))
            }
        }
        
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameState == .gameOver { return }
        
        
        playerMovement()
        
        scorpion.movement(frameWidth: self.frame.width, frameHeight: self.frame.height)
        checkSpeed()
        
        
        // Call scrolling function for the game
        spawnObstacles()

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
            if nodeB.name == "ground" {
                self.isTouchingGround = true
            }
        }
        
        if nodeA.name == "ground" {
            if nodeB.name == "player" {
                self.isTouchingGround = true
            }
        }
        
        
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        /* Runs when objects stop being in contact */
        
        /* Get references to the bodies invloved in the collision */
        let contactA: SKPhysicsBody = contact.bodyA
        let contactB: SKPhysicsBody = contact.bodyB
        
        /* Get references to the phyiscs body parent */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if nodeA.name == "player" {
            if nodeB.name == "ground" {
                self.isTouchingGround = false
            }
        }
        
        if nodeA.name == "ground" {
            if nodeB.name == "player" {
                self.isTouchingGround = false
            }
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
    
    
    // MARK: Player Auto Run
    func playerMovement() {
        /* Called if player is on bottom of screen */
        if player.orientation == .bottom {
            player.position.x += characterSpeed
            print(player.position)
            if player.position.x > self.frame.width - 50 {
                
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
            player.position.y += characterSpeed
            print(player.position)
            if player.position.y > self.frame.height - 50 {
                
                /* Change Gravity so top is down */
                self.physicsWorld.gravity.dx = 0
                self.physicsWorld.gravity.dy = 9.8
                
                /* Change player orientation to work with new gravity */
                player.orientation = .top
                player.run(SKAction(named: "Rotate")!)
            }
        }
        
        /* Called if the player is on top of screen */
        if player.orientation == .top {
            player.position.x -= characterSpeed
            print(player.position)
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
            player.position.y -= characterSpeed
            print(player.position)
            if player.position.y < 10 {
                
                /* Change Gravity so bottom is down */
                self.physicsWorld.gravity.dx = 0
                self.physicsWorld.gravity.dy = -9.8
                
                /* Change player orientation to work with new gravity */
                player.orientation = .bottom
                player.run(SKAction(named: "Rotate")!)
            }
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
    
    
    // TODO: Create way to monitor speed
    func checkSpeed() {
        
    }
    func spawnObstacles() {
        

    }
}
