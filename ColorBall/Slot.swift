//
//  Column.swift
//  ColorBall
//
//  Created by Emily Kolar on 1/10/18.
//  Copyright © 2018 Emily Kolar. All rights reserved.
//

import Foundation
import SpriteKit

enum SlotType: Int {
    case base = 0, slot
}

class Slot {
    var isBaseSlot: Bool {
        return false
    }
    var dot: SKShapeNode!
    var containsSkull = false
    var position: CGPoint = CGPoint(x: 0, y: 0)
    var stuck = false
    var startDistance: CGFloat = 0
    var endDistance: CGFloat = 0
    var diameter: CGFloat = 0
    var startRads: CGFloat = 0
    var colorType: BallColor!
    var isStarter = false
    var columnNumber: Int = -1
    var ball: SmallBall?
    var slotType: SlotType {
        get {
            return SlotType.slot
        }
    }
    
    init(position: CGPoint, startRads: CGFloat, isStarter: Bool, distance: CGFloat) {
        self.position = position
        self.startRads = startRads
        self.isStarter = isStarter
        self.startDistance = distance
    }
    
    func setBall(ball: SmallBall) {
        self.ball = ball
        self.colorType = ball.colorType
    }
    
    func lerp(a: CGFloat, b: CGFloat, t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }
    
    func update(player: PlayerCircle, dt: CGFloat) {
        var f = startDistance

        if let ball = ball, ball.stuck, ball.falling {
            if ball.fallTime > 0 {
                ball.fallTime -= dt
            }
            f = lerp(a: startDistance - diameter, b: startDistance, t: ball.fallTime / GameConstants.ballZapDuration)
        }

        let newX = f * cos(player.zRotation - startRads) + player.position.x
        let newY = f * sin(player.zRotation - startRads) + player.position.y
        position = CGPoint(x: newX, y: newY)

        if let ball = ball, ball.stuck {
            ball.position = position
        }
    }
}

class BaseSlot: Slot {
    var startPosition: CGPoint = CGPoint(x: 0, y: 0)
    var coversSurpriseBall: Bool = false

    override var slotType: SlotType {
        get {
            return SlotType.base
        }
    }

    var insidePosition: CGPoint = CGPoint(x: 0, y: 0)

    init(position: CGPoint, startPosition: CGPoint, insidePosition: CGPoint, startRads: CGFloat, isStarter: Bool, distance: CGFloat) {
        super.init(position: position, startRads: startRads, isStarter: true, distance: distance)
        self.insidePosition = insidePosition
        self.startPosition = startPosition
    }
    
    func setBall(ball: StartingSmallBall) {
        super.setBall(ball: ball)
    }
    
    var isFull: Bool {
        return ball != nil
    }
}



