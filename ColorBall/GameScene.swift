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
import AVFoundation
import AudioToolbox

// TODOS:
// - column snap top ball and/or distance calc points to columns - 1
// - get rid of one of the boolean controls
// - touching twice to start moving again?
// - make interaction animations (particle explosion, etc)
// - Search terms: Sk particle emitters, sk particle explosions

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: class properties20
    var rando: Int = 0
    var game: Game!
    var explosionpos = 0
    var spinMultiplier = CGFloat(1.0)
    var spinVar: CGFloat = 15.0
    // player (large circle)
    let Circle = PlayerCircle(imageNamed: "circle")
    let skullCircle = PlayerCircle(imageNamed: "skullCircle")
    let ring = PlayerCircle(imageNamed: "ring")
    
    // direction of rotation
    var direction: CGFloat = -1.0
    
    // ball arrays
    var fallingBalls = [SmallBall]()
    
    // available slots around circle
    var slots = [Slot]()
    
    // handling variable column heights and surprises
    var columns = [Column]()
    var columnIndex: Int = 0
    
    // timers
    var ballTimer: Timer?
    var fallTimer: Timer?
    var MemoryTime: Timer?
    
    // control variables
    var isTouching = false
    var isHolding = false

    // TODO: trim one of these though:
    var allowToMove = false
    var canMove = false
    var canpresspause = true

    // game loop update values
    var lastUpdateTime: TimeInterval = 0
    var dt: CGFloat = 0.0
    
    // delegates
    var scoreKeeper: GameScoreDelegate?
    var gameDelegate: StartGameDelegate?
    
    let skullTexture = SKTexture(image: #imageLiteral(resourceName: "skull"))
    let invisible = SKTexture(image: #imageLiteral(resourceName: "randomimage"))
    
    var popPlayer: AVAudioPlayer?
    
    var volumeOn = false
    
    var surpriseBallIndices = [Int]()
    var MemoryBallIndices = [Int]()
    var surpriseBallLocations = [Int: Int]()
    var MemoryBallLocations = [Int: Int]()
    
    var numberSurpriseBalls: Int = 0

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

        updateSlots(dt: dt)
        updateBalls(dt: dt)
    }
    
    override func didMove(to view: SKView) {
        //make a last backgroundColor
        Circle.alpha = 1.0
        skullCircle.alpha = 0.0
        let action = SKAction.fadeIn(withDuration: 0)
        Circle.run(action)
        //backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        //run(SKAction.colorize(with: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0), colorBlendFactor: 1.0, duration: 0.4))
        isPaused = false
        spinMultiplier = (20 / CGFloat(game.slotsOnCircle))
        //changes gravity spped up !!!not gravity//
        physicsWorld.gravity = CGVector(dx: 0, dy: 0.0)
        physicsWorld.contactDelegate = self

//        print("ALTERNATE MODE VARIABLES========")
//        let numberMemoryBalls = game.numberOfMemoryBalls
//        let shouldUseEscapeBall = game.shouldUseEscapeBall
//        print(numberMemoryBalls)
//        print(shouldUseEscapeBall)
//        print("ALTERNATE MODE VARIABLES========")

        
        //backgroundColor = game.backgroundColor
        setupPlayerCircle()
        
        game.resetAll()

        setupSurprises()
        setupMemory()
        setupSlots()

        addChild(Circle)
        addChild(skullCircle)
        
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
    }
    
    // MARK: custom update, animation, and movement methods
    
    /**
     Function to initially creates the large player circle and its physics body.
     */
    func setupPlayerCircle() {
        let startX = CGFloat((size.width / 2))
        let startY = CGFloat((size.height / 3.5))
        let startpos = CGPoint(x: startX, y: startY)

        Circle.position = startpos
        Circle.size = CGSize(width: game.playerDiameter, height: game.playerDiameter)
        skullCircle.position = startpos
        skullCircle.size = CGSize(width: game.playerDiameter, height: game.playerDiameter)
        
        ring.position = CGPoint(x: size.width / 2, y: size.height - 60)
        ring.size = CGSize(width: 65, height: 65)
        
        let body = SKPhysicsBody(texture: Circle.texture!, size: CGSize(width: Circle.size.width - 2, height: Circle.size.height - 2))
        body.categoryBitMask = PhysicsCategory.circleBall
        body.allowsRotation = true
        body.pinned = true
        body.isDynamic = false

        Circle.physicsBody = body
    }
    
    /**
     Function to update the circle's rotation.
      - parameters:
        - dt: Last calculated delta time
     */
    func updateCircle(dt: CGFloat) {
        // change animation
        let increment = (((CGFloat(Double.pi) * 1.0) * direction)) * dt * spinMultiplier
        Circle.zRotation = Circle.zRotation + increment
        Circle.distance = Circle.distance + increment
        
        if (fabs(Circle.distance) >= fabs(Circle.nextTickPosition - Circle.lastTickPosition)) {
            canMove = false
            Circle.distance = 0
            Circle.zRotation = Circle.nextTickPosition
            
            if isHolding {
               getCircleValues()
               if (spinMultiplier < (spinVar / CGFloat(game.slotsOnCircle)) * 2.0) {
                   spinMultiplier += 0.3
             }
            } else {
               spinMultiplier = (spinVar / CGFloat(game.slotsOnCircle))
               isTouching = false
           }
        }
    }
    
    /**
     Update the position of every applicable slot around the circle.
      - parameters:
        - dt: Last calculated delta time
     */
    func updateSlots(dt: CGFloat) {
        for slot in slots {
            slot.update(player: Circle, dt: dt)
        }
    }
    
    /**
     Update the position of every ball on the screen that is NOT stuck to a column slot.
     - parameters:
        - dt: Last calculated delta time
     */
    func updateBalls(dt: CGFloat) {
        for ball in fallingBalls {
            if !ball.inLine && !ball.stuck {
                let newX = ball.position.x
                let newY = ball.position.y - (5.0)
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
                self.allowToMove = true
                self.addBall()
                self.gameDelegate?.tapleftright()
                //self.moveCircle()
                
            })

    }

    
    func setupSlots() {
        // the radians to separate each starting ball by, when placing around the ring
        let incrementRads = degreesToRad(angle: 360 / CGFloat(game.slotsOnCircle))
        let startPosition = CGPoint(x: size.width / 2, y: Circle.position.y)
        let startDistance = (game.playerDiameter / 2) + (game.smallDiameter / 2)
        var nums = [1,2,3,4,5,6,7,8,9,10,11,12,13]
        for i in 0..<game.numberStartingBalls {
            if (game.numberStartingBalls <= 13){
                let arrayKey = Int(arc4random_uniform(UInt32(nums.count)))
                // your random number
                let randNum = nums[arrayKey]
                // make sure the number isnt repeated
                nums.remove(at: arrayKey)
                rando = randNum
            }else {
                rando = i
            }
            let startRads = incrementRads * CGFloat(rando) - degreesToRad(angle: 90.0)
            let newX = (startDistance) * cos(Circle.zRotation - startRads) + Circle.position.x
            let newY = (startDistance) * sin(Circle.zRotation - startRads) + Circle.position.y
            let targetPosition = CGPoint(x: newX, y: newY)

            let slot = BaseSlot(position: targetPosition, startPosition: startPosition, insidePosition: targetPosition, startRads: startRads, isStarter: true, distance: startDistance)
            
            slot.diameter = game.smallDiameter
            slot.columnNumber = i

            let ball = makeStartBall(index: i)
            ball.stuck = false
            slot.setBall(ball: ball)
            ball.position = CGPoint(x: size.width / 2, y: Circle.position.y)
            ball.zPosition = Circle.zPosition - 1
            addChild(ball)

            slots.append(slot)

            let numSurprises = surpriseBallLocations[rando] ?? 0 // default to 0
            let numMemory = MemoryBallLocations[rando] ?? 0 // default to 0
            let col = Column(numberOfSlots: game.slotsPerColumn, baseIndex: columnIndex, numOfSurprises: numSurprises, numOfMemory: numMemory, baseSlot: slot)
            // this will be useful when we have varying values for num column slots
            columnIndex += col.numberOfSlots
            columns.append(col)

            slot.ball?.isMemoryBall = numMemory > 0

            for j in 0..<game.slotsPerColumn - 1 {
                let updatedDistance = startDistance + (game.smallDiameter + 1) * CGFloat(j + 1)
                let slotX = (updatedDistance) * cos(Circle.zRotation - startRads) + Circle.position.x
                let slotY = (updatedDistance) * sin(Circle.zRotation - startRads) + Circle.position.y
                let slotPos = CGPoint(x: slotX, y: slotY)
                let slot = Slot(position: slotPos, startRads: startRads, isStarter: false, distance: updatedDistance)

                slot.diameter = game.smallDiameter
                slot.columnNumber = i
                slots.append(slot)
            }
        }
        
        for slot in slots {
            // only animate the slots closest to the circle when starting the scene
            if let slot = slot as? BaseSlot {
                animateSlotBall(slot: slot)
            }
        }
    }

    func setupSurprises() {
        numberSurpriseBalls = game.numberSurpriseBalls
        let max = numberSurpriseBalls > -1 ? numberSurpriseBalls : game.numberStartingBalls
        for _ in 0..<max {
            let surpriseIndex = randomInteger(upperBound: game.minStageForSurprises)
            if let existingValue = surpriseBallLocations[surpriseIndex] {
                surpriseBallLocations.updateValue(existingValue + 1, forKey: surpriseIndex)
            } else {
                surpriseBallLocations.updateValue(1, forKey: surpriseIndex)
            }
            surpriseBallIndices.append(surpriseIndex)
        }
        print("surprise ball locations", surpriseBallLocations)
    }
    
    func setupMemory() {
        let numbermemoryBalls = game.numberOfMemoryBalls
        for _ in 0..<numbermemoryBalls {
            let MemoryIndex = randomInteger(upperBound: game.minStageForSurprises)
            if let existingValue = MemoryBallLocations[MemoryIndex] {
                MemoryBallLocations.updateValue(existingValue + 1, forKey: MemoryIndex)
            } else {
                MemoryBallLocations.updateValue(1, forKey: MemoryIndex)
            }
            MemoryBallIndices.append(MemoryIndex)
        }
        print("surprise ball locations", MemoryBallLocations)
    }
    /**
     Teardown the stage.
     */
    func cleanupBalls() {
        //createstageexplosion()
        self.createstageexplosion()
        let waittimer = SKAction.wait(forDuration: 1.0)
        self.run(waittimer) {
            self.gameDelegate?.handleNextStage()
//            self.game.decrementBallType(type: BallColor.skull, byNumber: self.game.skulls)
        }
//        let skulls = slots
//            .filter({ $0.containsSkull == true })
//            .flatMap({ $0.ball as? SkullBall })
//
//        for i in 0..<skulls.count {
//            let isLast = (i == skulls.count - 1)
//            let action = getReverseAnimation(ball: skulls[i])
//
//            skulls[i].run(action) {
//                skulls[i].removeFromParent()
//
//                if isLast {
//                    self.gameDelegate?.scorelabelalpha()
//                    self.createstageexplosion()
//                    let waittimer = SKAction.wait(forDuration: 1.0)
//                    self.run(waittimer) {
//                        self.gameDelegate?.handleNextStage()
//                        self.game.decrementBallType(type: BallColor.skull, byNumber: self.game.skulls)
//                    }
//                }
//            }
//        }
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
        if slot.ball!.isMemoryBall {
            checkforMemory(ball: slot.ball!)
        }
    }
    
    /**
     Animate a ball from the outside of the large circle, inward.
     - parameters:
       - ball: A StartingSmallBall object.
     - returns: The SKAction to reverse animate the ball.
     */
    func getReverseAnimation(ball: SkullBall) -> SKAction {
        return SKAction.move(to: ball.startingPos, duration: 0.001)
    }
 
    /**
     Start a timer for allowing a ball to fall downward.
     - parameters:
        - ball: A SmallBall object.
     */
    func startFallTimer(ball: SmallBall) {
        //for how long they stay up (0.0 - 1.8)
        // if you don't want these to be linked, create a new variable in the game object for the fall multiplier (this could cause in-air crashes though)
        let interval = 0.7// * game.speedMultiplier
            fallTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: {
                timer in
                ball.inLine = false
                self.physicsWorld.gravity = CGVector(dx: 0, dy: (-self.game.gravityMultiplier)) // 3 bei stage 10 und 1.2 Speed
            })

    }
    
    func getCircleValues() {
        Circle.lastTickPosition = Circle.zRotation
        Circle.nextTickPosition = Circle.lastTickPosition + (((CGFloat(Double.pi) * 2) / CGFloat(game.slotsOnCircle) * direction))
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
        
        
        if firstBody.categoryBitMask == PhysicsCategory.circleBall {
            handleLargeCollisionWith(newBody: secondBody)
        } else if secondBody.categoryBitMask == PhysicsCategory.circleBall {
            handleLargeCollisionWith(newBody: firstBody)
            
        } else if firstBody.categoryBitMask == secondBody.categoryBitMask {
            if firstBody.isDynamic == true {
                handleSameColorCollision(newBody: firstBody, stuckBody: secondBody, contactPoint: contact.contactPoint)
            } else if secondBody.isDynamic == true {
                handleSameColorCollision(newBody: secondBody, stuckBody: firstBody, contactPoint: contact.contactPoint)
            }
        } else if firstBody.categoryBitMask != secondBody.categoryBitMask {
            if let _ = firstBody.node as? StartingSmallBall, let _ = secondBody.node as? SkullBall {
            } else if let _ = secondBody.node as? StartingSmallBall, let _ = firstBody.node as? SkullBall {
            } else {
                if firstBody.isDynamic == true {
                    handleDifferentColorCollision(newBody: firstBody, stuckBody: secondBody)
                } else if secondBody.isDynamic == true {
                    handleDifferentColorCollision(newBody: secondBody, stuckBody: firstBody)
                }
            }
        }
    }

