//
//  Game.swift
//  ColorBall
//
//  Created by Emily Kolar on 12/27/17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import CoreGraphics

/**
 For creating a Game object. Use to manage current game values, track the current score and level, etc. Should be instantiated or re-instantiated for each game played.
 */
class Game {
    // MARK: private properties
    
    // game score
    private var _score: Int = 0
    
    // game level
    private var _level: Int = 1
    
    // starting player circle diameter
    private var _playerDiameter: CGFloat = 200.0
    
    // starting small ball diameter
    private var _smallDiameter: CGFloat = 42.0
    
    // starting value for how often balls are added
    private var _ballInterval = TimeInterval(2.0)
    
    // MARK: properties' public getters
    
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
     Diameter of the player circle (read-only getter).
     */
    var playerDiameter: CGFloat {
        get {
            return _playerDiameter
        }
    }
    
    /**
     Radius of the player circle (read-only getter).
     */
    var radius: CGFloat {
        get {
            return _playerDiameter / 2.0
        }
    }
    
    /**
     Time interval for dropping new balls (read-only getter).
     */
    var ballInterval: Double {
        get {
            return _ballInterval
        }
    }
    
    /**
     Diameter of the player circle (read-only getter).
     */
    var smallDiameter: CGFloat {
        get {
            return _smallDiameter
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


