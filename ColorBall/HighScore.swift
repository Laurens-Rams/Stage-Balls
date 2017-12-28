//
//  HighScore.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 20.07.17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import RealmSwift

class HighScore: Object {
    @objc var id: Int = 1
    @objc var value: Int = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}
