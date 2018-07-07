//
//  NextStageButton.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/6/18.
//  Copyright © 2018 Emily Kolar. All rights reserved.
//

import UIKit

class NextStageButton: UIButton {

    class func instanceFromNib() -> NextStageButton {
        return UINib(nibName: "NextStageButton", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! NextStageButton
    }

}
