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

// TODOS:
// - column snap top ball and/or distance calc points to columns - 1
// - get rid of one of the boolean controls
// - touching twice to start moving again?
// - make interaction animations (particle explosion, etc)
// - Search terms: Sk particle emitters, sk particle explosions

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: class properties
    
    var game: Game!
    var slotsOnCircle = 30
    // player (large circle)
    let Circle = PlayerCircle(imageNamed: "circle")
    let ring = PlayerCircle(imageNamed: "ring")
    
    // direction of rotation
    var direction: CGFloat = -1.0
    
    // ball settings
    var hardness: Float = 0.0
    
    // ball arrays
    var fallingBalls = [SmallBall]()
    
    // available slots around circle
    var slots = [Slot]()
    
    // actions
    var rotation: SKAction!
    var runRotation: SKAction!
    var fall: SKAction!
    
    // timers
    var ballTimer: Timer?
    var fallTimer: Timer!
    
    // control variables
    var isTouching = false
    var isHolding = false
    // TODO: trim one of these though:
    var allowToMove = false
    var canMove = false

    // game loop update values
    var lastUpdateTime: TimeInterval = 0
    var dt: CGFloat = 0.0
    
    // delegates
    var scoreKeeper: GameScoreDelegate?
    var gameDelegate: StartGameDelegate?
    
    let skullTexture = SKTexture(image: #imageLiteral(resourceName: "skull"))
    
    deinit {
        print("deinit game scene")
    }
    
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

        updateSlots()
        updateBalls(dt: dt)
    }
    
    override func didMove(to view: SKView) {
        isPaused = false
        //changes gravity spped up !!!not gravity//
        physicsWorld.gravity = CGVector(dx: 0, dy: 0.0)
        physicsWorld.contactDelegate = self
        backgroundColor = game.backgroundColor
        
        let startX = CGFloat((size.width / 2))
        let startY = CGFloat((size.height / 3))
        let startpos = CGPoint(x: startX, y: startY)
        Circle.position = startpos
        Circle.size = CGSize(width: game.playerDiameter, height: game.playerDiameter)
        
        ring.position = CGPoint(x: size.width / 2, y: size.height - 60)
        ring.size = CGSize(width: 65, height: 65)
        
        let body = SKPhysicsBody(texture: Circle.texture!, size: CGSize(width: Circle.size.width - 2, height: Circle.size.height - 2))
        body.categoryBitMask = PhysicsCategory.circleBall
        body.allowsRotation = true
        body.pinned = true
        body.isDynamic = false
        Circle.physicsBody = body

        game.resetAll()

        setupSlots()

        addChild(Circle)
        
        setupFirstFallTimer()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       if allowToMove == true && !isTouching && !isHolding {
            isTouching = true
            isHolding = true

            let middle = size.width / 2

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
        isHolding = false
        // isTouching = false
    }
    
    // MARK: custom update, animation, and movement methods
    
    /**
     Function to update the circle's rotation.
    - parameters:
        - dt: Last calculated delta time
     */
    func updateCircle(dt: CGFloat) {
        //change animation
        let increment = (((CGFloat(Double.pi) * 1.0) * direction)) * dt

        Circle.zRotation = Circle.zRotation + increment
        Circle.distance = Circle.distance + increment
        
        if (fabs(Circle.distance) >= fabs(Circle.nextTickPosition - Circle.lastTickPosition)) {
            canMove = false
            Circle.distance = 0
            Circle.zRotation = Circle.nextTickPosition
            if isHolding {
                getCircleValues()
            } else {
                isTouching = false
            }
        }
    }
    
    func updateSlots() {
        for slot in slots {
            slot.update(player: Circle)
        }
    }
    
    /**
     Update the position of every applicable ball on the screen.
     - parameters:
        - dt: Last calculated delta time
     */
    func updateBalls(dt: CGFloat) {
        for ball in fallingBalls {
            if !ball.inLine && !ball.stuck {
                let newX = ball.position.x
                let newY = ball.position.y - (4.0 + CGFloat(game.gravityMultiplier))
                ball.position = CGPoint(x: newX, y: newY)
            }
        }
    }
    
    /**
     Set the timer for dropping the first ball.
     */
    func setupFirstFallTimer() {
        //timer sets when the first ball should fall
        let _ = Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false, block: {timer in
            self.addBall()
            self.allowToMove = true
        })
    }
    
    func setupSlots() {
        // the radians to separate each starting ball by, when placing around the ring
        let incrementRads = degreesToRad(angle: 360 / CGFloat(slotsOnCircle))
        let startPosition = CGPoint(x: size.width / 2, y: Circle.position.y)
        let startDistance = (game.playerDiameter / 2) + (game.smallDiameter / 2)

        for i in 0..<game.numberStartingBalls {
            let startRads = incrementRads * CGFloat(i) - degreesToRad(angle: 90.0)
            let newX = (startDistance) * cos(Circle.zRotation - startRads) + Circle.position.x
            let newY = (startDistance) * sin(Circle.zRotation - startRads) + Circle.position.y
            let targetPosition = CGPoint(x: newX, y: newY)

            let slot = BaseSlot(position: targetPosition, startPosition: startPosition, insidePosition: targetPosition, startRads: startRads, isStarter: true, distance: startDistance)
            slot.columnNumber = i
            
            let ball = makeStartBall(index: i)
            ball.stuck = false
            slot.setBall(ball: ball)
            ball.position = CGPoint(x: size.width / 2, y: Circle.position.y)
            ball.zPosition = Circle.zPosition - 1
            addChild(ball)

            slots.append(slot)
            
            for j in 0..<game.slotsPerColumn - 1 {
                let updatedDistance = startDistance + (game.smallDiameter * CGFloat(j + 1))
                let slotX = (updatedDistance) * cos(Circle.zRotation - startRads) + Circle.position.x
                let slotY = (updatedDistance) * sin(Circle.zRotation - startRads) + Circle.position.y
                let slotPos = CGPoint(x: slotX, y: slotY)
                let slot = Slot(position: slotPos, startRads: startRads, isStarter: false, distance: updatedDistance)
                slot.columnNumber = i
                slots.append(slot)
            }
        }
        
        for slot in slots {
            if let slot = slot as? BaseSlot {
                animateSlotBall(slot: slot)
            }
        }
    }
    
    /**
     Teardown the stage.
     */
    func cleanupBalls() {
        let skulls = slots.filter({ s in
            return s.containsSkull == true
        }).flatMap({ s in
            return (s.ball as? SkullBall)!
        })

        for i in 0..<skulls.count {
            let isLast = (i == skulls.count - 1)
            let action = getReverseAnimation(ball: skulls[i])
            skulls[i].run(action) {
                skulls[i].removeFromParent()
                if isLast {
                    self.gameDelegate?.handleNextStage()
                    self.game.decrementBallType(type: BallColor.skull, byNumber: self.game.skulls)
                }
            }
        }
    }
    
    /**
     Animate a ball from the inside of the large circle, outward.
     - parameters:
     - ball: A StartingSmallBall object.
     */
    func animateSlotBall(slot: BaseSlot) {
        let action = SKAction.move(to: slot.insidePosition, duration: 1.2)
        slot.ball!.run(action, completion: {
            slot.ball!.stuck = true
        })
    }
    
    /**
     Animate a ball from the outside of the large circle, inward.
     - parameters:
     - ball: A StartingSmallBall object.
     - returns: The SKAction to reverse animate the ball.
     */
    func getReverseAnimation(ball: SkullBall) -> SKAction {
        return SKAction.move(to: ball.startingPos, duration: 1.2)
    }
 
    /**
     Start a timer for allowing a ball to fall downward.
     - parameters:
        - ball: A SmallBall object.
     */
    func startFallTimer(ball: SmallBall) {

        //for how long they stay up (0.0 - 1.8)
        // if you don't want these to be linked, create a new variable in the game object for the fall multiplier (this could cause in-air crashes though)
        let interval = 1.2 * game.speedMultiplier
        fallTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: {
            timer in
            ball.inLine = false
        })
    }
    
    func getCircleValues() {
        Circle.lastTickPosition = Circle.zRotation
        Circle.nextTickPosition = Circle.lastTickPosition + (((CGFloat(Double.pi) * 2) / CGFloat(slotsOnCircle) * direction))
        canMove = true
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
                createExplosion(onBody: firstBody)
            } else if secondBody.isDynamic == true {
                handleSameColorCollision(newBody: secondBody, stuckBody: firstBody)
                createExplosion(onBody: secondBody)
            }
            // create an explision at the point of contact
            // createExplosion(pointOfContact: contact.contactPoint)
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

    func createExplosion(onBody body: SKPhysicsBody) {
        if let explosionPath = Bundle.main.path(forResource: "Spark", ofType: "sks"),
            let explosion = NSKeyedUnarchiver.unarchiveObject(withFile: explosionPath) as? SKEmitterNode,
            let ball = body.node as? SmallBall {
            let point = CGPoint(x: ball.x, y: ball.y - (game.smallDiameter / 2))
            explosion.position = point
            ball.addChild(explosion)
        }
    }
    
    func createExplosion(onBall ball: SKNode) {
        if let explosionPath = Bundle.main.path(forResource: "Spark", ofType: "sks"),
            let explosion = NSKeyedUnarchiver.unarchiveObject(withFile: explosionPath) as? SKEmitterNode,
            let ball = ball as? SmallBall {
            let point = CGPoint(x: ball.x, y: ball.y - (game.smallDiameter / 2))
            explosion.position = point
            ball.addChild(explosion)
        }
    }

    func getFirstSlotInColumn(num: Int) -> BaseSlot {
        return slots.first(where: { s in
            return s.columnNumber == num
        }) as! BaseSlot
    }
    
    func getSlotsInColumn(num: Int) -> [Slot] {
        return slots.filter{ s in
            return s.columnNumber == num
        }
    }
    
    func getFirstOpenSlot(slotList: [Slot]) -> Slot? {
        return slotList.first(where: { s in
            return s.ball == nil
        })
    }
    
    func getClosestOpenSlot(toPoint point: CGPoint) -> Slot {
        var closestSlot = slots[0]
        var shortestDistance = size.width

        for i in 0..<slots.count {
            let dist = distanceBetween(pointA: point, pointB: slots[i].position)
            if dist < shortestDistance {
                shortestDistance = dist
                closestSlot = slots[i]
            }
        }

        if closestSlot.ball != nil {
            let slotsInColumn = getSlotsInColumn(num: closestSlot.columnNumber)
            if let firstOpen = getFirstOpenSlot(slotList: slotsInColumn) {
                return firstOpen
            }
        }

        return closestSlot
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
        } else if let ball = newBody.node as? SmallBall {
            print("contact between circle and small ball")
            if (game.endGameOnCircleCollision) {
                startGameOverSequence(newBall: ball)
            }
        }
    }
    
    func checkForZaps(colNumber: Int, completion: @escaping () -> Void) {
        let colSlots = getSlotsInColumn(num: colNumber)

        if getFirstOpenSlot(slotList: colSlots) == nil {
            game.decrementBallType(type: colSlots[0].colorType, byNumber: game.slotsPerColumn)
            // map the column's slots to an array of the balls they contain
            let zapBalls = colSlots.map({ $0.ball }) as! [SKNode]

            // reset all slots in the column so we can add balls to them again
            for slot in colSlots {
                slot.ball = nil
            }

            // variable to count loop iterations
            var index = 0

            // loop through the array of balls we should be zapping
            for _ in zapBalls {
                // add one to the loop count
                index += 1

                // get a reference to the ball we want to animate this iteration
                let ball = zapBalls[zapBalls.count - index]

                // create the wait action (the delay before we start falling)
                let wait = SKAction.wait(forDuration: 0.25 * Double(index - 1))

                // create the move action
                let fall = SKAction.moveBy(x: 0, y: -game.smallDiameter, duration: 0.25)

                // add the delay and move actions to a sequence
                let sequence = SKAction.sequence([wait, fall])

                // if we're on the last ball, we want to remove the stack afterwards
                if (index == zapBalls.count) {
                    ball.run(sequence) {
                        self.removeChildren(in: zapBalls)
                        self.addSkull(toColumn: colNumber)
                        completion()
                    }
                } else {
                    // otherwise just run the delay/move sequence
                    ball.run(sequence) {
                        self.removeChildren(in: [ball])
                    }
                }
            }
        } else {
            completion()
        }
    }
    
    func addSkull(toColumn num: Int) {
        let skullSlot = getFirstSlotInColumn(num: num)
        let skullBall = makeSkullBall()
        skullBall.insidePos = skullSlot.insidePosition
        skullBall.startingPos = skullSlot.startPosition
        skullSlot.ball = skullBall
        skullBall.position = skullSlot.position
        skullBall.stuck = true
        skullBall.zPosition = -100
        skullSlot.containsSkull = true
        addChild(skullBall)
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
            let slot = getClosestOpenSlot(toPoint: ball.position)
            ball.position = slot.position
            slot.ball = ball
            ball.stuck = true
            ball.physicsBody?.isDynamic = false
            checkForZaps(colNumber: slot.columnNumber) {
                self.addBall()
            }
        }
    }
    
    func startGameOverSequence(newBall: SmallBall) {
        allowToMove = false
        canMove = false
        newBall.stuck = true
        newBall.physicsBody?.isDynamic = false
        gameDelegate?.gameoverdesign()
        // total length of each color action
        // let totalTime = 0.5
        // fade to red actions
        //let newDeadAction = getColorChangeActionForNode(originalColor: newBall.fillColor, endColor: UIColor.red, totalTime: totalTime)
        // fade back to original color actions
        //let newReturnAction = getColorChangeActionForNode(originalColor: UIColor.red, endColor: newBall.fillColor, totalTime: totalTime)
        
        // create the camera zoom action
        
        let shakeLeft = getMoveAction(moveX: -10.0, moveY: 0.0, totalTime: 0.09)
        let shakeRight = getMoveAction(moveX: 10.0, moveY: 0.0, totalTime: 0.09)
        //let popOut = SKAction.scale(to: 1.2, duration: 0.25)
       // let popIn = SKAction.scale(to: 1.0, duration: 0.25)
        //pop
        //newBall.run(SKAction.sequence([popOut, popIn]))
        camera?.run(SKAction.sequence([
            //popIn,
            //popOut,
            shakeLeft,
            shakeRight,
            shakeRight,
            shakeLeft,
            shakeLeft,
            shakeRight,
            shakeRight,
            shakeLeft
            
            ]))
        // run the actions as a sequence on each node
        //for red
        //newBall.run(SKAction.sequence([]))
        
        // start the timer
        UIView.animate(withDuration: 0.8, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.ring.alpha = 0.0
        }, completion: nil)
        
        let _ = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false, block: { t in
            self.handleGameOver()
        })
    }
    
    /**
     Handle a collision between two small balls of differing colors.
     - parameters:
        - newBody: The dynamic body.
        - stuckBody: The non-dynamic body.
     */
    func handleDifferentColorCollision(newBody: SKPhysicsBody, stuckBody: SKPhysicsBody) {
        print("contact between two different color balls")
        if let newBall = newBody.node as? SmallBall {
            startGameOverSequence(newBall: newBall)
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
        
        // generate a random integer betweeb 0 and 7
        let rando = index < game.ballColors.count ? index : randomInteger(upperBound: nil) - 1
        
        // use the random integer to get a ball type and a ball colorr
        let ballType = BallColor(rawValue: rando)!

        game.incrementBallType(type: ballType)
        print("ballcolors", game.ballColors.count, rando)
        print(game.blues)
        print(game.pinks)
        print(game.reds)
        print(game.yellows)
        print(game.greens)
        print(game.oranges)
        print(game.purples)
        print(game.greys)
        
        let newBall = StartingSmallBall(circleOfRadius: game.smallDiameter / 2)
        // set the fill color to our random color
        newBall.fillColor = game.ballColors[rando]
        // don't fill the outline
        newBall.lineWidth = 0.0

        let body = SKPhysicsBody(circleOfRadius: game.smallDiameter / 2)
        // our physics categories are offset by 1, the first entry in the arryay being the bitmask for the player's circle ball
        body.categoryBitMask = categories[rando + 1]
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.blueBall | PhysicsCategory.pinkBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall | PhysicsCategory.greenBall | PhysicsCategory.orangeBall | PhysicsCategory.purpleBall | PhysicsCategory.greyBall
        body.restitution = 0
        print("rando:", rando)
        categories.remove(at: rando)
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        body.isDynamic = false
        newBall.physicsBody = body
        newBall.colorType = ballType
        
        let positiontomove = CGPoint(x: size.width / 2, y: size.height - 60)
        
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
            PhysicsCategory.yellowBall,
            PhysicsCategory.greenBall,
            PhysicsCategory.orangeBall,
            PhysicsCategory.purpleBall,
            PhysicsCategory.greyBall,
        ]
        var rando = randomInteger(upperBound: nil) - 1
        var ballType = BallColor(rawValue: rando)!
        
        while (game.getCountForType(type: ballType) == 0) {
            rando = randomInteger(upperBound: nil) - 1
            ballType = BallColor(rawValue: rando)!
        }
        
        print("=======> making a new ball of type:", ballType.name())
        print("=======> old count for this type:", game.getCountForType(type: ballType))
        game.incrementBallType(type: ballType)
        print("=======> new count for this type:", game.getCountForType(type: ballType))

        let newBall = SmallBall(circleOfRadius: game.smallDiameter / 2)
        newBall.fillColor = game.ballColors[rando]
        newBall.lineWidth = 0.0
        
        let body = SKPhysicsBody(circleOfRadius: game.smallDiameter / 2)
        // our physics categories are offset by 1, the first entry in the arryay being the bitmask for the player's circle ball
        body.categoryBitMask = categories[rando + 1]
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.blueBall | PhysicsCategory.pinkBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall | PhysicsCategory.greenBall | PhysicsCategory.orangeBall | PhysicsCategory.purpleBall | PhysicsCategory.greyBall
        body.restitution = 0
        print("rando2", rando)
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
        
        newBall.fillColor = UIColor.white
        newBall.lineWidth = 0.0
        newBall.fillTexture = skullTexture
        
        newBall.colorType = .skull

        let body = SKPhysicsBody(circleOfRadius: game.smallDiameter / 2)
        body.categoryBitMask = PhysicsCategory.skullBall
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.blueBall | PhysicsCategory.pinkBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall | PhysicsCategory.greenBall | PhysicsCategory.orangeBall | PhysicsCategory.purpleBall | PhysicsCategory.greyBall
        body.restitution = 0
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        
        newBall.physicsBody = body
        
        game.incrementBallType(type: .skull)
        
        newBall.physicsBody?.isDynamic = false
        
        return newBall
    }
    
    /**
     Add a new ball to the array and to the game scene if we can.
     */
    @objc func addBall() {
        print(game.skulls, game.numberStartingBalls)
        if game.skulls < game.numberStartingBalls {
            let newBall = makeBall()
            
            newBall.position = CGPoint(x: size.width / 2, y: size.height - 35)
            
            newBall.inLine = true
            
            newBall.alpha = 0.4
            newBall.setScale(0.6)
            let fadeIn = SKAction.fadeIn(withDuration: 0.25)
            let moveaction = SKAction.move(to: CGPoint(x: size.width / 2, y: size.height - 60), duration: 0.25)
            let popOut = SKAction.scale(to: 1.0, duration: 0.15)
            newBall.run(SKAction.sequence([
                    popOut
                    ]))
            newBall.run(moveaction){
            }
            newBall.run(fadeIn) {
            }
            fallingBalls.append(newBall)
            
            addChild(newBall)
            
            startFallTimer(ball: newBall)
        } else {
            cleanupBalls()
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
        return Int(arc4random_uniform(8) + UInt32(1))
    }
    
    /**
     Get a random image name.
     - returns: Name of an image (string).
     */
    func randomImageName(imageNumber: Int) -> String {
        return "ball-\(imageNumber)"
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
    func getIdealBallPosition(fromSkull ball: SkullBall) -> CGPoint {
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





