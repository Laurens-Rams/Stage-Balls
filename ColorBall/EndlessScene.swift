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
        
        // let fadeInSkull = SKAction.fadeIn(withDuration: 2.0)
        //  let moveactionSkull = SKAction.move(to: skullSlot.insidePosition, duration: 2.0)
        
        // let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        // create an action group to run simultaneous actions
        // let actionGroup = SKAction.group([fadeInSkull])
        // skullBall.run(actionGroup)
//        let scale = SKAction.scale(by: 0.2, duration: 1.0)
//        skullBall.run(SKAction.sequence([
//            scale
//            ]))
        addChild(skullBall)
    }
}
