//
//  Scene2.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/15/17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation
import Darwin
import SpriteKit

class Scene2: SKScene, SKPhysicsContactDelegate {
    
    let Circle = PlayerCircle(imageNamed: "circle")
    
    var score: Int = 0
    
    let diameter = CGFloat(200.0)
    let radius = CGFloat(100.0)
    
    let smallDiameter = CGFloat(42)
    var hardness: Float = 0.0
    
    var balls = [SmallBall]()
    
    var startBalls = [StartingSmallBall]()
    
    var rotation: SKAction!
    
    var runRotation: SKAction!
    
    var fall: SKAction!
    
    var ballTimer: Timer?
    
    var fallTimer: Timer!
    
    var touchTimer: Timer!
    
    var direction: CGFloat = -1.0
    
    var scoreKeeper: GameScoreDelegate?
    
    var isTouching = false
    
    var allowtomove = false
    //for how often they are added
    var ballInterval = TimeInterval(2.0)
    
    var chain = 0
    
    var spinBalls: [SKSpriteNode]!
    
    var lastUpdateTime: TimeInterval = 0
    
    var dt: CGFloat = 0.0
    
    var canMove = false
    
    var gameoverdelegate: StartGameDelegate?
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        let currentFPS = 1 / deltaTime
        dt = 1.0/CGFloat(currentFPS)
        
        if canMove {
            updateCircle(dt: dt)
        }
        updateBalls(dt: dt)
        
    }
    
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
    
    func updateBalls(dt: CGFloat) {
        for ball in balls {
            var newX: CGFloat
            var newY: CGFloat
            if ball.inLine {
                continue
            }
            if !ball.stuck {
                newX = ball.position.x
                //change Gravity
                newY = ball.position.y - 4
            }
            else {
                newX = ball.startDistance * cos(Circle.zRotation - ball.startRads) + Circle.position.x
                newY = ball.startDistance * sin(Circle.zRotation - ball.startRads) + Circle.position.y
            }
            ball.position = CGPoint(x: newX, y: newY)
        }
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
    
    
    func setupBalls() {
        print("setup")
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
            print("animating balls")
            animateBall(ball: startBalls[i])
        }
    }
    
    func animateBall(ball: StartingSmallBall) {
        let action = SKAction.move(to: ball.insidePos, duration: 1.2)
        ball.run(action)
    }
    
    func startTimer() {
        print("ball timer starting")
        ballTimer = Timer.scheduledTimer(timeInterval: ballInterval, target: self, selector: #selector(addBall), userInfo: nil, repeats: true)
        allowtomove = true
    }
    
    func startFallTimer(ball: SmallBall) {
        print("fall timer starting")
        //for how long they stay up (0.0 - 1.8)
        fallTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: {
            timer in
            
            ball.inLine = false
        })
    }
    
    func startTouchTimer() {
        //timer for nothing
        touchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
            self.canMove = true
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isTouching {
            return
        }else if(allowtomove == true){
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
    
    func getCircleValues() {
        if !canMove {
            Circle.lastTickPosition = Circle.zRotation
            Circle.nextTickPosition = Circle.lastTickPosition + (((CGFloat(Double.pi) * 2) / 15) * direction)
            canMove = true
        }
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
        
        
        if firstBody.categoryBitMask == PhysicsCategory.circleBall || secondBody.categoryBitMask == PhysicsCategory.circleBall {
            if let ball = secondBody.node as? SmallBall {
                print("contact between circle and ball")
                getBallValues(ball: ball)
                return
                increaseScore(byValue: 1)
            }
        }
            
            
        else if firstBody.categoryBitMask == secondBody.categoryBitMask {
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
            }
            else if secondBody.isDynamic == true {
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
            
        }
        else if firstBody.categoryBitMask != secondBody.categoryBitMask {
            self.isPaused = true
            self.ballTimer?.invalidate()
            gameoverdelegate?.gameover()
            
        }
        
    }
    
    func increaseScore(byValue: Int) {
        scoreKeeper?.increaseScore(byValue: byValue)
    }
    
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
        print(distance)
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
    
    func makeBall() -> SmallBall {
        var categories = [
            PhysicsCategory.circleBall,
            PhysicsCategory.blueBall,
            PhysicsCategory.pinkBall,
            PhysicsCategory.redBall,
            PhysicsCategory.yellowBall
        ]
        
        let rando = randomInteger()
        print(rando)
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
    
    func addBall() {
        
        hardness = hardness + 0.1
        print(hardness)
        
        let newBall = makeBall()
        
        newBall.position = CGPoint(x: size.width / 2, y: size.height - 40)
        
        newBall.inLine = true
        
        addChild(newBall)
        
        startFallTimer(ball: newBall)
        
        balls.append(newBall)
        
    }
    
    // MARK: utilities
    
    //return a random integer
    func randomInteger() -> Int {
        return Int(arc4random_uniform(4) + UInt32(1))
    }
    
    // a function to return a random image name
    func randomImageName(imageNumber: Int) -> String {
        return "ball-\(imageNumber)"
    }
    
    func degreesToRad(angle: CGFloat) -> CGFloat {
        return angle * (CGFloat(Double.pi) / 180)
    }
    
    func radiansToDeg(angle: CGFloat) -> CGFloat {
        return angle * (CGFloat(Double.pi) * 180)
    }
    
    func distanceBetween(pointA: CGPoint, pointB: CGPoint) -> CGFloat {
        return sqrt(pow(pointB.x - pointA.x, 2) + pow(pointB.y - pointA.y, 2))
    }
    
    // []  |
    
    
}





