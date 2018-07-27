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
    override var prefersStatusBarHidden: Bool {
        return true
    }
    @IBOutlet var endlessButton: UIButton!
    
    @IBOutlet var memoryButton: UIButton!
    @IBOutlet var stageButton: UIButton!
    
    @IBAction func stageMode(_ sender: Any) {
        UserDefaults.standard.set(Settings.GAME_MODE_KEY_STAGE, forKey: Settings.GAME_MODE_KEY)
        UserDefaults.standard.set(Settings.TEXTURE_KEY_STAGE, forKey: Settings.TEXTURE_KEY_MODE)
        toggleTextureButtons()
    }

    @IBAction func endlessMode(_ sender: Any) {
        UserDefaults.standard.set(Settings.GAME_MODE_KEY_ENDLESS, forKey: Settings.GAME_MODE_KEY)
        UserDefaults.standard.set(Settings.TEXTURE_KEY_ENDLESS, forKey: Settings.TEXTURE_KEY_MODE)
        toggleTextureButtons()
    }
    
    @IBAction func memoryMode(_ sender: Any) {
        UserDefaults.standard.set(Settings.GAME_MODE_KEY_MEMORY, forKey: Settings.GAME_MODE_KEY)
        UserDefaults.standard.set(Settings.TEXTURE_KEY_MEMORY, forKey: Settings.TEXTURE_KEY_MODE)
        toggleTextureButtons()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toggleTextureButtons()
    }
    
    func toggleTextureButtons() {
        UserDefaults.standard.synchronize()
        if let textureMode = UserDefaults.standard.object(forKey: Settings.TEXTURE_KEY_MODE) as? String {
            if textureMode == Settings.TEXTURE_KEY_MEMORY {
                stageButton.backgroundColor = UIColor.clear
                endlessButton.backgroundColor = UIColor.clear
                memoryButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                
            }else if textureMode == Settings.TEXTURE_KEY_ENDLESS{
                stageButton.backgroundColor = UIColor.clear
                endlessButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                memoryButton.backgroundColor = UIColor.clear
            }else {
                stageButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                endlessButton.backgroundColor = UIColor.clear
                memoryButton.backgroundColor = UIColor.clear
            }
        }
    }

}