//    func createExplosion(onBody body: SKPhysicsBody) {
//        if let explosionPath = Bundle.main.path(forResource: "Spark", ofType: "sks"),
//            let explosion = NSKeyedUnarchiver.unarchiveObject(withFile: explosionPath) as? SKEmitterNode,
//            let ball = body.node as? SmallBall,
//            let thisExplosion = explosion.copy() as? SKEmitterNode {
//            let point = CGPoint(x: ball.x, y: ball.y)
//            thisExplosion.position = point
//            ball.addChild(thisExplosion)
//        }
//    }
//
//    func createExplosion(onBall ball: SKNode) {
//        if let explosionPath = Bundle.main.path(forResource: "Spark", ofType: "sks"),
//            let explosion = NSKeyedUnarchiver.unarchiveObject(withFile: explosionPath) as? SKEmitterNode,
//            let ball = ball as? SmallBall,
//            let thisExplosion = explosion.copy() as? SKEmitterNode {
//           let explosiony = size.width / 3 + game.playerDiameter + game.smallDiameter / 2 + (CGFloat(game.slotsPerColumn - 1 - explosionpos) * game.smallDiameter)
//            let point = CGPoint(x: size.width / 2, y: explosiony)
//            thisExplosion.position = point
//            let explosionTexture = SKTexture(imageNamed: ball.colorType.name())
//            thisExplosion.particleTexture = explosionTexture
//            addChild(thisExplosion)
//            explosionpos += 1
//        }
//    }
    func createExplosion(onBall ball: SKNode) {
        if let explosionPath = Bundle.main.path(forResource: "Spark", ofType: "sks"),
            let explosion = NSKeyedUnarchiver.unarchiveObject(withFile: explosionPath) as? SKEmitterNode,
            let ball = ball as? SmallBall,
            let thisExplosion = explosion.copy() as? SKEmitterNode {
            let explosiony = CGPoint(x: ball.position.x, y: ball.position.y)
            thisExplosion.position = explosiony
            //fruit explosion
            let explosionTexture = SKTexture(imageNamed: ball.colorType.name())
            thisExplosion.particleTexture = explosionTexture
            addChild(thisExplosion)
            
            }
    }
    func createstageexplosion(){
        if let explosionPath = Bundle.main.path(forResource: "sparkstage", ofType: "sks"),
            let explosion = NSKeyedUnarchiver.unarchiveObject(withFile: explosionPath) as? SKEmitterNode,
            let thisExplosion = explosion.copy() as? SKEmitterNode {
            let point = CGPoint(x: size.width / 2, y: size.height / 3.5)
            thisExplosion.particleSize = CGSize(width: game.playerDiameter, height: game.playerDiameter)
            thisExplosion.position = point
            addChild(thisExplosion)
            run(SKAction.wait(forDuration: 0.2)) {
                self.Circle.alpha = 0.0
            }
            
            
        }
    
    }
