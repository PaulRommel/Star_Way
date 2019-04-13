//
//  GameScene.swift
//  Star_Way
//
//  Created by Павел Попов on 03/04/2019.
//  Copyright © 2019 Yopi Studio. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var startfield: SKEmitterNode!
    var player: SKSpriteNode!
    
    var scoreLabel: SKLabelNode!
    var score: Int = 0{
        didSet{
            scoreLabel.text = "Счет: \(score)"
        }
    }
    
    var gameTimer:Timer!
    
    var aliens = ["alien","alien2","alien3"]
    
    let alienCategory: UInt32 = 0x1 << 1
    let bulletCategory: UInt32 = 0x1 << 0
    
    //движение героя-корабль
    let motionManager = CMMotionManager()
    var xAccelerate:CGFloat = 0
    
    override func didMove(to view: SKView) {
        //-------Добавление звездного неба-----------------------------------
        startfield = SKEmitterNode(fileNamed: "Starfield")
        startfield.position = CGPoint(x: 0, y: 1472)
        startfield.advanceSimulationTime(10)
        self.addChild(startfield)
        
        startfield.zPosition = -1
        
        //-------Добавление главного героя-----------------------------------
        player = SKSpriteNode(imageNamed: "shuttle")
        player.position = CGPoint(x: 0, y: -500)
        
        //player.setScale(2)
        
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Счет: 0")
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 56
        scoreLabel.fontColor = UIColor.white
        scoreLabel.position = CGPoint(x: -200, y: 500)
        score = 0
        
        self.addChild(scoreLabel)
        
        //инициализация врагов
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data: CMAccelerometerData?, error: Error?) in
            if let accelerometrData = data {
                let acceleration = accelerometrData.acceleration
                self.xAccelerate =  CGFloat(acceleration.x) * 0.75 + self.xAccelerate * 0.25
            }
        }
    }
    
    override func didSimulatePhysics() {
        player.position.x += xAccelerate * 50
        
        if player.position.x < -350{
            player.position = CGPoint(x:  350, y: player.position.y)
        } else if player.position.x > 350 {
            player.position = CGPoint(x:  -350, y: player.position.y)
        }
    }
 
    func didBegin(_ contact: SKPhysicsContact) {
        var alienBody: SKPhysicsBody
        var bulletBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            bulletBody = contact.bodyA
            alienBody = contact.bodyB
        } else {
            bulletBody  = contact.bodyB
            alienBody = contact.bodyA
        }
        
        if (alienBody.categoryBitMask & alienCategory) != 0  && (bulletBody.categoryBitMask & bulletCategory) != 0 {
            collisionElements(bulletNode: bulletBody.node as! SKSpriteNode, alienNode: alienBody.node as! SKSpriteNode)
        }
    }
    
    func collisionElements(bulletNode: SKSpriteNode, alienNode: SKSpriteNode) {
        let explosion = SKEmitterNode(fileNamed: "Vzriv")
        explosion?.position = alienNode.position
        self.addChild(explosion!)
        
        self.run(SKAction.playSoundFileNamed("vzriv.mp3", waitForCompletion: false))
        
        bulletNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)){
            explosion?.removeFromParent()
        }
        
        score += 5
    }
    
    @objc func addAlien() {
        aliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: aliens) as! [String]
        
        let alien = SKSpriteNode(imageNamed: aliens[0])
        let randomPos = GKRandomDistribution(lowestValue: 0/*-350*/, highestValue: 414/*350*/)
        let pos = CGFloat(randomPos.nextInt())
        alien.position = CGPoint(x: pos, y: /*800*/self.frame.size.height + alien.size.height)
        //alien.setScale(2)
        
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.categoryBitMask = bulletCategory
        alien.physicsBody?.contactTestBitMask = bulletCategory
        alien.physicsBody?.collisionBitMask = 0
        
        addChild(alien)
        
        //движение врагов
        let animDuration:TimeInterval = 6
        
        //удаление врагов которые покинули экран
        var actrions = [SKAction]()
        actrions.append(SKAction.move(to: CGPoint(x: pos, y: -800), duration: animDuration))
        //actrions.append(SKAction.move(to: CGPoint(x: pos, y: -alien.size.height), duration: animDuration))
        actrions.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actrions))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireBullet()
    }
    
    func fireBullet()  {
        self.run(SKAction.playSoundFileNamed("vzriv.mp3", waitForCompletion: false))
        
        let bullet = SKSpriteNode(imageNamed: "torpedo")
        bullet.position = player.position
        bullet.position.y += 5
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width /  2)
        bullet.physicsBody?.isDynamic = true
        //bullet.setScale(2)
        
        bullet.physicsBody?.categoryBitMask = bulletCategory
        bullet.physicsBody?.categoryBitMask = alienCategory
        bullet.physicsBody?.contactTestBitMask = alienCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        
        //вот здесь ошибка была
        self.addChild(bullet)
        
        //движение выстрела
        let animDuration:TimeInterval = 0.3
        
        //удаление врагов которые покинули экран
        var actrions = [SKAction]()
        actrions.append(SKAction.move(to: CGPoint(x: player.position.x, y: 800), duration: animDuration))
        actrions.append(SKAction.removeFromParent())
        
        bullet.run(SKAction.sequence(actrions))
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
