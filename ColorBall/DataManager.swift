//
//  DataManager.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 20.07.17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import Foundation
import RealmSwift

class DataManager {
    
    static let main = DataManager()
    private var _realm: Realm!
    
    private var _highScore: Int = 0
    private var _money: Int = 0
    private var _played: Int = 0
    
    private init() {
        do {
            _realm = try Realm()
        }
        catch let error {
            fatalError("database initialiyation failed: \(error.localizedDescription)")
        }
        initHighScore()
        initMoney()
        initPlayed()
    }
    
    func initHighScore() {
        if let score = _realm.objects(HighScore.self).first {
            _highScore = score.value
        }
    }
    
    func initMoney() {
        if let cash = _realm.objects(Money.self).first {
            _money = cash.value
        }
    }
    
    func initPlayed() {
        if let games = _realm.objects(Played.self).first {
            _played = games.value
        }
    }
    
    func saveHighScore(newScore: Int) {
        if newScore > _highScore {
            let newHighScore = HighScore()
            newHighScore.id = 1
            newHighScore.value = newScore
            do {
                try _realm.write {
                    _realm.add(newHighScore, update: true)
                }
            }
            catch let error {
                print(error.localizedDescription)
            }
            _highScore = newHighScore.value
        }
    }
    
    func addMoney(amount: Int) {
        let newMoney = Money()
        newMoney.id = 1
        newMoney.value = _money + amount
        do {
            try _realm.write {
                _realm.add(newMoney, update: true)
            }
        }
        catch let error {
            print(error.localizedDescription)
        }
        _money = newMoney.value
    }
    
    func addPlayed() {
        let games = Played()
        games.id = 1
        games.value = _played + 1
        do {
            try _realm.write {
                _realm.add(games, update: true)
            }
        }
        catch let error {
            print(error.localizedDescription)
        }
        _played = games.value
    }
    
    func subtractMoney(amount: Int) {
        let newMoney = Money()
        newMoney.id = 1
        newMoney.value = _money - amount
        do {
            try _realm.write {
                _realm.add(newMoney, update: true)
            }
        }
        catch let error {
            print(error.localizedDescription)
        }
        _money = newMoney.value
    }
    
    var highScore: Int {
        get {
            return _highScore
        }
    }
    
    var money: Int {
        get {
            return _money
        }
    }
    
    var played: Int {
        get {
            return _played
        }
    }
    
}
