//
//  MainMenu.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/5/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

import SpriteKit
import Firebase
import FirebaseDatabase

class MainMenu: SKScene, SKPhysicsContactDelegate {
    private var playLabel: SKLabelNode!
    private var creditLabel: SKLabelNode!
    private var themeLabel: SKLabelNode!
    private var businessLabel: SKLabelNode!
    private var gemLabel: SKLabelNode!
    private var leaderBoardLabel: SKLabelNode!
    var gameScene: GameScene!
    var player: Player!
    var characterSpeed = GameScene(fileNamed: "GameScene")?.characterSpeed
    
    static var viewController: GameViewController!
    static var character: Bool = false
    var gems: Int = UserDefaults.standard.integer(forKey: "gemCount")
    
    override func didMove(to view: SKView) {
        /* Set UI connections */
        playLabel = self.childNode(withName: "playLabel") as! SKLabelNode
        creditLabel = self.childNode(withName: "creditLabel") as! SKLabelNode
        themeLabel = childNode(withName: "themeLabel") as! SKLabelNode
        gemLabel = childNode(withName: "gemLabel") as! SKLabelNode
        leaderBoardLabel = childNode(withName: "leaderBoardLabel") as! SKLabelNode
        businessLabel = childNode(withName: "\"business\"Label") as! SKLabelNode
        gameScene = GameScene(fileNamed: "GameScene")!
        
        // Connect variables to code
        player = childNode(withName: "//player") as! Player
        
        // Create Physics Body for frame
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        // Gems
        gemLabel.text = "\(gems)"
        
        physicsWorld.contactDelegate = self
        beginningAnimation()
        
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        /* Called if player is on bottom of screen */
        if player.orientation == .bottom {
            player.physicsBody?.velocity.dx = characterSpeed!
        
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
            player.physicsBody?.velocity.dy = characterSpeed!
            
            if player.position.y > self.frame.height - 70 {
                
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
            player.physicsBody?.velocity.dx = -1 * characterSpeed!
            
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
            player.physicsBody?.velocity.dy = -1 * characterSpeed!
           
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
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* We only need a single touch here */
        let touch = touches.first!
        
        /* Get touch position in scene */
        let location = touch.location(in: self)
        let touchedNode = self.atPoint(location)
        
        if(touchedNode.name == "creditLabel"){
            self.loadCredits()
            
        } else if(touchedNode.name == "playLabel"){
            self.loadGame()
            
        } else if(touchedNode == themeLabel){
            if GameScene.theme == .monkey {
                GameScene.theme = .fox
                themeLabel.text = "Foxy"
            } else {
                GameScene.theme = .monkey
                themeLabel.text = "Monkey"
            }
        } else if touchedNode == leaderBoardLabel {
            MainMenu.viewController.checkGCLeaderboard()
        } else if touchedNode == businessLabel {
            /* 1) Grab reference to our spriteKit view */
            guard let skView = self.view as SKView! else {
                print("Could not get SkView")
                return
            }
            skView.showsPhysics = !(skView.showsPhysics)
        }
        
    
    }
    
    func loadGame() {
        /* Load Game Scene */
        guard let scene = GameScene(fileNamed: "GameScene") as GameScene! else {
            return
        }
        
        /* Ensure correct aspect mode */
        scene.scaleMode = .aspectFill
        
        /* Restart Game Scene */
        let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.5)
        view?.presentScene(scene, transition: transition)
        
    }
    
    func loadCredits() {
        /* Load Game Scene */
        guard let scene = CreditScene(fileNamed: "CreditScene") as CreditScene! else {
            return
        }
        
        /* Ensure correct aspect mode */
        scene.scaleMode = .aspectFill
        
        /* Restart Game Scene */
        let doorsOpen = SKTransition.doorsOpenHorizontal(withDuration: 0.5)
        view?.presentScene(scene, transition: doorsOpen)
        
    }
    
    func beginningAnimation() {
        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
        player.run(SKAction(named: "beginAnimationMonkey")!)
        player.run(SKAction(named: "Run")!)
    }
    
    
}
