//
//  GameScene.swift
//  Jump
//
//  Created by Andrew Tsukuda on 7/3/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//  MARK: The scene in relation to player position is 0 - 287
//  TODO: Add more platform orientations
//  TODO: Add spikes 
//  TODO: Powerup that auto shoots
//  TOOD: Make gems exist for a reason
//  TODO: Make character physicsbody rectangle so that it no longer gets stuck on platforms
//  TODO: Fix the game playing behind pause screen when returning froma another app

import SpriteKit
import GameplayKit
import Firebase
import FirebaseDatabase

enum GameSceneState {
    case active, gameOver, paused, reversed
}

enum Theme {
    case monkey, fox
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Declare GameScene objects
    
    private var player: Player!
    private var roundLabel: SKLabelNode! = SKLabelNode()
    private var pointsLabel: SKLabelNode! = SKLabelNode()
    private var dedLabel: SKLabelNode!
    private var highScoreLabel: SKLabelNode!
    private var restartLabel: SKLabelNode!
    private var menuLabel: SKLabelNode!
    private var gameOverScreen: SKSpriteNode!
    private var instructionOverlay: SKSpriteNode!
    private var pauseScreen: SKSpriteNode!
    private var playPauseButton: SKSpriteNode!
    private var pauseScoreLabel: SKLabelNode!
    private var timerBar: SKSpriteNode!
    private var slidingBarTop: SKSpriteNode!
    private var slidingBarBottom: SKSpriteNode!
    private var round: Int = 0
    private var canJump: Bool = true
    private var jumping: Bool = false
    private var enemyArray: [Enemy] = []
    private var points: Int = 0
    private var gem = Gem()
    private var cherry = Cherry()
    var sessionGemCounter: Int = 0 // Public so that it can be changed by the gem.onContact()
    
    private var leftPlatforms = [Platform(), Platform(), Platform(), Platform(), Platform()]
    private var rightPlatforms = [Platform(), Platform(), Platform(), Platform(), Platform()]
    
    
    static var theme: Theme = .monkey // Static so it can be modified from Main Menu
    let generator = UINotificationFeedbackGenerator()
    
    
    // Create Timing Variables
    var jumpTimer: CFTimeInterval = 0
    var powerUpTimer: CFTimeInterval = 0
    let powerUpTime: Double = 10
    let jumpTime: Double = 0.25
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */

    
    var health: CGFloat = 1.0 {
        didSet {
            
            /* Set upper limit on bar */
            if health > 1 { health = 1}
            /* Scale health bar between 0.0 -> 1.0 e.g 0 -> 100% */
            timerBar.xScale = health
            
        }
    }
    
    var characterSpeed: CGFloat = 150

    private var gameState: GameSceneState = .paused {
        didSet {
            switch gameState {
            case .active:
                isPaused = false
                slidingBarBottom.position.x = 291
                slidingBarTop.position.x = 29
                player.xScale = 1
                break
            case .paused:
                isPaused = true
                break
            case .reversed:
                slidingBarBottom.position.x = 29
                slidingBarTop.position.x = 291
                player.xScale = -1
                break
            case .gameOver:
                gameOver()
            }
        }
    }
    private var characterOrientation: characterOrientationState = .bottom
    
    var viewController: GameViewController!
    
