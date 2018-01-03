//
//  UIColorExtension.swift
//  ColorBall
//
//  Created by Emily Kolar on 1/3/18.
//  Copyright © 2018 Emily Kolar. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    func rgb() -> (red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat)? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            // Could extract RGBA components
            return (red:fRed, green:fGreen, blue:fBlue, alpha:fAlpha)
        } else {
            // Could not extract RGBA components
            return nil
        }
    }
}

extension CGFloat {
    static func lerp(a: CGFloat, b: CGFloat, fraction: CGFloat) -> CGFloat {
        return (b-a) * fraction + a
    }
}
