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
    var circleDiameter = UIScreen.main.bounds.size.width * 0.55
    let Circle = PlayerCircle(imageNamed: "play")
    var game: Game!
    let ballTextures: [SKTexture] = [
        // your textures here
        // e.g. SKTexture(imageNamed: ""),
        SKTexture(imageNamed: "Icon-1"),
        SKTexture(imageNamed: "Icon-2"),
        SKTexture(imageNamed: "Icon-3"),
        SKTexture(imageNamed: "Icon-4"),
        SKTexture(imageNamed: "Icon-5"),
        SKTexture(imageNamed: "Icon-6"),
        SKTexture(imageNamed: "Icon-7"),
    ]
    
    let names: [String] = [
        "gameCenter",
        "volume",
        "rate",
        "share",
        "endlessMode",
        "hardMode",
        "FruitMode",
        "like"
    ]
    
    // TODO: implement a hit test for the "buttons"
    // example of this is in MenuScene's touchesEnded() and related functions
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
        isPaused = false
        //changes gravity spped up !!!not gravity//
        physicsWorld.gravity = CGVector(dx: 0, dy: 0.0)
        physicsWorld.contactDelegate = self
        
        let startX = CGFloat((size.width / 2))
        let startY = CGFloat((size.height / 3.5))
        let startpos = CGPoint(x: startX, y: startY)
        Circle.position = startpos
        Circle.size = CGSize(width: circleDiameter, height: circleDiameter)
        Circle.name = "playButton"
        
        let body = SKPhysicsBody(texture: Circle.texture!, size: CGSize(width: Circle.size.width - 2, height: Circle.size.height - 2))
        body.categoryBitMask = PhysicsCategory.circleBall
        body.allowsRotation = true
        body.pinned = true
        body.isDynamic = false
        Circle.physicsBody = body
        
        setupBalls()
        
        addChild(Circle)
        
        setVolumeTexture()
    }
    
    func postRestartNotification() {
        let notification = Notification(name: Notification.Name.init(rawValue: "gameRestartRequested"), object: nil, userInfo: nil)
        NotificationCenter.default.post(notification)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    // hit test
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // print("touch")
            
            if let node = nodes(at: touch.location(in: self)).first {
                if node.name == "playButton" {
                    // print("startgameagain")
                    postRestartNotification()
                    node.removeAllChildren()
                    node.removeFromParent()

                } else if node.name == "gameCenter" {
                    // print("gameCenter")
                    del?.gameCenterPressed()
                }else if node.name == "volume" {
                    // print("volume")
                    AudioManager.only.toggleVolume()
                    setVolumeTexture()
                }else if node.name == "rate" {
                    // print("rate")
                    del?.ratePressed()
                }else if node.name == "share" {
                    // print("share")
                    del?.sharePressed()
                }else if node.name == "endlessMode" {
                    // print("no ads")
                }else if node.name == "hardMode" {
                    // print("like")
                }else if node.name == "FruitMode" {
                    // print("like")
                }
                
                AudioManager.only.playClickSound()
            }else{
                    postRestartNotification()
            }
        }
    }
    
    func setVolumeTexture() {
        guard let volumeOn = UserDefaults.standard.object(forKey: Settings.VOLUME_ON_KEY) as? Bool else {
            print("===========/ no volume default found")
            return
        }

        if volumeOn {
            print("~~~~> volume is ON")
            if let volumeNode = childNode(withName: "volume") as? StartingSmallBall {
              volumeNode.fillTexture = SKTexture(image: #imageLiteral(resourceName: "Icon-2OFF"))
            }
        } else if let volumeNode = childNode(withName: "volume") as? StartingSmallBall {
            print("~~~~> volume is OFF")
            volumeNode.fillTexture = SKTexture(image: #imageLiteral(resourceName: "Icon-2"))
        }
    }

    func setupBalls() {
        var balls = [StartingSmallBall]();

        // the radians to separate each starting ball by, when placing around the ring
        let incrementRads = degreesToRad(angle: 360 / CGFloat(6))
        let startPosition = CGPoint(x: size.width / 2, y: Circle.position.y)
        let startDistance: CGFloat = ((0.55 * GameConstants.screenWidth) / 2) + (GameConstants.screenWidth * GameConstants.startingBallScale * 0.5) + 6
        
        for i in 0..<6 {
            // print(i)
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
            
            // print(ball.colorType)

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
        let action = SKAction.move(to: ball.insidePos, duration: 0.5)
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
        
        let newBall = StartingSmallBall(circleOfRadius: (GameConstants.screenWidth * GameConstants.startingBallScale * 0.5) + 6)
        // set the fill color to our random color
        newBall.fillColor = UIColor(red: 255/255, green: 233/255, blue: 233/255, alpha: 1.0)
        
        newBall.alpha = 0.0
        let fadeIn = SKAction.fadeIn(withDuration: 1.2)
        newBall.run(fadeIn){
        }
        newBall.fillTexture = ballTextures[index]
        newBall.name = names[index]
        
        // don't fill the outline
        newBall.lineWidth = 0.0
        
        let body = SKPhysicsBody(circleOfRadius: (GameConstants.screenWidth * GameConstants.startingBallScale * 0.5) + 6)
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
