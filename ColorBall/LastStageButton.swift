//
//  LastStageButton.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/6/18.
//  Copyright © 2018 Emily Kolar. All rights reserved.
//

import UIKit

class LastStageButton: UIButton {

    class func instanceFromNib() -> LastStageButton {
        return UINib(nibName: "LastStageButton", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LastStageButton
    }

}
