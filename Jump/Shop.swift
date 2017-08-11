//
//  Shop.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 8/10/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//


import SpriteKit
import Firebase
import AVFoundation

class Shop: SKScene, SKPhysicsContactDelegate {
    
    private var playLabel: SKLabelNode!
    private var gemLabel: SKLabelNode!

    private var labelArray: [SKLabelNode]! = []
    private var gameStartSound: SKAction!

    var gameScene: GameScene!
    var player: Player!
    private var playerImage: SKSpriteNode!
    var characterSpeed: CGFloat = 150
    
    static var viewController: GameViewController!
    static var character: Bool = false
    var gems: Int = UserDefaults.standard.integer(forKey: "gemCount")
    
    override func didMove(to view: SKView) {
        /* Set UI connections */
        playLabel = self.childNode(withName: "playLabel") as! SKLabelNode
        gemLabel = childNode(withName: "gemLabel") as! SKLabelNode
        gameScene = GameScene(fileNamed: "GameScene")!
        
        /* Create label array to make edits to all of them */
        labelArray.append(playLabel)
        
        /* Audio */
        //        if let musicURL = Bundle.main.url(forResource: "menuBackgroundMusic", withExtension: "mp3") {
        //            backgroundMusic = SKAudioNode(url: musicURL)
        //            addChild(backgroundMusic)
        //        }
        
        // Connect variables to code
        player = childNode(withName: "//player") as! Player
        playerImage = childNode(withName: "//playerImage") as! SKSpriteNode
        
        // Create Physics Body for frame
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        // Gems
        gemLabel.text = "\(gems)"
        
        /* Instantiate Game Audio */
        gameStartSound = SKAction.playSoundFileNamed("gameStart", waitForCompletion: false)
        
        physicsWorld.contactDelegate = self
        
        playerImage.run(SKAction(named: "beginAnimationMonkey")!)
        playerImage.run(SKAction(named: "Run")!)
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* We only need a single touch here */
        let touch = touches.first!
        
        /* Get touch position in scene */
        let location = touch.location(in: self)
        let touchedNode = self.atPoint(location)
        
        /* This if let makes sure label is only of type SKLabelNode */
        if let label = touchedNode as? SKLabelNode {
            if labelArray.contains(label) {
                label.fontColor = UIColor.gray
            }
        } else { // If the touchedNode is not a label node this runs
            for label in labelArray {
                label.fontColor = UIColor.white
            }
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* We only need a single touch here */
        let touch = touches.first!
        
        /* Get touch position in scene */
        let location = touch.location(in: self)
        let touchedNode = self.atPoint(location)
        
        /* This if let makes sure label is only of type SKLabelNode */
        if let label = touchedNode as? SKLabelNode {
            if labelArray.contains(label) {
                label.fontColor = UIColor.gray
            }
        } else { // If the touchedNode is not a label node this runs
            for label in labelArray {
                label.fontColor = UIColor.white
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        
        let touchedNode = self.atPoint(location)
        
        if touchedNode.name == "playLabel" {
            self.loadGame()
        }
        
        for label in labelArray {
            label.fontColor = UIColor.white
        }
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        /* Called if player is on bottom of screen */
        if player.orientation == .bottom {
            player.physicsBody?.velocity.dx = characterSpeed
            
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
            player.physicsBody?.velocity.dy = characterSpeed
            
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
            player.physicsBody?.velocity.dx = -1 * characterSpeed
            
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
    
    
    func loadGame() {
        /* Play gameStart audio */
        run(gameStartSound)
        
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
    
}