//    func createstageexplosionreverse(){
//        if let explosionPath = Bundle.main.path(forResource: "sparkstagereverse2", ofType: "sks"),
//            let explosion = NSKeyedUnarchiver.unarchiveObject(withFile: explosionPath) as? SKEmitterNode,
//            let thisExplosion = explosion.copy() as? SKEmitterNode {
//            let point = CGPoint(x: size.width / 2, y: size.height / 3)
//            thisExplosion.particleSize = CGSize(width: game.playerDiameter, height: game.playerDiameter)
//            thisExplosion.position = point
//            addChild(thisExplosion)
//            Circle.alpha = 1.0
//        }
//
//    }
    
    func getFirstSlotInColumn(num: Int) -> BaseSlot {
        return slots.first(where: { $0.columnNumber == num }) as! BaseSlot
    }
    
    func getSlotsInColumn(num: Int) -> [Slot] {
        return slots.filter{ $0.columnNumber == num }
    }
    
    func getFirstOpenSlot(slotList: [Slot]) -> Slot? {
        return slotList.first(where: { $0.ball == nil })
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

        if let _ = closestSlot.ball {
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
            // add 3 points to the skull's y position
            ball.position = CGPoint(x: ball.position.x, y: ball.position.y + 3)
        } else if let ball = newBody.node as? SmallBall, game.endGameOnCircleCollision {
            startGameOverSequence(newBall: ball)
        }
    }
    
    func checkForZaps(colNumber: Int, completion: @escaping () -> Void) {
        
        let colSlots = getSlotsInColumn(num: colNumber)
        let firstOpenSlot = getFirstOpenSlot(slotList: colSlots)
        if firstOpenSlot == nil {
            game.decrementBallType(type: colSlots[0].colorType!, byNumber: game.slotsPerColumn)
            
            let currentColumn = columns[colNumber]
            
            // map the column's slots to an array of the balls they contain
            let zapBalls = colSlots.map({ $0.ball! })

            if let topBall = zapBalls.last {
                topBall.falling = true
            }

            // variable to count loop iterations
            var index = 0

            // loop through the array of balls we should be zapping
            for _ in zapBalls {
                // add one to the loop count
                index += 1
                let slotIndex = index.advanced(by: -1)

                // get a reference to the ball we want to animate this iteration
                let ball = zapBalls[zapBalls.count - index]

                // create the wait action (the delay before we start falling)
                let waitDuration = Double(GameConstants.ballZapDuration * CGFloat(index))
                let wait = SKAction.wait(forDuration: waitDuration)
                let waitLast = SKAction.wait(forDuration: waitDuration - Double(GameConstants.ballZapDuration))
                ball.fallTime = GameConstants.ballZapDuration

                // if we're on the last ball, we want to:
                // - 1. make sure the whole stack is removed afterwards
                // - 2. add a skull ball to the first slot
                // - 3. call the completion handler after finishing
                if (index == zapBalls.count) {
                    ball.run(waitLast) {
                        self.createExplosion(onBall: ball)
                        colSlots[slotIndex].unsetBall()
                        ball.fillColor = UIColor.clear
                        ball.strokeColor = UIColor.clear
                        ball.physicsBody = nil
                        if self.numberSurpriseBalls == -1 || currentColumn.numOfSurprises > 0 {
                            currentColumn.numOfSurprises -= 1
                            let b = self.addNewBall(toColumn: colNumber)
                            self.game.incrementBallType(type: b.colorType)
                            self.Circle.addChild(b)
                            let scenePosition = CGPoint(x: self.Circle.position.x, y: currentColumn.baseSlot.position.y - self.game.smallDiameter)
                            let positionConverted = self.convert(scenePosition, to: self.Circle)
                            b.position = positionConverted
                            self.animateNewBall(ball: b) {
                                b.removeFromParent()
                                currentColumn.baseSlot.setBall(ball: b)
                                self.addChild(b)
                            }
                        }
                        ball.run(SKAction.wait(forDuration: 1.2)) {
                            for b in zapBalls {
                                b.removeFromParent()
                            }
                        }
                        completion()
                    }
                } else {
                    // if we are not on the last ball yet, we want to:
                    // - 1. run the delay
                    // - 2. remove this ball
                    // - 3. set the next ball's falling property to true
                    ball.run(wait) {
                        if let nextBall = zapBalls.filter({ !$0.falling }).last {
                            nextBall.falling = true
                            AudioManager.only.playZapSound(iterations: self.game.slotsPerColumn - 1)
                        }
                        ball.fillColor = UIColor.clear
                        ball.strokeColor = UIColor.clear
                        ball.physicsBody = nil
                        colSlots[slotIndex].unsetBall()
                    }
                }
            }
        } else {
            completion()
        }
    }
    
    func V2dot(a: CGPoint, b: CGPoint) -> CGFloat {
        return a.x*b.x + a.y*b.y;
    }
    
    func V2lenSq(v: CGPoint) -> CGFloat {
        return V2dot(a: v, b: v);
    }
    
    func V2len(v: CGPoint) -> CGFloat {
        return CGFloat(sqrt(Double(V2lenSq(v: v))))
    }
    
    func V2add(a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPoint(x: b.x + a.x, y: b.y + a.y);
    }
    
    func V2sub(a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPoint(x: b.x - a.x, y: b.y - a.y);
    }

    func V2mul(s: CGFloat, a: CGPoint) -> CGPoint {
        return CGPoint(x: s*a.x, y: s*a.y);
    }
    
    func V2dist(a: CGPoint, b: CGPoint) -> CGFloat {
        return V2len(v: V2sub(a: b, b: a));
    }

    func animateNewBall(ball: SmallBall, completion: @escaping () -> Void) {
        let deg = Circle.zRotation
        let x = cos(deg) * game.smallDiameter
        let y = -sin(deg) * game.smallDiameter
        
        let newX = -y
        let newY = x
        
        
        let spring = SKAction.moveBy(x: newX, y: newY, duration: 1.0, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0)
        ball.run(spring) {
            completion()
        }
    }
    
    func moveCircle(){
        let shakeTop = getMoveAction(moveX: 0.0, moveY: 100.0, totalTime: 2.0)
        let shakeBottom = getMoveAction(moveX: 0.0, moveY: -100.0, totalTime: 2.0)
        let shakeTopfast = getMoveAction(moveX: 0.0, moveY: 100.0, totalTime: 1.0)
        Circle.run(SKAction.sequence([
            shakeTop,
            shakeBottom,
            shakeBottom,
            shakeTopfast,
            shakeTopfast,
            shakeBottom,
            shakeBottom,
            shakeTopfast,
            ]))
    }

    func addSkull(toColumn num: Int) {
        let skullSlot = getFirstSlotInColumn(num: num)
        let skullBall = makeSkullBall()
        skullBall.insidePos = skullSlot.insidePosition
        skullBall.startingPos = skullSlot.startPosition
        skullSlot.ball = skullBall
        skullBall.position = skullSlot.position
        skullBall.stuck = true
        skullBall.zPosition = -5
        skullSlot.containsSkull = true
        skullBall.alpha = 0
        // let fadeInSkull = SKAction.fadeIn(withDuration: 2.0)
      //  let moveactionSkull = SKAction.move(to: skullSlot.insidePosition, duration: 2.0)

        // let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        // create an action group to run simultaneous actions
       // let actionGroup = SKAction.group([fadeInSkull])
       // skullBall.run(actionGroup)
//        let scale = SKAction.scale(by: 0.2, duration: 1.0)
//        skullBall.run(SKAction.sequence([
//            scale
//        ]))
        addChild(skullBall)
    }

    func addNewBall(toColumn num: Int) -> StartingSmallBall {
        let skullSlot = getFirstSlotInColumn(num: num)
        let index = randomInteger(upperBound: game.numberBallColors) - 1
        let skullBall = makeStartBall(index: index)
        skullBall.insidePos = skullSlot.insidePosition
        skullBall.startingPos = skullSlot.startPosition
//        skullBall.position = CGPoint(x: skullSlot.position.x, y: skullSlot.position.y - game.smallDiameter)
        skullBall.stuck = true
        skullBall.zPosition = Circle.zPosition - 1
        skullSlot.containsSkull = false
        return skullBall
    }

    /**
     Handle a collision between two small balls of the same color.
     - parameters:
        - newBody: The dynamic body.
        - stuckBody: The non-dynamic body.
     */
    func handleSameColorCollision(newBody: SKPhysicsBody, stuckBody: SKPhysicsBody, contactPoint: CGPoint) {
        if let ball = newBody.node as? SmallBall {
            increaseScore(byValue: 1)
            let slot = getClosestOpenSlot(toPoint: contactPoint)

            // any position animations should be done here, before ball.position... and slot.ball....
            
//            let popIn = SKAction.scale(by: 1.15, duration: 0.125)
//            let popOut = SKAction.scale(by: 0.85, duration: 0.125)
//           // let shakeBottom = getMoveAction(moveX: 0.0, moveY: 5.0, totalTime: 0.06)
//            let shakeTop = getMoveAction(moveX: 0.0, moveY: -10.0, totalTime: 1.0)
//            camera?.run(SKAction.sequence([
//                //shakeBottom,
//                shakeTop
//                ]))
//            ball.run(SKAction.sequence([
//                popIn,
//                popOut
//            ]))
            
            ball.position = slot.position// this sets the position strictly
            slot.ball = ball // this will make that position update every frame
            
            ball.stuck = true
            ball.physicsBody?.isDynamic = false

            checkForZaps(colNumber: slot.columnNumber) {
                self.addBall()
            }
        }
    }
    
    func setBackgroundToDark() {
        backgroundColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
    }
    
    func fadeBackgroundBackToWhite() {
        run(SKAction.colorize(with: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0), colorBlendFactor: 1.0, duration: 0.3))
    }
    func BackgroundBackToWhite() {
        run(SKAction.colorize(with: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0), colorBlendFactor: 1.0, duration: 0.0))
    }
    
    func startGameOverSequence(newBall: SmallBall) {
        self.gameDelegate?.gameoverplayscore()
        run(SKAction.colorize(with: UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0), colorBlendFactor: 1.0, duration: 0.3))
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            let wait = SKAction.wait(forDuration: 0.01)
            self.run(wait) {
                generator.impactOccurred()
            }

        allowToMove = false
        canMove = false
        newBall.stuck = true
        newBall.physicsBody?.isDynamic = false
        gameDelegate?.gameoverdesign()
        self.gameDelegate?.scorelabelalpha()
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
        skullCircle.run(fadeIn)
        
        // create the camera zoom action
        let shakeLeft = getMoveAction(moveX: -9.0, moveY: 0.0, totalTime: 0.04)
        let shakeRight = getMoveAction(moveX: 9.0, moveY: 0.0, totalTime: 0.04)
        
        camera?.run(SKAction.sequence([
            shakeLeft,
            shakeRight,
            shakeRight,
            shakeLeft,
            shakeLeft,
            shakeRight,
            shakeRight,
            shakeLeft
        ]))
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
            PhysicsCategory.a,
            PhysicsCategory.s,
            PhysicsCategory.d,
            PhysicsCategory.f,
            PhysicsCategory.g,
            PhysicsCategory.h,
            PhysicsCategory.j,
            PhysicsCategory.k,
            PhysicsCategory.l,
            PhysicsCategory.y,
            PhysicsCategory.x,
            PhysicsCategory.c,
            PhysicsCategory.v,
            PhysicsCategory.b,
            PhysicsCategory.n,
            PhysicsCategory.m,
        ]
        
        // generate a random integer betweeb 0 and 7
        let rando = index < game.numberBallColors ? index : randomInteger(upperBound: game.numberBallColors) - 1
        
        // use the random integer to get a ball type and a ball colorr
        let ballType = BallColor(rawValue: rando)!

        game.incrementBallType(type: ballType)

        let newBall = StartingSmallBall(circleOfRadius: game.smallDiameter / 2)
        // set the fill color to our random color
        newBall.fillColor = GameConstants.ballColors[rando]
        // don't fill the outline
        let body = SKPhysicsBody(circleOfRadius: (game.smallDiameter / 2))
        // our physics categories are offset by 1, the first entry in the arryay being the bitmask for the player's circle ball
        body.categoryBitMask = categories[rando + 1]
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.blueBall | PhysicsCategory.pinkBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall | PhysicsCategory.greenBall | PhysicsCategory.orangeBall | PhysicsCategory.purpleBall | PhysicsCategory.greyBall | PhysicsCategory.a | PhysicsCategory.s | PhysicsCategory.d | PhysicsCategory.f | PhysicsCategory.g | PhysicsCategory.h | PhysicsCategory.j | PhysicsCategory.k | PhysicsCategory.l | PhysicsCategory.y | PhysicsCategory.x | PhysicsCategory.c | PhysicsCategory.v | PhysicsCategory.b | PhysicsCategory.n | PhysicsCategory.m
        body.restitution = 0
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        body.isDynamic = false
        newBall.physicsBody = body
        newBall.colorType = ballType
       //Fruits
        newBall.lineWidth = 0.1
        newBall.lineCap = CGLineCap(rawValue: 1)!
        newBall.strokeColor = GameConstants.ballColors[rando]
        newBall.isAntialiased = true
        //fruits
        // setFruits(ball: newBall, rando: rando)
        
        
        if (index == 1 ){
        // checkforMemory(ball: newBall)
        // escapeBall(ball: newBall)
        }
        return newBall
    }
    func setFruits(ball: SmallBall, rando: Int){
        ball.lineWidth = 0.0
        let currentFruitTexture = randomImageName(imageNumber: rando + 1)
        print(rando)
        let FruitTexture = SKTexture(imageNamed: currentFruitTexture)
        ball.fillTexture = FruitTexture
        ball.fillColor = .white
    }
    func escapeBall(ball: SmallBall){
        //ToDo: Make the i slot, connect to collum, explosion if you hit it, game over if it's gone, make it bigger so you can see it, make physics body bigger, random time
        let incrementRads = degreesToRad(angle: 360 / CGFloat(game.slotsOnCircle))
        let startRads = incrementRads * CGFloat(12) - degreesToRad(angle: 90.0)
        let newX = (400) * cos(Circle.zRotation - startRads) + Circle.position.x
        let newY = (400) * sin(Circle.zRotation - startRads) + Circle.position.y
        let targetPosition = CGPoint(x: newX, y: newY)
        let escape = SKAction.move(to: targetPosition, duration: 10.0)
        ball.run(SKAction.sequence([
            escape
        ]))
    }
    
    func checkforMemory(ball: SmallBall){
        //ToDO: Get a hint for money, make it random, connect to collum, show color if you're hit the same color, make it after a random sequence
            let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.3)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
            let fadeOutSlow = SKAction.fadeAlpha(to: 0.0, duration: 2.0)
            ball.run(SKAction.sequence([
                fadeOut,
                fadeIn,
                fadeOut,
                fadeIn,
                fadeOut,
                fadeIn,
                fadeOut,
                fadeIn,
                fadeOut,
                fadeIn,
                fadeOutSlow,
                ]), completion: {
                    ball.lineWidth = 12.0
                    ball.strokeColor = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1.0)
                    ball.fillColor = .clear
                    ball.alpha = 1.0
                    ball.setScale(0.55)
            })
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
            PhysicsCategory.a,
            PhysicsCategory.s,
            PhysicsCategory.d,
            PhysicsCategory.f,
            PhysicsCategory.g,
            PhysicsCategory.h,
            PhysicsCategory.j,
            PhysicsCategory.k,
            PhysicsCategory.l,
            PhysicsCategory.y,
            PhysicsCategory.x,
            PhysicsCategory.c,
            PhysicsCategory.v,
            PhysicsCategory.b,
            PhysicsCategory.n,
            PhysicsCategory.m,
        ]
        var rando = randomInteger(upperBound: game.numberBallColors) - 1
        var ballType = BallColor(rawValue: rando)!
        
        while (game.getCountForType(type: ballType) <= 0) {
            rando = randomInteger(upperBound: game.numberBallColors) - 1
            ballType = BallColor(rawValue: rando)!
        }
        
        game.incrementBallType(type: ballType)
        
        let newBall = SmallBall(circleOfRadius: game.smallDiameter / 2)
        newBall.fillColor = GameConstants.ballColors[rando]
        newBall.isAntialiased = false
        newBall.strokeColor = GameConstants.ballColors[rando]
        let body = SKPhysicsBody(circleOfRadius: (game.smallDiameter / 2))
        // our physics categories are offset by 1, the first entry in the arryay being the bitmask for the player's circle ball
        body.categoryBitMask = categories[rando + 1]
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.blueBall | PhysicsCategory.pinkBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall | PhysicsCategory.greenBall | PhysicsCategory.orangeBall | PhysicsCategory.purpleBall | PhysicsCategory.greyBall | PhysicsCategory.a | PhysicsCategory.s | PhysicsCategory.d | PhysicsCategory.f | PhysicsCategory.g | PhysicsCategory.h | PhysicsCategory.j | PhysicsCategory.k | PhysicsCategory.l | PhysicsCategory.y | PhysicsCategory.x | PhysicsCategory.c | PhysicsCategory.v | PhysicsCategory.b | PhysicsCategory.n | PhysicsCategory.m
        body.restitution = 0
        categories.remove(at: rando)
        body.allowsRotation = true
        body.usesPreciseCollisionDetection = true
        
        newBall.physicsBody = body
        
        newBall.colorType = ballType
        //to make ball invisible after falling
