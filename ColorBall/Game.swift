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
    static let startingBallScale: CGFloat = 0.11

    static let startingBallRadiusScale: CGFloat = GameConstants.startingBallScale * 0.5
    static let startingCircleDiameter: CGFloat = GameConstants.screenWidth * GameConstants.startingCircleScale
    static let startingOuterDiameter: CGFloat = GameConstants.startingCircleDiameter + (GameConstants.screenWidth * GameConstants.startingBallRadiusScale)
    
    static let ballColors: [UIColor] = [
//        UIColor(red: 48/255, green: 153/255, blue: 232/255, alpha: 1.0),
//        UIColor(red: 247/255, green: 117/255, blue: 132/255, alpha: 1.0),
//        UIColor(red: 63/255, green: 139/255, blue: 138/255, alpha: 1.0),
//        UIColor(red: 223/255, green: 175/255, blue: 71/255, alpha: 1.0),
//        UIColor(red: 124/255, green: 45/255, blue: 243/255, alpha: 1.0),
//        UIColor(red: 117/255, green: 228/255, blue: 179/255, alpha: 1.0),
//        UIColor(red: 255/255, green: 00/255, blue: 00/255, alpha: 1.0),
//        UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0),
        

 //1
 UIColor(red: 255/255, green: 141/255, blue: 193/255, alpha: 1.0),
 //2
 UIColor(red: 0/255, green: 104/255, blue: 255/255, alpha: 1.0),
 //3
 UIColor(red: 255/255, green: 190/255, blue: 2/255, alpha: 1.0),
 //4
 UIColor(red: 5/255, green: 153/255, blue: 149/255, alpha: 1.0),
 //5
 UIColor(red: 45/255, green: 222/255, blue: 252/255, alpha: 1.0),
 //6
 UIColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 1.0),
 //7
 UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0),
 //8
 UIColor(red: 57/255, green: 247/255, blue: 134/255, alpha: 1.0),
 
 // UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1.0), --> hard one
 //9
 UIColor(red: 247/255, green: 117/255, blue: 132/255, alpha: 1.0),
 //10
 UIColor(red: 214/255, green: 98/255, blue: 19/255, alpha: 1.0),
 //11
 UIColor(red: 166/255, green: 196/255, blue: 70/255, alpha: 1.0),
 //12
 UIColor(red: 179/255, green: 50/255, blue: 201/255, alpha: 1.0),
 //13
 UIColor(red: 154/255, green: 172/255, blue: 211/255, alpha: 1.0),
 //14
 UIColor(red: 29/255, green: 77/255, blue: 104/255, alpha: 1.0),
 //15
 UIColor(red: 52/255, green: 171/255, blue: 224/255, alpha: 1.0),
 //16
 UIColor(red: 255/255, green: 221/255, blue: 51/255, alpha: 1.0),
 //17
 UIColor(red: 93/255, green: 69/255, blue: 53/255, alpha: 1.0),
 //18
 UIColor(red: 100/255, green: 24/255, blue: 119/255, alpha: 1.0),
 //19
 UIColor(red: 239/255, green: 221/255, blue: 182/255, alpha: 1.0),
 //20
 UIColor(red: 137/255, green: 46/255, blue: 44/255, alpha: 1.0),
 //21
 UIColor(red: 100/255, green: 109/255, blue: 108/255, alpha: 1.0),
 //22
 UIColor(red: 175/255, green: 150/255, blue: 133/255, alpha: 1.0),
 //23
 UIColor(red: 239/255, green: 96/255, blue: 113/255, alpha: 1.0),
 //24
 UIColor(red: 224/255, green: 30/255, blue: 58/255, alpha: 1.0),

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
    private var _speedMultiplier: Double = 0.005
    
    // multiplier for gravity
    // this is the multiplied amount by which things fall faster
    private var _gravityMultiplier: Double = 0.02
    
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
    private var _a = 0
    private var _s = 0
    private var _d = 0
    private var _f = 0
    private var _g = 0
    private var _h = 0
    private var _j = 0
    private var _k = 0
    private var _l = 0
    private var _y = 0
    private var _x = 0
    private var _c = 0
    private var _v = 0
    private var _b = 0
    private var _n = 0
    private var _m = 0
    private var _skulls = 0
    
    init(startingStage: Int) {
        _stage = startingStage
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
    var a: Int {
        get {
            return _blues
        }
    }
    
    /**
     Number of reds in game (read-only getter).
     */
    var s: Int {
        get {
            return _reds
        }
    }
    
    /**
     Number of pinks in game (read-only getter).
     */
    var d: Int {
        get {
            return _pinks
        }
    }
    
    /**
     Number of yellows in game (read-only getter).
     */
    var f: Int {
        get {
            return _yellows
        }
    }
    /**
     Number of greens in game (read-only getter).
     */
    var g: Int {
        get {
            return _greens
        }
    }
    /**
     Number of purples in game (read-only getter).
     */
    var h: Int {
        get {
            return _purples
        }
    }
    /**
     Number of oranges in game (read-only getter).
     */
    var j: Int {
        get {
            return _oranges
        }
    }
    
    /**
     Number of greys in game (read-only getter).
     */
    var k: Int {
        get {
            return _greys
        }
    }
    var l: Int {
        get {
            return _blues
        }
    }
    
    /**
     Number of reds in game (read-only getter).
     */
    var y: Int {
        get {
            return _reds
        }
    }
    
    /**
     Number of pinks in game (read-only getter).
     */
    var x: Int {
        get {
            return _pinks
        }
    }
    
    /**
     Number of yellows in game (read-only getter).
     */
    var c: Int {
        get {
            return _yellows
        }
    }
    /**
     Number of greens in game (read-only getter).
     */
    var v: Int {
        get {
            return _greens
        }
    }
    /**
     Number of purples in game (read-only getter).
     */
    var b: Int {
        get {
            return _purples
        }
    }
    /**
     Number of oranges in game (read-only getter).
     */
    var n: Int {
        get {
            return _oranges
        }
    }
    
    /**
     Number of greys in game (read-only getter).
     */
    var m: Int {
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
            return (_stage + 1) * (slotsPerColumn - 1)
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
            let newDiameter = ((15 * GameConstants.startingBallScale) / CGFloat(numberStartingBalls)) * UIScreen.main.bounds.size.width
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
                let newSlots = _slotsPerColumn + 2 + multiplesOfTwenty
                if newSlots > 5 { return 5 }
                return newSlots
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
    
    var numberBallColors: Int {
        get {
            if _stage <= 24 { return _numberBallColors }
            if _stage >= 84 { return 24 }
            let numberToAdd = Int((_stage - 24) / 3)
           return _numberBallColors + Int(numberToAdd)
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

       // if _stage >= 24 && _stage <= 29 {
        //    _numberBallColors += 1
       // }

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
            case .a:
                _a += 1
                break
            case .s:
                _s += 1
                break
            case .d:
                _d += 1
                break
            case .f:
                _f += 1
                break
            case .g:
                _g += 1
                break
            case .h:
                _h += 1
                break
            case .j:
                _j += 1
                break
            case .k:
                _k += 1
                break
            case .l:
                _l += 1
                break
            case .y:
                _y += 1
                break
            case .x:
                _x += 1
                break
            case .c:
                _c += 1
                break
            case .v:
                _v += 1
                break
            case .b:
                _b += 1
                break
            case .n:
                _n += 1
                break
            case .m:
                _m += 1
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
        case .a:
            _a -= byNumber
            break
        case .s:
            _s -= byNumber
            break
        case .d:
            _d -= byNumber
            break
        case .f:
            _f -= byNumber
            break
        case .g:
            _g -= byNumber
            break
        case .h:
            _h -= byNumber
            break
        case .j:
            _j -= byNumber
            break
        case .k:
            _k -= byNumber
            break
        case .l:
            _l -= byNumber
            break
        case .y:
            _y -= byNumber
            break
        case .x:
            _x -= byNumber
            break
        case .c:
            _c -= byNumber
            break
        case .v:
            _v -= byNumber
            break
        case .b:
            _b -= byNumber
            break
        case .n:
            _n -= byNumber
            break
        case .m:
            _m -= byNumber
            break
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
            case .a:
                return a
            case .s:
                return s
            case .d:
                return d
            case .f:
                return f
            case .g:
                return g
            case .h:
                return h
            case .j:
                return j
            case .k:
                return k
            case .l:
                return l
            case .y:
                return y
            case .x:
                return x
            case .c:
                return c
            case .v:
                return v
            case .b:
                return b
            case .n:
                return n
            case .m:
                return m
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
        _a = 0
        _s = 0
        _d = 0
        _f = 0
        _g = 0
        _h = 0
        _j = 0
        _k = 0
        _l = 0
        _y = 0
        _x = 0
        _c = 0
        _v = 0
        _b = 0
        _n = 0
        _m = 0
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


