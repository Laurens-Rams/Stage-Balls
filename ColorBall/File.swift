//
//  File.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/10/17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation
import SpriteKit

class File {
    
    var delegate: MyCoolDelegate?
    
    func launch() {
        delegate?.sayBye()
    }
}

class OtherThing {
    
    var delegate: MyCoolDelegate?
    
    func launch() {
        delegate?.sayHi()
    }
}