    override func didMove(to view: SKView) {
        // Connect variables to code
        player = childNode(withName: "//player") as! Player
        dedLabel = childNode(withName: "//dedLabel") as! SKLabelNode
        restartLabel = childNode(withName: "//restartLabel") as! SKLabelNode
        menuLabel = childNode(withName: "//menuLabel") as! SKLabelNode
        highScoreLabel = childNode(withName: "//highScoreLabel") as! SKLabelNode
        gameOverScreen = childNode(withName: "gameOverScreen") as! SKSpriteNode
        instructionOverlay = childNode(withName: "startingOverlay") as! SKSpriteNode
        playPauseButton = childNode(withName: "playPauseButton") as! SKSpriteNode
        pauseScreen = childNode(withName: "pauseScreen") as! SKSpriteNode
        pauseScoreLabel = childNode(withName: "//pauseScoreLabel") as! SKLabelNode
        timerBar = childNode(withName: "timerBar") as! SKSpriteNode
        slidingBarTop = childNode(withName: "slidingWallTop") as! SKSpriteNode
        slidingBarBottom = childNode(withName: "slidingWallBottom") as! SKSpriteNode
        
        /* Set Labels to be hidden */
        restartLabel.isHidden = true
        dedLabel.isHidden = true
        menuLabel.isHidden = true
        highScoreLabel.isHidden = true
        
        // Create Physics Body for frame
        setupPhysicsBody()
        
        /* Make all the platforms */
        setupGame()
        flipPlatforms()
        
        dedLabel.text = "Your Score: \(points)"
        dedLabel.isHidden = false
        restartLabel.isHidden = false
        menuLabel.isHidden = false
        highScoreLabel.isHidden = false
        pointsLabel.isHidden = true
        
        /* Use UserDefaults to see if we should show the instruction screen */
//        let showScreen = UserDefaults.standard.bool(forKey: "showScreen")
//
//        if showScreen {
//            instructionOverlay.run(SKAction.moveTo(x: 0, duration: 0))
//            gameState = .paused
//        }
        /* Adds collectible items to gameScene */
        addChild(gem)
        addChild(cherry)
        
        /* This helps reduce the vibration lag when the player dies */
        generator.prepare()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* We only need a single touch here */
        let touch = touches.first!
        
        /* Get touch position in scene */
        let location = touch.location(in: self)
        let touchedNode = self.atPoint(location)
        
        /* Did the user tap on the restart label? */
        if(touchedNode.name == "restartLabel"){
            restartGame()
        } else if touchedNode.name == "menuLabel" {
            loadMenu()
        } else if touchedNode == playPauseButton {
            if gameState == .active {
                gameState = .paused
                playPauseButton.texture = SKTexture(imageNamed: "play")
                pauseScreen.position.x = 0
                pauseScoreLabel.text = "Your Score: \(points)"
                pointsLabel.isHidden = true
            } else if gameState == .paused {
                gameState = .active
                playPauseButton.texture = SKTexture(imageNamed: "pause")
                pauseScreen.run(SKAction.moveTo(x: 320, duration: 0.25))
                pointsLabel.isHidden = false
            }
        } else if touchedNode == instructionOverlay {
            gameState = .active
            instructionOverlay.run(SKAction.fadeOut(withDuration: 0.25))
        }
            
       
        
        /* Checks if player is on the ground */
        if canJump && jumpTimer <= jumpTime {
            /* Switch statement to determine where the player is so that it can apply the correct impulse */
            switch player.orientation {
            case .bottom:
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 12))
            case .right:
                player.physicsBody?.applyImpulse(CGVector(dx: -12, dy: 0))
            case .top:
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -12))
            case .left:
                player.physicsBody?.applyImpulse(CGVector(dx: 12, dy: 0))
                
            }
            
            player.physicsBody?.affectedByGravity = false
            canJump = false
            
        }
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameState == .gameOver || gameState == .paused { return }

        playerMovement()
        
        /* Checks to see if the player is on the ground, if not, the jump timer starts */
        if !canJump {
            /* Update jump timer */
            jumpTimer += fixedDelta
        }
        
        /* Only countdown death timer when there are still enemies alive */
        if Enemy.totalAlive > 0 {
            health -= 0.001 // MARK: Tweak speed of rounds
        }
        
        
        if health <= 0 {
            gameState = .gameOver
        }
        
        /* Once the jumpTimer is complete, the player falls to the ground and the timer is reset */
        if jumpTimer > jumpTime{
            player.physicsBody?.affectedByGravity = true
            jumpTimer = 0
        }
        
        /* This checks to see if the player is in SSJ or not */
        if player.state == .superSaiyajin {
            /* Check to see if the player just went SSJ, if so run the animation */
            if powerUpTimer == 0 {
                player.run(SKAction(named: "powerUpRun")!)
            }
            /* Update SSJ timer */
            powerUpTimer += fixedDelta
            
            /* Reset player state and visual to match */
            if powerUpTimer >= powerUpTime {
                player.state = .normal
                player.run(SKAction(named: "Run")!)
            }
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

        
        /* Check that player has landed on ground or platform */
        if nodeA.name == "player" && nodeB.physicsBody?.contactTestBitMask != 3 {
            canJump = true
            jumpTimer = 0
        } else if nodeB.name == "player" && nodeA.physicsBody?.contactTestBitMask != 3 {
            canJump = true
            jumpTimer = 0
        }
        
        // MARK: Enemy Contact Functions
        if nodeB.physicsBody?.contactTestBitMask == 2 {
            
            if nodeA.name == "player" {
                if (nodeB as! Enemy).isAlive {
                    if (nodeA as! Player).state == .normal {
                        checkScorpion(scorpion: (nodeB as! Enemy), contactPoint: contact.contactPoint)
                    } else if (nodeA as! Player).state == .superSaiyajin {
                        (nodeB as! Enemy).die()
                        health += CGFloat(0.1 + 0.05 * Double((nodeB as! Enemy).pointValue))
                        points += (nodeB as! Enemy).pointValue
                        pointsLabel.text = String(points)
                    }
                    
                }
            } else {
                (nodeB as! Enemy).turnAround()
            }
        }
        
        if nodeA.physicsBody?.contactTestBitMask == 2 {
            if nodeB.name == "player" {
                if (nodeA as! Enemy).isAlive {
                    if (nodeB as! Player).state == .normal {
                        checkScorpion(scorpion: (nodeA as! Enemy), contactPoint: contact.contactPoint)
                    } else if (nodeB as! Player).state == .superSaiyajin {
                        (nodeA as! Enemy).die()
                        health += CGFloat(0.1 + 0.05 * Double((nodeA as! Enemy).pointValue))
                        points += (nodeA as! Enemy).pointValue
                        pointsLabel.text = String(points)
                    }
                    
                }
            } else {
                (nodeA as! Enemy).turnAround()
            }
        }
        
        
        /* Checks if either contact is a gem */
        if nodeA == gem || nodeB == gem {
            if gem.gemValue == 1 {
                gem.onContact()
                sessionGemCounter += 1
            }
            
        }
        
        /* Checks if either contact is a cherry */
        if nodeA == cherry || nodeB == cherry {
            if !cherry.used {
                cherry.onContact()
                player.state = .superSaiyajin
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Checks to see if game is running */
        if gameState == .gameOver || gameState == .paused { return }
        
        /* The player is now affected by gravity again and the timer is reset */
        player.physicsBody?.affectedByGravity = true
        jumpTimer = 0
    }
    
    func spawnObstacles(orientation: characterOrientationState) {
        var fixedOrientation = orientation
        
        removePlatforms(side: .left)
        removePlatforms(side: .right)
        
        if gameState == .reversed {
            
            if fixedOrientation == .bottom {
                fixedOrientation = .top
            } else {
                fixedOrientation = .bottom
            }
        }
        switch fixedOrientation {
        case .bottom:
            
            /* Position new platforms */
            positionPlatforms(side: .right)
            /* Remove old platforms */
            removePlatforms(side: .left)
            
            /* Add platform to scene */
            addPlatforms(side: .right)

        case .top:
            
            /* Remove old platforms */
            removePlatforms(side: .right)
            
            /* Position new platforms */
            positionPlatforms(side: .left)
            
            /* Add new platforms */
            addPlatforms(side: .left)
            
        default:
            break

        }
    }
    
    func roundChecker() {
        /* Runs at every corner */
        
        /* Once all the enemies are cleared, the next round begins and more enemies spawn */
        if Enemy.totalAlive == 0 {
            round += 1
            roundLabel.text = "Round \(round)"
            roundLabel.run(SKAction(named: "RoundLabel")!)
            
            newRound(round: round)
        }
        
        let color = SKAction.colorize(with: UIColor.purple, colorBlendFactor: 1.0, duration: 0.25)
        let uncolor = SKAction.colorize(with: self.backgroundColor, colorBlendFactor: 1.0, duration: 0.25)
        let seq = SKAction.sequence([color, uncolor])
        
        /* The game will run in reverse if the round is a multiple of 5 */
        if round % 5 == 0 {
            if gameState == .active {
                run(seq)
            }
            gameState = .reversed

        } else if (round - 1) % 5 == 0 {
            if gameState == .reversed {
                run(seq)
            }
            gameState = .active
        } else {
            gameState = .active
        }
    }
    
    // MARK: Setup Game
    func setupGame() {
        /* Called in the didMove function */
        
        /* Sets the game to load active gamestate, because it is set to paused originally for pause menu stuffs */
        gameState = .active
        print("bottom thing: \(slidingBarBottom.position.x)")
        
        /* Makes the player "Jump" to begin the game */
        player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
        
        /* Switch statement to show different themes */
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
        roundLabel.text = "Defeat All the Enemies!!!"
        roundLabel.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.5), SKAction.fadeOut(withDuration: 0.5)]))
        roundLabel.zPosition = 5
        self.addChild(roundLabel)
        
        /* Setup Points Label */
        pointsLabel.position = CGPoint(x: (self.frame.width / 2), y: (self.frame.height / 2) + 20)
        self.addChild(pointsLabel)
        
        /* This is a fadeIn and fadeOut animation */
        roundLabel.run(SKAction(named: "RoundLabel")!)
    }
  
    func spawnEnemy(round: Int) {
        /* Create arrays of different spawn locations */
        var heightArray = [100,200,300,400,480]
        var sideArray = [15, 305]
        
        var count = round + 1 // The round begins at 1 and we want 2 enemies to spawn in that round
        
        if round >= 5 { // Don't want to get an indexOutOfBounds exception
            count = 5
        }
        
        for _ in 0..<count {
            /* This for loop is what spawns an enemy */
            
            /* Create the random numbers to pick heght and side */
            let height = arc4random_uniform(UInt32(heightArray.count))
            var side = arc4random_uniform(UInt32(2))
            
            /* Spawns enemies on otherside of game as player */
            if ((round - 1) % 5 == 0) && round > 0 {
                if player.orientation == .bottom {
                    side = 0
                } else {
                    side = 1
                }
                
            } else if round % 5 == 0 && round > 0 {
                if player.orientation == .top {
                    side = 0
                } else {
                    side = 1
                }
            }
            
            
            /* Create an enemy object and add it to the scene and enemy array */
            let scorpion = Enemy()
            enemyArray.append(scorpion) // MARK: Remove enemyArray
            addChild(scorpion)
            
            /* Check to see which side the enemy is on, then rotate and set velcoity accordingly */
            if side == 0 {
                scorpion.zRotation = CGFloat(Double.pi) // Marshall Cain Suggestion, fixed scropions
                scorpion.orientation = .left
                scorpion.physicsBody?.velocity.dy = CGFloat(50.0 * scorpion.xScale * -1)
            } else if side == 1 {
                scorpion.orientation = .right
                scorpion.physicsBody?.velocity.dy = CGFloat(50.0 * scorpion.xScale)
            }
            /* Move the scorpion to the randomly chosen spawn point */
            scorpion.position = CGPoint(x: Int(sideArray[Int(side)]), y: Int(heightArray[Int(height)]))
            
            /* Prevent scorpios from being spawned at the same spots */
            heightArray.remove(at: Int(height))
        }
        
        
    }
    
    
    /* Checks if player is above scorpion */
    func checkScorpion(scorpion: Enemy, contactPoint: CGPoint) {
        
        switch scorpion.orientation {
        case .right:
            if contactPoint.x - 10 < scorpion.position.x - (scorpion.size.height / 2) {
                scorpion.isAlive = false
                scorpion.die()
                player.physicsBody?.velocity = CGVector.zero
                player.physicsBody?.applyImpulse(CGVector(dx: -10, dy: 0))
                points += scorpion.pointValue
                pointsLabel.text = String(points)
                health += CGFloat(0.005 * Double(scorpion.pointValue))
                
            } else {
                gameOver()
            }
        case .left:
            if contactPoint.x + 12 > scorpion.position.x + (scorpion.size.height / 2) {
                scorpion.isAlive = false
                scorpion.die()
                player.physicsBody?.velocity = CGVector.zero
                player.physicsBody?.applyImpulse(CGVector(dx: 10, dy: 0))
                points += scorpion.pointValue
                pointsLabel.text = String(points)
                health += CGFloat(0.005 * Double(scorpion.pointValue))
                
            } else {
                gameOver()
            }
        default:
            break
        }
    }
    
    func newRound(round: Int) {
        
        /* Spawn new enemies*/
        spawnEnemy(round: round)
        
        /* Reset gem contact and stuffs */
        gem.reset()
        gem.canSpawn = true
        
        /* Reset Health */
        health = 1
        
        
    }
    
    func gameOver() {
        /* Set gamestate to gameOver and run player death animation */
        player.death()
        gameOverScreen.run(SKAction.moveTo(y: 0, duration: 0.5))
        
        dedLabel.text = "Your Score: \(points)"
        dedLabel.isHidden = false
        restartLabel.isHidden = false
        menuLabel.isHidden = false
        highScoreLabel.isHidden = false
        pointsLabel.isHidden = true
        
        /* Use UserDefaults to save the high score to the user's device */
        let oldHigh = UserDefaults.standard.integer(forKey: "highScore")
        highScoreLabel.text = "High Score: \(oldHigh)"
        if oldHigh < points {
            UserDefaults.standard.set(points, forKey: "highScore")
            highScoreLabel.text = "High Score: \(points)"
        }
        
        /* Submit high score to Game Center leaderboard */
        MainMenu.viewController.addScoreAndSubmitToGC(score: Int64(points))
        
        /* Remove all scorpions from scene */
        for scorpion in enemyArray {
            scorpion.die()
        }
        
        /* Haptic Feeback */
        
        generator.notificationOccurred(.success)
        
    }
    
    func restartGame() {
        /* Grab reference to the SPriteKit view */
        let skView = self.view as SKView!
        
        /* Load Game Scene */
        guard let scene = GameScene(fileNamed: "GameScene") as GameScene! else {
            return
        }
        
        /* Reset outside variables */
        Enemy.totalSpawned = 0
        Enemy.totalAlive = 0
        
        /* Ensure correct aspect mode */
        scene.scaleMode = .aspectFill
        
        let moveTo = SKAction.moveTo(y: 568, duration: 0.5)
        let wait = SKAction.wait(forDuration: 0.1)
        let seq = SKAction.sequence([moveTo, wait])
        
        gameOverScreen.run(seq)
        
        /* Restart Game Scene */
        skView?.presentScene(scene)
    }
    
    func loadMenu() {
        /* Grab reference to the SPriteKit view */
        let skView = self.view as SKView!
        
        /* Load Game Scene */
        guard let scene = MainMenu(fileNamed: "MainMenu") as MainMenu! else {
            return
        }
        
        /* Reset outside variables */
        Enemy.totalSpawned = 0
        Enemy.totalAlive = 0
        
        /* Ensure correct aspect mode */
        scene.scaleMode = .aspectFill
        
        let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.5)
        /* Restart Game Scene */
        skView?.presentScene(scene, transition: transition)
    }
    
    

    func addPlatforms(side: Orientation) {
        /* Add platforms on the specified side to the gameScene */
        
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
        /* Remove platforms on the specified side from the gameScene */
        
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
        /* This rotates the left platforms so that they appear in the correct orientation */
        for platform in leftPlatforms {
            platform.flip()
        }
    }
    
    func positionPlatforms(side: Orientation) {
        
        /* Create a random number variable to choose the formation of platforms */
        let formation = arc4random_uniform(UInt32(3)) // there are 3 formations
        
        /* Set Variables */
        let x1 = 80.0
        let x2 = x1 * 1.5
        let x3 = x2 * 1.5
        let width = Double(frame.width)
        
        let y1 = 100.0
        let y2 = y1 + 95.0
        let y3 = y2 + 95.0
        let y4 = y3 + 95.0
        let y5 = y4 + 95.0
        
        let oppositeX1 = width - x1
        let oppositeX2 = width - x2
        let oppositeX3 = width - x3
        
        /* Rotate collectibles to match screen side */
        if side == .right {
            gem.zRotation = CGFloat(Double.pi * 0.5)
            cherry.zRotation = CGFloat(Double.pi * 0.5)
        } else {
            gem.zRotation = CGFloat(Double.pi * 1.5)
            cherry.zRotation = CGFloat(Double.pi * 1.5)
        }
        
        /* Random numbers to choose spawn rate and location of collectibles */
        var gemSpawn = arc4random_uniform(5)
        let cherrySpawn = arc4random_uniform(30)
        
        /* Makes sure that the cherries and gems don't spawn on top of each other */
        if cherrySpawn == gemSpawn {
            gemSpawn = arc4random_uniform(5)
        }
        
        switch side {
        case .right:
            switch formation {
            case 0:
                leftPlatforms[0].position = CGPoint(x: x1, y: y1)
                leftPlatforms[1].position = CGPoint(x: x1, y: y2)
                leftPlatforms[2].position = CGPoint(x: x1, y: y3)
                leftPlatforms[3].position = CGPoint(x: x1, y: y4)
                leftPlatforms[4].position = CGPoint(x: x1, y: y5)
                break
            case 1:
                leftPlatforms[0].position = CGPoint(x: x1, y: y1)
                leftPlatforms[1].position = CGPoint(x: x2, y: y2)
                leftPlatforms[2].position = CGPoint(x: x1, y: y3)
                leftPlatforms[3].position = CGPoint(x: x2, y: y4)
                leftPlatforms[4].position = CGPoint(x: x1, y: y5)
                break
            case 2:
                leftPlatforms[0].position = CGPoint(x: x3, y: y1)
                leftPlatforms[1].position = CGPoint(x: x3, y: y2)
                leftPlatforms[2].position = CGPoint(x: x3, y: y3)
                leftPlatforms[3].position = CGPoint(x: x2, y: y4)
                leftPlatforms[4].position = CGPoint(x: x1, y: y5)
                break
            default:
                print("default ran")
            }
            
        case .left:
            switch formation {
            case 0:
                rightPlatforms[0].position = CGPoint(x: oppositeX1, y: y1)
                rightPlatforms[1].position = CGPoint(x: oppositeX1, y: y2)
                rightPlatforms[2].position = CGPoint(x: oppositeX1, y: y3)
                rightPlatforms[3].position = CGPoint(x: oppositeX1, y: y4)
                rightPlatforms[4].position = CGPoint(x: oppositeX1, y: y5)
                break
            case 1:
                rightPlatforms[0].position = CGPoint(x: oppositeX1, y: y1)
                rightPlatforms[1].position = CGPoint(x: oppositeX2, y: y2)
                rightPlatforms[2].position = CGPoint(x: oppositeX1, y: y3)
                rightPlatforms[3].position = CGPoint(x: oppositeX2, y: y4)
                rightPlatforms[4].position = CGPoint(x: oppositeX1, y: y5)
                break
            case 2:
                rightPlatforms[0].position = CGPoint(x: oppositeX1, y: y1)
                rightPlatforms[1].position = CGPoint(x: oppositeX2, y: y2)
                rightPlatforms[2].position = CGPoint(x: oppositeX3, y: y3)
                rightPlatforms[3].position = CGPoint(x: oppositeX3, y: y4)
                rightPlatforms[4].position = CGPoint(x: oppositeX3, y: y5)
                break
            default:
                print("default ran")
            }

        default:
            break
        }
        
        /* First check to see if the gem can spawn */
        if gem.canSpawn {
            
            /* Use the randomly generated gemSpawn number to choose a platform to spawn above */
            switch gemSpawn {
            case 0:
                gem.position = gemPositioner(random: 0, side: side)
                break
            case 1:
                gem.position = gemPositioner(random: 1, side: side)
                break
            case 2:
                gem.position = gemPositioner(random: 2, side: side)
                break
            case 3:
                gem.position = gemPositioner(random: 3, side: side)
                break
            case 4:
                gem.position = gemPositioner(random: 4, side: side)
                
            default:
                gem.position = CGPoint(x: -50, y: -50)
                
            }
            /* Mark that the gem has already been spawned */
            gem.canSpawn = false
            
        } else {
            /* If the gem has already been spawned, then set it off-screen */
            gem.position = CGPoint(x: -50, y: -50)
        }
    
       /* Use the randomly generated cherrySpawn number to choose a platform to spawn above */
        switch cherrySpawn {
        case 0:
            cherry.position = gemPositioner(random: 0, side: side)
            break
        case 1:
            cherry.position = gemPositioner(random: 1, side: side)
            break
        case 2:
            cherry.position = gemPositioner(random: 2, side: side)
            break
        case 3:
            cherry.position = gemPositioner(random: 3, side: side)
            break
        case 4:
            cherry.position = gemPositioner(random: 4, side: side)
        /* If the randomly chosen number is not 0-4, which should happen often, the cherry is positioned off-screen */
        default:
            cherry.position = CGPoint(x: -50, y: -50)
            
        }
        
    }
    
    // MARK: Player Auto Run and calls spawnObstacles()
    func playerMovement() {
        if gameState == .active {
            switch player.orientation {
            case .bottom:
                player.physicsBody?.velocity.dx = characterSpeed
                
                if player.position.x > 287 * 0.5 {
                    
                    /* Change Gravity so right is down */
                    self.physicsWorld.gravity.dx = 9.8
                    self.physicsWorld.gravity.dy = 0
                    
                    /* Change player orientation to work with new gravity */
                    player.orientation = .right
                    player.run(SKAction(named: "Rotate")!)
                    
                }
            case .right:
                /* Make it so the player falls down and hits ground before moving forward */
                if player.position.x > 285 {
                    player.physicsBody?.velocity.dy = characterSpeed
                } else if player.position.y > 40 {
                    player.physicsBody?.velocity.dy = characterSpeed
                }
                
                
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
                if player.position.x < 287 * 0.5 {
                    
                    /* Change Gravity so left is down */
                    self.physicsWorld.gravity.dx = -9.8
                    self.physicsWorld.gravity.dy = 0
                    
                    /* Change player orientation to work with new gravity */
                    player.orientation = .left
                    player.run(SKAction(named: "Rotate")!)
                }
            case .left:
                /* Make it so the player falls down and hits ground before moving forward */
                if player.position.x < 5 {
                    player.physicsBody?.velocity.dy = -1 * characterSpeed
                } else if player.position.y < 515 { // MARK: Get height and change
                    player.physicsBody?.velocity.dy = -1 * characterSpeed
                }
                
                
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

        } else if gameState == .reversed {
            switch player.orientation {
            case .bottom:
                player.physicsBody?.velocity.dx = characterSpeed * -1
                
                if player.position.x < 287/2 * 0.5 {
                    
                    /* Change Gravity so left is down */
                    self.physicsWorld.gravity.dx = -9.8
                    self.physicsWorld.gravity.dy = 0
                    
                    /* Change player orientation to work with new gravity */
                    player.orientation = .left
                    player.run(SKAction(named: "FlipRotate")!)
                    
                }
            case .left:
                /* Make it so the player falls down and hits ground before moving forward */
                if player.position.x < 5 {
                    player.physicsBody?.velocity.dy = characterSpeed
                } else if player.position.y > 58 {
                    player.physicsBody?.velocity.dy = characterSpeed
                }
                player.physicsBody?.velocity.dy = characterSpeed
                
                if player.position.y > self.frame.height - 46 { // 46 is from math it good dont worry
                    
                    /* Change Gravity so top is down */
                    self.physicsWorld.gravity.dx = 0
                    self.physicsWorld.gravity.dy = 9.8
                    
                    /* Change player orientation to work with new gravity */
                    player.orientation = .top
                    player.run(SKAction(named: "FlipRotate")!)
                    
                    roundChecker()
                    spawnObstacles(orientation: player.orientation)
                    
                }
            case .top:
                player.physicsBody?.velocity.dx = characterSpeed
        
                if player.position.x > 287 * 0.5 {
                    
                    /* Change Gravity so right is down */
                    self.physicsWorld.gravity.dx = 9.8
                    self.physicsWorld.gravity.dy = 0
                    
                    /* Change player orientation to work with new gravity */
                    player.orientation = .right
                    player.run(SKAction(named: "FlipRotate")!)
                }
            case .right:
                /* Make it so the player falls down and hits ground before moving forward */
                if player.position.x > 285 {
                    player.physicsBody?.velocity.dy = -1 * characterSpeed
                } else if player.position.y < 515 { // MARK: Get height and change
                    player.physicsBody?.velocity.dy = -1 * characterSpeed
                }
                
                if player.position.y < 10 {
                    
                    /* Change Gravity so bottom is down */
                    self.physicsWorld.gravity.dx = 0
                    self.physicsWorld.gravity.dy = -9.8
                    
                    /* Change player orientation to work with new gravity */
                    player.orientation = .bottom
                    player.run(SKAction(named: "FlipRotate")!)
                    
                    spawnObstacles(orientation: player.orientation)
                    roundChecker()
                    
                }
            }

        }
        
        
    }
    
    func setupPhysicsBody() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        physicsBody?.categoryBitMask = 2
        physicsBody?.contactTestBitMask = 4294967295
        physicsBody?.collisionBitMask = 4294967295
        physicsBody?.restitution = 0.15
        physicsBody?.friction = 0
        physicsWorld.contactDelegate = self
    }
    
    func gemPositioner(random: Int, side: Orientation) -> CGPoint {
        /* This returns a CGPoint that is meant to be positioned directly above a platform that has spawned */
        var returnPoint = CGPoint()
        
        if side == .left {
            returnPoint = CGPoint(x: leftPlatforms[random].position.x + 27, y: leftPlatforms[random].position.y)
        } else if side == .right {
            returnPoint = CGPoint(x: rightPlatforms[random].position.x - 27, y: rightPlatforms[random].position.y)
        }
        
        return returnPoint
    }


}







