//
//  GameScene.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/15/17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation
import Darwin
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: class properties
    
    // player (large circle)
    let Circle = PlayerCircle(imageNamed: "circle")
    
    // game score
    var score: Int = 0
    
    // direction of rotation
    var direction: CGFloat = -1.0
    
    // ball settings
    let diameter = CGFloat(200.0)
    let radius = CGFloat(100.0)
    let smallDiameter = CGFloat(42)
    var hardness: Float = 0.0
    // for how often they are added
    var ballInterval = TimeInterval(2.0)
    
    // ball arrays
    var balls = [SmallBall]()
    var startBalls = [StartingSmallBall]()
    
    // actions
    var rotation: SKAction!
    var runRotation: SKAction!
    var fall: SKAction!
    
    // timers
    var ballTimer: Timer?
    var fallTimer: Timer!
    
    // control variables
    var isTouching = false
    var allowToMove = false
    var canMove = false

    // game loop update values
    var lastUpdateTime: TimeInterval = 0
    var dt: CGFloat = 0.0
    
    // delegates
    var scoreKeeper: GameScoreDelegate?
    var gameOverDelegate: StartGameDelegate?
    
    // MARK: lifecycle methods and overrides
    
    // main update function (game loop)
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTime
        let currentFPS = 1 / deltaTime

        dt = 1.0/CGFloat(currentFPS)
        lastUpdateTime = currentTime
        
        if canMove {
            updateCircle(dt: dt)
        }

        updateBalls(dt: dt)
    }
    
    override func didMove(to view: SKView) {
        isPaused = false
        //changes gravity spped up !!!not gravity//
        physicsWorld.gravity = CGVector(dx: 0, dy: 0.0)
        physicsWorld.contactDelegate = self
        backgroundColor = .white
        
        let startX = CGFloat((size.width / 2))
        let startY = CGFloat((size.height / 2.5))
        let startpos = CGPoint(x: startX, y: startY)
        Circle.position = startpos
        Circle.size = CGSize(width: diameter, height: diameter)
        
        
        let body = SKPhysicsBody(texture: Circle.texture!, size: CGSize(width: Circle.size.width - 2, height: Circle.size.height - 2))
        body.categoryBitMask = PhysicsCategory.circleBall
        body.allowsRotation = true
        body.pinned = true
        body.isDynamic = false
        Circle.physicsBody = body
        
        setupBalls()
        addChild(Circle)
        //timer sets when the first ball should fall
        let _ = Timer.scheduledTimer(withTimeInterval: 1.85, repeats: false, block: {timer in
            for i in 0..<15 {
                self.getBallValues(ball: self.startBalls[i])
                self.balls.append(self.startBalls[i])
            }
            self.startTimer()
            self.addBall()
            
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isTouching {
            return
        }else if(allowToMove == true){
            isTouching = true
            let middle = (view?.frame.width)! / 2
            if let touch = touches.first {
                let touchX = touch.location(in: view).x
                if touchX < middle {
                    direction = 1
                    
                }
                else if touchX > middle {
                    direction = -1
                }
                getCircleValues()
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }
    
    // MARK: custom update, animation, and movement methods
    
    /**
     Function to update the circle's rotation.
    - parameters:
        - dt: Last calculated delta time
     */
    func updateCircle(dt: CGFloat) {
        //change animation
        let increment = (((CGFloat(Double.pi) * 1) * direction)) * dt

        Circle.zRotation = Circle.zRotation + increment
        Circle.distance = Circle.distance + increment
        
        if (fabs(Circle.distance) >= fabs(Circle.nextTickPosition - Circle.lastTickPosition)) {
            Circle.distance = 0
            Circle.zRotation = Circle.nextTickPosition
            canMove = false
        }
    }
    
    /**
     Update the position of every applicable ball on the screen.
     - parameters:
        - dt: Last calculated delta time
     */
    func updateBalls(dt: CGFloat) {
        for ball in balls {
            var newX: CGFloat
            var newY: CGFloat

            if !ball.inLine {
                // if the ball isn't waiting in line to fall
                if !ball.stuck {
                    // if the ball isn't stuck to any other balls yet
                    newX = ball.position.x
                    newY = ball.position.y - 4
                } else {
                    // if the ball is stuck to another ball already
                    newX = ball.startDistance * cos(Circle.zRotation - ball.startRads) + Circle.position.x
                    newY = ball.startDistance * sin(Circle.zRotation - ball.startRads) + Circle.position.y
                }

                // set the new ball position
                ball.position = CGPoint(x: newX, y: newY)
            }
        }
    }
    
    /**
     Setup the level's starting balls.
     */
    func setupBalls() {
        let incrementRads = degreesToRad(angle: (360 / 15))
        for i in 0..<15 {
            let newBall = makeStartBall(index: i)
            newBall.startingPos = CGPoint(x: size.width / 2, y: Circle.position.y)
            newBall.position = newBall.startingPos
            addChild(newBall)
            startBalls.append(newBall)
            let startRads = (incrementRads * CGFloat(i) - (incrementRads / 4))
            let newX = 121 * cos(startRads) + Circle.position.x
            let newY = 121 * sin(startRads) + Circle.position.y
            newBall.startRads =  startRads * -1
            newBall.insidePos = CGPoint(x: newX, y: newY)
            newBall.startDistance = 121
        }
        for i in 0..<startBalls.count {
            animateBall(ball: startBalls[i])
        }
    }
    
    /**
     Animate a ball from the inside of the large circle, outward.
     - parameters:
        - ball: A StartingSmallBall object.
     */
    func animateBall(ball: StartingSmallBall) {
        let action = SKAction.move(to: ball.insidePos, duration: 1.2)
        ball.run(action)
    }
    
    /**
     Start the repeating timer for adding a new ball to the scene.
     */
    func startTimer() {
        ballTimer = Timer.scheduledTimer(timeInterval: ballInterval, target: self, selector: #selector(addBall), userInfo: nil, repeats: true)
        allowToMove = true
    }
    
    /**
     Start a timer for allowing a ball to fall downward.
     - parameters:
        - ball: A SmallBall object.
     */
    func startFallTimer(ball: SmallBall) {
        //for how long they stay up (0.0 - 1.8)
        fallTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: {
            timer in
            
            ball.inLine = false
        })
    }
    
    func getCircleValues() {
        if !canMove {
            Circle.lastTickPosition = Circle.zRotation
            Circle.nextTickPosition = Circle.lastTickPosition + (((CGFloat(Double.pi) * 2) / 15) * direction)
            canMove = true
        }
    }

    // checks the physics contact between two bodies
    // evaluates what type of object each body is, and what to do
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
        
        
        if firstBody.categoryBitMask == PhysicsCategory.circleBall || secondBody.categoryBitMask == PhysicsCategory.circleBall {
            if let ball = secondBody.node as? SmallBall {
                print("contact between circle and ball")
                getBallValues(ball: ball)
                increaseScore(byValue: 1)
                return
            }
        } else if firstBody.categoryBitMask == secondBody.categoryBitMask {
            if firstBody.isDynamic == true {
                print("small ball contact")
                if let ball = firstBody.node as? SmallBall {
                    let ball2 = secondBody.node as! SmallBall
                    for i in 0..<ball2.inContactWith.count {
                        ball.inContactWith.append(ball2.inContactWith[i])
                    }
                    ball.inContactWith.append(ball2)
                    if ball.inContactWith.count >= 3 {
                        zapBalls(ball: ball)
                        return
                    }
                    let dist = distanceBetween(pointA: ball.position, pointB: (secondBody.node?.position)!)
                    let v = 42 - dist
                    let vect = CGVector(dx: (ball.position.x - ball2.position.x) * v / dist, dy: (ball.position.y - ball2.position.y) * v / dist)
                    ball.position = CGPoint(x: ball.position.x, y: ball.position.y + vect.dy)
                    getBallValues(ball: ball)
                }
                increaseScore(byValue: 1)
            } else if secondBody.isDynamic == true {
                print("contact between small balls")
                if let ball = secondBody.node as? SmallBall {
                    let ball2 = firstBody.node as! SmallBall
                    for i in 0..<ball2.inContactWith.count {
                        ball.inContactWith.append(ball2.inContactWith[i])
                        
                    }
                    ball.inContactWith.append(ball2)
                    if ball.inContactWith.count >= 3 {
                       zapBalls(ball: ball)
                        return
                    }
                    let dist = distanceBetween(pointA: ball.position, pointB: (firstBody.node?.position)!)
                    let v = 42 - dist
                    let vect = CGVector(dx: (ball.position.x - ball2.position.x) * v / dist, dy: (ball.position.y - ball2.position.y) * v / dist)
                    ball.position = CGPoint(x: ball.position.x, y: ball.position.y + vect.dy)
                    getBallValues(ball: ball)
                }
                increaseScore(byValue: 1)
            }
            return
            
        } else if firstBody.categoryBitMask != secondBody.categoryBitMask {
            self.isPaused = true
            self.ballTimer?.invalidate()
            gameOverDelegate?.gameover()
        }
    }
    
    /**
     Increase the game score.
     - parameters:
        - byValue: Number to increase the score by.
     */
    func increaseScore(byValue: Int) {
        scoreKeeper?.increaseScore(byValue: byValue)
    }
    
    /**
     When four balls of the same type have stuck together, zap the whole column.
     - parameters:
        - ball: The topmost ball in the chain.
     */
    func zapBalls(ball: SmallBall) {
        for contactedBall in ball.inContactWith {
            if let position = balls.index(of: contactedBall) {
                balls.remove(at: position)
                contactedBall.physicsBody = nil
            }
        }

        self.removeChildren(in: ball.inContactWith)

        if let position = balls.index(of: ball) {
            balls.remove(at: position)
        }

        self.removeChildren(in: [ball])
        increaseScore(byValue: 2)
    }
    
    func moveAlongVector(ballA: SmallBall, ballB: SKSpriteNode) {
        let dist = distanceBetween(pointA: ballA.position, pointB: ballB.position)
        let v = smallDiameter - dist
        let vect = CGVector(dx: (ballA.position.x - ballB.position.x) * v / dist, dy: (ballA.position.y - ballB.position.y) * v / dist)
        ballA.position = CGPoint(x: ballA.position.x + vect.dx, y: ballB.position.y + vect.dy)
    }
    
    func checkDistance(ballA: SmallBall, ballB: SKSpriteNode) -> Bool {
        let distance = distanceBetween(pointA: ballA.position, pointB: ballB.position)
        if distance < smallDiameter {
            return false
        }
        return true
    }

    func getBallValues(ball: SmallBall) {
        if ball.stuck {
            return
        }
        if ball.startDistance == 0 {
            ball.startDistance = ball.position.y - Circle.position.y
        }
        // let angle = atan2(ball.position.y - Circle.position.y,
                          //ball.position.x - Circle.position.x)
        if ball.startRads == 0 {
            ball.startRads = Circle.zRotation - degreesToRad(angle: 90.0)
        }
        // balls.append(ball)
        ball.stuck = true
        ball.physicsBody?.isDynamic = false
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
            PhysicsCategory.yellowBall
        ]
        
        let rando = index < 4 ? index + 1 : randomInteger()
        let ballImage = randomImageName(imageNumber: rando)
        
        let newBall = StartingSmallBall(imageNamed: ballImage)
        
        newBall.size = CGSize(width: smallDiameter, height: smallDiameter)
        
        let body = SKPhysicsBody(circleOfRadius: 21.0)
        body.categoryBitMask = categories[rando]
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.pinkBall | PhysicsCategory.blueBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall
        body.restitution = 0
        categories.remove(at: rando)
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        body.isDynamic = false
        newBall.physicsBody = body
        
        return newBall
    }
    
    /**
     Create a small ball to drop from the top.
     - returns: A new SmallBall object.
     */
    func makeBall() -> SmallBall {
        var categories = [
            PhysicsCategory.circleBall,
            PhysicsCategory.blueBall,
            PhysicsCategory.pinkBall,
            PhysicsCategory.redBall,
            PhysicsCategory.yellowBall
        ]
        
        let rando = randomInteger()
        let ballImage = randomImageName(imageNumber: rando)
        
        let newBall = SmallBall(imageNamed: ballImage)
        
        newBall.size = CGSize(width: smallDiameter, height: smallDiameter)
        
        let body = SKPhysicsBody(circleOfRadius: 21.0)
        body.categoryBitMask = categories[rando]
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.pinkBall | PhysicsCategory.blueBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall
        body.restitution = 0
        categories.remove(at: rando)
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        
        newBall.physicsBody = body
        
        return newBall
    }
    
    /**
     Add a new ball to the array and to the game scene.
     */
    func addBall() {
        hardness = hardness + 0.1
        
        let newBall = makeBall()
        
        newBall.position = CGPoint(x: size.width / 2, y: size.height - 40)
        
        newBall.inLine = true
        
        addChild(newBall)
        
        startFallTimer(ball: newBall)
        
        balls.append(newBall)
    }
    
    // MARK: utilities
    
    /**
     Generate a random integer between 0 and 4.
     - returns: A number.
     */
    func randomInteger() -> Int {
        return Int(arc4random_uniform(4) + UInt32(1))
    }
    
    /**
     Get a random image name.
     - returns: Name of an image (string).
     */
    func randomImageName(imageNumber: Int) -> String {
        return "ball-\(imageNumber)"
    }
    
    /**
     Convert degrees to radians.
     - parameters:
        - angle: Angle as a CGFloat.
     - returns: Radians as a CGFloat.
     */
    func degreesToRad(angle: CGFloat) -> CGFloat {
        return angle * (CGFloat(Double.pi) / 180)
    }
    
    /**
     Convert radians to degrees.
     - parameters:
        - angle: Radians as a CGFloat.
     - returns: Angle as a CGFloat.
     */
    func radiansToDeg(angle: CGFloat) -> CGFloat {
        return angle * (CGFloat(Double.pi) * 180)
    }
    
    /**
     Get the distance between two points.
     - parameters:
        - pointA: First point.
        - pointB: Second point.
     - returns: Distance as a CGFloat.
     */
    func distanceBetween(pointA: CGPoint, pointB: CGPoint) -> CGFloat {
        return sqrt(pow(pointB.x - pointA.x, 2) + pow(pointB.y - pointA.y, 2))
    }
    
    // []  |
}





