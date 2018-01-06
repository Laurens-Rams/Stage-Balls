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
    case pink = 0, yellow, blue, red, skull
    
    func asColor() -> UIColor {
        switch (self) {
            case .pink:
                return UIColor(red: 0.978, green: 0.458, blue: 0.51, alpha: 1.0)
            case .yellow:
                return UIColor(red: 0.882, green: 0.694, blue: 0.235, alpha: 1.0)
            case .blue:
                return UIColor(red: 0.302, green: 0.6, blue: 0.886, alpha: 1.0)
            case .red:
                return UIColor(red: 0.235, green: 0.549, blue: 0.548, alpha: 1.0)
            default:
                return UIColor.black
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
class SkullBall: SKSpriteNode {
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
}

struct PhysicsCategory {
    static let circleBall: UInt32 = 0b0001
    static let blueBall: UInt32 = 0b0010
    static let pinkBall: UInt32 = 0b0011
    static let redBall: UInt32 = 0b0100
    static let yellowBall: UInt32 = 0b0101
    static let skullBall: UInt32 = 0b1000
    
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
            return skullBall
        default:
            return blueBall
        }
    }
}
