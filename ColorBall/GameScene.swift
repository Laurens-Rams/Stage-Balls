//
//  GameScene.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/15/17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import Darwin
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: class properties
    
    var game: Game!
    
    // player (large circle)
    let Circle = PlayerCircle(imageNamed: "circle")
    
    // direction of rotation
    var direction: CGFloat = -1.0
    
    // ball settings
    var hardness: Float = 0.0
    
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
    var gameDelegate: StartGameDelegate?
    
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
        backgroundColor = game.backgroundColor
        
        let startX = CGFloat((size.width / 2))
        let startY = CGFloat((size.height / 2.5))
        let startpos = CGPoint(x: startX, y: startY)
        Circle.position = startpos
        Circle.size = CGSize(width: game.playerDiameter, height: game.playerDiameter)
        
        
        let body = SKPhysicsBody(texture: Circle.texture!, size: CGSize(width: Circle.size.width - 2, height: Circle.size.height - 2))
        body.categoryBitMask = PhysicsCategory.circleBall
        body.allowsRotation = true
        body.pinned = true
        body.isDynamic = false
        Circle.physicsBody = body
        
        setupBalls()
        addChild(Circle)
        
        setupFirstFallTimer()
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
                    newY = ball.position.y - (4.0 + CGFloat(game.gravityMultiplier))
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
     Set the timer for dropping the first ball.
     */
    func setupFirstFallTimer() {
        //timer sets when the first ball should fall
        let _ = Timer.scheduledTimer(withTimeInterval: 1.85, repeats: false, block: {timer in
            for i in 0..<self.game.numberStartingBalls {
                self.getBallValues(ball: self.startBalls[i])
                self.balls.append(self.startBalls[i])
            }
            self.startTimer()
            self.addBall()
        })
    }
    
    /**
     Setup the level's starting balls.
     */
    func setupBalls() {
        let incrementRads = degreesToRad(angle: (360 / CGFloat(game.numberStartingBalls)))
        for i in 0..<game.numberStartingBalls {
            let newBall = makeStartBall(index: i)
            newBall.startingPos = CGPoint(x: size.width / 2, y: Circle.position.y)
            newBall.position = newBall.startingPos
            newBall.zPosition = Circle.zPosition - 1
            addChild(newBall)
            startBalls.append(newBall)
            let startRads = (game.stage % 2 == 0) ? (incrementRads * CGFloat(i + 1)) : (incrementRads * CGFloat(i + 1)) - (incrementRads / 4)
            let newX = (100 + (game.smallDiameter / 2)) * cos(startRads) + Circle.position.x
            let newY = (100 + (game.smallDiameter / 2)) * sin(startRads) + Circle.position.y
            newBall.startRads =  startRads * -1
            newBall.insidePos = CGPoint(x: newX, y: newY)
            newBall.startDistance =  100 + (game.smallDiameter / 2)
        }
        for i in 0..<startBalls.count {
            animateBall(ball: startBalls[i])
        }
    }
    
    /**
     Teardown the stage.
     */
    func cleanupBalls() {
        for i in 0..<balls.count {
            if let skullBall = balls[i] as? StartingSmallBall {
                let isLast = (i == balls.count - 1)
                let action = getReverseAnimation(ball: skullBall)
                skullBall.run(action) {
                    skullBall.removeFromParent()
                    if isLast {
                        self.removeChildren(in: self.balls)
                        self.removeChildren(in: self.startBalls)
                        self.balls.removeAll()
                        self.startBalls.removeAll()
                        self.gameDelegate?.handleNextStage()
                    }
                }
            }
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
     Animate a ball from the outside of the large circle, inward.
     - parameters:
     - ball: A StartingSmallBall object.
     - returns: The SKAction to reverse animate the ball.
     */
    func getReverseAnimation(ball: StartingSmallBall) -> SKAction {
        return SKAction.move(to: ball.startingPos, duration: 1.2)
    }
    
    /**
     Start the repeating timer for adding a new ball to the scene.
     */
    func startTimer() {
        if ballTimer == nil {
            let interval = game.ballInterval * game.speedMultiplier
            ballTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(addBall), userInfo: nil, repeats: true)
        } else {
            
        }
        allowToMove = true
    }

    
    /**
     Start a timer for allowing a ball to fall downward.
     - parameters:
        - ball: A SmallBall object.
     */
    func startFallTimer(ball: SmallBall) {
        //for how long they stay up (0.0 - 1.8)
        let interval = 1.0 * game.speedMultiplier
        fallTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: {
            timer in
            
            ball.inLine = false
        })
    }
    
    func getCircleValues() {
        if !canMove {
            Circle.lastTickPosition = Circle.zRotation
            Circle.nextTickPosition = Circle.lastTickPosition + (((CGFloat(Double.pi) * 2) / CGFloat(game.numberStartingBalls)) * direction)
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
            handleLargeCollisionWith(smallBody: secondBody)
            return
        } else if firstBody.categoryBitMask == secondBody.categoryBitMask {
            if firstBody.isDynamic == true {
                print("small ball contact")
                if let ball = firstBody.node as? SmallBall {
                    let ball2 = secondBody.node as! SmallBall
                    ball.inContactWith.append(contentsOf: ball2.inContactWith)
                    ball.inContactWith.append(ball2)
                    ball2.inContactWith.removeAll()
                    if ball.inContactWith.count >= 3 {
                        zapBalls(ball: ball)
                        return
                    }
                    let newPos = getIdealBallPosition(fromBall: ball2)
                    ball.position = newPos
                    getBallValues(ball: ball)
                }
                increaseScore(byValue: 1)
            } else if secondBody.isDynamic == true {
                print("contact between small balls")
                if let ball = secondBody.node as? SmallBall {
                    let ball2 = firstBody.node as! SmallBall
                    ball.inContactWith.append(contentsOf: ball2.inContactWith)
                    ball.inContactWith.append(ball2)
                    ball2.inContactWith.removeAll()
                    if ball.inContactWith.count >= 3 {
                       zapBalls(ball: ball)
                        return
                    }
                    ball.position = getIdealBallPosition(fromBall: ball2)
                    getBallValues(ball: ball)
                }
                increaseScore(byValue: 1)
            }
            return
        } else if firstBody.categoryBitMask != secondBody.categoryBitMask {
            if let _ = firstBody.node as? StartingSmallBall, let _ = secondBody.node as? SkullBall {
              print("contact between starter ball and skull")
            } else if let _ = secondBody.node as? StartingSmallBall, let _ = firstBody.node as? SkullBall {
                print("contact between starter ball and skull")
            } else {
                self.isPaused = true
                self.ballTimer?.invalidate()
                gameDelegate?.gameover()
            }
        }
    }
    
    func handleLargeCollisionWith(smallBody body: SKPhysicsBody) {
        if let ball = body.node as? SkullBall {
            print("contact between circle and skull ball")
            ball.position = CGPoint(x: ball.position.x, y: ball.position.y + 4)
            getBallValues(ball: ball)
        } else if let ball = body.node as? SmallBall {
            print("contact between circle and small ball")
            getBallValues(ball: ball)
            increaseScore(byValue: 1)
        }
    }
    
    func handleCollision(firstBody: SKPhysicsBody, secondBody: SKPhysicsBody) {
        if let ball = firstBody.node as? SmallBall {
            let ball2 = secondBody.node as! SmallBall
            ball.inContactWith.append(contentsOf: ball2.inContactWith)
            ball.inContactWith.append(ball2)
            ball2.inContactWith.removeAll()
            if ball.inContactWith.count >= 3 {
                zapBalls(ball: ball)
                return
            }
            let newPos = getIdealBallPosition(fromBall: ball2)
            ball.position = newPos
            getBallValues(ball: ball)
        }
        increaseScore(byValue: 1)
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
            if let starter = contactedBall as? StartingSmallBall {
                let ballCoords = CGPoint(x: starter.position.x, y: starter.position.y)
                let skullBall = makeSkullBall()
                skullBall.startingPos = starter.startingPos
                skullBall.position = ballCoords
                balls.append(skullBall)
                addChild(skullBall)
                
            }
            if let position = balls.index(of: contactedBall) {
                balls.remove(at: position)
                contactedBall.physicsBody = nil
            }
        }
        
        game.decrementBallType(type: ball.colorType, byNumber: 4)

        self.removeChildren(in: ball.inContactWith)

        if let position = balls.index(of: ball) {
            balls.remove(at: position)
        }

        self.removeChildren(in: [ball])
        increaseScore(byValue: 2)
    }
    
    func moveAlongVector(ballA: SmallBall, ballB: SKSpriteNode) {
        let dist = distanceBetween(pointA: ballA.position, pointB: ballB.position)
        let v = game.smallDiameter - dist
        let vect = CGVector(dx: (ballA.position.x - ballB.position.x) * v / dist, dy: (ballA.position.y - ballB.position.y) * v / dist)
        ballA.position = CGPoint(x: ballA.position.x + vect.dx, y: ballB.position.y + vect.dy)
    }
    
    func checkDistance(ballA: SmallBall, ballB: SKSpriteNode) -> Bool {
        let distance = distanceBetween(pointA: ballA.position, pointB: ballB.position)
        if distance < game.smallDiameter {
            return false
        }
        return true
    }

    func getBallValues(ball: SmallBall) {
        if ball.stuck {
            return
        }
        ball.stuck = true
        if ball.startDistance == 0 {
            ball.startDistance = ball.position.y - Circle.position.y
        }
        // let angle = atan2(ball.position.y - Circle.position.y,
                          //ball.position.x - Circle.position.x)
        if ball.startRads == 0 {
            ball.startRads = Circle.zRotation - degreesToRad(angle: 90.0)
        }
        // balls.append(ball)
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
        
        let rando = index < 4 ? index + 1 : randomInteger(upperBound: nil)
        
        let ballColor = BallColor(rawValue: rando)!
        
        game.incrementBallType(type: ballColor)
        
        let ballImage = randomImageName(imageNumber: rando)
        
        let newBall = StartingSmallBall(imageNamed: ballImage)
        
        newBall.size = CGSize(width: game.smallDiameter, height: game.smallDiameter)
        
        let body = SKPhysicsBody(circleOfRadius: 21.0)
        body.categoryBitMask = categories[rando]
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.pinkBall | PhysicsCategory.blueBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall
        body.restitution = 0
        categories.remove(at: rando)
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        body.isDynamic = false
        newBall.physicsBody = body
        newBall.colorType = ballColor
        
        return newBall
    }
    
    func checkIfOnlySkulls() -> Bool {
        var onlySkulls = true
        for ball in balls {
            if ball.colorType != BallColor.skull {
                onlySkulls = false
                break
            }
        }
        return onlySkulls
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
        
        var rando = randomInteger(upperBound: nil)
        var ballType = BallColor(rawValue: rando)!
        
        while (game.getCountForType(type: ballType) == 0) {
            rando = randomInteger(upperBound: nil)
            ballType = BallColor(rawValue: rando)!
        }
        
        game.incrementBallType(type: ballType)
        
        let ballImage = randomImageName(imageNumber: rando)
        
        let newBall = SmallBall(imageNamed: ballImage)
        
        newBall.size = CGSize(width: game.smallDiameter, height: game.smallDiameter)
        
        let body = SKPhysicsBody(circleOfRadius: 21.0)
        body.categoryBitMask = categories[rando]
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.pinkBall | PhysicsCategory.blueBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall
        body.restitution = 0
        categories.remove(at: rando)
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        
        newBall.physicsBody = body
        newBall.colorType = ballType
        
        return newBall
    }
    
    /**
     Create a small ball to drop from the top.
     - returns: A new SmallBall object.
     */
    func makeSkullBall() -> SkullBall {
        let newBall = SkullBall(imageNamed: "skull")
        
        newBall.size = CGSize(width: game.smallDiameter, height: game.smallDiameter)
        
        let body = SKPhysicsBody(circleOfRadius: 21.0)
        body.categoryBitMask = PhysicsCategory.skullBall
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.pinkBall | PhysicsCategory.blueBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall
        body.restitution = 0
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        
        newBall.physicsBody = body
        
        newBall.colorType = BallColor.skull
        
        game.incrementBallType(type: .skull)
        
        return newBall
    }
    
    /**
     Add a new ball to the array and to the game scene if we can.
     */
    @objc func addBall() {
        if checkIfOnlySkulls() {
            cleanupBalls()
        } else {
            hardness = hardness + 0.1
            
            let newBall = makeBall()
            
            newBall.position = CGPoint(x: size.width / 2, y: size.height - 40)
            
            newBall.inLine = true
            
            addChild(newBall)
            
            startFallTimer(ball: newBall)
            
            balls.append(newBall)
        }
    }
    
    func handleNextStage() {
        cleanupBalls()
    }
    
    // MARK: utilities
    
    /**
     Generate a random integer between 1 and 4.
     - parameters:
     - upperBound: Optional max.
     - returns: A number.
     */
    func randomInteger(upperBound: Int?) -> Int {
        if let bound = upperBound {
             return Int(arc4random_uniform(UInt32(bound)) + UInt32(1))
        }
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
    
    /**
     Get the ideal position for a ball, based on the ball that it just hit.
     - parameters:
     - fromBall: SmallBall that was hit.
     - returns: CGPoint to snap the newest ball to.
     */
    func getIdealBallPosition(fromBall ball: SmallBall) -> CGPoint {
        let xPos = size.width / 2
        let yPos = ball.position.y + game.smallDiameter
        return CGPoint(x: xPos, y: yPos)
    }
    
    // []  |
}





