//
//  Game.swift
//  ColorBall
//
//  Created by Emily Kolar on 12/27/17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
// preupload new
// test for ads

import Foundation
import CoreGraphics
import UIKit

enum Difficulty: Int {
    case easy = 0, hard
}

struct GameConstants {
    // MARK: static properties
    
    static var allBallTypes = Array(BallColor.cases(removingIndices: [24]))
    
    static let initialSlotsOnCircle: CGFloat = 13
    static let initialSlotsPerColumn = 2
    
    static let ballZapDuration: CGFloat = 0.125
    
    static let screenWidth: CGFloat = UIScreen.main.bounds.size.width
    
    static let startingCircleScale: CGFloat = 0.55
    static let startingBallScale: CGFloat = 0.12
    
    static let startingBallRadiusScale: CGFloat = GameConstants.startingBallScale * 0.5
    static let startingCircleDiameter: CGFloat = GameConstants.screenWidth * GameConstants.startingCircleScale
    static let startingOuterDiameter: CGFloat = GameConstants.startingCircleDiameter + (GameConstants.screenWidth * GameConstants.startingBallRadiusScale)
    
    static let ballColors: [UIColor] = [
        //1
        UIColor(red: 255/255, green: 141/255, blue: 193/255, alpha: 1.0),
        //2
        UIColor(red: 52/255, green: 171/255, blue: 224/255, alpha: 1.0),
        //3
        UIColor(red: 255/255, green: 190/255, blue: 2/255, alpha: 1.0),
        //4
        UIColor(red: 5/255, green: 153/255, blue: 149/255, alpha: 1.0),
        //5
        UIColor(red: 112/255, green: 32/255, blue: 132/255, alpha: 1.0),
        //6
        UIColor(red: 239/255, green: 221/255, blue: 182/255, alpha: 1.0),
        //7
        UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0),
        //8
        UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1.0),
        
        
        //9
        UIColor(red: 232/255, green: 21/255, blue: 62/255, alpha: 1.0),
        //10
        UIColor(red: 57/255, green: 247/255, blue: 134/255, alpha: 1.0),
        ]
    
    static let backgroundColors: [UIColor] = [
        UIColor.white
    ]
    
    static let colorSets: [[UIColor]] = [[UIColor]]()
}

/**
 For creating a Game object. Use to manage current game values, track the current score and level, etc. Should be instantiated or re-instantiated for each game played.
 */
class Game {
    // MARK: private properties
    
    // number balls fallen in current stage
    // TODO: create a "stage" object to manage all stage-related vars
    private var _ballsFallen = 0
    
    // using the user defaults keys let us track values for different modes, but
    // it also means we don't have to have separate variables for the stage,
    // since the _stage variable will always represent the stage for the current mode
    // private var _stageMemoryMode = 0
    
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
    private var _speedMultiplier: Double = 0.002
    private var _ballzapduration: CGFloat = 0.0
    private var _rotationSpeedIncrement = CGFloat(0.02)
    private var _spinVar = CGFloat(15.0)

    // multiplier for gravity
    // this is the multiplied amount by which things fall faster
    private var _gravityMultiplier: Double = 0.04
    private var _startgravity: Double = 4.0

    // starting value for how often balls are added
    private var _ballInterval = TimeInterval(1.8)

    // number of balls on starting row
    private var _numberStartingBalls = 1

    // number of colors to use this stage
    private var _numberBallColors = 4

    private var _colorSetIndex = 0

    // keep track of extra chance
    private var _extraChance = 1

    private var _slotsPerColumn = GameConstants.initialSlotsPerColumn

    private var _isEndlessMode = false
    private var _isMemoryMode = false
    private var _isStageMode = false
    private var _isReversedMode = false
    private var _isInvisibleMode = false

    private var _mode: GameMode!
    
    private var _endlessScore = 0
    
    // escape stage controls
    private var _nextEscapeStage = 0
    
    // memory stage controls
    private var _nextMemoryStage = 0
    private var _lastMemoryCount: Double = 0.5
    
    // =========
    // surprise stage controls
    // =========
    // minimum stage for surprises
    private var _minStageForSurprises: Int = 7
    // we always add 0.5 to this BEFORE returning it
    // thus, we should start at 0.5, so the first time we hit a surprise stage,
    // it will add and return 1, then increase by 1 every other time after that
    private var _lastSurpriseCount: Double = 0.5
    
    private var _columnHeights = [Int]()
    
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
    
