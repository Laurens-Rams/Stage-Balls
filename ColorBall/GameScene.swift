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
                } else if touchX > middle {
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
            for ball in self.startBalls {
                self.getBallValues(ball: ball)
                self.balls.append(ball)
            }
            self.startTimer()
            self.addBall()
        })
    }
    
    /**
     Setup the level's starting balls.
     */
    func setupBalls() {
        // the radians to separate each starting ball by, when placing around the ring
        let incrementRads = degreesToRad(angle: (360 / CGFloat(game.numberStartingBalls)))

        for i in 0..<game.numberStartingBalls {
            let newBall = makeStartBall(index: i)

            newBall.startingPos = CGPoint(x: size.width / 2, y: Circle.position.y)
            newBall.position = newBall.startingPos
            newBall.zPosition = Circle.zPosition - 1

            addChild(newBall)
            startBalls.append(newBall)

            // on odd-numbered stages, we have to tweak the starting radians slightly
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
            handleLargeCollisionWith(newBody: secondBody)
        } else if firstBody.categoryBitMask == secondBody.categoryBitMask {
            if firstBody.isDynamic == true {
                handleSameColorCollision(newBody: firstBody, stuckBody: secondBody)
            } else if secondBody.isDynamic == true {
                handleSameColorCollision(newBody: secondBody, stuckBody: firstBody)
            }
        } else if firstBody.categoryBitMask != secondBody.categoryBitMask {
            if let _ = firstBody.node as? StartingSmallBall, let _ = secondBody.node as? SkullBall {
              print("contact between starter ball and skull")
            } else if let _ = secondBody.node as? StartingSmallBall, let _ = firstBody.node as? SkullBall {
                print("contact between starter ball and skull")
            } else {
                if firstBody.isDynamic == true {
                    handleDifferentColorCollision(newBody: firstBody, stuckBody: secondBody)
                } else if secondBody.isDynamic == true {
                    handleDifferentColorCollision(newBody: secondBody, stuckBody: firstBody)
                }
            }
        }
    }
    
    /**
     Handle a collision between the large circle and a small ball.
     - parameters:
        - newBody: The dynamic body (dynamic body has a larger category bitmask, but represents a small ball).
     */
    func handleLargeCollisionWith(newBody: SKPhysicsBody) {
        if let ball = newBody.node as? SkullBall {
            print("contact between circle and skull ball")
            // add 3 points to the skull's y position
            ball.position = CGPoint(x: ball.position.x, y: ball.position.y + 3)
            getBallValues(ball: ball)
        } else if let ball = newBody.node as? SmallBall {
            print("contact between circle and small ball")
            getBallValues(ball: ball)
            increaseScore(byValue: 1)
        }
    }
    
    /**
     Handle a collision between two small balls of the same color.
     - parameters:
        - newBody: The dynamic body.
        - stuckBody: The non-dynamic body.
     */
    func handleSameColorCollision(newBody: SKPhysicsBody, stuckBody: SKPhysicsBody) {
        print("contact between two same color balls")
        if let ball = newBody.node as? SmallBall {
            increaseScore(byValue: 1)

            let ball2 = stuckBody.node as! SmallBall

            ball.inContactWith.append(contentsOf: ball2.inContactWith)
            ball.inContactWith.append(ball2)

            // save the ideal (snapped) x,y position before we empty ball2's inContactWith
            let newPos = getIdealBallPosition(fromBall: ball2)
            
            ball2.inContactWith.removeAll()
            if ball.inContactWith.count >= 3 {
                zapBalls(ball: ball)
                return
            }

            ball.position = newPos
            getBallValues(ball: ball)
        }
    }
    
    /**
     Handle a collision between two small balls of differing colors.
     - parameters:
        - newBody: The dynamic body.
        - stuckBody: The non-dynamic body.
     */
    func handleDifferentColorCollision(newBody: SKPhysicsBody, stuckBody: SKPhysicsBody) {
        print("contact between two different color balls")
        if let stuckBall = stuckBody.node as? SmallBall, let newBall = newBody.node as? SmallBall {
            let newPos = getIdealBallPosition(fromBall: stuckBall)
            newBall.position = newPos
            getBallValues(ball: newBall)
            
            // total length of each color action
            let totalTime = 0.5
            // fade to red actions
            let newDeadAction = getColorChangeActionForNode(originalColor: newBall.fillColor, endColor: UIColor.red, totalTime: totalTime)
            // fade back to original color actions
            let newReturnAction = getColorChangeActionForNode(originalColor: UIColor.red, endColor: newBall.fillColor, totalTime: totalTime)
            
            // create the camera zoom action
            let cameraStart = camera!.position
            let crashPosition = CGPoint(x: cameraStart.x, y: cameraStart.y + 121.0)
            let offsetZoom = getOffsetZoomAnimation(startingPoint: cameraStart, endingPoint: crashPosition, scaleFactor: 0.9, totalTime: 0.2)
            
            let shakeLeft = getMoveAction(moveX: -30.0, moveY: 0.0, totalTime: 0.2)
            let shakeRight = getMoveAction(moveX: 30.0, moveY: 0.0, totalTime: 0.2)
            
            camera?.run(SKAction.sequence([
                offsetZoom,
                shakeLeft,
                shakeRight,
                shakeRight,
                shakeLeft,
                offsetZoom.reversed()
            ]))
            
            // run the actions as a sequence on each node
            newBall.run(SKAction.sequence([newDeadAction, newReturnAction]))

            // start the timer
            let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { t in
                self.handleGameOver()
            })
            // TODO: zoom to contact point
        }
    }
    
    func getMoveAction(moveX: CGFloat, moveY: CGFloat, totalTime: Double) -> SKAction {
        return SKAction.moveBy(x: moveX, y: moveY, duration: totalTime)
    }
    
    func getOffsetZoomAnimation(startingPoint: CGPoint, endingPoint: CGPoint, scaleFactor: CGFloat, totalTime: Double) -> SKAction {
        return SKAction.customAction(withDuration: totalTime, actionBlock: { node, time in
            // get the ratio of elapsed time
            let fraction = time / CGFloat(totalTime)
            // get the ideal values for the node's next position
            let newX = CGFloat.lerp(a: startingPoint.x, b: endingPoint.x, fraction: fraction)
            let newY = CGFloat.lerp(a: startingPoint.y, b: endingPoint.y, fraction: fraction)
            // set the node the the next position
            node.position = CGPoint(x: newX, y: newY)
            // also lerp the zoom at the same time
            if let node = node as? SKCameraNode {
                let newScale = CGFloat.lerp(a: 1.0, b: scaleFactor, fraction: fraction)
                node.setScale(newScale)
            }
        })
    }
    
    func getZoomAction(scaleFactor: CGFloat, totalTime: Double) -> SKAction {
        return SKAction.scale(by: scaleFactor, duration: totalTime)
    }
    
    func getShakeActionForNode(startPosition: CGPoint, endPosition: CGFloat, totalTime: Double) -> SKAction {
        return SKAction.customAction(withDuration: totalTime, actionBlock: { node, time in
            // do stuff with the position here
        })
    }
    
    func getColorChangeActionForNode(originalColor: UIColor, endColor: UIColor, totalTime: Double) -> SKAction {
        // return a new action to run on the node
        return SKAction.customAction(withDuration: totalTime, actionBlock: { node, time in
            // get the total difference between starting color and ending color for each of RGB
            let fraction = time / CGFloat(totalTime)
            if let red = originalColor.rgb()?.red, let green = originalColor.rgb()?.green, let blue = originalColor.rgb()?.blue, let node = node as? SKShapeNode {
                // for the time elapsed, get the value for the current difference amount, in each color value
                let red3 = CGFloat.lerp(a: red, b: (endColor.rgb()?.red)!, fraction: fraction)
                let green3 = CGFloat.lerp(a: green, b: (endColor.rgb()?.green)!, fraction: fraction)
                let blue3 = CGFloat.lerp(a: blue, b: (endColor.rgb()?.blue)!, fraction: fraction)
                let transitionColor = UIColor.init(red: red3, green: green3, blue: blue3, alpha: 1.0)
                node.fillColor = transitionColor
            }
            // example: starting red 60, ending red 200, total difference 140, time elapsed is 1second, we should be at 60 + 140/2 for red
        })
    }
    
    func handleGameOver() {
        isPaused = true
        ballTimer?.invalidate()
        gameDelegate?.gameover()
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
            if let starter = contactedBall as? StartingSmallBall, starter.isStarter == true {
                let skullBall = makeSkullBall()
                let ballCoords = getIdealSkullPosition(fromBall: starter)
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

        removeChildren(in: ball.inContactWith)

        if let position = balls.index(of: ball) {
            balls.remove(at: position)
        }

        removeChildren(in: [ball])
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
        
        // generate a random integer betweeb 0 and 3
        let rando = index < game.ballColors.count - 1 ? index : randomInteger(upperBound: nil) - 1
        
        // use the random integer to get a ball type and a ball color
        let ballType = BallColor(rawValue: rando)!
        let ballColor = game.ballColors[rando]
        
        game.incrementBallType(type: ballType)
        
        let newBall = StartingSmallBall(circleOfRadius: game.smallDiameter / 2)
        // set the fill color to our random color
        newBall.fillColor = ballColor
        // don't fill the outline
        newBall.lineWidth = 0.0

        let body = SKPhysicsBody(circleOfRadius: 21.0)
        // our physics categories are offset by 1, the first entry in the arryay being the bitmask for the player's circle ball
        body.categoryBitMask = categories[rando + 1]
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.pinkBall | PhysicsCategory.blueBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall
        body.restitution = 0
        categories.remove(at: rando)
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        body.isDynamic = false
        newBall.physicsBody = body
        newBall.colorType = ballType
        
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
        
        let ballColor = game.ballColors[rando]

        let newBall = SmallBall(circleOfRadius: game.smallDiameter / 2)
        newBall.fillColor = ballColor
        newBall.lineWidth = 0.0
        
        let body = SKPhysicsBody(circleOfRadius: 21.0)
        // our physics categories are offset by 1, the first entry in the arryay being the bitmask for the player's circle ball
        body.categoryBitMask = categories[rando + 1]
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
        let newBall = SkullBall(circleOfRadius: game.smallDiameter / 2)
        newBall.fillColor = UIColor.black
        newBall.lineWidth = 0.0

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
     Generate a random integer between 0 and 3.
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
        let rowMultiplier = CGFloat(ball.inContactWith.count) + 1.5
        let yPos = Circle.position.y + (game.playerDiameter / 2) + (game.smallDiameter * rowMultiplier)
        return CGPoint(x: xPos, y: yPos)
    }
    
    /**
     Get the ideal position for a ball, based on the ball that it just hit.
     - parameters:
     - fromBall: SmallBall that was hit.
     - returns: CGPoint to snap the newest ball to.
     */
    func getIdealSkullPosition(fromBall ball: SmallBall) -> CGPoint {
        let xPos = size.width / 2
        let rowMultiplier = CGFloat(ball.inContactWith.count) + 0.5
        let yPos = Circle.position.y + (game.playerDiameter / 2) + (game.smallDiameter * rowMultiplier)
        return CGPoint(x: xPos, y: yPos)
    }
    
    // []  |
}





