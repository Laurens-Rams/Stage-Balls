//
//  GameOverScene.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 13.01.18.
//  Copyright © 2018 Emily Kolar. All rights reserved.
//
import Foundation
import Darwin
import SpriteKit


/*
 Menu TODOs:
 
 - Run actions for the falling instead of using delta time (need the spacing to be consistent)
 - Menu balls need button press actions
 */

class GameOverSceneOld: SKScene, SKPhysicsContactDelegate {
    
    // MARK: class properties
    
    // player (large circle)
    let Circle = PlayerCircle(imageNamed: "circle")
    var slots = [Slot]()
    // delegate to handle "button" clicks (on nodes)
    var del: StartSceneDelegate?
    
    // direction of rotation
    var direction: CGFloat = -1.0
    
    // ball settings
    var hardness: Float = 0.0
    
    // ball arrays
    var balls = [StartMenuBall]()
    
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
    var forceUpdate = true
    
    // game loop update values
    var lastUpdateTime: TimeInterval = 0
    var dt: CGFloat = 0.0
    
    // delegates
    var scoreKeeper: GameScoreDelegate?
    var gameDelegate: StartGameDelegate?
    
    let numberOfMenuBalls = 6
    var index = 0
    var contactsMade = 0
    
    // MARK: lifecycle methods and overrides
    
    // main update function (game loop)
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTime
        let currentFPS = 1 / deltaTime
        
        dt = 1.0/CGFloat(currentFPS)
        lastUpdateTime = currentTime
        
        updateCircle(dt: dt)
        
        updateBalls(dt: dt)
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        isPaused = false
        //changes gravity spped up !!!not gravity//
        physicsWorld.gravity = CGVector(dx: 0, dy: 0.0)
        physicsWorld.contactDelegate = self
        
        let startX = CGFloat((size.width / 2))
        let startY = CGFloat((size.height / 3))
        let startpos = CGPoint(x: startX, y: startY)
        Circle.position = startpos
        Circle.size = CGSize(width: 200.0, height: 200.0)
        Circle.name = "Player"
        
        let body = SKPhysicsBody(texture: Circle.texture!, size: CGSize(width: Circle.size.width - 2, height: Circle.size.height - 2))
        body.categoryBitMask = PhysicsCategory.circleBall
        body.allowsRotation = true
        body.pinned = true
        body.isDynamic = false
        Circle.physicsBody = body
        
        addChild(Circle)
        
        self.addBall()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            print("touch")
            
