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

// TODOS:
// - column snap top ball and/or distance calc points to columns - 1
// - get rid of one of the boolean controls
// - touching twice to start moving again?
// - make interaction animations (particle explosion, etc)
// - Search terms: Sk particle emitters, sk particle explosions

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: class properties20
    var fruitBool: Bool = false
    let defaults = UserDefaults.standard
    var rando: Int = 0
    var game: Game!
    var explosionpos = 0
    var spinMultiplier = 0.0
    // player (large circle)
    let Circle = PlayerCircle(imageNamed: "circle")
    let skullCircle = PlayerCircle(imageNamed: "lose")
    let winCircle = PlayerCircle(imageNamed: "win")
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
    var canpresspause = false
    // timers
    var ballTimer: Timer?
    var fallTimer: Timer?
    var MemoryTime: Timer?
    var directionFlipTimer: Timer?
    
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
    let invisible = SKTexture(image: #imageLiteral(resourceName: "randomimage"))
    
    var volumeOn = false
    
    var surpriseBallIndices = [Int]()
    var MemoryBallIndices = [Int]()
    var surpriseBallLocations = [Int: Int]()
    var MemoryBallLocations = [Int: Int]()
    
    var numberSurpriseBalls: Int = 0
    
    var slotsToClear = [Slot]()
    var ballsNeedUpdating = false

    var columnHeights: [Int]!
    // MARK: lifecycle methods and overrides

    var nextBall: SmallBall?
    var stopSpinOverride = false
    var reversedModeSpinMultMax: Double = 5
    
    // main update function (game loop)
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTime
        let currentFPS = 1 / deltaTime

        dt = 1.0/CGFloat(currentFPS)
        lastUpdateTime = currentTime
        
        if canMove || (game.isReversedMode && !stopSpinOverride) {
            updateCircle(dt: dt)
        }

        updateSlots(dt: dt)
        updateBalls(dt: dt)

        updateZaps()
        addBall()
    }
    
    func updateZaps() {
        if slotsToClear.count > 0 {
            var colSlots = [Slot]()
            colSlots.append(contentsOf: slotsToClear)
            slotsToClear.removeAll()
            zapBalls(colSlots: colSlots) {
                // called after all balls have zapped and animated
                self.ballsNeedUpdating = true
            }
        }
    }

    override func didMove(to view: SKView) {
        if game.isReversedMode {
            spinMultiplier = 0.6
        } else {
            spinMultiplier = Double(CGFloat(game.spinVar / CGFloat(game.slotsOnCircle)))
        }

        Circle.alpha = 1.0
        skullCircle.alpha = 0.0
        winCircle.alpha = 0.0
        let action = SKAction.fadeIn(withDuration: 0)
        Circle.run(action)

        isPaused = false
        //spinMultiplier = (20 / CGFloat(game.slotsOnCircle))
        //changes gravity spped up !!!not gravity//
        physicsWorld.gravity = CGVector(dx: 0, dy: 0.0)
        physicsWorld.contactDelegate = self

        setupPlayerCircle()
        
        game.resetAll()

        setupSurprises()
        setupMemory()
        setupSlots()

        addChild(Circle)
        addChild(skullCircle)
        addChild(winCircle)
        setupFirstFallTimer()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       if !game.isReversedMode && allowToMove == true && !isTouching && !isHolding {
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
        } else if game.isReversedMode {
          if let nextBall = nextBall {
              dropBall(nextBall)
              self.nextBall = nil
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
        winCircle.position = startpos
        skullCircle.size = CGSize(width: game.playerDiameter, height: game.playerDiameter)
        winCircle.size = CGSize(width: game.playerDiameter, height: game.playerDiameter)
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
        let increment = (((CGFloat(Double.pi) * 1.0) * direction)) * dt * CGFloat(spinMultiplier)
        Circle.zRotation = Circle.zRotation + increment
        Circle.distance = Circle.distance + increment

        if fabs(Circle.distance) >= fabs(Circle.nextTickPosition - Circle.lastTickPosition) {
            canMove = false
            Circle.distance = 0
            Circle.zRotation = Circle.nextTickPosition

            if isHolding || game.isReversedMode {
                getCircleValues()
                if !game.isReversedMode {
                  if (CGFloat(spinMultiplier) < ((game.spinVar + game.rotationSpeedIncrement) / CGFloat(game.slotsOnCircle) * 1.2)) {
                      spinMultiplier += 0.5 // wie schnell es schneller wird
                  }
                }
            } else {
                spinMultiplier = (Double((game.spinVar + game.rotationSpeedIncrement) / CGFloat(game.slotsOnCircle)))
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
                let newY = ball.position.y - CGFloat((game.startgravity + game.gravityMultiplier)) // 5.0 - 8.0
                ball.position = CGPoint(x: newX, y: newY)
            }
        }
    }

    /**
     Update the position of every ball on the screen that is NOT stuck to a column slot.
     - parameters:
        - dt: Last calculated delta time
     */
    func setupDirectionTimer() {
//        if game.isReversedMode {
//            let _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: {timer in
//                if self.direction == 1 {
//                    self.direction = -1
//                } else {
//                   self.direction = 1
//                }
//                self.getCircleValues()
//                self.isTouching = true
//                self.isHolding = true
//            })
//        }
    }

    /**
     Set the timer for dropping the first ball.
     */
    func setupFirstFallTimer() {
        Metadata.shared.trackUserStageStart(stage: game.stage, mode: game.mode.modeName())

        //timer sets when the first ball should fall
        if game.isMemoryMode {
            let _ = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false, block: {timer in
                self.allowToMove = true
                self.canpresspause = true
                self.ballsNeedUpdating = true
                self.addBall()
                self.gameDelegate?.tapleftright()
                self.setupDirectionTimer()
                //self.moveCircle()
            })
        } else {
            let _ = Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false, block: {timer in
                self.allowToMove = true
                self.canpresspause = true
                self.ballsNeedUpdating = true
                self.addBall()
                self.gameDelegate?.tapleftright()
                self.setupDirectionTimer()
                //self.moveCircle()
            })
        }
    }
  
