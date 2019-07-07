//
//  BallsViewController.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/26/18.
//  Copyright © 2018 Laurens Ramsenthaler. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Firebase

class BallsViewController: UIViewController, GADInterstitialDelegate {
    @IBOutlet weak var fruitsButton: UIButton!
    @IBOutlet weak var colorsButton: UIButton!
    @IBOutlet weak var poolButton: UIButton!
    
    var Interstitial: GADInterstitial?
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    @IBAction func colorBalls(_ sender: Any) {
        UserDefaults.standard.set(Settings.TEXTURE_COLORS, forKey: Settings.TEXTURE_KEY)
        toggleTextureButtons()
    }
    
    @IBAction func deliciousFruits(_ sender: Any) {
        IAPHandler.shared.purchaseMyProduct(index: 2)
        UserDefaults.standard.set(Settings.TEXTURE_FRUITS, forKey: Settings.TEXTURE_KEY)
        toggleTextureButtons()
    }
    
    @IBAction func poolBalls(_ sender: Any) {
        UserDefaults.standard.set(Settings.TEXTURE_POOL, forKey: Settings.TEXTURE_KEY)
        toggleTextureButtons()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        toggleTextureButtons()
        
        setupIAP()
    }

    
    func setupIAP() {
        // inAppPurchase
        IAPHandler.shared.fetchAvailableProducts()
        IAPHandler.shared.purchaseStatusBlock = {[weak self] (type) in
            guard let strongSelf = self else{ return }
            if type == .purchased {
                let alertView = UIAlertController(title: "", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                    
                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
            }
        }
    }
    
    func toggleTextureButtons() {
        UserDefaults.standard.synchronize()
        if let textureMode = UserDefaults.standard.object(forKey: Settings.TEXTURE_KEY) as? String {
            if textureMode == Settings.TEXTURE_FRUITS {
                fruitsButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                colorsButton.backgroundColor = UIColor.clear
                poolButton.backgroundColor = UIColor.clear
            } else if textureMode == Settings.TEXTURE_POOL {
                poolButton.backgroundColor = UIColor(red: 225/255, green:225/255, blue: 225/255, alpha: 1.0)
                colorsButton.backgroundColor = UIColor.clear
                fruitsButton.backgroundColor = UIColor.clear
            } else {
                fruitsButton.backgroundColor = UIColor.clear
                colorsButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                poolButton.backgroundColor = UIColor.clear
            }
        }
    }
}
