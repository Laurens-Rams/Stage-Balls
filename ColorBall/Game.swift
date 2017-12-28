//
//  Game.swift
//  ColorBall
//
//  Created by Emily Kolar on 12/27/17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation

/**
 For creating a Game object. Use to manage current game values, track the current score and level, etc. Should be instantiated or re-instantiated for each game played.
 */
class Game {
    // MARK: private properties
    
    // game score
    private var _score: Int = 0
    
    // game level
    private var _level: Int = 1
    
    // MARK: public properties/getters
    
    /**
     The current game score (read-only getter).
     */
    var score: Int {
        get {
            return _score
        }
    }
    
    /**
     The current game level (read-only getter).
     */
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


