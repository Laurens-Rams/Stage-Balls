//
//  CustomImage.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 20.07.17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation
import RealmSwift

class CustomImage: Object {
    dynamic var id: Int = 0
    dynamic var filePath: String = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}


