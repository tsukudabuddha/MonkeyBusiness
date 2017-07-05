//
//  MainMenu.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/5/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

import SpriteKit

class MainMenu: SKScene {
    private var buttonPlay: MSButtonNode!
    var GameScene: GameScene!
    
    
    override func didMove(to view: SKView) {
        /* Setup Scene here */
        
        /* Set UI connections */
        buttonPlay = self.childNode(withName: "buttonPlay") as! MSButtonNode
        
        buttonPlay.selectedHandler = {
            /* Load Game scene */
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene?.scaleMode = .aspectFill
            
            /* Character Animation */
            scene.beginningAnimation()
            scene.buttonPlay.isHidden = true
            
            /* Change gamestate */
            scene.gameState = .active

        }
    }
}
