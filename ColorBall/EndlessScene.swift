//
//  EndlessScene.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/16/18.
//  Copyright © 2018 Laurens Ramsenthaler. All rights reserved.
//

import Foundation
import SpriteKit

class EndlessScene: GameScene {
    override func addSkull(toColumn num: Int) {
        let skullSlot = getFirstSlotInColumn(num: num)
        let index = randomInteger(upperBound: game.numberBallColors) - 1
        let skullBall = makeStartBall(index: index)
        skullBall.insidePos = skullSlot.insidePosition
        skullBall.startingPos = skullSlot.startPosition
        skullSlot.ball = skullBall
        skullBall.position = skullSlot.position
        skullBall.stuck = true
        skullBall.zPosition = -5
        skullSlot.containsSkull = false
        addChild(skullBall)
    }
}