    init(startingStage: Int, mode: GameMode) {
        _stage = startingStage
        _mode = mode

        // thanks to our user defaults setup, only one of these
        // should be able to be true at any given moment
       switch mode {
            case .endless:
                initEndlessMode()
                break
            case .memory:
                initMemoryMode()
                break
            case .reversed:
                initReversedMode()
                break
            case .invisible:
                initInvisibleMode()
                break
            default:
                initStageMode()
                break
        }

        // if you decide to use color sets someday, you can bring this back and make use of it :)
        // _colorSetIndex = randomColorSet()
    }
    
    func initEndlessMode() {
        // initializers for endless
        _isEndlessMode = true
        print("endlessMode")
    }
    
    func initMemoryMode() {
        // initializers for memory
        _isMemoryMode = true
        print("memoryMode")
        
    }
    
    func initStageMode() {
        // initializers for stage
        _isStageMode = true
        print("StageMode")
    }
  
    func initReversedMode() {
        // initializers for reversed
        _isReversedMode = true
        print("ReversedMode")
    }
  
    func initInvisibleMode() {
        // initializers for reversed
        _isInvisibleMode = true
        print("InvisibleMode")
    }
  
    /**
     Generate a random integer between 0 and 3.
     - parameters:
     - upperBound: Optional max.
     - returns: A number.
     */
    func randomColorSet() -> Int {
        return Int(arc4random_uniform(4) + UInt32(1))
    }

    // we'll flip this to false later to test the other option
    var endGameOnCircleCollision = true

    // MARK: properties' public getters

    var isEndlessMode: Bool {
        return _isEndlessMode
    }

    var isMemoryMode: Bool {
        return _isMemoryMode
    }
  
    var isReversedMode: Bool {
        return _isReversedMode
    }
  
    var isInvisibleMode: Bool {
        return _isInvisibleMode
    }

    var slotsOnCircle: Int {
        get {
            return numberStartingBalls <= 13 ? 13 : numberStartingBalls
        }
    }

    var mode: GameMode {
        get {
            return _mode
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
            return _a
        }
    }
    
    /**
     Number of reds in game (read-only getter).
     */
    var s: Int {
        get {
            return _s
        }
    }
    
    /**
     Number of pinks in game (read-only getter).
     */
    var d: Int {
        get {
            return _d
        }
    }
    
    /**
     Number of yellows in game (read-only getter).
     */
    var f: Int {
        get {
            return _f
        }
    }
    /**
     Number of greens in game (read-only getter).
     */
    var g: Int {
        get {
            return _g
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
            return _j
        }
    }
    
    /**
     Number of greys in game (read-only getter).
     */
    var k: Int {
        get {
            return _k
        }
    }
    var l: Int {
        get {
            return _l
        }
    }
    
    /**
     Number of reds in game (read-only getter).
     */
    var y: Int {
        get {
            return _y
        }
    }
    
    /**
     Number of pinks in game (read-only getter).
     */
    var x: Int {
        get {
            return _x
        }
    }
    
    /**
     Number of yellows in game (read-only getter).
     */
    var c: Int {
        get {
            return _c
        }
    }
    /**
     Number of greens in game (read-only getter).
     */
    var v: Int {
        get {
            return _v
        }
    }
    /**
     Number of purples in game (read-only getter).
     */
    var b: Int {
        get {
            return _b
        }
    }
    /**
     Number of oranges in game (read-only getter).
     */
    var n: Int {
        get {
            return _n
        }
    }
    
