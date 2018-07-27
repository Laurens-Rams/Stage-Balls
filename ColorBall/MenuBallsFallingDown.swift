//
//  MenuBallsFallingDown.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 19.07.17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import SpriteKit

enum MenuOptionType: Int {
    case gameCenter = 0, volume, rate, share, mode, balls, start

    func toName() -> String {
        switch self {
        case .gameCenter:
            return "gameCenter"
        case .volume:
            return "volume"
        case .rate:
            return "rate"
        case .share:
            return "share"
        case .mode:
            return "mode"
        case .balls:
            return "balls"
        case .start:
            return "start"
    }
}
}
class MenuBall: SKSpriteNode {
    var hasCollited = false
    var type: MenuOptionType = MenuOptionType.gameCenter
}
