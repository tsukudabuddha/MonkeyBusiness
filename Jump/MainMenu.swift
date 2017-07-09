//
//  MainMenu.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/5/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

import SpriteKit

class MainMenu: SKScene {
    var playLabel: SKLabelNode!
    var player: Player!
    
    
    override func didMove(to view: SKView) {
        /* Setup Scene here */
        
        /* Set UI connections */
        playLabel = self.childNode(withName: "playLabel") as! SKLabelNode
        
        }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* We only need a single touch here */
        let touch = touches.first!
        
        /* Get touch position in scene */
        let location = touch.location(in: self)
        
        print("location: \(location)")
        print("playLabel: \(playLabel.position)")
        
        /* Did the user tap on the play button? */
        if location.x < playLabel.position.x + 35 && location.x > playLabel.position.x - 35 && location.y < playLabel.position.y + 20 && location.y > playLabel.position.y  {
            self.loadGame()
        }
        
    
    }
    
    
    
    
        func loadGame() {
            
            /* Grab reference to the SPriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game Scene */
            guard let scene = GameScene(fileNamed: "GameScene") as GameScene! else {
                return
            }
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .aspectFill
            
            /* Restart Game Scene */
            skView?.presentScene(scene)

        }
    
    
}
