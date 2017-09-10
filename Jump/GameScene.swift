//
//  GameScene.swift
//  Jump
//
//  Created by Andrew Tsukuda on 7/3/17.
//  Copyright © 2017 Andrew Tsukuda. All rights reserved.
//  MARK: The scene in relation to player position is 0 - 287


/* To-Do List */

// TODO: Add more platform orientations
// TODO: Add spikes
// TODO: Powerup that auto shoots
// TOOD: Make gems exist for a reason
// TODO: Add more enemies
// TODO: Dress up monkey
// TODO: Fix background music turn on with toggle
// TODO: Add in chain counter/ more points
// TODO: Add label informing player that if the player missees, they will have multiple chances with last one

// TODO: Fix Round 5 bug

import SpriteKit
import GameplayKit
import Firebase
import AVFoundation

enum GameSceneState {
    case active, gameOver, paused, reversed
}

enum Theme {
    case monkey, fox
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Declare GameScene objects
    
    /* Sprite Nodes */
    private var player: Player!
    private var playerImage: SKSpriteNode!
    private var gameOverScreen: SKSpriteNode!
    private var pauseScreen: SKSpriteNode!
    private var playPauseButton: SKSpriteNode!
    private var pauseScoreLabel: SKLabelNode!
    private var timerBar: SKSpriteNode!
    private var slidingBarTop: SKSpriteNode!
    private var slidingBarBottom: SKSpriteNode!
    private var musicToggle: SKSpriteNode!
    
    /* Labels */
    private var roundLabel: SKLabelNode! = SKLabelNode()
    private var pointsLabel: SKLabelNode! = SKLabelNode()
    private var dedLabel: SKLabelNode!
    private var highScoreLabel: SKLabelNode!
    private var restartLabel: SKLabelNode!
    private var menuLabel: SKLabelNode!
    private var resumeLabel: SKLabelNode!
    private var deathLabel: SKLabelNode!
    
    /* Etc */
    private var gem = Gem()
    private var cherry = Cherry()
    private var backgroundMusic: SKAudioNode!
    private var powerUpMusic: SKAudioNode!
    private var gameOverNoise: SKAction!
    
    /* Create Arrays */
    private var leftPlatforms = [Platform(), Platform(), Platform(), Platform()]
    private var rightPlatforms = [Platform(), Platform(), Platform(), Platform()]
    private var enemyArray: [Enemy] = []
    
    /* Create Variables */
    private var round: Int = 0
    private var canJump: Bool = true
    private var jumping: Bool = false
    private var characterOrientation: characterOrientationState = .bottom
    private var points: Int = 0
    private var chain: Int = 0
    private var reversed = false
    var characterSpeed: CGFloat = 150
    var viewController: GameViewController!
    var sessionGemCounter: Int = 0 // Public so that it can be changed by the gem.onContact()
    static var theme: Theme = .monkey // Static so it can be modified from Main Menu
    let generator = UINotificationFeedbackGenerator() // Used to generate haptic feeback
    
    
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
            
//            /* "Flash" when low health */
//            if health <  0.33 {
//                let fadeOut = SKAction.fadeOut(withDuration: 0.05)
//                let fadeIn = SKAction.fadeIn(withDuration: 0.05)
//                let seq = SKAction.sequence([fadeOut, fadeIn])
//                player.run(seq)
//            } else {
//                player.alpha = 1
//            }
            
