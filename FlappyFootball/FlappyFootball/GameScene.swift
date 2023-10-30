//
//  GameScene.swift
//  FlappyFootball
//
//  Created by Harrison Showman on 10/20/23.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let Ghost : UInt32 = 0x1 << 1
    static let Ground : UInt32 = 0x1 << 2
    static let Wall : UInt32 = 0x1 << 3
    static let Score : UInt32 = 0x1 << 4
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    var Ground = SKSpriteNode()
    var Ghost = SKSpriteNode()
    
    var wallPair = SKNode()
    var moveAndRemove = SKAction()
    var gameStarted = Bool()
    
    var score = Int()
    let scoreLabel = SKLabelNode()
    
    var died = Bool()
    var restartButton = SKSpriteNode()
    
    
    func createScene() {
        self.physicsWorld.contactDelegate = self
        
        for i in 0..<2 {
            let background = SKSpriteNode(imageNamed: "Background")
            background.size = CGSize(width: self.frame.width, height: self.frame.height)
            background.position = CGPointMake(CGFloat(i) * self.frame.width, 0)
            background.color = .black
            background.colorBlendFactor = 0.5
            background.name = "background"
            self.addChild(background)
        }
        
        scoreLabel.position = CGPoint(x: 0, y: 400)
        scoreLabel.text = "\(score)"
        scoreLabel.fontName = "Game Over"
        scoreLabel.fontSize = 300
        scoreLabel.zPosition = 5
        self.addChild(scoreLabel)
        
        // Add the ground to the scene
        Ground = SKSpriteNode(imageNamed: "Ground")
        Ground.setScale(0.6)
        Ground.position = CGPoint(x: 0, y: -self.frame.height / 2 + Ground.frame.height / 2)
        Ground.physicsBody = SKPhysicsBody(rectangleOf: Ground.size)
        Ground.physicsBody?.categoryBitMask = PhysicsCategory.Ground
        Ground.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        Ground.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        Ground.physicsBody?.affectedByGravity = false
        Ground.physicsBody?.isDynamic = false
        Ground.zPosition = 3
        self.addChild(Ground)
        
        // Add the ghost
        Ghost = SKSpriteNode(imageNamed: "Football")
        Ghost.size = CGSize(width: 60, height: 70)
        Ghost.position = CGPoint(x: -Ghost.frame.width, y: 0)
        Ghost.physicsBody = SKPhysicsBody(circleOfRadius: Ghost.frame.height / 2)
        Ghost.physicsBody?.categoryBitMask = PhysicsCategory.Ghost
        Ghost.physicsBody?.collisionBitMask = PhysicsCategory.Ground | PhysicsCategory.Wall
        Ghost.physicsBody?.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Wall | PhysicsCategory.Score
        Ghost.physicsBody?.affectedByGravity = false
        Ghost.physicsBody?.isDynamic = true
        Ghost.zPosition = 2
        self.addChild(Ghost)
    }
    
    func restartScene() {
        self.removeAllChildren()
        self.removeAllActions()
        died = false
        gameStarted = false
        score = 0
        createScene()
    }
    
    override func didMove(to view: SKView) {
        createScene()
    }
    
    func createButton() {
        restartButton = SKSpriteNode(imageNamed: "RestartBtn")
        restartButton.size = CGSize(width: 400, height: 200)
        restartButton.position = CGPoint(x: 0, y: 0)
        restartButton.zPosition = 6
        restartButton.setScale(0)
        self.addChild(restartButton)
        restartButton.run(SKAction.scale(to: 1.0, duration: 0.3))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        // Ghost collides with score
        if (firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Score) || (firstBody.categoryBitMask == PhysicsCategory.Score && secondBody.categoryBitMask == PhysicsCategory.Ghost) {
            
            score += 1
            scoreLabel.text = "\(score)"
            scoreLabel.fontName = "Game Over"
            scoreLabel.fontSize = 300
            if(firstBody.categoryBitMask == PhysicsCategory.Score) {
                firstBody.node?.removeFromParent()
            } else {
                secondBody.node?.removeFromParent()
            }
        }
        
        // Ghost collides with Wall or Ground
        if (firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Wall) || (firstBody.categoryBitMask == PhysicsCategory.Wall && secondBody.categoryBitMask == PhysicsCategory.Ghost || (firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Ground) || (firstBody.categoryBitMask == PhysicsCategory.Ground && secondBody.categoryBitMask == PhysicsCategory.Ghost)) {
            


            enumerateChildNodes(withName: "wallPair", using:({
                (node, error) in
                
                node.speed = 0
                self.removeAllActions()
            }))
            if (!died) {
                createButton()
            }
            died = true

        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameStarted == false {
            
            gameStarted = true
            Ghost.physicsBody?.affectedByGravity = true
            
            let spawn = SKAction.run({
                () in
                
                self.createWalls()
                
            })
            
            let delay = SKAction.wait(forDuration: 1.0)
            let spawnDelay = SKAction.sequence([spawn, delay])
            let spawnDelayForever = SKAction.repeatForever(spawnDelay)
            self.run(spawnDelayForever)
            
            let distance = CGFloat(self.frame.width + wallPair.frame.width)
            let movePipes = SKAction.moveBy(x: -distance / 20, y: 0, duration: TimeInterval(0.01 * distance))
            let removePipes = SKAction.removeFromParent()
            moveAndRemove = SKAction.sequence([movePipes, removePipes])
            
            Ghost.physicsBody?.velocity = CGVectorMake(0, 0)
            Ghost.physicsBody?.applyImpulse(CGVectorMake(0, 100))
            
        } else {
            if(!died) {
                Ghost.physicsBody?.velocity = CGVectorMake(0, 0)
                Ghost.physicsBody?.applyImpulse(CGVectorMake(0, 100))
            }
        }
        
        for touch in touches {
            let location = touch.location(in: self)
            if (died) {
                if (restartButton.contains(location)) {
                        restartScene()
                }
            }
        }

    }
    
    
    func createWalls() {
        wallPair = SKNode()
        wallPair.name = "wallPair"
        
        let scoreNode = SKSpriteNode(imageNamed: "Coin")
        
        scoreNode.size = CGSize(width: 50, height: 50)
        scoreNode.position = CGPoint(x: self.frame.width, y: 0)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: scoreNode.size)
        scoreNode.physicsBody?.affectedByGravity = false
        scoreNode.physicsBody?.isDynamic = false
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.Score
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        
        let topWall = SKSpriteNode(imageNamed: "Wall")
        let bottomWall = SKSpriteNode(imageNamed: "Wall")
        
        topWall.position = CGPoint(x: self.frame.width, y: 500)
        bottomWall.position = CGPoint(x: self.frame.width, y: -500)
        
        topWall.setScale(0.7)
        bottomWall.setScale(0.7)
        
        topWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        topWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        topWall.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        topWall.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        topWall.physicsBody?.affectedByGravity = false
        topWall.physicsBody?.isDynamic = false
        
        bottomWall.physicsBody = SKPhysicsBody(rectangleOf: bottomWall.size)
        bottomWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        bottomWall.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        bottomWall.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        bottomWall.physicsBody?.affectedByGravity = false
        bottomWall.physicsBody?.isDynamic = false
        
        topWall.zRotation = CGFloat(Double.pi)
        
        wallPair.addChild(topWall)
        wallPair.addChild(bottomWall)
        wallPair.addChild(scoreNode)
        wallPair.zPosition = 1
        
        let randomNumber = CGFloat(arc4random_uniform(400)) - 200
        wallPair.position.y += randomNumber
        
        self.addChild(wallPair)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        wallPair.run(moveAndRemove)
        
        if (gameStarted && !died) {
            enumerateChildNodes(withName: "background", using: ({
                (node, error) in
                
                let bg = node as! SKSpriteNode
                bg.position = CGPoint(x: bg.position.x - 2, y: bg.position.y)
                if (bg.position.x <= -bg.frame.width) {
                    bg.position = CGPointMake(bg.position.x + bg.size.width * 2, bg.position.y)
                }
            }))
        }
        
    }
}
