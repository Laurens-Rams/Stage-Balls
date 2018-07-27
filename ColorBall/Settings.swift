//
//  Settings.swift
//  ColorBall
//
//  Created by Emily Kolar on 12/27/17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation
import UIKit

struct Settings {
    // interval for giving presents
    // 21600 == 6 hours in seconds (6 * 60 * 60)
    static let PRESENT_INTERVAL: Double = 21600
    static let CURRENT_STAGE_KEY = "CURRENT_STAGE"
    static let HIGH_SCORE_KEY = "HIGH_SCORE"
    static let PLAYS_PER_GAME = "PLAYS_PER_GAME"
    static let LAST_AD_TIME = "LAST_AD_TIME"
    static let VOLUME_ON_KEY = "VOLUME_ON_KEY"
    
    static let LAUNCHED_BEFORE_KEY = "LAUNCHED_BEFORE_KEY"
    
    static let PresentGameControllerNotification = Notification.Name("PresentGameController")

    static let TutorialTapsCompletedNotification = Notification.Name("TutorialTapsCompleted")
    static let TutorialStageOneCompletedNotification = Notification.Name("TutorialStageOneCompleted")
    
    static let TutorialSpinsCompletedNotification = Notification.Name("TutorialSpinsCompleted")
    static let TutorialStageTwoCompletedNotification = Notification.Name("TutorialStageTwoCompleted")
    
    static let ResetTutorialLevelNotification = Notification.Name("ResetTutorialLevel")

    static var isIphoneX: Bool {
        get {
            if UIDevice().userInterfaceIdiom == .phone {
                switch UIScreen.main.nativeBounds.height {
                    case 2436:
                        return true
                    default:
                        return false
                    }
            }
            return false
        }
    }
}
