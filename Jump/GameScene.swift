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

enum Theme {
    case monkey, fox
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Declare GameScene objects
    
    private var player: Player!
    private var roundLabel: SKLabelNode! = SKLabelNode()
    private var dedLabel: SKLabelNode!
    private var restartLabel: SKLabelNode!
    private var round: Int = 1
    private var canJump: Bool = true
    private var jumping: Bool = false
    private var scorpionArray: [Scorpion] = []
    
    private var leftPlatforms = [Platform(), Platform(), Platform(), Platform(), Platform(), Platform()]
    private var rightPlatforms = [Platform(), Platform(), Platform(), Platform(), Platform(), Platform()]
    
    
    static var theme: Theme = .monkey // static so it can be modified from Main Menu
    
    
    // Create Timing Variables
    var jumpTimer: CFTimeInterval = 0
    let jumpTime: Double = 0.25
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */

    var characterSpeed: CGFloat = 150

    private var gameState: GameSceneState = .active
    private var characterOrientation: characterOrientationState = .bottom
    
    override func didMove(to view: SKView) {
        // Connect variables to code
        player = childNode(withName: "//player") as! Player
        dedLabel = childNode(withName: "dedLabel") as! SKLabelNode
        restartLabel = childNode(withName: "restartLabel") as! SKLabelNode
        
        /* Set Labels to be hidden */
        restartLabel.isHidden = true
        dedLabel.isHidden = true
        
        // Create Physics Body for frame
        setupPhysicsBody()
        
        /* Make all the platforms */
        setupGame()
        flipPlatforms()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        
        /* Checks to see if game is running */
        if gameState != .active {
            
            /* We only need a single touch here */
            let touch = touches.first!
            
            /* Get touch position in scene */
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
            
            /* Did the user tap on the restart label? */
            if(touchedNode.name == "restartLabel"){
                restartGame()
            }
            
        }
        
        /* Checks if player is on the ground */
        if canJump && jumpTimer <= jumpTime {
            
            switch player.orientation {
            case .bottom:
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 12.5))
            case .right:
                player.physicsBody?.applyImpulse(CGVector(dx: -12.5, dy: 0))
            case .top:
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -12.5))
            case .left:
                player.physicsBody?.applyImpulse(CGVector(dx: 12.5, dy: 0))
                
            }
            
            player.physicsBody?.affectedByGravity = false
            canJump = false
            
        }
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameState == .gameOver { return }

        playerMovement()
        
        if !canJump {
            /* Update jump timer */
            jumpTimer += fixedDelta
        }
    
        if jumpTimer > jumpTime{
            player.physicsBody?.affectedByGravity = true
            jumpTimer = 0
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
        
        if nodeA.name == "player" || nodeB.name == "player"{
            canJump = true
            jumpTimer = 0
        }
        
        // MARK: Enemy Contact Functions
        if nodeB.physicsBody?.contactTestBitMask == 2 {
            if nodeA.name == "player" {
                if (nodeB as! Scorpion).isAlive {
                    checkScorpion(scorpion: nodeB as! Scorpion)
                }
            } else {
                (nodeB as! Scorpion).turnAround()
                print("Turn Around")
            }
        }
        
        if nodeA.physicsBody?.contactTestBitMask == 2 {
            if nodeB.name == "player" {
                if (nodeA as! Scorpion).isAlive {
                    checkScorpion(scorpion: nodeA as! Scorpion)
                }
            } else {
                (nodeA as! Scorpion).turnAround()
                print("Turn Around")
            }
        }
        

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Checks to see if game is running */
        if gameState != .active { return }
        
        player.physicsBody?.affectedByGravity = true
        jumpTimer = 0
    }
    
    func spawnObstacles(orientation: characterOrientationState) {
        switch orientation {
        case .bottom:
            
            /* Position new platforms */
            positionPlatforms(side: .left)
            /* Remove old platforms */
            removePlatforms(side: .right)
            
            /* Add platform to scene */
            addPlatforms(side: .left)

        case .top:
            
            /* Remove old platforms */
            removePlatforms(side: .left)
            
            /* position new platforms */
            positionPlatforms(side: .right)
            
            /* Add new platforms */
            addPlatforms(side: .right)
            
        default:
            break

        }
    }
    
    func roundChecker() {
        
        if Scorpion.totalAlive == 0 {
            round += 1
            roundLabel.text = "Round \(round)"
            roundLabel.run(SKAction(named: "RoundLabel")!)
            
            newRound(round: round)
        }
    }
    
    func setupGame() {
        
        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
        
        switch GameScene.theme {
        case .fox:
            player.size = CGSize(width: 28, height: 30)
            player.run(SKAction(named: "characterRun")!)
            break
        case .monkey:
            player.run(SKAction(named: "Run")!)
        }
        
        /* Initialize roundLabel object */
        roundLabel.position = CGPoint(x: (self.frame.width / 2), y: (self.frame.height / 2))
        roundLabel.text = "Round \(round)"
        self.addChild(roundLabel)
        
        roundLabel.run(SKAction(named: "RoundLabel")!)
    }
  
    func spawnEnemy(round: Int) {
        /* Create array of spawn heights */
        var heightArray = [100,170,240,310,380,450,520]
        var sideArray = [15, 305]
        for _ in 0..<round { /* do something */
            let height = arc4random_uniform(UInt32(heightArray.count))
            
            let side = arc4random_uniform(UInt32(2))
            
            let scorpion = Scorpion()
            scorpionArray.append(scorpion)
            addChild(scorpion)
            if side == 0 {
                scorpion.zRotation = CGFloat(Double.pi) // Marshall Cain Suggestion, fixed scropions
                scorpion.orientation = .left
                scorpion.physicsBody?.velocity.dy = CGFloat(50.0 * scorpion.xScale * -1)
            } else if side == 1 {
                scorpion.orientation = .right
                scorpion.physicsBody?.velocity.dy = CGFloat(50.0 * scorpion.xScale)
            }
            scorpion.position = CGPoint(x: Int(sideArray[Int(side)]), y: Int(heightArray[Int(height)]))
            
            
            heightArray.remove(at: Int(height))
            
        }
        
    }
    
    
    /* Checks if player is above scorpion */
    func checkScorpion(scorpion: Scorpion) {
        
        switch player.orientation {
        case .right:
            if player.position.x + 33 < scorpion.position.x {
                scorpion.die()
                player.physicsBody?.applyImpulse(CGVector(dx: -10, dy: 0))
                
            } else {
                gameOver()
            }
        case .left:
            if player.position.x + 25 > scorpion.position.x {
                scorpion.die()
                player.physicsBody?.applyImpulse(CGVector(dx: 10, dy: 0))
                
            } else {
                gameOver()
            }
        default:
            break
        }
    }
    
    func newRound(round: Int) {
        spawnEnemy(round: round)
        
    }
    
    func gameOver() {
        /* Set gamestate to gameOver */
        gameState = .gameOver
        player.death()
        dedLabel.text = "You made it to Round \(round)"
        dedLabel.isHidden = false
        restartLabel.isHidden = false
    }
    
    func restartGame() {
        /* Grab reference to the SPriteKit view */
        let skView = self.view as SKView!
        
        /* Load Game Scene */
        guard let scene = GameScene(fileNamed: "GameScene") as GameScene! else {
            return
        }
        
        /* Reset outside variables */
        Scorpion.totalSpawned = 0
        Scorpion.totalAlive = 0
        
        /* Ensure correct aspect mode */
        scene.scaleMode = .aspectFill
        
        /* Restart Game Scene */
        skView?.presentScene(scene)
    }
    
    func addPlatforms(side: Orientation) {
        switch side {
        case .right:
            
            for platform in rightPlatforms {
                addChild(platform)
            }
            break
            
        case .left:
            for platform in leftPlatforms {
                addChild(platform)
            }
        default:
            break
        }
    }
    
    func removePlatforms(side: Orientation) {
        
        switch side {
        case .right:
            
            for platform in rightPlatforms {
            platform.removeFromParent()
            }
            break
            
        case .left:
            for platform in leftPlatforms {
            platform.removeFromParent()
            }
        default:
            break
        }
        
    }
    
    func flipPlatforms() {
        for platform in rightPlatforms {
            platform.flip()
        }
    }
    
    func positionPlatforms(side: Orientation) {
        let formation = arc4random_uniform(UInt32(2))
        
        let x1 = 70
        let x2 = x1 * 2
        let width = Int(frame.width)
        
        let y1 = 120
        let y2 = y1 + 90
        let y3 = y2 + 90
        let y4 = y3 + 90
        let y5 = y4 + 90
        
        let oppositeX1 = width - x1
        let oppositeX2 = width - x2
        
        switch side {
        case .right:
            switch formation {
            case 0:
                rightPlatforms[0].position = CGPoint(x: x1, y: y1)
                rightPlatforms[1].position = CGPoint(x: x1, y: y2)
                rightPlatforms[2].position = CGPoint(x: x1, y: y3)
                rightPlatforms[3].position = CGPoint(x: x1, y: y4)
                rightPlatforms[4].position = CGPoint(x: x1, y: y5)
                break
            case 1:
                rightPlatforms[0].position = CGPoint(x: x1, y: y1)
                rightPlatforms[1].position = CGPoint(x: x2, y: y2)
                rightPlatforms[2].position = CGPoint(x: x1, y: y3)
                rightPlatforms[3].position = CGPoint(x: x2, y: y4)
                rightPlatforms[4].position = CGPoint(x: x1, y: y5)
                break
            default:
                break
            }
            break
        case .left:
            switch formation {
            case 0:
                leftPlatforms[0].position = CGPoint(x: oppositeX1, y: y1)
                leftPlatforms[1].position = CGPoint(x: oppositeX1, y: y2)
                leftPlatforms[2].position = CGPoint(x: oppositeX1, y: y3)
                leftPlatforms[3].position = CGPoint(x: oppositeX1, y: y4)
                leftPlatforms[4].position = CGPoint(x: oppositeX1, y: y5)
                break
            case 1:
                leftPlatforms[0].position = CGPoint(x: oppositeX1, y: y1)
                leftPlatforms[1].position = CGPoint(x: oppositeX2, y: y2)
                leftPlatforms[2].position = CGPoint(x: oppositeX1, y: y3)
                leftPlatforms[3].position = CGPoint(x: oppositeX2, y: y4)
                leftPlatforms[4].position = CGPoint(x: oppositeX1, y: y5)
                break
            default:
                break

        }

        default:
            break
        }
    }
    
    // MARK: Player Auto Run and calls spawnObstacles()
    func playerMovement() {
        
        switch player.orientation {
        case .bottom:
            player.physicsBody?.velocity.dx = characterSpeed
            
            if player.position.x > self.frame.width * 0.6 { // MARK: Changed from -60
                
                /* Change Gravity so right is down */
                self.physicsWorld.gravity.dx = 9.8
                self.physicsWorld.gravity.dy = 0
                
                /* Change player orientation to work with new gravity */
                player.orientation = .right
                player.run(SKAction(named: "Rotate")!)
                
            }
        case .right:
            player.physicsBody?.velocity.dy = characterSpeed
            
            if player.position.y > self.frame.height - 46 { // 46 is from math it good dont worry
                
                /* Change Gravity so top is down */
                self.physicsWorld.gravity.dx = 0
                self.physicsWorld.gravity.dy = 9.8
                
                /* Change player orientation to work with new gravity */
                player.orientation = .top
                player.run(SKAction(named: "Rotate")!)
                
                roundChecker()
                spawnObstacles(orientation: player.orientation)
                
            }
        case .top:
            player.physicsBody?.velocity.dx = -1 * characterSpeed
            //print(player.position)
            if player.position.x < frame.width * 0.4 { // MARK: Changed from 0
                
                /* Change Gravity so left is down */
                self.physicsWorld.gravity.dx = -9.8
                self.physicsWorld.gravity.dy = 0
                
                /* Change player orientation to work with new gravity */
                player.orientation = .left
                player.run(SKAction(named: "Rotate")!)
            }
        case .left:
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
    func setupPhysicsBody() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        physicsBody?.categoryBitMask = 2
        physicsBody?.contactTestBitMask = 4294967295
        physicsBody?.collisionBitMask = 1
        physicsBody?.restitution = 0.15
        physicsBody?.friction = 0
        physicsWorld.contactDelegate = self
    }


}







