//
//  SmallBall.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 18.07.17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import SpriteKit

// EMILY TODO:
// - outline a game ball superclass SKNode, which we can implement together

enum BallColor: Int {
    case blue = 0, pink, red, yellow, green, orange, purple, grey, skull
    
    func name() -> String {
        switch self {
        case .blue:
            return "blue"
        case .pink:
            return "pink"
        default:
            return "ball"
        }
    }
}

class SmallBall: SKShapeNode {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var inLine: Bool = false
    var stuck = false
    var lastVelocity: CGVector = CGVector(dx: 0, dy: 0)
    var angularDistance: CGFloat = 0
    var orbitRadius = CGPoint(x: 0, y: 0)
    var startDistance: CGFloat = 0
    var startRads: CGFloat = 0
    var inContactWith = [SmallBall]()
    // non-optional type
    var colorType: BallColor!
    var emitterPoint: CGPoint!
    var isStarter: Bool {
        return false
    }
}

class StartingSmallBall: SmallBall {
    override var isStarter: Bool {
        return true
    }
    var startingPos: CGPoint = CGPoint(x: 0, y: 0)
    var insidePos: CGPoint = CGPoint(x: 0, y: 0)
}

// TODO: make an interface or protocol for all these properties
class SkullBall: StartingSmallBall {
}

class StartMenuBall: SKSpriteNode {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var inLine: Bool = false
    var stuck = false
    var lastVelocity: CGVector = CGVector(dx: 0, dy: 0)
    var angularDistance: CGFloat = 0
    var orbitRadius = CGPoint(x: 0, y: 0)
    var startDistance: CGFloat = 0
    var startRads: CGFloat = 0
    var inContactWith = [SmallBall]()
    // non-optional type
    var colorType: BallColor = BallColor.skull
    var isStarter: Bool = true
    var startingPos: CGPoint = CGPoint(x: 0, y: 0)
    var insidePos: CGPoint = CGPoint(x: 0, y: 0)
    var optionType: MenuOptionType = MenuOptionType.gameCenter
}

struct PhysicsCategory {
    static let circleBall: UInt32 = 0b0001
    static let blueBall: UInt32 = 0b0010
    static let pinkBall: UInt32 = 0b0011
    static let redBall: UInt32 = 0b0100
    static let yellowBall: UInt32 = 0b0101
    static let greenBall: UInt32 = 0b0110
    static let orangeBall: UInt32 = 0b0111
    static let purpleBall: UInt32 = 0b1000
    static let greyBall: UInt32 = 0b1001
    static let skullBall: UInt32 = 0b1011
    
    static func returnCategory(num: Int) -> UInt32 {
        switch (num) {
        case 1:
            return blueBall
        case 2:
            return pinkBall
        case 3:
            return redBall
        case 4:
            return yellowBall
        case 5:
            return greenBall
        case 6:
            return orangeBall
        case 7:
            return purpleBall
        case 8:
            return greyBall
        case 9:
            return skullBall
        default:
            return blueBall
        }
    }
}
