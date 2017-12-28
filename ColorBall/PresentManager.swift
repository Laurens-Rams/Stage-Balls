//
//  PresentManager.swift
//  ColorBall
//
//  Created by Emily Kolar on 12/27/17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation

/**
 Creates a singleton `PresentManager` object (access with `PresentManager.main`). Manages giving the player presents at regular intervals. Methods called during `setup` and `teardown` in `AppDelegate.swift`.
 */
class PresentManager {
    static let main = PresentManager()
    
    private var _timer:  BackgroundRepeatingTimer!
    private var _defaults: UserDefaults!
    private var _maxInterval: Double = 5
    
    private init() {
        _timer = BackgroundRepeatingTimer()
        _defaults = UserDefaults.standard
        _timer.setEventHandler(handler: _timerEventHandler)
        _timer.resume()
    }
    
    /**
     Check when a present was last given. If more than the max interval has ellapsed, give out a present for each interval block we've passed.
     */
    private func _checkLastPresentTime() {
        // current time in seconds
        let now = Date().timeIntervalSince1970

        // see if we've saved a lastPresentTime before
        if let lastPresentTime = _defaults.object(forKey: "lastPresentTime") as? Double {
            // get the time that's ellapsed
            let timeElapsed = now - lastPresentTime

            if timeElapsed >= _maxInterval {
                // if it's been 7 hours since the last present, we want to give a present again in 5 hours instead of the full 6 hours
                let lastFired = now - timeElapsed.truncatingRemainder(dividingBy: _maxInterval)
                // number of times the interval has ellapsed (13 hours passed == 2 times)
                let numberOfPresents = Int(floor(timeElapsed / _maxInterval))

                _setLastPresentTime(time: lastFired)
                _givePresents(numberOfPresents: numberOfPresents)
            }
        } else {
            // if we have never saved a lastPresentTime before, start now
            _setLastPresentTime(time: now)
        }
    }
    
    /**
     Save the last time we gave a present.
     - parameters:
        - time: Time since 1970 in seconds.
     */
    private func _setLastPresentTime(time: Double) {
        _defaults.set(time, forKey: "lastPresentTime")
        _defaults.synchronize()
    }
    
    /**
     Handler when our background timer fires (will fire in a background queue, but only when the app itself is running in the foreground).
     */
    private func _timerEventHandler() {
        _setLastPresentTime(time: Date().timeIntervalSince1970)
        _givePresents(numberOfPresents: 1)
    }
    
    /**
     Add a number of presents to the player's stash.
     - parameters:
        - numberOfPresents: Number of presents to give.
     */
    private func _givePresents(numberOfPresents: Int) {
        print(numberOfPresents)
    }

    /**
     Restart the present timer when app launches or enters foreground.
     */
    func start() {
        _checkLastPresentTime()
        _timer.resume()
    }
    
    /**
     Cleanup the present timer (call when the app terminates or enters an inactive background state).
     */
    func pause() {
        _timer.suspend()
    }
}


