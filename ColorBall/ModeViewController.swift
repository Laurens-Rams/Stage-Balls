//
//  ModeViewController.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/26/18.
//  Copyright © 2018 Laurens Ramsenthaler. All rights reserved.
//

import UIKit
import StoreKit

class ModeViewController: UIViewController{

    
    @IBOutlet var endlessButton: UIButton!
    @IBOutlet var memoryButton: UIButton!
    @IBOutlet var stageButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toggleModeButtons()
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    @IBAction func backButton(_ sender: Any) {
        UserDefaults.standard.synchronize()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func stageMode(_ sender: Any) {
        UserDefaults.standard.set(Settings.GAME_MODE_STAGE, forKey: Settings.GAME_MODE_KEY)
        // are all the modes going to have their own sets of textures? that's cool.
        UserDefaults.standard.set(Settings.TEXTURE_KEY_STAGE, forKey: Settings.TEXTURE_KEY_MODE)
        toggleModeButtons()
    }

    @IBAction func endlessMode(_ sender: Any) {
        UserDefaults.standard.set(Settings.GAME_MODE_ENDLESS, forKey: Settings.GAME_MODE_KEY)
        UserDefaults.standard.set(Settings.TEXTURE_KEY_ENDLESS, forKey: Settings.TEXTURE_KEY_MODE)
        toggleModeButtons()
    }
    
    @IBAction func memoryMode(_ sender: Any) {
        UserDefaults.standard.set(Settings.GAME_MODE_MEMORY, forKey: Settings.GAME_MODE_KEY)
        UserDefaults.standard.set(Settings.TEXTURE_KEY_MEMORY, forKey: Settings.TEXTURE_KEY_MODE)
        toggleModeButtons()
    }
    
    func toggleModeButtons() {
        UserDefaults.standard.synchronize()
        // question: why are you checking against texture keys here and not game mode keys?
        // the end result is that it won't toggle the game mode buttons unless a texture key is set...
        // this seems like a poor choice. ¯\_(ツ)_/¯
        if let textureMode = UserDefaults.standard.object(forKey: Settings.TEXTURE_KEY_MODE) as? String {
            if textureMode == Settings.TEXTURE_KEY_MEMORY {
                stageButton.backgroundColor = UIColor.clear
                endlessButton.backgroundColor = UIColor.clear
                memoryButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                
            } else if textureMode == Settings.TEXTURE_KEY_ENDLESS{
                stageButton.backgroundColor = UIColor.clear
                endlessButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                memoryButton.backgroundColor = UIColor.clear
            } else {
                stageButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                endlessButton.backgroundColor = UIColor.clear
                memoryButton.backgroundColor = UIColor.clear
            }
        }
    }
    func enableEndlessMode(){
        
    }

}
