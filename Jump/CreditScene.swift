//
//  CreditScene.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/8/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

import SpriteKit

class CreditScene: SKScene {
    
    private var returnLabel: SKLabelNode!
    
    
    override func didMove(to view: SKView) {
        /* Setup Scene here */
        
        /* Set UI connections */
        returnLabel = self.childNode(withName: "returnLabel") as! SKLabelNode
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* We only need a single touch here */
        let touch = touches.first!
        
        /* Get touch position in scene */
        let location = touch.location(in: self)
        
        print("location: \(location)")
        print("playLabel: \(returnLabel.position)")
        
        /* Did the user tap on the return label? */
        if location.x < returnLabel.position.x + 35 && location.x > returnLabel.position.x - 35 && location.y < returnLabel.position.y + 20 && location.y > returnLabel.position.y  {
            self.loadMenu()
        }
        
        
        
    }
    
    
    
    
    func loadMenu() {
        
        /* Grab reference to the SPriteKit view */
        let skView = self.view as SKView!
        
        /* Load Game Scene */
        guard let scene = MainMenu(fileNamed: "MainMenu") as MainMenu! else {
            return
        }
        
        /* Ensure correct aspect mode */
        scene.scaleMode = .aspectFill
        
        /* Restart Game Scene */
        skView?.presentScene(scene)
        
    }
    
    
}