            // TODO: Change opacity then wait then change back
            
            
        }
    }
    
    var gameState: GameSceneState = .active {
        didSet {
            switch gameState {
            case .active:
                isPaused = false
                player.xScale = 1
                break
            case .paused:
                isPaused = true
                break
            case .reversed:
                player.xScale = -1
                break
            case .gameOver:
                gameOver()
            }
        }
    }
    
    /* stayPaused and isPaused handle pausing when game is re-opened - stayPaused in App Delegate */
    static var stayPaused = false as Bool
    
    override var isPaused: Bool {
        get {
            return super.isPaused
        }
        set {
            if (newValue || !GameScene.stayPaused) {
                super.isPaused = newValue
            }
            GameScene.stayPaused = false
            
        }
    }
    
    /* This function runs when the scene is loaded */
    override func didMove(to view: SKView) {
        // Connect variables to code
        player = childNode(withName: "//player") as! Player
        playerImage = childNode(withName: "//playerImage") as! SKSpriteNode
        dedLabel = childNode(withName: "//dedLabel") as! SKLabelNode
        deathLabel = childNode(withName: "//deathLabel") as! SKLabelNode
        restartLabel = childNode(withName: "//restartLabel") as! SKLabelNode
        menuLabel = childNode(withName: "//menuLabel") as! SKLabelNode
        highScoreLabel = childNode(withName: "//highScoreLabel") as! SKLabelNode
        gameOverScreen = childNode(withName: "gameOverScreen") as! SKSpriteNode
        playPauseButton = childNode(withName: "playPauseButton") as! SKSpriteNode
        pauseScreen = childNode(withName: "pauseScreen") as! SKSpriteNode
        pauseScoreLabel = childNode(withName: "//pauseScoreLabel") as! SKLabelNode
        timerBar = childNode(withName: "timerBar") as! SKSpriteNode
        slidingBarTop = childNode(withName: "slidingWallTop") as! SKSpriteNode
        slidingBarBottom = childNode(withName: "slidingWallBottom") as! SKSpriteNode
        resumeLabel = pauseScreen.childNode(withName: "resumeLabel") as! SKLabelNode
        musicToggle = childNode(withName: "//musicToggle") as! SKSpriteNode
        
        /* Audio */
        if let musicURL = Bundle.main.url(forResource: "PimPoyPocket", withExtension: "wav") {
            backgroundMusic = SKAudioNode(url: musicURL)
            play(node: backgroundMusic)
        }
        
        if let musicURL = Bundle.main.url(forResource: "powerUpMusic", withExtension: "wav") {
            powerUpMusic = SKAudioNode(url: musicURL)
        }
        
        /* Instantiate GameOver Sound */
        gameOverNoise = SKAction.playSoundFileNamed("gameOver", waitForCompletion: false)
        
        /* Set Labels to be hidden */
        restartLabel.isHidden = true
        dedLabel.isHidden = true
        menuLabel.isHidden = true
        highScoreLabel.isHidden = true
        
        /* Create Physics Body for frame */
        setupPhysicsBody()
        
        /* Make all the platforms */
        setupGame()
        flipPlatforms()
        
        /* This helps reduce the vibration lag when the player dies */
        generator.prepare()
        
        /* Mute Toggle */
        if MainMenu.isMuted {
            musicToggle.texture = SKTexture(imageNamed: "musicOff")
        } else {
            musicToggle.texture = SKTexture(imageNamed: "musicOn")
        }
        
        /* Spawn Platforms and enemies */
        spawnEnemy(round: round)
        spawnObstacles(orientation: player.orientation)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* Only runs fucntion if the game is paused or over */
        if gameState == .paused || gameState == .gameOver {
            /* We only need a single touch here */
            let touch = touches.first!
            
            /* Get touch position in scene */
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
            
            /* touch stuff :: will fix comment eventually*/
            if touchedNode.name == "menuLabel" || touchedNode.name == "restartLabel" || touchedNode == resumeLabel {
                (touchedNode as! SKLabelNode).fontColor = UIColor.lightGray
                
            } else { // If the touchedNode is not a label node this runs
                (gameOverScreen.childNode(withName: "menuLabel") as! SKLabelNode).fontColor = UIColor.white
                (gameOverScreen.childNode(withName: "restartLabel") as! SKLabelNode).fontColor = UIColor.white
                (pauseScreen.childNode(withName: "menuLabel") as! SKLabelNode).fontColor = UIColor.white
                (pauseScreen.childNode(withName: "restartLabel") as! SKLabelNode).fontColor = UIColor.white
                resumeLabel.fontColor = UIColor.white
            }
        }
        
        
        
        
        
        /* Checks if player is on the ground */
        if canJump && jumpTimer <= jumpTime {
            /* Switch statement to determine where the player is so that it can apply the correct impulse */
            switch player.orientation {
            case .bottom:
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 17))
            case .right:
                player.physicsBody?.applyImpulse(CGVector(dx: -17, dy: 0))
            case .top:
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -17))
            case .left:
                player.physicsBody?.applyImpulse(CGVector(dx: 17, dy: 0))
                
            }
            
            player.physicsBody?.affectedByGravity = false
            canJump = false
            
        }
        
    }
    
    /* Literally only for buttons */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if gameState == .reversed || gameState == .active { return } // Doesn't run code if game is running
        /* We only need a single touch here */
        let touch = touches.first!
        
        /* Get touch position in scene */
        let location = touch.location(in: self)
        let touchedNode = self.atPoint(location)
        
        /* touch stuff :: will fix comment eventually*/
        if touchedNode.name == "menuLabel" || touchedNode.name == "restartLabel" || touchedNode == resumeLabel {
            (touchedNode as! SKLabelNode).fontColor = UIColor.lightGray
            
        } else { // If the touchedNode is not a label node this runs
            (gameOverScreen.childNode(withName: "menuLabel") as! SKLabelNode).fontColor = UIColor.white
            (gameOverScreen.childNode(withName: "restartLabel") as! SKLabelNode).fontColor = UIColor.white
            (pauseScreen.childNode(withName: "menuLabel") as! SKLabelNode).fontColor = UIColor.white
            (pauseScreen.childNode(withName: "restartLabel") as! SKLabelNode).fontColor = UIColor.white
            resumeLabel.fontColor = UIColor.white
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
        if Enemy.totalAlive > 0 && player.state != .superSaiyajin {
            health -= 0.0006 // MARK: Tweak speed of rounds
        }
        
        
        if health <= 0 {
            gameState = .gameOver
            deathLabel.text = "Your time ran out"
        }
        
        /* Once the jumpTimer is complete, the player falls to the ground and the timer is reset */
        if jumpTimer > jumpTime {
            player.physicsBody?.affectedByGravity = true
            jumpTimer = 0
        }
        
        /* This checks to see if the player is in SSJ or not */
        if player.state == .superSaiyajin {
            /* Check to see if the player just went SSJ, if so run the animation and begin music*/
            if powerUpTimer == 0 {
                playerImage.run(SKAction(named: "powerUpRun")!)
                play(node: powerUpMusic)
                
                if backgroundMusic.parent == self {
                    backgroundMusic.removeFromParent() // Stops playing regular background music
                }
                characterSpeed = 200
            }
            /* Update SSJ timer */
            powerUpTimer += fixedDelta
            
            /* Reset player state and visual to match */
            if powerUpTimer >= powerUpTime {
                player.state = .normal
                playerImage.run(SKAction(named: "Run")!)
                if powerUpMusic.parent == self {
                    powerUpMusic.removeFromParent() // Stops playing powerUp background music
                }
                play(node: backgroundMusic) // Starts playing the regular background music
                characterSpeed = 150
            }
        }
        
        /* Add 'gravity' to enemies */
        for enemy in enemyArray {
            switch enemy.orientation {
            case .right:
                enemy.physicsBody?.applyForce(CGVector(dx: 9.8, dy: 0))
                break
            case .left:
                enemy.physicsBody?.applyForce(CGVector(dx: -9.8, dy: 0))
            default:
                break
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
                        checkEnemy(enemy: (nodeB as! Enemy), contactPoint: contact.contactPoint)
                    } else if (nodeA as! Player).state == .superSaiyajin {
                        (nodeB as! Enemy).die()
                        
                        if let index = enemyArray.index(of: (nodeB as! Enemy)) {
                            enemyArray.remove(at: index)
                        }
                        
                        health += CGFloat(Double((nodeB as! Enemy).pointValue) / Double(Enemy.totalPointValue)) / 2
                        points += (nodeB as! Enemy).pointValue
                        pointsLabel.text = String(points)
                    }
                    
                }
            } else if nodeA.physicsBody?.contactTestBitMask == 2 || nodeA.physicsBody?.contactTestBitMask == 3 {
                (nodeB as! Enemy).turnAround()
            }
        }
        
        if nodeA.physicsBody?.contactTestBitMask == 2 {
            if nodeB.name == "player" {
                if (nodeA as! Enemy).isAlive {
                    if (nodeB as! Player).state == .normal {
                        checkEnemy(enemy: (nodeA as! Enemy), contactPoint: contact.contactPoint)
                    } else if (nodeB as! Player).state == .superSaiyajin {
                        (nodeA as! Enemy).die()
                        
                        if let index = enemyArray.index(of: (nodeA as! Enemy)) {
                            enemyArray.remove(at: index)
                        }
                        health += CGFloat(Double((nodeA as! Enemy).pointValue) / Double(Enemy.totalPointValue)) / 2
                        points += (nodeA as! Enemy).pointValue
                        pointsLabel.text = String(points)
                    }
                    
                }
            } else if nodeB.physicsBody?.contactTestBitMask == 2 || nodeB.physicsBody?.contactTestBitMask == 3 {
                (nodeA as! Enemy).turnAround()
            }
        }
        
        
        /* Checks if either contact is a gem */
        if nodeA == gem || nodeB == gem {
            if gem.gemValue == 1 {
                gem.onContact()
                health += ((1 - health) / 2) // Gives player health so they can go for it without losing too much time
                sessionGemCounter += 1
            }
            
        }
        
        /* Checks if either contact is a cherry */
        if nodeA == cherry || nodeB == cherry {
            if !cherry.used {
                cherry.onContact()
                health += ((1 - health) / 2) // Gives player health so they can go for it without losing too much time
                player.state = .superSaiyajin
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Runs when player removes their finger from the screen */
        
        /* Get first touch and location */
        let touch  = touches.first!
        let location = touch.location(in: self)
        
        /* Use touch location to determine what node is being touched */
        let touchedNode = self.atPoint(location)
        
        /* Only check touchedNode if the game is running... */
        if gameState == .gameOver || gameState == .paused {
            
            /* "Button" Code */
            if(touchedNode.name == "restartLabel"){
                restartGame()
            } else if touchedNode.name == "menuLabel" {
                loadMenu()
            } else if touchedNode == resumeLabel {
                gameState = .active
                playPauseButton.texture = SKTexture(imageNamed: "pause")
                pauseScreen.run(SKAction.moveTo(x: 320, duration: 0.25))
                pointsLabel.isHidden = false
                resumeLabel.fontColor = UIColor.white
            } else if touchedNode == musicToggle {
                if MainMenu.isMuted {
                    MainMenu.isMuted = false
                    musicToggle.texture = SKTexture(imageNamed: "musicOn")
                    UserDefaults.standard.set(MainMenu.isMuted, forKey: "isMuted")
                } else {
                    MainMenu.isMuted = true
                    musicToggle.texture = SKTexture(imageNamed: "musicOff")
                    UserDefaults.standard.set(MainMenu.isMuted, forKey: "isMuted")
                }
                play(node: backgroundMusic)
                print("touched")
            }
            
        } else if touchedNode == playPauseButton { // ... unless the node is the pause button
            if gameState != .gameOver {
                gameState = .paused
                playPauseButton.texture = SKTexture(imageNamed: "play")
                pauseScreen.position.x = 0
                pauseScoreLabel.text = "Your Score: \(points)"
                pointsLabel.isHidden = true
            }
        }
        
        /* The player is now affected by gravity again and the timer is reset */
        player.physicsBody?.affectedByGravity = true
        jumpTimer = 0
        
    }
    
    func spawnObstacles(orientation: characterOrientationState) {
        /* This function handles the spawning of obstacles */
        
        /* Remove all the platforms so that new ones can be added to the correct side */
        removePlatforms(side: .left)
        removePlatforms(side: .right)
        
        
        var fixedOrientation = orientation // This is necessary for the reverse game mode to function properly
        
        if gameState == .reversed {
            
            if fixedOrientation == .bottom {
                fixedOrientation = .top
            } else {
                fixedOrientation = .bottom
            }
        }
        
        switch fixedOrientation {
        case .bottom:
            
            /* Add platform to scene */
            addPlatforms(side: .right)
            
            /* Position new platforms */
            positionPlatforms(side: .right)
            break
            
        case .top:
            
            /* Add new platforms */
            addPlatforms(side: .left)
            
            /* Position new platforms */
            positionPlatforms(side: .left)
            
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
        
        /* Create color animation to indicate change in gameplay */
        let color = SKAction.colorize(with: UIColor.purple, colorBlendFactor: 1.0, duration: 0.25)
        let uncolor = SKAction.colorize(with: self.backgroundColor, colorBlendFactor: 1.0, duration: 0.25)
        let seq = SKAction.sequence([color, uncolor])
        
        /* The game will run in reverse if the round is a multiple of 5 */
        if round % 5 == 0 {
            if gameState == .active {
                run(seq)
            }
            gameState = .reversed
            reversed = true
            
        } else if (round - 1) % 5 == 0 {
            if gameState == .reversed {
                run(seq)
            }
            gameState = .active
            reversed = false
        } else {
            gameState = .active
            reversed = false
        }
        if Enemy.totalAlive == 1 {
            if enemyArray[0].orientation == .right {
                if gameState == .active {
                    if player.orientation == .top {
                        gameState = .reversed
                        run(seq)
                    } else if player.orientation == .bottom {
                        gameState = .active
                    }
                } else { // Reverse Case
                    if player.orientation == .bottom {
                         gameState = .active
                        run(seq)
                    } else if player.orientation == .top {
                        gameState = .reversed
                    }
                }
            } else if enemyArray[0].orientation == .left {
                if gameState == .active {
                    if player.orientation == .bottom {
                        gameState = .reversed
                        run(seq)
                    } else if player.orientation == .top {
                        gameState = .active
                    }
                } else { // Reverse Case
                    if player.orientation == .top {
                        gameState = .reversed
                    } else if player.orientation == .bottom {
                        gameState = .active
                        run(seq)
                    }
                    
                }
            }
            print("Orientation: \(enemyArray[0].orientation)")
        }
        print("player orientation: \(player.orientation)")
    }
    
    func setupGame() {
        /* Called in the didMove function */
        
        /* Switch statement to show different themes */
        switch GameScene.theme {
        case .fox:
            player.size = CGSize(width: 28, height: 30)
            playerImage.run(SKAction(named: "characterRun")!)
            break
        case .monkey:
            playerImage.run(SKAction(named: "Run")!)
        }
        
        /* Initialize roundLabel object */
        roundLabel.position = CGPoint(x: (self.frame.width / 2), y: (self.frame.height / 2) - 20)
        roundLabel.text = ""
        roundLabel.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.5), SKAction.fadeOut(withDuration: 0.5)]))
        roundLabel.fontName = "Gang of Three"
        roundLabel.zPosition = 5
        self.addChild(roundLabel)
        
        /* Instuction Label */
        let instructionLabel = SKLabelNode()
        instructionLabel.position = CGPoint(x: (self.frame.width / 2), y: (self.frame.height / 2) - 20)
        instructionLabel.text = "Defeat All the"
        instructionLabel.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.5), SKAction.fadeOut(withDuration: 0.5)]))
        instructionLabel.fontName = "Gang of Three"
        instructionLabel.zPosition = 5
        self.addChild(instructionLabel)
        
        /* Instuction Label pt 2 */
        let instructionLabelp2 = SKLabelNode()
        instructionLabelp2.position = CGPoint(x: (self.frame.width / 2), y: (self.frame.height / 2) - 50)
        instructionLabelp2.text = "Enemies!!!"
        instructionLabelp2.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.5), SKAction.fadeOut(withDuration: 0.5)]))
        instructionLabelp2.fontName = "Gang of Three"
        instructionLabelp2.zPosition = 5
        self.addChild(instructionLabelp2)
        
        /* Add collectibles to scene */
        self.addChild(gem)
        self.addChild(cherry)
        
        /* Setup Points Label */
        pointsLabel.position = CGPoint(x: (self.frame.width / 2), y: (self.frame.height / 2) + 20)
        pointsLabel.isHidden = false
        pointsLabel.zPosition = -1
        pointsLabel.fontName = "Gang of Three"
        self.addChild(pointsLabel)
        
        dedLabel.text = "Your Score: \(points)"
        dedLabel.isHidden = false
        restartLabel.isHidden = false
        menuLabel.isHidden = false
        highScoreLabel.isHidden = false
        
        /* This is a fadeIn and fadeOut animation */
        roundLabel.run(SKAction(named: "RoundLabel")!)
    }
    
    func spawnEnemy(round: Int) {
        /* Create arrays of different spawn locations */
        var heightArray = [140,220,300,380]
        var sideArray = [20, 305]
        
        /* 2D array of arrays of Ints set to 0. Array size is 2x4 */
        var positionArray = Array(repeating: Array(repeating: 0, count: 2), count: 8)
        
        /* Fill in array with values from height and side arrays */
        for x in 0..<sideArray.count * heightArray.count {
            if x < heightArray.count {
                positionArray[x] = [sideArray[0], heightArray[x]]
            } else {
                positionArray[x] = [sideArray[1], heightArray[x - 4]]
            }
        }
        
        var count = round + 1 // The round begins at 1 and we want 2 enemies to spawn in that round
        
        if round % 5 == 0 && round > 0 {
            count = (round / 5) + 1
        } else if( (round - 1) % 5 == 0) && round > 1 {
            count = heightArray.count
        }
        
        if count >= positionArray.count { // Don't want to get an indexOutOfBounds exception
            count = positionArray.count
        }
        
        
        for _ in 0..<count {
            /* This for loop is what spawns an enemy */
            
            /* Create the random numbers to pick height and side */
            let spawnPoint = arc4random_uniform(UInt32(positionArray.count))
            var adjustedSpawn = Int(spawnPoint)
            
            /* Spawns enemies on otherside of game as player */
            if ((round - 1) % 5 == 0) && round > 1 {
                if player.orientation == .bottom {
                    if adjustedSpawn >= heightArray.count {
                        adjustedSpawn -= heightArray.count
                    }
                } else {
                    if adjustedSpawn < heightArray.count {
                        adjustedSpawn += heightArray.count
                    }
                }
                
            } else if round % 5 == 0 && round > 0 {
                if player.orientation == .top {
                    if adjustedSpawn >= 4 {
                        adjustedSpawn -= 4
                    }
                } else {
                    if adjustedSpawn < 4 {
                        adjustedSpawn += 4
                    }
                }
            }
            
            if round == 0 {
                if adjustedSpawn < 4 {
                    adjustedSpawn += 4
                }
            }
            
            
            /* Create an enemy object and add it to the scene and enemy array */
            let enemy = Enemy(round: round)
            enemyArray.append(enemy)
            
            /* Conditional to prevent king cobra from spawniong outside of point */
            if (positionArray[adjustedSpawn][1] == 0 || (positionArray[adjustedSpawn][1] == heightArray[heightArray.count - 1]) && enemy.type == .cobra) {
                
                if enemy.orientation == .right {
                    enemy.position.x -= 10
                } else if enemy.orientation == .left {
                    enemy.position.x += 10
                }
            }
            
            self.addChild(enemy)
            
            /* Check to see which side the enemy is on, then rotate and set velcoity accordingly */
            if positionArray[adjustedSpawn][0] == sideArray[0] {
                enemy.zRotation = CGFloat(Double.pi) // Marshall Cain Suggestion, fixed scropions
                enemy.orientation = .left
                enemy.physicsBody?.velocity.dy = CGFloat(50.0 * enemy.xScale * -1)
            } else if positionArray[adjustedSpawn][0] == sideArray[1] {
                enemy.orientation = .right
                enemy.physicsBody?.velocity.dy = CGFloat(50.0 * enemy.xScale)
            }
            
            /* Move the scorpion to the randomly chosen spawn point */
            enemy.position = CGPoint(x: positionArray[adjustedSpawn][0], y: positionArray[adjustedSpawn][1])
            
            /* Prevent enemies from being spawned at the same spot */
            positionArray.remove(at: adjustedSpawn)
        }
        
        
    }
    
    
    /* Checks if player is above scorpion */
    func checkEnemy(enemy: Enemy, contactPoint: CGPoint) {
        
        switch enemy.orientation {
        case .right:
            if player.position.x + 25 < enemy.position.x - (enemy.size.height / 2) {
                enemy.isAlive = false
                enemy.die()
                
                if let index = enemyArray.index(of: enemy) {
                    enemyArray.remove(at: index)
                }
                
                player.physicsBody?.velocity = CGVector.zero
                player.physicsBody?.applyImpulse(CGVector(dx: -10, dy: 0))
                points += enemy.pointValue
                pointsLabel.text = String(points)
                health += CGFloat(0.01 * Double(enemy.pointValue))
                
            } else {
                gameState = .gameOver
                deathLabel.text = "Death by \(enemy.type)"
            }
            break
            
        case .left:
            if player.position.x + 8 > enemy.position.x + (enemy.size.height / 2) {
                enemy.isAlive = false
                enemy.die()
                if let index = enemyArray.index(of: enemy) {
                    enemyArray.remove(at: index)
                }
                player.physicsBody?.velocity = CGVector.zero
                player.physicsBody?.applyImpulse(CGVector(dx: 10, dy: 0))
                points += enemy.pointValue
                pointsLabel.text = String(points)
                health += CGFloat(0.01 * Double(enemy.pointValue))
                
            } else {
                gameState = .gameOver
                deathLabel.text = "Death by \(enemy.type)"
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
        /* Run player death animation and gameOver screen animation */
        player.death()
        gameOverScreen.run(SKAction.moveTo(y: 0, duration: 0.5))
        
        /* End background music */
        if backgroundMusic.parent == self {
            backgroundMusic.removeFromParent()
        }
        
        
        /* Run Wha Wha Noise */
        play(audio: gameOverNoise)
        
        /* Hide all the unnecessary labels and change death label to output player score */
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
        
        let currentHigh = UserDefaults.standard.integer(forKey: "highScore")
        
        /* Submit high score to Game Center leaderboard */
        MainMenu.viewController.addScoreAndSubmitToGC(score: Int64(currentHigh))
        
        /* Remove all scorpions from scene */
        for scorpion in enemyArray {
            scorpion.die()
            if let index = enemyArray.index(of: scorpion) {
                enemyArray.remove(at: index)
            }
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
        
        /* Create SK transition */
        let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.5)
        
        /* Restart Game Scene */
        skView?.presentScene(scene, transition: transition)
    }
    
    
    
    func addPlatforms(side: Orientation) {
        /* Add platforms on the specified side to the gameScene */
        switch side {
        case .right:
            for platform in rightPlatforms {
                self.addChild(platform)
            }
            break
            
        case .left:
            for platform in leftPlatforms {
                self.addChild(platform)
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
        /* This function positions the platforms and collectibles */
        
        /* Create a random number variable to choose the formation of platforms */
        let formation = arc4random_uniform(UInt32(3)) // there are 3 formations
        
        /* Set Variables */
        let x1 = 80.0
        let x2 = x1 * 1.5
        let x3 = x2 * 1.5
        let width = Double(frame.width)
        let spacing = 94.0
        
        let y1 = 140.0
        let y2 = y1 + spacing
        let y3 = y2 + spacing
        let y4 = y3 + spacing
        
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
                break
            case 1:
                leftPlatforms[0].position = CGPoint(x: x2, y: y1)
                leftPlatforms[1].position = CGPoint(x: x1, y: y2)
                leftPlatforms[2].position = CGPoint(x: x2, y: y3)
                leftPlatforms[3].position = CGPoint(x: x1, y: y4)
                break
            case 2:
                leftPlatforms[0].position = CGPoint(x: x3, y: y1)
                leftPlatforms[1].position = CGPoint(x: x2, y: y2)
                leftPlatforms[2].position = CGPoint(x: x1, y: y3)
                leftPlatforms[3].position = CGPoint(x: x1, y: y4)
                break
            case 3:
                leftPlatforms[0].position = CGPoint(x: x3, y: y1)
                leftPlatforms[1].position = CGPoint(x: x2, y: y2)
                leftPlatforms[2].position = CGPoint(x: x2, y: y3)
                leftPlatforms[3].position = CGPoint(x: x1, y: y4)
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
                break
            case 1:
                rightPlatforms[0].position = CGPoint(x: oppositeX1, y: y1)
                rightPlatforms[1].position = CGPoint(x: oppositeX2, y: y2)
                rightPlatforms[2].position = CGPoint(x: oppositeX1, y: y3)
                rightPlatforms[3].position = CGPoint(x: oppositeX2, y: y4)
                break
            case 2:
                rightPlatforms[0].position = CGPoint(x: oppositeX1, y: y1)
                rightPlatforms[1].position = CGPoint(x: oppositeX1, y: y2)
                rightPlatforms[2].position = CGPoint(x: oppositeX2, y: y3)
                rightPlatforms[3].position = CGPoint(x: oppositeX3, y: y4)
                break
            case 3:
                rightPlatforms[0].position = CGPoint(x: oppositeX1, y: y1)
                rightPlatforms[1].position = CGPoint(x: oppositeX2, y: y2)
                rightPlatforms[2].position = CGPoint(x: oppositeX2, y: y3)
                rightPlatforms[3].position = CGPoint(x: oppositeX3, y: y4)
            default:
                print("default ran")
            }
            
        default:
            break
        }
        
        /* Checks that gemSpawn is less than the number of platforms to preven index out of bounds and that it can spawn */
        if Int(gemSpawn) < rightPlatforms.count && gem.canSpawn {
            gem.position = gemPositioner(random: Int(gemSpawn), side: side)
            
            /* Mark that the gem has been spawned already */
            gem.canSpawn = false
        } else { // If the gem has already spawned or the random number is off, run this
            gem.position = CGPoint(x: -50, y: -50)
        }
        
        /* This statement places a cherry above a platform if the random number correlates to a platform */
        if Int(cherrySpawn) < rightPlatforms.count {
            cherry.position = gemPositioner(random: Int(cherrySpawn), side: side)
        } else {
            cherry.position = CGPoint(x: -50, y: -50)
        }
        
    }
    
    func playerMovement() {
        if gameState == .active {
            switch player.orientation {
            case .bottom:
                player.physicsBody?.velocity.dx = characterSpeed
                
                if player.position.x > 277 {
                    
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
                
                if player.position.x < 10 {
                    
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
                
                if player.position.x < 10 {
                    
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
                
                if player.position.x > 277 {
                    
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
        /* This functions sets up the physicsBody for the scene */
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
    
    func play(audio: SKAction) {
        if !MainMenu.isMuted {
            run(audio)
        } 
    }
    
    func play(node: SKAudioNode) {
        if !MainMenu.isMuted && node.parent != self { // if isMuted = false
            addChild(node)
           
        } else if node.parent == self {
            node.removeFromParent()
        }
    }
    
    
}





