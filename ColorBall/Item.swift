//
//  Item.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 20.07.17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import RealmSwift

class Item: Object {
    @objc var id: Int = 0
    @objc var using: Bool = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
}


