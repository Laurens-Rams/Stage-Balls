//
//  SmallBall.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 18.07.17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation
import SpriteKit

class SmallBall: SKSpriteNode {
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
}

class StartingSmallBall: SmallBall {
    var startingPos: CGPoint = CGPoint(x: 0, y: 0)
    var insidePos: CGPoint = CGPoint(x: 0, y: 0)
}

struct PhysicsCategory {
    static let circleBall: UInt32 = 0b0001
    static let blueBall: UInt32 = 0b0010
    static let pinkBall: UInt32 = 0b0011
    static let redBall: UInt32 = 0b0100
    static let yellowBall: UInt32 = 0b0101
    
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
        default:
            return blueBall
        }
    }
}
