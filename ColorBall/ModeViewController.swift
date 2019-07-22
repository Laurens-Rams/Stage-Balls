//
//  ModeViewController.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/26/18.
//  Copyright © 2018 Laurens Ramsenthaler. All rights reserved.
//

import UIKit
import StoreKit

enum GameMode: String {
    case stage = "stage", endless = "endless", memory = "memory"
  
    func canPurchase() -> Bool {
        switch self {
            case .endless:
                return true
            case .memory:
                return true
            default:
                return false
        }
    }

    func productId() -> String? {
        switch self {
            case .endless:
                return StageBallsProducts.EndlessModeProductId
            case .memory:
                return StageBallsProducts.MemoryModeProductId
            default:
                return nil
        }
    }
  
    func modeName() -> String {
        switch self {
            case .endless:
                return "Endless Mode"
            case .memory:
                return "Memory Mode"
            case .stage:
                return "Stage Mode"
        }
    }
  
    static func modeForId(id: String) -> GameMode? {
        switch id {
            case StageBallsProducts.EndlessModeProductId:
                return .endless
            case StageBallsProducts.MemoryModeProductId:
                return .memory
            default:
                return nil
        }
    }
}

class ModeViewController: UIViewController{

    
    @IBOutlet var endlessButton: UIButton!
    @IBOutlet var memoryButton: UIButton!
    @IBOutlet var stageButton: UIButton!
  
    var products = [SKProduct]()

    override func viewDidLoad() {
        super.viewDidLoad()
        toggleModeButtons()
        getProductData()
        NotificationCenter.default.addObserver(self, selector: #selector(self.handlePurchaseNotification),
                                           name: .IAPHelperPurchaseNotification,
                                           object: nil)
    }
  
    @objc func handlePurchaseNotification(_ notification: Notification) {
        guard let productId = notification.object as? String else { return }
      
        if let mode = GameMode.modeForId(id: productId) {
            selectMode(mode: mode)
        }
    }

    func getProductData() {
        StageBallsProducts.store.requestProducts() { success, products in
            if success {
                self.products = products!
            }
            self.checkForPurchased()
            print(success, self.products)
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    @IBAction func backButton(_ sender: Any) {
        UserDefaults.standard.synchronize()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func stageMode(_ sender: Any) {
        setModeToStage()
    }

    func setModeToStage() {
        UserDefaults.standard.set(Settings.GAME_MODE_STAGE, forKey: Settings.GAME_MODE_KEY)
        // are all the modes going to have their own sets of textures? that's cool.
        UserDefaults.standard.set(Settings.TEXTURE_KEY_STAGE, forKey: Settings.TEXTURE_KEY_MODE)
        toggleModeButtons()
    }

    @IBAction func endlessMode(_ sender: Any) {
        showPurchaseAlertOrSelect(mode: .endless)
    }
  
    func productPurchase(identifier: String) {
        for p in products {
            if p.productIdentifier == identifier {
                print("purchasing product with id \(identifier)")
                StageBallsProducts.store.buyProduct(p)
            }
        }
    }

    func showPurchaseAlertOrSelect(mode: GameMode) {
//        #if DEBUG
//          selectMode(mode: mode)
//        #else
          // first, check if this user has already purchased the product with the given identifier
          if (mode.canPurchase() && mode.productId() != nil) {
              if StageBallsProducts.store.isProductPurchased(mode.productId()!) {
                  selectMode(mode: mode)
              } else {
                  let alert = UIAlertController(title: "Purchase \(mode.modeName())", message: "Do you want tp purchase \(mode.modeName().lowercased())?", preferredStyle: .alert)
                  alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                      alert.dismiss(animated: true, completion: nil)
                  }))
                  alert.addAction(UIAlertAction(title: "Buy", style: .default, handler: { action in
                      self.productPurchase(identifier: mode.productId()!)
                      alert.dismiss(animated: true, completion: nil)
                  }))
                  present(alert, animated: true, completion: nil)
              }
          } else {
              selectMode(mode: mode)
          }
//        #endif
    }

    func selectMode(mode: GameMode) {
        switch mode {
            case .endless:
              setModeToEndless()
              break
            case .memory:
              setModeToMemory()
              break
            case .stage:
              setModeToStage()
              break
        }
    }

    func setModeToEndless() {
        UserDefaults.standard.set(Settings.GAME_MODE_ENDLESS, forKey: Settings.GAME_MODE_KEY)
        UserDefaults.standard.set(Settings.TEXTURE_KEY_ENDLESS, forKey: Settings.TEXTURE_KEY_MODE)
        toggleModeButtons()
    }

    @IBAction func memoryMode(_ sender: Any) {
        showPurchaseAlertOrSelect(mode: .memory)
    }

    func setModeToMemory() {
        UserDefaults.standard.set(Settings.GAME_MODE_MEMORY, forKey: Settings.GAME_MODE_KEY)
        UserDefaults.standard.set(Settings.TEXTURE_KEY_MEMORY, forKey: Settings.TEXTURE_KEY_MODE)
        toggleModeButtons()
    }

    func checkForPurchased() {
        if StageBallsProducts.store.isProductPurchased(StageBallsProducts.MemoryModeProductId) {
            memoryButton.setImage(#imageLiteral(resourceName: "memoryMode"), for: .normal)
        }
        if StageBallsProducts.store.isProductPurchased(StageBallsProducts.EndlessModeProductId) {
            endlessButton.setImage(#imageLiteral(resourceName: "endlessMode"), for: .normal)
        }
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