//        let waitfordis = SKAction.wait(forDuration: 2.0)
//        self.run(waitfordis) {
//            newBall.fillTexture = self.invisible
//        }
        newBall.lineWidth = 0.1
        newBall.lineCap = CGLineCap(rawValue: 1)!
        newBall.strokeColor = GameConstants.ballColors[rando]
        newBall.isAntialiased = true
        // setFruits(ball: newBall, rando: rando)
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

        let body = SKPhysicsBody(circleOfRadius: (game.smallDiameter / 2))
        body.categoryBitMask = PhysicsCategory.skullBall
        body.contactTestBitMask = PhysicsCategory.circleBall | PhysicsCategory.blueBall | PhysicsCategory.pinkBall | PhysicsCategory.redBall | PhysicsCategory.yellowBall | PhysicsCategory.greenBall | PhysicsCategory.orangeBall | PhysicsCategory.purpleBall | PhysicsCategory.greyBall | PhysicsCategory.a | PhysicsCategory.s | PhysicsCategory.d | PhysicsCategory.f | PhysicsCategory.g | PhysicsCategory.h | PhysicsCategory.j | PhysicsCategory.k | PhysicsCategory.l | PhysicsCategory.y | PhysicsCategory.x | PhysicsCategory.c | PhysicsCategory.v | PhysicsCategory.b | PhysicsCategory.n | PhysicsCategory.m
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
        if game.ballsRemaining > 0 {
            let newBall = makeBall()
            var yPos = size.height
            var moveToY = size.height - (spinVar + (game.smallDiameter/2))
            if (Settings.isIphoneX) {
                // adjust these to adjust fall position on iphone x
                yPos -= 35
                moveToY -= 35
            }
            self.physicsWorld.gravity = CGVector(dx: 0, dy: 0.0)
            newBall.position = CGPoint(x: (size.width / 2), y: yPos)
            newBall.inLine = true
            newBall.alpha = 0.4

            let fadeIn = SKAction.fadeIn(withDuration: 0.25)
            let moveaction = SKAction.move(to: CGPoint(x: (size.width / 2), y: moveToY), duration: 0.25)
            let popOut = SKAction.scale(to: 1.0, duration: 0.15)
            // create an action group to run simultaneous actions
            let actionGroup = SKAction.group([popOut, moveaction, fadeIn])
            newBall.run(actionGroup)

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
        return "Fruit-\(imageNumber)"
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





