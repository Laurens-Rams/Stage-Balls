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

class Metadata {
    static let shared = Metadata()
    static let eventName_userStageStart = "user_stage_start"
    static let eventName_userStageEnd = "user_stage_end"
    static let propName_stage = "stage"
    static let propName_mode = "mode"
    static let propName_startTime = "start_time"
    static let propName_endTime = "end_time"

    private var _user: User?

    private init() {}
  
    var user: User? { get { return _user } }

    func setUser(user: User?) {
        _user = user
        if let user = user {
            Analytics.setUserID(user.uid)
        }
    }
  
    func trackUserStageStart(stage: Int, mode: String) {
        var params: [String: Any] = [:]
        params[Metadata.propName_stage] = stage
        params[Metadata.propName_mode] = mode
        params[Metadata.propName_startTime] = Date().timeIntervalSince1970
        Analytics.logEvent(Metadata.eventName_userStageStart, parameters: params)
    }
  
    func trackUserStageEnd(stage: Int, mode: String) {
        var params: [String: Any] = [:]
        params[Metadata.propName_stage] = stage
        params[Metadata.propName_mode] = mode
        params[Metadata.propName_startTime] = Date().timeIntervalSince1970
        Analytics.logEvent(Metadata.eventName_userStageEnd, parameters: params)
    }
}
