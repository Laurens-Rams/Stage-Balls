//
//  Column.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/20/18.
//  Copyright © 2018 Laurens Ramsenthaler. All rights reserved.
//

import Foundation

class Column {
    var numberOfSlots: Int = 2
    var baseIndex: Int = 0
    var hasSurprise: Bool = false
    var numOfSurprises: Int = 0
    var baseSlot: BaseSlot!

    init(numberOfSlots: Int, baseIndex: Int, hasSurprise: Bool, baseSlot: BaseSlot) {
        self.numberOfSlots = numberOfSlots
        self.baseIndex = baseIndex
        self.hasSurprise = hasSurprise
        self.baseSlot = baseSlot
    }
    
    init(numberOfSlots: Int, baseIndex: Int, numOfSurprises: Int, baseSlot: BaseSlot) {
        self.numberOfSlots = numberOfSlots
        self.baseIndex = baseIndex
        self.numOfSurprises = numOfSurprises
        self.baseSlot = baseSlot
    }
}
