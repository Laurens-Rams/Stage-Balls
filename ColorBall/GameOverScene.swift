//
//  GOScene.swift
//  ColorBall
//
//  Created by Emily Kolar on 1/20/18.
//  Copyright © 2018 Emily Kolar. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene, SKPhysicsContactDelegate {
    
    var del: StartSceneDelegate?

    let Circle = PlayerCircle(imageNamed: "circle")
    
    let ballTextures: [SKTexture] = [
        // your textures here
        // e.g. SKTexture(imageNamed: ""),
    ]
    
    let names: [String] = [
        "presents",
        "volume"
    ]
    
    // TODO: implement a hit test for the "buttons"
    // example of this is in MenuScene's touchesEnded() and related functions
    
    override func didMove(to view: SKView) {
        isPaused = false
        //changes gravity spped up !!!not gravity//
        physicsWorld.gravity = CGVector(dx: 0, dy: 0.0)
        physicsWorld.contactDelegate = self
        
        let startX = CGFloat((size.width / 2))
        let startY = CGFloat((size.height / 3))
        let startpos = CGPoint(x: startX, y: startY)
        Circle.position = startpos
        Circle.size = CGSize(width: 200, height: 200)
        
        let body = SKPhysicsBody(texture: Circle.texture!, size: CGSize(width: Circle.size.width - 2, height: Circle.size.height - 2))
        body.categoryBitMask = PhysicsCategory.circleBall
        body.allowsRotation = true
        body.pinned = true
        body.isDynamic = false
        Circle.physicsBody = body
        
        setupBalls()
        
        addChild(Circle)
    }

    func setupBalls() {
        var balls = [StartingSmallBall]();

        // the radians to separate each starting ball by, when placing around the ring
        let incrementRads = degreesToRad(angle: 360 / CGFloat(14))
        let startPosition = CGPoint(x: size.width / 2, y: Circle.position.y)
        let startDistance: CGFloat = 123.0
        
        for i in 0..<4 {
            print(i)
            let startRads = incrementRads * CGFloat(i) - degreesToRad(angle: 90.0)
            let newX = (startDistance) * cos(Circle.zRotation - startRads) + Circle.position.x
            let newY = (startDistance) * sin(Circle.zRotation - startRads) + Circle.position.y
            let targetPosition = CGPoint(x: newX, y: newY)
            
            let ball = makeStartBall(index: i)
            ball.stuck = false
            ball.position = startPosition
            ball.zPosition = Circle.zPosition - 1
            ball.startingPos = startPosition
            ball.insidePos = targetPosition
            ball.startRads = startRads
            ball.startDistance = startDistance
            balls.append(ball);
            
            print(ball.colorType)

            addChild(ball)
        }
        
        for b in balls {
            animateBall(ball: b)
        }
    }
    
    /**
     Animate a ball from the inside of the large circle, outward.
     - parameters:
     - ball: A StartingSmallBall object.
     */
    func animateBall(ball: StartingSmallBall) {
        let action = SKAction.move(to: ball.insidePos, duration: 1.2)
        ball.run(action, completion: {
            ball.stuck = true
        })
    }
    
    /**
     Create a ball to appear at the beginning of the level.
     - parameters:
     - index: The index of this ball in the array of starting balls.
     - returns: A new StartingSmallBall object.
     */
    func makeStartBall(index: Int) -> StartingSmallBall {
        var categories = [
            PhysicsCategory.circleBall,
            PhysicsCategory.blueBall,
            PhysicsCategory.pinkBall,
            PhysicsCategory.redBall,
            PhysicsCategory.yellowBall,
            PhysicsCategory.greenBall,
            PhysicsCategory.orangeBall,
            PhysicsCategory.purpleBall,
            PhysicsCategory.greyBall,
        ]

        // use the random integer to get a ball type and a ball colorr
        let ballType = BallColor(rawValue: index)!
        let ballColor = Settings.ballColors[index]
        
        let newBall = StartingSmallBall(circleOfRadius: 21.0)
        // set the fill color to our random color
        newBall.fillColor = ballColor
        
        // newBall.fillTexture = ballTextures[index]
        // newBall.name = names[index]
        
        // don't fill the outline
        newBall.lineWidth = 0.0
        
        let body = SKPhysicsBody(circleOfRadius: 21.0)
        // our physics categories are offset by 1, the first entry in the arryay being the bitmask for the player's circle ball
        body.categoryBitMask = categories[index + 1]
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.blueBall | PhysicsCategory.pinkBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall | PhysicsCategory.greenBall | PhysicsCategory.orangeBall | PhysicsCategory.purpleBall | PhysicsCategory.greyBall
        body.restitution = 0
        categories.remove(at: index)
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        body.isDynamic = false
        newBall.physicsBody = body
        newBall.colorType = ballType
        
        return newBall
    }
}
