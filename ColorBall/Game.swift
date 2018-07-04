//
//  Game.swift
//  ColorBall
//
//  Created by Emily Kolar on 12/27/17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

/* TODO:

 - Getting items/presents every 6 hours (the timer is done, we just to make the items)
 
 */

struct GameConstants {
    // MARK: static properties

    static let initialSlotsOnCircle: CGFloat = 13
    static let initialSlotsPerColumn = 2

    static let ballZapDuration: CGFloat = 0.2

    static let screenWidth: CGFloat = UIScreen.main.bounds.size.width

    static let startingCircleScale: CGFloat = 0.55
    static let startingBallScale: CGFloat = 0.116

    static let startingBallRadiusScale: CGFloat = GameConstants.startingBallScale * 0.5
    static let startingCircleDiameter: CGFloat = GameConstants.screenWidth * GameConstants.startingCircleScale
    static let startingOuterDiameter: CGFloat = GameConstants.startingCircleDiameter + (GameConstants.screenWidth * GameConstants.startingBallRadiusScale)
    
    static let ballColors: [UIColor] = [
        UIColor(red: 48/255, green: 153/255, blue: 232/255, alpha: 1.0),
        UIColor(red: 247/255, green: 117/255, blue: 132/255, alpha: 1.0),
        UIColor(red: 63/255, green: 139/255, blue: 138/255, alpha: 1.0),
        UIColor(red: 223/255, green: 175/255, blue: 71/255, alpha: 1.0),
        UIColor(red: 124/255, green: 45/255, blue: 243/255, alpha: 1.0),
        UIColor(red: 117/255, green: 228/255, blue: 179/255, alpha: 1.0),
        UIColor(red: 255/255, green: 00/255, blue: 00/255, alpha: 1.0),
        UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0),
    ]
    
    static let backgroundColors: [UIColor] = [
        UIColor.white
    ]
}

/**
 For creating a Game object. Use to manage current game values, track the current score and level, etc. Should be instantiated or re-instantiated for each game played.
 */
class Game {
    // MARK: private properties

    // number balls fallen in current stage
    // TODO: create a "stage" object to manage all stage-related vars
    private var _ballsFallen = 0

    // game level
    private var _stage: Int = 1
    
    // starting player circle diameter
    private var _playerDiameter: CGFloat = GameConstants.startingCircleDiameter
    private var _outerDiameter: CGFloat = GameConstants.startingOuterDiameter
    private var _minOuterDiameter: CGFloat = GameConstants.startingOuterDiameter

    
    // starting small ball diameter
    private var _smallDiameter: CGFloat = GameConstants.screenWidth * GameConstants.startingBallScale
    
    // multiplier for speeds
    // this controls the frequency of things falling
    // how often things fall
    private var _speedMultiplier: Double = 0.01
    
    // multiplier for gravity
    // this is the multiplied amount by which things fall faster
    private var _gravityMultiplier: Double = 0.04
    
    // starting value for how often balls are added
    private var _ballInterval = TimeInterval(1.8)
    
    // number of balls on starting row
    private var _numberStartingBalls = 2
    
    // number of colors to use this stage
    private var _numberBallColors = 4
    
    // keep track of extra chance
    private var _extraChance = 1
    
    private var _slotsPerColumn = GameConstants.initialSlotsPerColumn
    
    // counts for each type of physics category on the screen
    private var _blues = 0
    private var _pinks = 0
    private var _reds = 0
    private var _yellows = 0
    private var _greens = 0
    private var _purples = 0
    private var _oranges = 0
    private var _greys = 0
    private var _skulls = 0
    
    init(startingStage: Int) {
        _stage = 10
        print("NUMBER STARTING BALLS:", numberStartingBalls)
    }

    // we'll flip this to false later to test the other option
    var endGameOnCircleCollision = true
    
    // MARK: properties' public getters
    
    var slotsOnCircle: Int {
        get {
            return numberStartingBalls <= 13 ? 13 : numberStartingBalls
        }
    }
    
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
     Number of greens in game (read-only getter).
     */
    var greens: Int {
        get {
            return _greens
        }
    }
    /**
     Number of purples in game (read-only getter).
     */
    var purples: Int {
        get {
            return _purples
        }
    }
    /**
     Number of oranges in game (read-only getter).
     */
    var oranges: Int {
        get {
            return _oranges
        }
    }
    
    /**
     Number of greys in game (read-only getter).
     */
    var greys: Int {
        get {
            return _greys
        }
    }


    /**
     Number of skulls in game (read-only getter).
     */
    var skulls: Int {
        get {
            return _skulls
        }
    }

    /**
     The number of balls that have dropped in current stage (read-only).
    */
    var ballsFallen: Int {
        get {
            return _ballsFallen
        }
    }

    /**
     The number of balls remaining to fall in the current stage.
     */
    var ballsRemaining: Int {
        get {
            return numberBallsInQueue - ballsFallen
        }
    }

    /**
     Number of balls remaining that will fall in current stage.
     */
    var numberBallsInQueue: Int {
        get {
            return (_stage + 1) * (_slotsPerColumn - 1)
        }
    }
    
