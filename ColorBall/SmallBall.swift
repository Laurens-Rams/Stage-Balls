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

protocol EnumCollection : Hashable {}
extension EnumCollection {
    static func cases() -> AnySequence<Self> {
        typealias S = Self
        return AnySequence { () -> AnyIterator<S> in
            var raw = 0
            return AnyIterator {
                let current : Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: S.self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw else { return nil }
                raw += 1
                return current
            }
        }
    }
    
    static func cases(removingIndices indices: [Int]) -> AnySequence<Self> {
        typealias S = Self
        return AnySequence { () -> AnyIterator<S> in
            var raw = 0
            return AnyIterator {
                let current : Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: S.self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw, !indices.contains(raw) else { return nil }
                raw += 1
                return current
            }
        }
    }
}

enum BallColor: Int, EnumCollection {
    case blue = 0, pink, red, yellow, green, orange, purple, grey, a, s, d, f, g, h, j, k, l, y, x, c, v, b, n, m, skull
    
    func name() -> String {
        switch self {
        case .blue:
            return "blue"
        case .pink:
            return "pink"
        case .red:
            return "red"
        case .yellow:
            return "yellow"
        case .green:
            return "green"
        case .orange:
            return "orange"
        case .purple:
            return "purple"
        case .grey:
            return "grey"
        case .a:
            return "a"
        case .s:
            return "s"
        case .d:
            return "d"
        case .f:
            return "f"
        case .g:
            return "g"
        case .h:
            return "h"
        case .j:
            return "j"
        case .k:
            return "k"
        case .l:
            return "l"
        case .y:
            return "y"
        case .x:
            return "x"
        case .c:
            return "c"
        case .v:
            return "v"
        case .b:
            return "b"
        case .n:
            return "n"
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
    
    var isMemoryBall = false

    var fallTime: CGFloat = 0
    var falling = false
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

    static let circleBall: UInt32 = 11101110
    static let blueBall: UInt32 = 10101000
    static let pinkBall: UInt32 = 10110010
    static let redBall: UInt32 = 10001010
    
    static let yellowBall: UInt32 = 10001001
    static let greenBall: UInt32 = 10100101
    static let orangeBall: UInt32 = 01111011
    static let purpleBall: UInt32 = 00101001
    
    static let greyBall: UInt32 = 00110101
    
    static let a: UInt32 = 10011010
    static let s: UInt32 = 01000000
    static let d: UInt32 = 10110000
    static let f: UInt32 = 01010011
    static let g: UInt32 = 11111100
    static let h: UInt32 = 11101101
    static let j: UInt32 = 00100101
    static let k: UInt32 = 00011101
    static let l: UInt32 = 10110010
    static let y: UInt32 = 11100100
    static let x: UInt32 = 01100000
    static let c: UInt32 = 11110010
    static let v: UInt32 = 01101011
    static let b: UInt32 = 01010110
    static let n: UInt32 = 01101000
    static let m: UInt32 = 01111111
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
            return a
        case 10:
            return s
        case 11:
            return d
        case 12:
            return f
        case 13:
            return g
        case 14:
            return h
        case 15:
            return j
        case 16:
            return k
        case 17:
            return l
        case 18:
            return y
        case 19:
            return x
        case 20:
            return c
        case 21:
            return v
        case 22:
            return b
        case 23:
            return n
        case 24:
            return m
        case 9:
            return skullBall
        default:
            return blueBall
        }
    }
}
