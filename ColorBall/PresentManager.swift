//
//  PresentManager.swift
//  ColorBall
//
//  Created by Emily Kolar on 12/27/17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation

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
    
    private func _checkLastPresentTime() {
        let now = Date().timeIntervalSince1970
        if let lastPresentTime = _defaults.object(forKey: "lastPresentTime") as? Double {
            let timeElapsed = now - lastPresentTime
            if timeElapsed >= _maxInterval {
                let numberOfPresents = Int(floor(timeElapsed / _maxInterval))
                _givePresents(numberOfPresents: numberOfPresents)
                _setLastPresentTime(time: now)
            }
        } else {
            _setLastPresentTime(time: now)
        }
    }
    
    private func _setLastPresentTime(time: Double) {
        _defaults.set(time, forKey: "lastPresentTime")
        _defaults.synchronize()
    }
    
    private func _timerEventHandler() {
        _givePresents(numberOfPresents: 1)
        _setLastPresentTime(time: Date().timeIntervalSince1970)
    }
    
    private func _givePresents(numberOfPresents: Int) {
        print(numberOfPresents)
    }

    func start() {
        _timer.resume()
        _checkLastPresentTime()
    }
    
    func pause() {
        _timer.suspend()
    }
}


