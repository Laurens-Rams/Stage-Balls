//
//  Game.swift
//  ColorBall
//
//  Created by Emily Kolar on 12/27/17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation

class Game {
    // game score
    private var _score: Int = 0
    
    // game level
    private var _level: Int = 1
    
    // score (read only)
    var score: Int {
        get {
            return _score
        }
    }
    
    // level (read only)
    var level: Int {
        get {
            return _level
        }
    }
    
    /**
     Increment the game level by 1.
     */
    func increaseLevel() {
        _level += 1
    }
    
    /**
     Increment the score by an integer value.
     - parameters:
        - byValue: How much to add to the score.
     */
    func increaseScore(byValue: Int) {
        _score += byValue
    }
}


