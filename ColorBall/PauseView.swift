//
//  PauseView.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/14/17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import UIKit

class PauseView: UIView {
    
    @IBOutlet weak var playButton: UIButton!
    var delegate: StartGameDelegate?
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "PauseView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PauseView
    }
    
    func disappear() {
        delegate?.unpauseGame()
        self.removeFromSuperview()
    }
    
    @IBAction func unpauseAction(_ sender: AnyObject) {
        AudioManager.only.playClickSound()
        disappear()
    }

    @IBAction func showalternativeview(_ sender: AnyObject) {
        delegate?.showaltmenu()
        self.removeFromSuperview()
    }
    
    @IBAction func restartpressed(_ sender: AnyObject) {
        AudioManager.only.playClickSound()
        delegate?.restartGame()
        self.removeFromSuperview()

    }
    

}
