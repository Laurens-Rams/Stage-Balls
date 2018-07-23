//
//  StartGameDelegate.swift
//  ColorBall
//
//  Created by Laurens-Art Ramsenthaler on 16.07.17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import Foundation

protocol StartGameDelegate {
    func restartGame()
    func unpauseGame()
    func showaltmenu()
    func gameover()
    func handleNextStage()
    func gameoverdesign()
    func rewardnextstage()
    func scorelabelalpha()
    func gameoverplayscore()
    func tapleftright()
}

protocol StartSceneDelegate {
    func launchGame()
    func launchShop()
    func ratePressed()
    func sharePressed()
    func gameCenterPressed()
}

