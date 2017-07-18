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
    private var dedLabel: SKLabelNode!
    private var restartLabel: SKLabelNode!
    private var round: Int = 1
    private var canJump: Bool = true
    private var jumping: Bool = false
    private var scorpionArray: [Scorpion] = []
    
    private var platform = [Platform(), Platform(), Platform(), Platform(), Platform(), Platform(), Platform(), Platform(), Platform(), Platform(), Platform(), Platform()]
    
    
    
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
        
        createObjects()
        beginningAnimation()
        
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
                
            default:
                break
            }
            
            player.physicsBody?.affectedByGravity = false
            canJump = false
            
        }
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameState == .gameOver { return }

        playerMovement()
        
        for scorpion in scorpionArray {
            scorpion.turnTimer += scorpion.fixedDelta
        }
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
        
        if nodeA.physicsBody?.categoryBitMask == 1 {
            canJump = true
            jumpTimer = 0
        }
        
        if nodeB.physicsBody?.categoryBitMask == 1 {
            canJump = true
            jumpTimer = 0
        }
        
        
        // MARK: Enemy contacts
        if nodeA.name == "player" {
            if nodeB.physicsBody?.contactTestBitMask == 2 {
                if (nodeB as! Scorpion).isAlive {
                    checkScorpion(scorpion: nodeB as! Scorpion)
                }

            }
        }
        if nodeA.physicsBody?.contactTestBitMask == 2 {
            if nodeB.name == "player" {
                if (nodeA as! Scorpion).isAlive {
                    checkScorpion(scorpion: nodeA as! Scorpion)
                }
            }
        }
        
        if nodeB.physicsBody?.contactTestBitMask == 2 {
            if (nodeB as! Scorpion).turnTimer > 0.02 {
                print((nodeB as! Scorpion).turnTimer)
                (nodeB as! Scorpion).turnAround()
                (nodeB as! Scorpion).turnTimer = 0
            }
            
            
        }
        
        if nodeA.physicsBody?.contactTestBitMask == 2 {
            if (nodeA as! Scorpion).turnTimer > 0.02 {
                print((nodeA as! Scorpion).turnTimer)
                (nodeA as! Scorpion).turnAround()
                (nodeA as! Scorpion).turnTimer = 0
            }
            
        }
        
        

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Checks to see if game is running */
        if gameState != .active { return }
        
        player.physicsBody?.affectedByGravity = true
        jumpTimer = 0
    }
    

    // Make a Class method to load levels
    func level() -> GameScene? {
        guard let scene = GameScene(fileNamed: "GameScene") else {
            return nil
        }
        scene.scaleMode = .aspectFit
        return scene
        
    }
    
    func spawnObstacles(orientation: characterOrientationState) {
        switch orientation {
        case .bottom:
            
            /* Position new platforms */
            platform[0].position = CGPoint(x: 235, y: 400)
            platform[1].position = CGPoint(x: 235, y: 300)
            platform[2].position = CGPoint(x: 235, y: 200)
            platform[3].position = CGPoint(x: 235, y: 100)
            
            /* Remove old platforms */
            removePlatforms()
            
            /* Add platform to scene */
            addPlatforms()

        case .top:
            
            /* Remove old platforms */
            removePlatforms()
            
            /* position new platforms */
            platform[6].position = CGPoint(x: 80, y: 500)
            platform[7].position = CGPoint(x: 80, y: 450)
            platform[8].position = CGPoint(x: 80, y: 300)
            platform[9].position = CGPoint(x: 80, y: 150)
            
            /* Add new platforms */
            addPlatforms()
            
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
            
            newRound(round: round)
        }
    }
    
    func beginningAnimation() {
        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
        player.run(SKAction(named: "beginAnimationMonkey")!)
        player.run(SKAction(named: "Run")!)
        roundLabel.run(SKAction(named: "RoundLabel")!)
    }
    
    func createObjects() {
        /* Initialize roundLabel object */
        roundLabel.position = CGPoint(x: (self.frame.width / 2), y: (self.frame.height / 2))
        roundLabel.text = "Round \(round)"
        self.addChild(roundLabel)
    }
  
    func spawnEnemy(round: Int) {
        /* Create array of spawn heights */
        var heightArray = [100,170,240,310,380,450,520]
        var sideArray = [15, 305]
        for _ in 0..<round { /* do something */
            let direction = arc4random_uniform(5)
            let height = arc4random_uniform(UInt32(heightArray.count))
            
            let side = arc4random_uniform(UInt32(2))
            
            let scorpion = Scorpion()
            scorpionArray.append(scorpion)
            print("Scorpion added to the array")
            print(scorpionArray.count)
            addChild(scorpion)
            if side == 0 {
                scorpion.yScale = scorpion.yScale * -1
                scorpion.orientation = .left
            } else if side == 1 {
                scorpion.orientation = .right
            }
            print("scorpion orientation: \(scorpion.orientation)")
            scorpion.run(SKAction(named: "Scorpion")!)
            scorpion.position = CGPoint(x: Int(sideArray[Int(side)]), y: Int(heightArray[Int(height)]))
            scorpion.physicsBody?.velocity.dy = CGFloat(50.0 * (pow(-1.0, Double(direction))))
            
            heightArray.remove(at: Int(height))
            
        }
        
    }
    
    
    /* Checks if player is above scorpion */
    func checkScorpion(scorpion: Scorpion) {
        
        switch player.orientation {
        case .right:
            if player.position.x + 33 < scorpion.position.x {
                scorpion.die()
                
            } else {
                gameOver()
            }
        case .left:
            if player.position.x + 25 > scorpion.position.x {
                scorpion.die()
                
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
    
    func addPlatforms() {
        for n in 0..<platform.count {
            addChild(platform[n])
        }
    }
    
    func removePlatforms() {
        for n in 0..<platform.count {
            platform[n].removeFromParent()
        }
    }
    
    func flipPlatforms() {
        for n in 0..<platform.count / 2 {
            platform[n].xScale = platform[n].xScale * -1
        }
    }
    
    // MARK: Player Auto Run and calls spawnObstacles()
    func playerMovement() {
        /* Called if player is on bottom of screen */
        if player.orientation == .bottom {
            
            player.physicsBody?.velocity.dx = characterSpeed
            
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
                
                roundChecker()
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















