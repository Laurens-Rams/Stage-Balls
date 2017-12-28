//
//  Scene.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/11/17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import SpriteKit

struct PhysicsCategoryTwo {
    static let circleBall: UInt32 = 0b0001
    static let blueBall: UInt32 = 0b0010
    static let pinkBall: UInt32 = 0b0011
    static let redBall: UInt32 = 0b0100
    static let yellowBall: UInt32 = 0b0101
    
    static func returnCategory(num: Int) -> UInt32 {
        switch (num) {
        case 1:
            return blueBall
        case 2:
            return pinkBall
        case 3:
            return redBall
        case 4:
            return yellowBall
        default:
            return blueBall
        }
    }
}

class StartScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: properties
    
    let Circle = Planet(imageNamed: "circleunsichtbar")
    
    let diameter = CGFloat(217.0)
    
    let smallDiameter = CGFloat(52)
    
    var turnspeed = TimeInterval(0.05)
    
 var ImageCounter = 0
    
    var balls = [MenuBall]()
    
    var rotationsmallballs: SKAction!
    
    var rotation: SKAction!
    
    var runRotation: SKAction!
    
    var fall: SKAction!
    
    var ballTimer: Timer!
    
    
    
    var lastDirection: Double = -1
    
    var rotationRadians = Double.pi * 0.004
    
    var isTouching = true
    
    var allowTouches = false
    
    var ballInterval = TimeInterval(0.8)
    
    var multiplier = TimeInterval(1.0)
    
    var chain = 0
    
    var spinBalls: [SKSpriteNode]!
    
    
    
    // MARK: game update
    
    override func update(_ currentTime: TimeInterval) {
        Circle.doGravityUpdate(children: balls)
        if isTouching {
            rotation = SKAction.rotate(byAngle: CGFloat(rotationRadians * lastDirection), duration: TimeInterval(0.05))
            Circle.run(rotation)

        }
    }
    
    // scene setup
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        
        backgroundColor = .white
        
        let startX = CGFloat((size.width / 2))
        let startY = CGFloat((size.height / 2.5))
        let startpos = CGPoint(x: startX, y: startY)
        Circle.position = startpos
        Circle.size = CGSize(width: diameter, height: diameter)
        
        let body = SKPhysicsBody(texture: Circle.texture!, size: Circle.size)
        body.categoryBitMask = PhysicsCategory.circleBall
        body.angularDamping = 0.0
        body.allowsRotation = true
        
        body.pinned = true
        body.usesPreciseCollisionDetection = true
        body.isDynamic = false
        body.restitution = 0
        body.linearDamping = 1.0
        body.friction = 1.0
        Circle.physicsBody = body
        
        Circle.setGravityRange(range: size.height)
        Circle.setGravityMultiplier(mult: 0.4)
        addChild(Circle)
        addBall()


        
    }
    
    func useTheBreaks() {
        // Circle.physicsBody?.applyTorque(CGFloat(5.0 * lastDirection * -1))
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask > PhysicsCategory.circleBall && secondBody.categoryBitMask > PhysicsCategory.circleBall {
            // not sure about this yet
        }
        else if firstBody.categoryBitMask == PhysicsCategory.circleBall && secondBody.categoryBitMask != PhysicsCategory.circleBall {
            
            if let ball = secondBody.node as? MenuBall{
                if (ball.hasCollited == true){
                    print("true")
                    return
                }
                print("false")
                let pin = SKPhysicsJointFixed.joint(withBodyA: firstBody, bodyB: secondBody, anchor: contact.contactPoint)
                physicsWorld.add(pin)
                ball.hasCollited = true
                addBall()
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(allowTouches == true){
            
        
        let middle = (view?.frame.width)! / 2
        if let touch = touches.first {
            let touchX = touch.location(in: view).x
            isTouching = true
            if touchX < middle && lastDirection < 0 {
                useTheBreaks()
                lastDirection = 1
            }
            else if touchX > middle && lastDirection > 0 {
                useTheBreaks()
                lastDirection = -1
            }
        }
        }else{
            return
        }
    }
    func addBall() {

        if(ImageCounter < 4){
            ImageCounter = ImageCounter + 1
        
            let ballImage = randomImageName(imageNumber: ImageCounter)
            
            var categories = [
                PhysicsCategory.circleBall,
                PhysicsCategory.blueBall,
                PhysicsCategory.pinkBall,
                PhysicsCategory.yellowBall,
                PhysicsCategory.redBall
            ]
            
            let newBall = MenuBall(imageNamed: ballImage)
            newBall.size = CGSize(width: smallDiameter, height: smallDiameter)
            newBall.position = CGPoint(x: size.width / 2, y: size.height)
            
            let body = SKPhysicsBody(texture: newBall.texture!, size: newBall.size)
            body.contactTestBitMask = categories[0] | categories[1] | categories[2] | categories[3] | categories[4]
            body.allowsRotation = true
            body.angularDamping = 0.5
            body.linearDamping = 1.0
            body.restitution = 0
            body.friction = 1.0
            body.collisionBitMask = categories[0] | categories[1] | categories[2] | categories[3] | categories[4]
            
            newBall.physicsBody = body
            
            balls.append(newBall)
            
            addChild(newBall)
            
            
        }else{
            allowTouches = true
            rotationRadians = Double.pi * 0.001
        }
        
    }
    }
    
    
    
    // MARK: class methods
    
    func randomInteger() -> Int {
        return Int(arc4random_uniform(4) + UInt32(1))
    }
    
    // a function to return a random image name
    func randomImageName(imageNumber: Int) -> String {
        return "Icon-\(imageNumber)"
    }
    
    



