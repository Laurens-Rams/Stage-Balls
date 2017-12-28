//
//  BackgroundRepeatingTimer.swift
//  ColorBall
//
//  Created by Emily Kolar on 12/27/17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation

class BackgroundRepeatingTimer {
    private enum State {
        case suspended, resumed
    }
    
    var eventHandler: (() -> Void)?
    
    private var _state: State = .suspended

    private lazy var _timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        // 6 hours (6 * 60 min * 60 seconds = 21600 seconds)
        let interval = DispatchTimeInterval.seconds(5)
        let deadline = DispatchTime.now() + 5

        t.scheduleRepeating(deadline: deadline, interval: interval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })

        return t
    }()
    
    func setEventHandler(handler: @escaping () -> Void) {
        _timer.suspend()
        eventHandler = handler
        _timer.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        _timer.resume()
    }
    
    func resume() {
        if _state == .resumed {
            return
        } else {
            _state = .resumed
            _timer.resume()
        }
    }
    
    func suspend() {
        if _state == .suspended {
            return
        } else {
            _state = .suspended
            _timer.suspend()
        }
    }
    
    deinit {
        _timer.setEventHandler(handler: {})
        _timer.cancel()
        resume()
        eventHandler = nil
    }
}


