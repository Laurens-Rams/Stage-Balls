//
//  Game.swift
//  ColorBall
//
//  Created by Emily Kolar on 12/27/17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import CoreGraphics

/* TODO:

 - Snap balls to columns (fix extreme air hovering)
 - Increment game levels after each row (more stages)
 - Make changes to balls, speed, etc for each level
 - Getting items/presents every 6 hours (the timer is done, we just to make the items)
 - Backgrounds
 
 */

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
    
    // counts for each type of physics category on the screen
    private var _blues = 0
    private var _pinks = 0
    private var _reds = 0
    private var _yellows = 0
    
    // MARK: properties' public getters
    
    /**
     Number of blues in game (read-only getter).
     */
    var blues: Int {
        get {
            return _blues
        }
    }
    
    /**
     Number of reds in game (read-only getter).
     */
    var reds: Int {
        get {
            return _reds
        }
    }
    
    /**
     Number of pinks in game (read-only getter).
     */
    var pinks: Int {
        get {
            return _pinks
        }
    }
    
    /**
     Number of yellows in game (read-only getter).
     */
    var yellows: Int {
        get {
            return _yellows
        }
    }
    
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
    
    /**
     Increment the numer of a given ball type by 1.
     - parameters:
     - type: What type of ball to increment.
     */
    func incrementBallType(type: BallType) {
        switch (type) {
            case .red:
                _reds += 1
                break
            case .blue:
                _blues += 1
                break
            case .pink:
                _pinks += 1
                break
            case .yellow:
                _yellows += 1
                break
            default: break
        }
    }
    
    /**
     Increment the numer of a given ball type by 1.
     - parameters:
     - type: What type of ball to increment.
     - byNumber: How many to subtract.
     */
    func decrementBallType(type: BallType, byNumber: Int) {
        switch (type) {
            case .red:
                _reds -= byNumber
                break
            case .blue:
                _blues -= byNumber
                break
            case .pink:
                _pinks -= byNumber
                break
            case .yellow:
                _yellows -= byNumber
                break
            default: break
        }
    }
    
    /**
     Get the count of a ball type.
     - parameters:
     - type: The ball type to count.
     - returns: The number of balls of that type.
     */
    func getCountForType(type: BallType) -> Int {
        switch (type) {
            case .red:
                return reds
            case .blue:
                return blues
            case .pink:
                return pinks
            case .yellow:
                return yellows
            default: return 0
        }
    }
}