            if let node = nodes(at: touch.location(in: self)).first {
                if node.name == "playButton" {
                    print("start ball")
                    handleMenuClick(option: .start)
                } else if let menuNode = node as? StartMenuBall {
                    handleMenuClick(option: menuNode.optionType)
                }
            }
        }
    }
    
    func handleMenuClick(option: MenuOptionType) {
        switch option {
        case .gameCenter:
            print("game center")
            break
        case .like:
            print("like")
            
            break
        case .presents:
            print("presents")
            break
        case .shop:
            // showing a view controller
            // use a StartSceneDelegate method
            del?.launchShop()
            print("shop")
            break
        case .volume:
            print("volume")
            break
        case .rate:
            print("rate")
            break
        case .start:
            print("start")
            del?.launchGame()
            break
        }
    }
    
    // MARK: custom update, animation, and movement methods
    
    /**
     Function to update the circle's rotation.
     - parameters:
     - dt: Last calculated delta time
     */
    func updateCircle(dt: CGFloat) {
        //change animation
        let increment = (((CGFloat(Double.pi) * 0.25) * direction)) * dt
        
        Circle.zRotation = Circle.zRotation + increment
        Circle.distance = Circle.distance + increment
    }
    
    /**
     Update the position of every applicable ball on the screen.
     - parameters:
     - dt: Last calculated delta time
     */
    func updateBalls(dt: CGFloat) {
        // TODO: COMBINE THESE UPDATE METHODS
        for ball in balls {
            var newX: CGFloat
            var newY: CGFloat
            
            if !ball.inLine {
                // if the ball isn't waiting in line to fall
                if !ball.stuck {
                    // if the ball isn't stuck to any other balls yet
                    newX = ball.position.x
                    newY = ball.position.y - 4.0
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
     Start the repeating timer for adding a new ball to the scene.
     */
    func startTimer() {
        let interval = 2.0
        ballTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(addBall), userInfo: nil, repeats: false)
    }
    
    /**
     Start a timer for allowing a ball to fall downward.
     - parameters:
     - ball: A StartMenuBall object.
     */
    func startFallTimer(ball: StartMenuBall) {
        //for how long they stay up (0.0 - 1.8)
        // if you don't want these to be linked, create a new variable in the game object for the fall multiplier (this could cause in-air crashes though)
        fallTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: {
            timer in
            
            ball.inLine = false
        })
    }
    
    func getCircleValues() {
        if !canMove || !forceUpdate {
            Circle.lastTickPosition = Circle.zRotation
            Circle.nextTickPosition = Circle.lastTickPosition + (((CGFloat(Double.pi) * 2) / 15.0) * direction)
            canMove = true
            forceUpdate = true
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
        }
    }
    
    /**
     Handle a collision between the large circle and a small ball.
     - parameters:
     - newBody: The dynamic body (dynamic body has a larger category bitmask, but represents a small ball).
     */
    func handleLargeCollisionWith(newBody: SKPhysicsBody) {
        if let ball = newBody.node as? StartMenuBall {
            print("contact between circle and small ball")
            getBallValues(ball: ball)
            contactsMade += 1
            if index < numberOfMenuBalls {
                getCircleValues()
                self.addBall()
            } else {
                allowToMove = true
                forceUpdate = false
            }
        }
    }
    
    func moveAlongVector(ballA: StartMenuBall, ballB: SKSpriteNode) {
        let dist = distanceBetween(pointA: ballA.position, pointB: ballB.position)
        let v = 42.0 - dist
        let vect = CGVector(dx: (ballA.position.x - ballB.position.x) * v / dist, dy: (ballA.position.y - ballB.position.y) * v / dist)
        ballA.position = CGPoint(x: ballA.position.x + vect.dx, y: ballB.position.y + vect.dy)
    }
    
    func checkDistance(ballA: StartMenuBall, ballB: SKSpriteNode) -> Bool {
        let distance = distanceBetween(pointA: ballA.position, pointB: ballB.position)
        if distance < 42.0 {
            return false
        }
        return true
    }
    
    // TODO: dry-up this code
    func getBallValues(ball: SKNode) {
        if let ball = ball as? StartMenuBall {
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
        } else if let ball = ball as? SkullBall {
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
    }
    
    /**
     Create a small ball to drop from the top.
     - returns: A new StartMenuBall object.
     */
    func makeBall() -> StartMenuBall {
        let image = randomImageName(imageNumber: index + 1)
        let optionType = MenuOptionType(rawValue: index)!
        
        let newBall = StartMenuBall(imageNamed: image)
        newBall.optionType = optionType
        
        newBall.size = CGSize(width: 50.0, height: 50.0)
        
        let body = SKPhysicsBody(circleOfRadius: 40.0)
        // our physics categories are offset by 1, the first entry in the arryay being the bitmask for the player's circle ball
        body.categoryBitMask = PhysicsCategory.blueBall
        body.contactTestBitMask = PhysicsCategory.circleBall
        
        body.restitution = 0
        body.allowsRotation = true
        
        body.usesPreciseCollisionDetection = true
        
        newBall.physicsBody = body
        
        return newBall
    }
    
    /**
     Add a new ball to the array and to the game scene if we can.
     */
    @objc func addBall() {
        
        let newBall = makeBall()
        
        newBall.position = CGPoint(x: size.width / 2, y: size.height - 40)
        
        addChild(newBall)
        
        balls.append(newBall)
        
        index += 1
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
        return "Icon-\(imageNumber)"
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
     - fromBall: StartMenuBall that was hit.
     - returns: CGPoint to snap the newest ball to.
     */
    func getIdealBallPosition(fromBall ball: StartMenuBall) -> CGPoint {
        let xPos = size.width / 2
        let rowMultiplier = CGFloat(ball.inContactWith.count) + 1.5
        let yPos = Circle.position.y + (200.0 / 2) + (42.0 * rowMultiplier)
        return CGPoint(x: xPos, y: yPos)
    }
    
    // []  |
}







