//
//  MainMenu.swift
//  MonkeyBusiness
//
//  Created by Andrew Tsukuda on 7/5/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//

import SpriteKit

class MainMenu: SKScene {
    var buttonPlay: MSButtonNode!
    var player: Player!
    
    
    override func didMove(to view: SKView) {
        /* Setup Scene here */
        
        /* Set UI connections */
        buttonPlay = self.childNode(withName: "buttonPlay") as! MSButtonNode
        
        buttonPlay.selectedHandler = {
                self.loadGame()
            }
        }
    
    
        func loadGame() {
            
            //print("Game Should Load")
            
            /* 1) Grab reference to our spriteKit view */
            guard let skView = self.view as SKView! else {
                print("Could not get SkView")
                return
            }
            
            /* 2) Load Game Scene */
            guard let scene = GameScene.level() else {
                print("Could not load GameScene")
                return
            }
            
            /* 3) Ensure correct aspect mode */
            scene.scaleMode = .aspectFit
            
            /* Show Debug */
            //        skView.showsPhysics = true
            //        skView.showsDrawCount = true
            skView.showsFPS = true
            
            /* 4) Start game scene */
            print(scene)
            skView.presentScene(scene)
        }
    
    
}
