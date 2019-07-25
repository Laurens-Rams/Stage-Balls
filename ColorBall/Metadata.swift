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
        Mixpanel.mainInstance().track(event: "User stage start", properties: [
          "stage": stage,
          "mode": mode,
          "start_time": time
        ])
        Analytics.logEvent("user_stage_start", parameters: [
          "stage": stage,
          "mode": mode,
          "start_time": time
        ])
    }
  
    func trackUserStageEnd(stage: Int, mode: String) {
        let time = Date().timeIntervalSince1970
        Mixpanel.mainInstance().track(event: "User stage start", properties: [
          "stage": stage,
          "mode": mode,
          "start_time": time
        ])
        Analytics.logEvent("user_stage_end", parameters: [
          "stage": stage,
          "mode": mode,
          "start_time": time
        ])
    }
  
    func trackUserSelectedMode(mode: String) {
        let time = Date().timeIntervalSince1970
        Mixpanel.mainInstance().track(event: "User selected mode", properties: [
          "mode": mode,
          "start_time": time
        ])
        Analytics.logEvent("user_selected_mode", parameters: [
          "mode": mode,
          "start_time": time
        ])
    }
}