//    func postFirstFallTimerActions() {
//        self.allowToMove = true
//          self.canpresspause = true
//          self.ballsNeedUpdating = true
//          self.addBall()
//          self.gameDelegate?.tapleftright()
//          self.setupDirectionTimer()
//    }
  
    func setupSlots() {
        print("gravityMultiplier:" , game.gravityMultiplier)
        print("speedMultiplier:" , game.speedMultiplier)
        print("MemoryBalls:" , game.numberOfMemoryBalls)
        print("SurpriseBalls:" , game.numberSurpriseBalls)
        
        // generate the column heights for this stage
        game.generateColumnHeights()

        // the radians to separate each starting ball by, when placing around the ring
        let incrementRads = degreesToRad(angle: 360 / CGFloat(game.slotsOnCircle))
        let startPosition = CGPoint(x: size.width / 2, y: Circle.position.y)
        let startDistance = (game.playerDiameter / 2) + (game.smallDiameter / 2)
        var nums = [1,2,3,4,5,6,7,8,9,10,11,12,13]

        for i in 0..<game.numberStartingBalls {
            if (game.numberStartingBalls <= 13) {
                let arrayKey = Int(arc4random_uniform(UInt32(nums.count)))
                // your random number
                let randNum = nums[arrayKey]
                // make sure the number isnt repeated
                nums.remove(at: arrayKey)
                rando = randNum
            } else {
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

            let height = game.columnsHeights.count >= i - 1 ? game.columnsHeights[i] : 2 // set to a default just in case
            let numSurprises = surpriseBallLocations[rando] ?? 0 // default to 0
            let numMemory = MemoryBallLocations[rando] ?? 0 // default to 0
            let col = Column(numberOfSlots: height, baseIndex: columnIndex, numOfSurprises: numSurprises, numOfMemory: numMemory, baseSlot: slot)
            // this will be useful when we have varying values for num column slots
            columnIndex += col.numberOfSlots
            columns.append(col)

            slot.ball?.isMemoryBall = numMemory > 0

            for j in 0..<col.numberOfSlots - 1 {
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
        print("memory ball locations", MemoryBallLocations)
    }

    /**
     Teardown the stage.
     */
    func cleanupBalls() {
        Metadata.shared.trackUserStageEnd(stage: game.stage, mode: game.mode.modeName())

        canpresspause = false
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
        winCircle.run(fadeIn)
        self.gameDelegate?.rewardnextstage()
        self.gameDelegate?.scorelabelalpha()
        let waittimerone = SKAction.wait(forDuration: 0.4)
        self.run(waittimerone) {
            self.createstageexplosion()
            let waittimer = SKAction.wait(forDuration: 1.0)
            self.run(waittimer) {
                self.gameDelegate?.handleNextStage()
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
        if slot.ball!.isMemoryBall {
            let wait = SKAction.wait(forDuration: 2.0)
            run(wait, completion: {
                self.checkforMemory(ball: slot.ball!)
            })
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
            self.dropBall(ball)
        })
    }
  
    func dropBall(_ ball: SmallBall) {
        ball.inLine = false
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

    func createExplosion(onBall ball: SKNode) {
        if let explosionPath = Bundle.main.path(forResource: "Spark", ofType: "sks"),
            let explosion = NSKeyedUnarchiver.unarchiveObject(withFile: explosionPath) as? SKEmitterNode,
            let ball = ball as? SmallBall,
            let thisExplosion = explosion.copy() as? SKEmitterNode {
            let explosiony = CGPoint(x: ball.position.x, y: ball.position.y)
            thisExplosion.position = explosiony
            //fruit explosion
            if let mode = UserDefaults.standard.object(forKey: Settings.TEXTURE_KEY) as? String{
                if mode == Settings.TEXTURE_FRUITS{
                    if ball.colorType.name() == "blue"{
                        let explosionTexture = SKTexture(imageNamed: "Fruit-1")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "pink"{
                        let explosionTexture = SKTexture(imageNamed: "Fruit-2")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "red"{
                        let explosionTexture = SKTexture(imageNamed: "Fruit-3")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "yellow"{
                        let explosionTexture = SKTexture(imageNamed: "Fruit-4")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "green"{
                        let explosionTexture = SKTexture(imageNamed: "Fruit-5")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "orange"{
                        let explosionTexture = SKTexture(imageNamed: "Fruit-6")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "purple"{
                        let explosionTexture = SKTexture(imageNamed: "Fruit-7")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "grey"{
                        let explosionTexture = SKTexture(imageNamed: "Fruit-8")
                        thisExplosion.particleTexture = explosionTexture
                    }
                }else if mode == Settings.TEXTURE_POOL{
                    if ball.colorType.name() == "blue"{
                        let explosionTexture = SKTexture(imageNamed: "Pool-1")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "pink"{
                        let explosionTexture = SKTexture(imageNamed: "Pool-2")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "red"{
                        let explosionTexture = SKTexture(imageNamed: "Pool-3")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "yellow"{
                        let explosionTexture = SKTexture(imageNamed: "Pool-4")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "green"{
                        let explosionTexture = SKTexture(imageNamed: "Pool-5")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "orange"{
                        let explosionTexture = SKTexture(imageNamed: "Pool-6")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "purple"{
                        let explosionTexture = SKTexture(imageNamed: "Pool-7")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "grey"{
                        let explosionTexture = SKTexture(imageNamed: "Pool-8")
                        thisExplosion.particleTexture = explosionTexture
                    }
                }else if mode == Settings.TEXTURE_BALLS{
                    if ball.colorType.name() == "blue"{
                        let explosionTexture = SKTexture(imageNamed: "ball-1")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "pink"{
                        let explosionTexture = SKTexture(imageNamed: "ball-2")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "red"{
                        let explosionTexture = SKTexture(imageNamed: "ball-3")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "yellow"{
                        let explosionTexture = SKTexture(imageNamed: "ball-4")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "green"{
                        let explosionTexture = SKTexture(imageNamed: "ball-5")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "orange"{
                        let explosionTexture = SKTexture(imageNamed: "ball-6")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "purple"{
                        let explosionTexture = SKTexture(imageNamed: "ball-7")
                        thisExplosion.particleTexture = explosionTexture
                    }else if ball.colorType.name() == "grey"{
                        let explosionTexture = SKTexture(imageNamed: "ball-8")
                        thisExplosion.particleTexture = explosionTexture
                    }
                    
                }else{
                    let explosionTexture = SKTexture(imageNamed: ball.colorType.name())
                    thisExplosion.particleTexture = explosionTexture
                    }
        
        addChild(thisExplosion)
    }
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
                self.winCircle.alpha = 0.0
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
    
    /**
     * Called only when the update method found items in the array of
     * slots that need to be cleared
     */
    func zapBalls(colSlots: [Slot], completion: @escaping () -> Void) {
        guard let colNumber = colSlots.first?.columnNumber,
            let ballType = colSlots.first?.ball?.colorType else { return }

        let currentColumn = columns[colNumber]

        game.decrementBallType(type: ballType, byNumber: colSlots.count)

        // map the column's slots to an array of the balls they contain
        let zapBalls = colSlots.map({ $0.ball! })

        zapBalls.last?.falling = true

        // variable to count loop iterations
        var index = 0
        
        // loop through the array of balls we should be zapping
        for _ in colSlots {
            // add one to the loop count
            index += 1
            let slotIndex = index.advanced(by: -1)
            
            // get a reference to the ball we want to animate this iteration
            let ball = zapBalls[zapBalls.count - index]
            
            // create the wait action (the delay before we start falling)
            let waitDuration = Double(game.ballzapduration * CGFloat(index))
            let wait = SKAction.wait(forDuration: waitDuration)
            let waitLast = SKAction.wait(forDuration: waitDuration - Double(game.ballzapduration))
            ball.fallTime = game.ballzapduration
       
            // if we're on the last ball, we want to:
            // - 1. make sure the whole stack is removed afterwards
            // - 2. add a skull ball to the first slot
            // - 3. call the completion handler after finishing
            if (index == zapBalls.count) {
                ball.run(waitLast) {
                    ball.fillColor = UIColor.clear
                    ball.strokeColor = UIColor.clear
                    self.createExplosion(onBall: ball)
                    colSlots[slotIndex].unsetBall()
                    ball.physicsBody = nil
                    if self.numberSurpriseBalls == -1 || currentColumn.numOfSurprises > 0 || self.game.isReversedMode {
                        currentColumn.numOfSurprises -= 1
                        let b = self.addNewBall(toColumn: colNumber, isSurprise: true)
                        self.Circle.addChild(b)
                        let scenePosition = CGPoint(x: currentColumn.baseSlot.position.x, y: currentColumn.baseSlot.position.y - self.game.smallDiameter)
                        let positionConverted = self.convert(scenePosition, to: self.Circle)
                        b.position = positionConverted
                        self.animateNewBall(ball: b, deg: self.Circle.zRotation) {
                            // switch the parent without removing it
                            b.move(toParent: self)
                            currentColumn.baseSlot.setBall(ball: b)
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
                    ball.fillColor = UIColor.clear
                    ball.strokeColor = UIColor.clear
                    if let nextBall = zapBalls.filter({ !$0.falling }).last {
                        nextBall.falling = true
                        AudioManager.only.playZapSound(iterations: self.game.slotsPerColumn - 1)
                    }
                    ball.physicsBody = nil
                    colSlots[slotIndex].unsetBall()
                }
            }
        }
    }
    
    // check if we have a full stack, and if so, add its slots to
    // the slotsToClear array... they will get cleared as part of an
    // `update` submethod (now we aren't mutating objects mid-loop).
    // if we have no full stacks, this will just call the completion handler
    func checkForZaps(colNumber: Int, completion: @escaping () -> Void) {
        let colSlots = getSlotsInColumn(num: colNumber)
        let column = columns[colNumber]
        let firstOpenSlot = getFirstOpenSlot(slotList: colSlots)

        if column.hasSurprise && column.baseSlot.ball != nil && column.baseSlot.ball!.isSurprise {
            slotsToClear.append(contentsOf: Array(colSlots[0..<2]))
        }else  if firstOpenSlot == nil {
            slotsToClear.append(contentsOf: colSlots)
        } else {
            completion()
        }
    }

    // spring animation applied to surprise balls
    func animateNewBall(ball: SmallBall, deg: CGFloat, completion: @escaping () -> Void) {
//        let deg = Circle.zRotation
        let x = cos(deg) * game.smallDiameter
        let y = -sin(deg) * game.smallDiameter
        
        let newX = -y
        let newY = x
        
        
        let spring = SKAction.moveBy(x: newX, y: newY, duration: 1.2 , delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0)
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
        skullSlot.setBall(ball: skullBall)
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

    func addNewBall(toColumn num: Int, isSurprise: Bool = false) -> StartingSmallBall {
        let slot = getFirstSlotInColumn(num: num)
        let index = randomInteger(upperBound: game.numberBallColors) - 1
        let newBall = makeStartBall(index: index)
        newBall.isSurprise = isSurprise
        newBall.insidePos = slot.insidePosition
        newBall.startingPos = slot.startPosition
        newBall.stuck = true
        newBall.zPosition = Circle.zPosition - 1
        slot.containsSkull = false
        return newBall
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
            
            slot.setBall(ball: ball) // this will make that position update every frame
            
            ball.stuck = true
            ball.physicsBody?.isDynamic = false

            checkForZaps(colNumber: slot.columnNumber) {
                // completion called from checkForZaps, if there are
                // no full stacks to be zapped
                self.ballsNeedUpdating = true
            }
        }
    }
    
    func setBackgroundToDark() {
        backgroundColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
    }
  
    // duration is 1 sec by default; use this param when calling to change
    func transitionToBgColor(color: UIColor, duration: TimeInterval = 1.1) {
          run(SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: duration))
    }
  
    // duration is 1 sec by default; use this param when calling to change
    func cycleThroughBgColors(duration: TimeInterval = 2.5) {
        var actions = [SKAction]()
        for i in 0..<game.numberBallColors {
            actions.append(SKAction.colorize(with: GameConstants.ballColors[i], colorBlendFactor: 1.0, duration: duration))
        }
        run(SKAction.sequence(actions)) {
            self.cycleThroughBgColors()
        }
    }

    func fadeBackgroundBackToWhite() {
        run(SKAction.colorize(with: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0), colorBlendFactor: 1.0, duration: 0.3))
    }

    func BackgroundBackToWhite() {
        run(SKAction.colorize(with: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0), colorBlendFactor: 1.0, duration: 0.0))
    }
    
    func startGameOverSequence(newBall: SmallBall) {
        stopSpinOverride = true
        canpresspause = false
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
        let shakeLeft = getMoveAction(moveX: -10.0, moveY: 0.0, totalTime: 0.04)
        let shakeRight = getMoveAction(moveX: 10.0, moveY: 0.0, totalTime: 0.04)
        
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
        setFruits(ball: newBall, rando: rando)
        //checkforMemory(ball: newBall)
        return newBall
    }

    func setFruits(ball: SmallBall, rando: Int){
        if let mode = UserDefaults.standard.object(forKey: Settings.TEXTURE_KEY) as? String{
            if mode == Settings.TEXTURE_FRUITS{
                ball.setScale(1.02)
                ball.lineWidth = 0.0
                let currentFruitTexture = randomImageName(imageNumber: rando + 1)
                print(rando)
                let FruitTexture = SKTexture(imageNamed: currentFruitTexture)
                ball.fillTexture = FruitTexture
                ball.fillColor = .white
            }else if mode == Settings.TEXTURE_POOL{
                ball.setScale(1.02)
                ball.lineWidth = 0.0
                let currentPoolTexture = randomImageNamePool(imageNumber: rando + 1)
                print(rando)
                let PoolTexture = SKTexture(imageNamed: currentPoolTexture)
                ball.fillTexture = PoolTexture
                ball.fillColor = .white
            }else if mode == Settings.TEXTURE_BALLS{
                ball.setScale(1.02)
                ball.lineWidth = 0.0
                let currentBallsTexture = randomImageNameBalls(imageNumber: rando + 1)
                print(rando)
                let BallsTexture = SKTexture(imageNamed: currentBallsTexture)
                ball.fillTexture = BallsTexture
                ball.fillColor = .white
            }
        }
    }

    func checkforEscape(ball: SmallBall, index: Int){
        //ToDo: Make the i slot, connect to collum, explosion if you hit it, game over if it's gone, make it bigger so you can see it, make physics body bigger, random time
        let incrementRads = degreesToRad(angle: 360 / CGFloat(game.slotsOnCircle))
        let startRads = incrementRads * CGFloat(index) - degreesToRad(angle: 90.0)
        let newX = (200) * cos(Circle.zRotation - startRads) + Circle.position.x
        let newY = (200) * sin(Circle.zRotation - startRads) + Circle.position.y
        let targetPosition = CGPoint(x: newX, y: newY)
        let escape = SKAction.move(to: targetPosition, duration: 5.0)
        let randoInt = randomInteger(upperBound: 5)
        let wait = SKAction.wait(forDuration: TimeInterval(randoInt))
        ball.run(SKAction.sequence([
            wait,
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
        setFruits(ball: newBall, rando: rando)
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
        guard ballsNeedUpdating else { return }

        // at this point, we are definitely going to either drop a new ball or
        // end the level if the player zapped them all
        // either way, the balls no longer need an update decision; set to false
        ballsNeedUpdating = false

        let shouldAddBall = game.isEndlessMode || game.isReversedMode || game.numberBallsInQueue > 0

        if shouldAddBall {
            let newBall = makeBall()

            if game.isInvisibleMode {
                transitionToBgColor(color: newBall.fillColor)
            }

            var yPos = size.height
            var moveToY = size.height - (game.spinVar + (game.smallDiameter/2))
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

            if !game.isReversedMode { startFallTimer(ball: newBall) }
            else {
                nextBall = newBall
                // if multiplier is less than the max allowed
                if spinMultiplier < reversedModeSpinMultMax {
                    spinMultiplier += 0.02 // spin the circle faster with each ball dropped
                }
          }
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
    func randomImageNamePool(imageNumber: Int) -> String {
            return "Pool-\(imageNumber)"
        }
    func randomImageNameBalls(imageNumber: Int) -> String {
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

func getPoint(a: CGPoint, b: CGPoint, d: CGFloat) -> CGPoint {
    let v = V2sub(a: b, b: a)
    let dist = V2len(v: v)
    let v1 = V2mul(s: 1/dist, a: v)
    let v2 = V2mul(s: -d, a: v1)
    let v3 = V2add(a: a, b: v2)
    return v3
}

// ===========
// game utility functions from shawn
// ===========
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