    /**
     The current game stage (read-only getter).
     */
    var stage: Int {
        get {
            return _stage
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
     Number of starting balls (read-only getter).
     */
    var numberStartingBalls: Int {
        get {
            let amountToAdd = _stage - 1
            let newStart = _numberStartingBalls + amountToAdd
            if newStart > 24 { return 24 }
            return newStart
        }
    }
    
    /**
     Multiplier for ball speeds (read-only getter).
     */
    var speedMultiplier: Double {
        get {
            return 1.0 - (Double(_stage - 1) * _speedMultiplier)
        }
    }
    
    /**
     Multiplier for ball falling speed ("gravity") (read-only getter).
     */
    var gravityMultiplier: Double {
        get {
            return Double(_stage - 1) * _gravityMultiplier
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
            let minDiameter = (GameConstants.startingOuterDiameter * CGFloat(Double.pi)) / CGFloat(numberStartingBalls)

            if numberStartingBalls >= 24 { return minDiameter }

            let newDiameter = ((14 * GameConstants.startingBallScale) / CGFloat(numberStartingBalls)) * UIScreen.main.bounds.size.width

            if (newDiameter < _smallDiameter) { return newDiameter }

            return _smallDiameter
        }
    }
    
    /**
     How high the balls should be able to stack (read-only getter).
     */
    var slotsPerColumn: Int {
        get {
            if _stage < 13 { return _slotsPerColumn }
            else if _stage < 24 { return _slotsPerColumn + 1 }
            else if _stage < 29 { return _slotsPerColumn + 2 }
            else {
                let multiplesOfTwenty = Int(round(Double(_stage - 9) / 20))
                return _slotsPerColumn + 2 + multiplesOfTwenty
            }
        }
    }

    
    /**
     One extra chance to beat the level. (read-only getter).
     */
    var extraChance: Int {
        get {
            return _extraChance
        }
    }
    
    /**
     The current background color (read-only getter).
     */
    var backgroundColor: UIColor {
        get {
            return GameConstants.backgroundColors[0]
        }
    }
    
    /**
     Increment the game level by 1.
     */
    func increaseStage() {
        _stage += 1
        if _outerDiameter > _minOuterDiameter {
            _outerDiameter -= 2
        }
        print("increased stage to \(_stage)")

        if _stage >= 24 && _stage <= 29 {
            _numberBallColors += 1
        }

//        if (_stage >= 14 && _stage <= 23) {
//            _smallDiameter -= (14 * 0.11) / CGFloat(numberBallsInQueue + numberStartingBalls)
//        }
    }
    
    /**
     Increment the score by an integer value.
     - parameters:
        - byValue: How much to add to the score.
     */
    func increaseScore(byValue: Int) {
        _ballsFallen += byValue
    }
    
    /**
     Increment the score by an integer value.
     - returns: Whether we successfully used the extra chance.
     */
    func useExtraChance() -> Bool {
        if _extraChance >= 1 {
            _extraChance = 0
            return true
        }
        return false
    }
    
    /**
     Increment the numer of a given ball type by 1.
     - parameters:
     - type: What type of ball to increment.
     */
    func incrementBallType(type: BallColor) {
        switch (type) {
            case .blue:
                _blues += 1
                break
            case .pink:
                _pinks += 1
                break
            case .red:
                _reds += 1
                break
            case .yellow:
                _yellows += 1
                break
            case .green:
                _greens += 1
                break
            case .purple:
                _purples += 1
                break
            case .orange:
                _oranges += 1
                break
            case .grey:
                _greys += 1
                break
            case .skull:
                _skulls += 1
        }
    }
    
    /**
     Increment the numer of a given ball type by 1.
     - parameters:
     - type: What type of ball to increment.
     - byNumber: How many to subtract.
     */
    func decrementBallType(type: BallColor, byNumber: Int) {
        switch (type) {
            case .blue:
                _blues -= byNumber
                break
            case .pink:
                _pinks -= byNumber
                break
            case .red:
                _reds -= byNumber
                break
            case .yellow:
                _yellows -= byNumber
                break
            case .green:
                _greens -= byNumber
                break
            case .purple:
                _purples -= byNumber
                break
            case .orange:
                _oranges -= byNumber
                break
            case .grey:
                _greys -= byNumber
                break
            case .skull:
                _skulls -= byNumber
        }
    }
    
    /**
     Get the count of a ball type.
     - parameters:
     - type: The ball type to count.
     - returns: The number of balls of that type.
     */
    func getCountForType(type: BallColor) -> Int {
        switch (type) {
            case .blue:
                return blues
            case .pink:
                return pinks
            case .red:
                return reds
            case .yellow:
                return yellows
            case .green:
                return greens
            case .orange:
                return oranges
            case .purple:
                return purples
            case .grey:
                return greys
            case .skull:
                return skulls
        }
    }
    
    /**
     Reset the count of every ball type (color) to zero, e.g. on a game reset
     */
    func resetAllBallTypeCounts() {
        _blues = 0
        _pinks = 0
        _reds = 0
        _yellows = 0
        _greens = 0
        _oranges = 0
        _purples = 0
        _greys = 0
        _skulls = 0
    }

    func resetBallsFallen() {
        _ballsFallen = 0
    }

    // reset everything, e.g. on start of a new game
    func resetAll() {
        resetAllBallTypeCounts()
        resetBallsFallen()
    }
}


