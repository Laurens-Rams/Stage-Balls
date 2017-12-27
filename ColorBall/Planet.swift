//
//  Planet.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/13/17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation
import SpriteKit

class Planet: SKSpriteNode {
    
    private var _gravityRange: CGFloat = 0
    private var _gravMultiplier: CGFloat = 0
    
    func setGravityRange(range: CGFloat) {
        _gravityRange = range
    }
    
    func setGravityRange() -> CGFloat {
        return _gravityRange
    }
    
    func setGravityMultiplier(mult: CGFloat) {
        _gravMultiplier = mult
    }
    
    func getGravityMultiplier() -> CGFloat {
        return _gravMultiplier
    }
    
    func doGravityUpdate(children: [SKNode]) {
        for node in children {
            if let child = node as? SmallBall {
                if child.stuck == false {
                    let deltaX = self.position.x - node.position.x
                    let deltaY = self.position.y - node.position.y
                    let powX = deltaX * deltaX
                    let powY = deltaY * deltaY
                    let result = sqrt(powX + powY)
                    
                    if result <= _gravityRange {
                        let vector = CGVector(dx: (self.position.x - node.position.x) * _gravMultiplier, dy: (self.position.y - node.position.y) * CGFloat(_gravMultiplier))
                        node.physicsBody?.applyForce(vector)
                    }
                }
            }
            else {
                let deltaX = self.position.x - node.position.x
                let deltaY = self.position.y - node.position.y
                let powX = deltaX * deltaX
                let powY = deltaY * deltaY
                let result = sqrt(powX + powY)
                
                if result <= _gravityRange {
                    let vector = CGVector(dx: (self.position.x - node.position.x) * _gravMultiplier, dy: (self.position.y - node.position.y) * CGFloat(_gravMultiplier))
                    node.physicsBody?.applyForce(vector)
                }
            }
        }
    }
}
