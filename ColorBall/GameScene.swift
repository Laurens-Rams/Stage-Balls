////
////  GameScene.swift
////  ColorBall
////
////  Created by Emily Kolar on 6/18/17.
////  Copyright © 2017 Emily Kolar. All rights reserved.
////
//
//import SpriteKit
//import GameplayKit
//
////struct PhysicsCategory {
////    static let playerBall: UInt32 = 0b1
////    static let yellowBall: UInt32 = 0b10
////}
//
//class GameScene: SKScene, SKPhysicsContactDelegate {
//    
//    /**
//     Constant for the player sprite node.
//     */
//    let player = SKSpriteNode(imageNamed: "PlayerBall")
//    
//    /**
//     The duration between spawning new balls.
//     */
//    let BALL_INTERVAL = TimeInterval(0.45)
//    
//    /**
//     The duration over which to rotate the player ball.
//     */
//    let SPIN_INTERVAL = TimeInterval(2.0)
//    
//    /**
//     Distance (relative angle in radians) to rotate the player ball.
//     pi: 3.14
//     */
//    let SPIN_RADIANS = CGFloat(Double.pi * 0.5)
//    
//    override func didMove(to view: SKView) {
//        
//        // assign this class as the delgate responsible for physicsWorld contact tasks
//        physicsWorld.contactDelegate = self
//
//        // set the background color
//        backgroundColor = SKColor(red: 0.5, green: 0, blue: 0.8, alpha: 0.4)
//        
//        // set the player ball's size
//        player.size = CGSize(width: size.width * 0.5, height: size.width * 0.5)
//        
//        /**
//         A unique name for the player ball node so it can be referenced from SKActions.
//         */
//        let playerName = "Player"
//        player.name = playerName
//
//        /**
//         The player ball's x-coordinate.
//         */
//        let playerX = view.frame.width / 2
//        
//        /**
//         The player ball's y-coordinate.
//         */
//        let playerY = (player.size.height / 2) + (size.height * 0.2)
//        
//        // set the player's starting point
//        player.position = CGPoint(x: playerX, y: playerY)
//        
//        /**
//         The object with physics properties that will be associated with the player's sprite.
//         */
//        let body = SKPhysicsBody(circleOfRadius: player.size.width / 2)
//        body.categoryBitMask = PhysicsCategory.circleBall
//        body.pinned = true
//        body.allowsRotation = true
//        body.angularDamping = 0
//        body.friction = 0
//        // body.restitution = 0 // try getting rid of bouncing; same effect
//        body.isDynamic = false
//        body.usesPreciseCollisionDetection = true
//        
//        player.physicsBody = body
//
//        // add the player to the scene
//        addChild(player)
//        
//        /**
//         Action describing a relative rotation over a duration in seconds.
//         */
//        let rotation = SKAction.rotate(byAngle: SPIN_RADIANS, duration: SPIN_INTERVAL)
//        
//        // run the rotation on loop
//        run(SKAction.repeatForever(
//            SKAction.sequence([
//                SKAction.run(rotation, onChildWithName: "Player"),
//                SKAction.wait(forDuration: SPIN_INTERVAL)
//            ])
//        ))
//        
//        // call the addBall() function as an action, on loop
//        run(SKAction.repeatForever(
//            SKAction.sequence([
//                SKAction.run(addBall),
//                SKAction.wait(forDuration: BALL_INTERVAL)
//            ])
//        ))
//    }
//    
//    func didBegin(_ contact: SKPhysicsContact) {
//
//        var firstBody: SKPhysicsBody
//        var secondBody: SKPhysicsBody
//
//        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
//            firstBody = contact.bodyA
//            secondBody = contact.bodyB
//        } else {
//            firstBody = contact.bodyB
//            secondBody = contact.bodyA
//        }
//
//        if firstBody.categoryBitMask == PhysicsCategory.playerBall && secondBody.categoryBitMask != PhysicsCategory.playerBall {
//            print("Hit player's ball. First contact has been made.")
//            let pin = SKPhysicsJointFixed.joint(withBodyA: firstBody, bodyB: secondBody, anchor: contact.contactPoint)
//            physicsWorld.add(pin)
//            secondBody.categoryBitMask = PhysicsCategory.playerBall
//        }
//    }
//    
//    /**
//     Return a random number.
//     - returns: CGFloat
//     */
//    func random() -> CGFloat {
//        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
//    }
//    
//    /**
//     Return a random number, between a min value and max value.
//     - parameter min: Lower bound (inclusive).
//     - parameter max: Upper bound (exclusive).
//     - returns: CGFloat
//     */
//    func random(min: CGFloat, max: CGFloat) -> CGFloat {
//        return random() * (max - min) + min
//    }
//    
//    /**
//     Creates a random colored ball (sprite node) and adds it to the scene.
//     - returns: Void
//     */
//    func addBall() {
//        
//        /**
//         Srite node for the random colored ball.
//         */
//        let ball = SKSpriteNode(imageNamed: "BallYellow")
//        
//        ball.size = CGSize(width: 30, height: 30)
//        
//        /**
//         The starting point along the x-axis, dead-center.
//         */
//        let xPos = size.width / 2
//        
//        /**
//         The starting point for the ball, slightly off the top edge of the screen.
//         */
//        let yPos = size.height + ball.size.height
//        
//        // set the position coordinates
//        ball.position = CGPoint(x: xPos, y: yPos)
//        
//        /**
//         The object with physics properties that will be associated with the player's sprite.
//         */
//        let body = SKPhysicsBody(circleOfRadius: (ball.size.width / 2) - 2)
//        body.categoryBitMask = PhysicsCategory.yellowBall
//        body.contactTestBitMask = PhysicsCategory.playerBall | PhysicsCategory.yellowBall
//        body.allowsRotation = true
//        body.usesPreciseCollisionDetection = true
//        // body.restitution = 0 // try eliminating bouncing here too... same
//        ball.physicsBody = body
//        
//        // add the ball to the scene
//        addChild(ball)
//        
//    }
//    
//}
//
//
