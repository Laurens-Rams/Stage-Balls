//
//  ModeViewController.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/26/18.
//  Copyright © 2018 Laurens Ramsenthaler. All rights reserved.
//

import UIKit

class ModeViewController: UIViewController {

    @IBAction func backButton(_ sender: Any) {
        UserDefaults.standard.synchronize()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func stageMode(_ sender: Any) {
        UserDefaults.standard.set(Settings.GAME_MODE_KEY_STAGE, forKey: Settings.GAME_MODE_KEY)
    }

    @IBAction func endlessMode(_ sender: Any) {
        UserDefaults.standard.set(Settings.GAME_MODE_KEY_ENDLESS, forKey: Settings.GAME_MODE_KEY)
    }
    
    @IBAction func memoryMode(_ sender: Any) {
        UserDefaults.standard.set(Settings.GAME_MODE_KEY_MEMORY, forKey: Settings.GAME_MODE_KEY)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
