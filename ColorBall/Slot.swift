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
    
    func update(player: PlayerCircle) {
        let newX = self.startDistance * cos(player.zRotation - self.startRads) + player.position.x
        let newY = self.startDistance * sin(player.zRotation - self.startRads) + player.position.y
        self.position = CGPoint(x: newX, y: newY)
        if let ball = self.ball, ball.stuck == true {
            ball.position = self.position
        }
    }
}

class BaseSlot: Slot {
    var startPosition: CGPoint = CGPoint(x: 0, y: 0)
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
        return self.ball != nil
    }
}



