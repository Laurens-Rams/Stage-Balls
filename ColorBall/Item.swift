//
//  Item.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 20.07.17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation
import RealmSwift

class Item: Object {
    dynamic var id: Int = 0
    dynamic var using: Bool = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
}


