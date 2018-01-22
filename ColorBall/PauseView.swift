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
    
    var delegate: StartGameDelegate?
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "PauseView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PauseView
    }
    
    func disappear() {
        delegate?.unpauseGame()
        self.removeFromSuperview()
    }
    
    @IBAction func unpauseAction(_ sender: AnyObject) {
        disappear()
    }

    @IBAction func showalternativeview(_ sender: AnyObject) {
        delegate?.showaltmenu()
        self.removeFromSuperview()
    }
    
    @IBAction func restartpressed(_ sender: AnyObject) {
        delegate?.restartGame()
        self.removeFromSuperview()

    }
    

}
