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
    case stage = "stage", endless = "endless", memory = "memory", reversed = "reversed", invisible = "invisible"
  
    func canPurchase() -> Bool {
        switch self {
            case .endless:
                return true
            case .memory:
                return true
            case .reversed:
              return true
            case .invisible:
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
            case .reversed:
                return StageBallsProducts.ReversedModeProductId
            case .invisible:
                return StageBallsProducts.InvisibleModeProductId
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
            case .reversed:
                return "Reversed Mode"
            case .invisible:
                return "Invisible Mode"
            case .stage:
                return "Stage Mode"
        }
    }
  
     func modeDefaultsKey() -> String {
        switch self {
            case .endless:
                return Settings.GAME_MODE_ENDLESS
            case .memory:
                return Settings.GAME_MODE_MEMORY
            case .reversed:
                return Settings.GAME_MODE_REVERSED
            case .invisible:
                return Settings.GAME_MODE_INVISIBLE
            default:
                return Settings.GAME_MODE_STAGE
        }
    }

    static func modeForId(id: String) -> GameMode? {
        switch id {
            case StageBallsProducts.EndlessModeProductId:
                return .endless
            case StageBallsProducts.MemoryModeProductId:
                return .memory
            case StageBallsProducts.ReversedModeProductId:
                return .reversed
            case StageBallsProducts.InvisibleModeProductId:
                return .invisible
            default:
                return nil
        }
    }
  
    static func modeForDefaultsKey(id: String) -> GameMode? {
        switch id {
            case Settings.GAME_MODE_ENDLESS:
                return .endless
            case Settings.GAME_MODE_MEMORY:
                return .memory
            case Settings.GAME_MODE_REVERSED:
                return .reversed
            case Settings.GAME_MODE_INVISIBLE:
                return .invisible
            default:
                return nil
        }
    }
}

class ModeViewController: UIViewController{

    @IBOutlet var endlessButton: UIButton!
    @IBOutlet var memoryButton: UIButton!
    @IBOutlet var stageButton: UIButton!
    @IBOutlet weak var reversedButton: UIButton!

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

        checkForPurchased()
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
                StageBallsProducts.store.buyProduct(p)
            }
        }
    }

    func showPurchaseAlertOrSelect(mode: GameMode) {
        #if DEBUG
          selectMode(mode: mode)
        #else
          // first, check if this user has already purchased the product with the given identifier
          if (mode.canPurchase() && mode.productId() != nil) {
              if StageBallsProducts.store.isProductPurchased(mode.productId()!) {
                  selectMode(mode: mode)
              } else {
                  self.productPurchase(identifier: mode.productId()!)
              }
          } else {
              selectMode(mode: mode)
          }
        #endif
    }

    func selectMode(mode: GameMode) {
        switch mode {
            case .endless:
              setModeToEndless()
              break
            case .memory:
              setModeToMemory()
              break
            case .reversed:
              setModeToReversed()
              break
            case .invisible:
              setModeToInvisible()
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

    @IBAction func reversedMode(_ sender: Any) {
        showPurchaseAlertOrSelect(mode: .reversed)
    }
  
    func setModeToReversed() {
        UserDefaults.standard.set(Settings.GAME_MODE_REVERSED, forKey: Settings.GAME_MODE_KEY)
        UserDefaults.standard.set(Settings.TEXTURE_KEY_REVERSED, forKey: Settings.TEXTURE_KEY_MODE)
        toggleModeButtons()
    }
  
    // TODO: Connect this action to invisible button
    @IBAction func invisibleMode(_ sender: Any) {
        showPurchaseAlertOrSelect(mode: .invisible)
    }

    func setModeToInvisible() {
        UserDefaults.standard.set(Settings.GAME_MODE_INVISIBLE, forKey: Settings.GAME_MODE_KEY)
        UserDefaults.standard.set(Settings.TEXTURE_KEY_INVISIBLE, forKey: Settings.TEXTURE_KEY_MODE)
        toggleModeButtons()
    }

    func checkForPurchased() {
        if StageBallsProducts.store.isProductPurchased(StageBallsProducts.MemoryModeProductId) {
            memoryButton.setImage(#imageLiteral(resourceName: "memoryMode"), for: .normal)
        }
        if StageBallsProducts.store.isProductPurchased(StageBallsProducts.EndlessModeProductId) {
            endlessButton.setImage(#imageLiteral(resourceName: "endlessMode"), for: .normal)
        }
        if StageBallsProducts.store.isProductPurchased(StageBallsProducts.ReversedModeProductId) {
            reversedButton.setImage(#imageLiteral(resourceName: "unlockReversedunlocked"), for: .normal)
        }
        if StageBallsProducts.store.isProductPurchased(StageBallsProducts.InvisibleModeProductId) {
            // TODO: Set invisible button and image here
            reversedButton.setImage(#imageLiteral(resourceName: "unlockReversedunlocked"), for: .normal)
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
                reversedButton.backgroundColor = UIColor.clear
                memoryButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
            } else if textureMode == Settings.TEXTURE_KEY_ENDLESS{
                stageButton.backgroundColor = UIColor.clear
                endlessButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                reversedButton.backgroundColor = UIColor.clear
                memoryButton.backgroundColor = UIColor.clear
            } else if textureMode == Settings.TEXTURE_KEY_REVERSED {
                stageButton.backgroundColor = UIColor.clear
                endlessButton.backgroundColor = UIColor.clear
                reversedButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                memoryButton.backgroundColor = UIColor.clear
            } else {
                stageButton.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                endlessButton.backgroundColor = UIColor.clear
                reversedButton.backgroundColor = UIColor.clear
                memoryButton.backgroundColor = UIColor.clear
            }
        }
    }
}
