//
//  Scores.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 20.07.17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation
import RealmSwift

class Money: Object {
    dynamic var id: Int = 1
    dynamic var value: Int = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class HighScore: Object {

    dynamic var id: Int = 1
    dynamic var value: Int = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}

class Played: Object {
    dynamic var id: Int = 1
    dynamic var value: Int = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class CustomImage: Object {
    
    dynamic var id: Int = 0
    dynamic var filePath: String = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}


class Item: Object {
    
    dynamic var id: Int = 0
    dynamic var using: Bool = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
}


// volume setting