    /**
     Number of greys in game (read-only getter).
     */
    var m: Int {
        get {
            return _m
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

    var spinVar: CGFloat {
        get {
            return _spinVar
        }
    }

    var rotationSpeedIncrement: CGFloat {
        get {
            return _rotationSpeedIncrement * CGFloat(_stage)
        }
    }

    /**
     The number of balls remaining to fall in the current stage.
     */
    var ballsRemaining: Int {
        get {
            var total = 0

            for type in GameConstants.allBallTypes {
                total += getCountForType(type: type)
            }
            return total
        }
    }

    /**
     Number of balls remaining that will fall in current stage.
     */
    var numberBallsInQueue: Int {
        get {
            if _isEndlessMode || _isReversedMode {
                return _ballsFallen
            }
          
            return  totalInColumns - ballsFallen + numberSurpriseBalls
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
    
    // min 13
    // max 22
    // maxStage 57
    // f 5
    var numberStartingBalls: Int {
        get {
            if _isEndlessMode || _isReversedMode {
                return 14
            }

            if _isMemoryMode {
                let frequency = 5
              //  let baseAmountToAdd = _stage - 1
                let highestVariableStage = 13
                
                if _stage < highestVariableStage {
                    let newStart = 13 //_numberStartingBalls + baseAmountToAdd --> if you want to start with 1-13
                    return newStart
                }
                
                let multiplesOfFrequency = Int(round(Double((_stage - highestVariableStage) / frequency)))
                if _stage < 38{
                    return highestVariableStage + multiplesOfFrequency
                }else{
                    return 18
                }
            }

            // TODO: Setup number of starting balls invisible mode
            if _isInvisibleMode {
                if _stage == 1{
                    return 14
                }else if _stage == 2{
                    return 15
                }else if _stage >= 3{
                    // every 4 balls 1 new ball until stage 35 that makes 8
                    let multiplesOfFrequency = Int(round(Double((_stage - 2) / 4)))
                    if _stage < 23{
                        return 14 + multiplesOfFrequency
                    } else {
                        return 18
                    }
                }
            }

            let frequency = 7
            let baseAmountToAdd = _stage - 1
            let highestVariableStage = 13
            
            if _stage <= 4 {
                let newStart = _numberStartingBalls + baseAmountToAdd + 2  // = 13
                return newStart
            }else if (_stage == 5) {
                let newStart = 9 // = 13
                return newStart
                
            }else if (_stage == 6) {
                let newStart = 11 // = 13
                return newStart
                
            } else if (_stage == 7) {
                let newStart = 13 // = 13
                return newStart
                
            }
            
            let multiplesOfFrequency = Int(round(Double((_stage - highestVariableStage) / frequency)))
            if _stage < 48{ // bis 18
                return highestVariableStage + multiplesOfFrequency
            } else {
                return 18
            }
        }
    }

    // not used
    var shouldUseEscapeBall: Bool {
        get {
            let frequencyMin = 2
            let frequencyMax = 4
            let highestVariableStage = 20
            
            if _stage < highestVariableStage {
                return false
            }
            
            if _stage == _nextEscapeStage || _nextEscapeStage == 0 {
                // set the next nextEscapeStage
                let nextMin = _stage + frequencyMin
                let nextMax = _stage + frequencyMax
                _nextEscapeStage = _stage + randomInteger(lowerBound: nextMin, upperBound: nextMax)
                // yes, we should have an escape ball this stage
                if _stage == _nextEscapeStage {
                    return true
                }
            }
            
            return false
        }
    }
    // min 30
    // max 22
    // maxStage 57
    // f 5
//    var numberOfMemoryBallsAlt: Int {
//        get {
//            if _isMemoryMode == true{
//
//            }
//            let frequencyMin = 3
//            let frequencyMax = 6
//            let maxBalls: Double = 4
//            let highestVariableStage = 30
//
//            if _stage < highestVariableStage {
//                return 0
//            }
//
//            if _stage == _nextMemoryStage || _nextMemoryStage == 0 {
//                // set the next nextEscapeStage
//                let nextMin = _stage + frequencyMin
//                let nextMax = _stage + frequencyMax
//                _nextMemoryStage = _stage + randomInteger(lowerBound: nextMin, upperBound: nextMax)
//                print("next mem stage", _nextMemoryStage)
//                // yes, we should have an escape ball this stage
//                if _stage == _nextMemoryStage {
//                    if _lastMemoryCount < maxBalls { _lastMemoryCount += 0.5 }
//                    return Int(floor(_lastMemoryCount))
//                }
//            }
//
//            return 0
//        }
//    }
    
    var numberOfMemoryBalls: Int {
        get {
            if _isMemoryMode == true{
                if _stage == 1{
                    return 2
                }else if _stage <= 3 {
                    return 3
                }else if _stage <= 5{
                    return 4
                }else if _stage <= 15{
                    return 5
                }else if _stage <= 20{
                    return 6
                }else if _stage <= 22{
                    return 7
                }else if _stage <= 24{
                    return 8
                }else if _stage <= 26{
                    return 9
                }else if _stage <= 28{
                    return 10
                }else{
                    return 11
                }
            }
            return 0
        }
    }

    // getter for private variable for minumum stage for surprise balls
    var minStageForSurprises: Int {
        get {
            return _minStageForSurprises
        }
    }
    
    var numberSurpriseBalls: Int {
        get {
            if _isEndlessMode || _isReversedMode {
                return -1
            }
            // use same as in stage
            if _stage < _minStageForSurprises { // 7
                return 0
            }

            let maxBalls: Double = 49
            let initialSurpriseCount = 1.0
            let stagesEllapsed = _stage - _minStageForSurprises

            // if we've gone 4 stages and frequency is 2,
            // 4 % 2 will give us 0 (the remainder of 4 / 2)
            // similarly, if we've gone 5 stages and frequency is 2,
            // 5 % 2 will give us the remainder 1, so we'll skip that stage
           // if stagesEllapsed % 1 == 0 {
                if _lastSurpriseCount <= maxBalls {
                    if _stage <= 10 {
                        _lastSurpriseCount = initialSurpriseCount + (Double(stagesEllapsed))
                    }else if _stage <= 14 {
                        _lastSurpriseCount = ((Double(stagesEllapsed) * 2) - 2 )
                    }else if _stage <= 30 {
                        _lastSurpriseCount = ((Double(stagesEllapsed) * 3) - 10)
                    }else if _stage <= 49 {
                        _lastSurpriseCount = ((Double(stagesEllapsed)  * 5) - 55)
                    }else if _stage > 49 {
                        _lastSurpriseCount = 160 // end
                    }
                }
                return Int(floor(_lastSurpriseCount))
//}
        }
    }
    
//    var numberSurpriseBalls: Int {
//        get {
//            if _isEndlessMode || _isReversedMode {
//                return -1
//            }
//            // use same as in stage
//            if isInvisibleMode{
//
//            }
//            let frequency = 1
//            let maxBalls: Double = 44
//            let initialSurpriseCount = 1.0
//
//            if _stage < _minStageForSurprises {
//                return 0
//            }
//
//            let stagesEllapsed = _stage - _minStageForSurprises
//            // if we've gone 4 stages and frequency is 2,
//            // 4 % 2 will give us 0 (the remainder of 4 / 2)
//            // similarly, if we've gone 5 stages and frequency is 2,
//            // 5 % 2 will give us the remainder 1, so we'll skip that stage
//            if stagesEllapsed  % frequency == 0 {
//                if _lastSurpriseCount < maxBalls {
//                    _lastSurpriseCount = initialSurpriseCount + ((Double(stagesEllapsed) * 2))
//                }
//
//                return Int(floor(_lastSurpriseCount))
//            }
//
//            return 0
//        }
//    }
    /**
     Multiplier for ball speeds (read-only getter).
     */
    var speedMultiplier: Double {
        get {
            if _isEndlessMode{
                if _ballsFallen > 100{
                    return 0.5
                }

                return 1.0 - (Double(_stage - 1) * _speedMultiplier)
                
            }

            return 1.0 - (Double(_stage - 1) * _speedMultiplier) // 200 * 0.02 = 1. 1-1 = 0.5
        }
    }

    var ballzapduration: CGFloat {
        get {
            if isReversedMode{
                return 0.03
            } else if isEndlessMode{
                return 0.125
            } else{
                return 0.125
            }
        }
    }
    
    /**
     Multiplier for ball falling speed ("gravity") (read-only getter).
     */
    var gravityMultiplier: Double {
        get {
            if _isReversedMode {
                return Double(700) * (_gravityMultiplier) + 1.5
            } else if _isEndlessMode {
                if (_stage < 50){
                    return Double(_ballsFallen) * (_gravityMultiplier) + 1.5
                }else if (_stage < 70){
                    return Double(50) * (_gravityMultiplier) + 1.5 // 1.5 damit am start schneller
                }else if (_stage < 90){
                    return Double(60) * (_gravityMultiplier) + 1.5
                }else if (_stage < 120){
                    return Double(70) * (_gravityMultiplier) + 1.5
                }else if (_stage < 140){
                    return Double(75) * (_gravityMultiplier) + 1.5
                }else {
                    return Double(80) * (_gravityMultiplier) + 1.5
                }
            } else if _isMemoryMode {
                if (_stage < 70){
                    return Double(_stage - 1) * (_gravityMultiplier)
                }else {
                    return 5.0
                }
            } else if (_stage < 30){
                return Double(_stage - 1) * (_gravityMultiplier + 0.01)
            } else if (_stage < 57){
                return Double(_stage - 1) * _gravityMultiplier
            }

            return 3.0 // 4.0
        }
    }
    var startgravity: Double {
        get {
            if _isEndlessMode{
                return 6.0
            }

            return 5.0
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

            if (newDiameter < _smallDiameter) {
                return newDiameter
            }

            return _smallDiameter
        }
    }
    
    func generateColumnHeights() {
        if _isEndlessMode || _isReversedMode {
            for _ in 0..<numberStartingBalls {
                let num = 2
                _columnHeights.append(num)
            }
        } else {
            let minVariableStage: Double = 7
//            let maxFrequency: Double = 15
//            let minFrequency: Double = 25
//            let s = Double(_stage)
//            var min: Double = 2
//            var max: Double = 3
               var height: Int = 2

            _columnHeights.removeAll() // RESET WHEN WE GENERATE
            
//            if s < minVariableStage {
//                min = 2
//                max = 2 - 1
//            } else {
//                let multiplesOfMax = floor((s - minVariableStage) / maxFrequency)
//                let multiplesOfMin = floor((s - minVariableStage) / minFrequency)
//                if max > 5{
//                    max = 5
//                    min = 3
//                }else {
//                    min += multiplesOfMin
//                    max += multiplesOfMax - 1
//                }
//            }
//
            
            if _stage <= 9 {
                height = 2
            }else if _stage <= 19 {
                height = 3
            }else if _stage <= 35 {
                height = 4
            }else if _stage <= 45 {
                height = 5
            }else if _stage > 45 {
                height = 6
            }
            for _ in 0..<numberStartingBalls {
               
                let num = Int(height)
                _columnHeights.append(num)
                print(_columnHeights)
                
            }
        }
    }
    
    var columnsHeights: [Int] {
        get {
            return _columnHeights
        }
    }

    var totalInColumns: Int {
        get {
            var total = 0
            for height in _columnHeights {
                total += (height - 1)
            }

            return total
        }
    }
//

    /**
     How high the balls should be able to stack (read-only getter).
     */
    // the height
    // not in use
    var slotsPerColumn: Int {
        get {
            if _stage < 13 { return _slotsPerColumn } // 1-12 = 2
            else if _stage < 39 { return _slotsPerColumn + 1 } // 13-33 = 3
            else if _stage < 59 { return _slotsPerColumn + 2 } // 34-53 = 4
            else if _stage < 79 { return _slotsPerColumn + 3 } // 54-63 = 5
            else if _stage < 99 { return _slotsPerColumn + 4 } // 54-63 = 6
            else { return 6 }
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
            if _isEndlessMode {
                if _ballsFallen <= 10 { return 4 }
                if _ballsFallen <= 20 { return _numberBallColors } // = 5
                if _ballsFallen <= 35 { return _numberBallColors + 1} // = 6
                if _ballsFallen <= 50 { return _numberBallColors + 2 } // = 7
                if _ballsFallen <= 75 { return _numberBallColors + 3 } // = 8

                return 8
            }

            if isInvisibleMode{
                if _stage <= 3 { return _numberBallColors }
                if _stage <= 8 { return _numberBallColors + 1 } // = 5
                if _stage <= 15 { return _numberBallColors + 2 } // = 6
                if _stage <= 22 { return _numberBallColors + 3 } // 7
                if _stage <= 30 { return _numberBallColors + 4 } // 8
                return 8
            }
            if _isReversedMode { return 4 }
            
            if _stage <= 10 { return _numberBallColors }
            if _stage <= 15 { return _numberBallColors + 1 } // = 5
            if _stage <= 25 { return _numberBallColors + 2 } // = 6
            if _stage <= 35 { return _numberBallColors + 3 } // 7
            if _stage <= 45 { return _numberBallColors + 4 } // 8
            return 8
        }
    }
    
    var colorSetIndex: Int {
        get {
            return _colorSetIndex
        }
    }
    
    var ballColorSet: [UIColor] {
        get {
            return GameConstants.colorSets[colorSetIndex]
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
    }
    
    func setStage(toStage: Int) {
        _stage = toStage
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

    func getCountOfColorTypesRemaining(inSlots slots: [Slot]) -> [BallColor: Int] {
        var counts = [BallColor: Int]()

        for slot in slots {
            if slot.isStarter, let b = slot.ball {
                if let countForType = counts[b.colorType] {
                    counts[b.colorType] = countForType + 1
                } else {
                    counts[b.colorType] = 1
                }
            }
        }
      
        return counts
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
    
    /**
     Generate a random integer between 0 and 3.
     - parameters:
     - upperBound: Optional max.
     - returns: A number.
     */
    func randomInteger(lowerBound: Int, upperBound: Int) -> Int {
        return Int(arc4random_uniform(UInt32(upperBound)) + UInt32(lowerBound))
    }
}

