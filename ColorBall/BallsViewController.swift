//
//  BallsViewController.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/26/18.
//  Copyright © 2018 Laurens Ramsenthaler. All rights reserved.
//

import UIKit

class BallsViewController: UIViewController {
    
    @IBOutlet weak var fruitsButton: UIButton!
    @IBOutlet weak var colorsButton: UIButton!
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func colorBalls(_ sender: Any) {
        UserDefaults.standard.set(Settings.TEXTURE_KEY_COLORS, forKey: Settings.TEXTURE_KEY)
        toggleTextureButtons()
    }
    
    @IBAction func deliciousFruits(_ sender: Any) {
        UserDefaults.standard.set(Settings.TEXTURE_KEY_FRUITS, forKey: Settings.TEXTURE_KEY)
        toggleTextureButtons()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toggleTextureButtons()
    }
    
    func toggleTextureButtons() {
        UserDefaults.standard.synchronize()
        if let textureMode = UserDefaults.standard.object(forKey: Settings.TEXTURE_KEY) as? String {
            if textureMode == Settings.TEXTURE_KEY_FRUITS {
                fruitsButton.backgroundColor = UIColor.gray
                colorsButton.backgroundColor = UIColor.clear
            } else {
                fruitsButton.backgroundColor = UIColor.clear
                colorsButton.backgroundColor = UIColor.gray
            }
        }
    }
}
