//
//  Metadata.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/23/19.
//  Copyright © 2019 Laurens Ramsenthaler. All rights reserved.
//

import Foundation
import FirebaseAnalytics
import FirebaseAuth
import Mixpanel

class Metadata {
    static let shared = Metadata()
    static let eventName_userStageStart = "user_stage_start"
    static let eventName_userStageEnd = "user_stage_end"

    private var _user: User?

    private init() {}
  
    var user: User? { get { return _user } }

    func setUser(user: User?) {
        _user = user
        if let user = user {
            Mixpanel.mainInstance().identify(distinctId: user.uid)
            Analytics.setUserID(user.uid)
        }
    }
  
    func trackUserStageStart(stage: Int, mode: String) {
        let time = Date().timeIntervalSince1970
        Mixpanel.mainInstance().track(event: "Stage start", properties: [
          "stage": stage,
          "mode": mode,
          "start_time": time
        ])
//        Analytics.logEvent("user_stage_start", parameters: [
//          "stage": stage,
//          "mode": mode,
//          "start_time": time
//        ])
    }
  
    func trackUserStageEnd(stage: Int, mode: String) {
        let time = Date().timeIntervalSince1970
        Mixpanel.mainInstance().track(event: "Stage end", properties: [
          "stage": stage,
          "mode": mode,
          "start_time": time
        ])
//        Analytics.logEvent("user_stage_end", parameters: [
//          "stage": stage,
//          "mode": mode,
//          "start_time": time
//        ])
    }
  
    func trackUserSelectedMode(mode: String) {
        let time = Date().timeIntervalSince1970
        Mixpanel.mainInstance().track(event: "Mode selected", properties: [
          "mode": mode,
          "start_time": time
        ])
    }
  
    func trackUserSelectedBalls(type: String) {
        Mixpanel.mainInstance().track(event: "Balls selected", properties: [
          "type": type,
        ])
    }
  
    func trackUserPressedGameCenterSetting() {
        Mixpanel.mainInstance().track(event: "Game center setting pressed")
    }
  
    func trackUserPressedBallsSetting() {
        Mixpanel.mainInstance().track(event: "Balls setting pressed")
    }
  
    func trackUserPressedModesSetting() {
        Mixpanel.mainInstance().track(event: "Modes setting pressed")
    }
  
    func trackUserPressedShareSetting() {
        Mixpanel.mainInstance().track(event: "Share setting pressed")
    }
  
    func trackUserPressedRateSetting() {
        Mixpanel.mainInstance().track(event: "Rate setting pressed")
    }
  
    func trackStageScore(stage: Int, score: Int, mode: GameMode) {
        switch mode {
            case .stage:
                Mixpanel.mainInstance().people.set(property: "Stage mode score", to: score)
                break
            case .memory:
                Mixpanel.mainInstance().people.set(property: "Memory mode score", to: score)
                break
            case .endless:
                Mixpanel.mainInstance().people.set(property: "Endless mode score", to: score)
                break
            case .reversed:
                Mixpanel.mainInstance().people.set(property: "Reversed mode score", to: score)
                break
        }
    }
}






