//
//  TriesLabel.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/27/19.
//  Copyright © 2019 Laurens Ramsenthaler. All rights reserved.
//

import UIKit

class TriesLabel: UILabel {

    private var _mode: GameMode!
  
    private var _numTries = 3 {
        didSet {
            let freeunlocked = UserDefaults.standard.bool(forKey: Settings.UNLOCK_FREE_MODES)
            if freeunlocked{
                 text = ""
            }else if _numTries > 0 {
                text = "\(_numTries) Tries"
            } else {
                text = "0.99$"
            }
        }
    }

    func configureForMode(_ mode: GameMode) {
        _mode = mode

        if let triesLeftKey = _mode.modeTriesLeftDefaultsKey() {
            if let numTries = UserDefaults.standard.object(forKey: triesLeftKey) as? Int {
                _numTries = numTries
            } else {
                UserDefaults.standard.set(_numTries, forKey: triesLeftKey)
            }
        }
    }

    func setNumTries(to num: Int) {
        if num >= 0 {
            _numTries = num
        } else {
            _numTries = 0
        }
        if let triesLeftKey = _mode.modeTriesLeftDefaultsKey() {
            UserDefaults.standard.set(_numTries, forKey: triesLeftKey)
        }
    }
}
