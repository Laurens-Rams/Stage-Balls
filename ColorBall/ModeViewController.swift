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
  
    func highScoreKey() -> String {
        switch self {
            case .endless:
                return Settings.HIGH_SCORE_KEY_ENDLESS
            case .memory:
                return Settings.HIGH_SCORE_KEY_MEMORY
            case .reversed:
                return Settings.HIGH_SCORE_KEY_REVERSED
            case .invisible:
                return Settings.HIGH_SCORE_KEY_INVISIBLE
            case .stage:
                return Settings.HIGH_SCORE_KEY
        }
    }
  
    func highestStageKey() -> String? {
        switch self {
            case .memory:
                return Settings.HIGHEST_STAGE_KEY_MEMORY
            case .invisible:
                return Settings.HIGHEST_STAGE_KEY_INVISIBLE
            case .stage:
                return Settings.HIGHEST_STAGE_KEY
            default:
                return nil
        }
    }
  
    func currentStageKey() -> String {
        switch self {
            case .endless:
                return Settings.CURRENT_STAGE_KEY_ENDLESS
            case .memory:
                return Settings.CURRENT_STAGE_KEY_MEMORY
            case .reversed:
                return Settings.CURRENT_STAGE_KEY_REVERSED
            case .invisible:
                return Settings.CURRENT_STAGE_KEY_INVISIBLE
            case .stage:
                return Settings.CURRENT_STAGE_KEY
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
  
    func modeTriesLeftDefaultsKey() -> String? {
        switch self {
            case .endless:
                return Settings.TRIES_LEFT_KEY_ENDLESS
            case .memory:
                return Settings.TRIES_LEFT_KEY_MEMORY
            case .reversed:
                return Settings.TRIES_LEFT_KEY_REVERSED
            case .invisible:
                return Settings.TRIES_LEFT_KEY_INVISIBLE
            default:
                return nil
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
            case Settings.GAME_MODE_STAGE:
                return .stage
            default:
                return nil
        }
    }
  
    static func allModesWithFreeTries() -> [GameMode] {
        return [.endless, .memory, .reversed, .invisible]
    }
}

class ModeViewController: UIViewController{
    @IBOutlet weak var endlessButton: UIButton!
    @IBOutlet weak var memoryButton: UIButton!
    @IBOutlet weak var stageButton: UIButton!
    @IBOutlet weak var reversedButton: UIButton!
    @IBOutlet weak var invisibleButton: UIButton!
  
    @IBOutlet weak var endlessTriesLabel: TriesLabel!
    @IBOutlet weak var memoryTriesLabel: TriesLabel!
    @IBOutlet weak var reversedTriesLabel: TriesLabel!
    @IBOutlet weak var invisibleTriesLabel: TriesLabel!
  
    var products = [SKProduct]()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handlePurchaseNotification),
            name: .IAPHelperPurchaseNotification,
            object: nil
        )

        for mode in GameMode.allModesWithFreeTries() {
            if let label = triesLabelForGameMode(mode: mode) {
                label.configureForMode(mode)
            }
        }

        whenReceivedProductDataOrThingsChangedOrLoading()
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getProductData() { success in
            self.whenReceivedProductDataOrThingsChangedOrLoading()
        }
    }
  
    func whenReceivedProductDataOrThingsChangedOrLoading() {
        self.toggleModeButtons()
        self.hideTriesLabelsIfNeeded()
        self.checkForPurchased()
        if let savedMode = UserDefaults.standard.object(forKey: Settings.GAME_MODE_KEY) as? String {
            if let gameMode = GameMode.modeForDefaultsKey(id: savedMode) {
                let shouldShowAlert = checkIfShouldAutoShowPurchaseAlert(mode: gameMode)
                if shouldShowAlert {
                    showPurchaseAlertOrSelect(mode: gameMode)
                }
            }
        }
    }

    @objc func handlePurchaseNotification(_ notification: Notification) {
        guard let productId = notification.object as? String else { return }
      
        if let mode = GameMode.modeForId(id: productId) {
            selectMode(mode: mode)
        }

        checkForPurchased()
        hideTriesLabelsIfNeeded()
    }

    func checkIfShouldAutoShowPurchaseAlert(mode: GameMode) -> Bool {
        if GameMode.allModesWithFreeTries().contains(mode) {
            if let triesLeft = Settings.getTriesLeftForMode(mode: mode) {
                if triesLeft > 0{
                    return false
                }
                return true
            }
        }

        return false
    }

    func triesLabelForGameMode(mode: GameMode) -> TriesLabel? {
        switch mode {
            case .memory:
                return memoryTriesLabel
            case .endless:
                return endlessTriesLabel
            case .invisible:
                return invisibleTriesLabel
            case .reversed:
                return reversedTriesLabel
            default:
                return nil
        }
    }

    func buttonForGameMode(mode: GameMode) -> UIButton {
        switch mode {
            case .stage:
                return stageButton
            case .memory:
                return memoryButton
            case .endless:
                return endlessButton
            case .invisible:
                return invisibleButton
            case .reversed:
                return reversedButton
        }
    }

    func getProductData(completion: @escaping (Bool) -> Void) {
        StageBallsProducts.store.requestProducts() { success, products in
            if success {
                self.products = products!
            }
            self.checkForPurchased()
            print(success, self.products)
            completion(success)
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
        let freeunlocked = UserDefaults.standard.bool(forKey: Settings.UNLOCK_FREE_MODES)
        if Settings.DEV_MODE || freeunlocked {
            // if dev mode is true, select the mode
            selectMode(mode: mode)
            return
        }

        if GameMode.allModesWithFreeTries().contains(mode) {
            if let triesLeft = Settings.getTriesLeftForMode(mode: mode) {
                if triesLeft > 0{
                    // if we're tracking tries left for this mode, and we have more than 0 left, select it
                    selectMode(mode: mode)
                    return
                }
            }
        }

        print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
        print("we would show the purchase alert here")
        print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")

        // first, check if this user has already purchased the product with the given identifier
        if mode.canPurchase() && mode.productId() != nil {
            if StageBallsProducts.store.isProductPurchased(mode.productId()!){
                // already purchased? select it
                selectMode(mode: mode)
            } else {
                // show the purchase alert
                self.productPurchase(identifier: mode.productId()!)
            }
        } else {
            // not purchasable? must be stage mode; select it
            selectMode(mode: mode)
        }
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
  
    @IBAction func invisibleMode(_ sender: Any) {
        showPurchaseAlertOrSelect(mode: .invisible)
    }

    func setModeToInvisible() {
        UserDefaults.standard.set(Settings.GAME_MODE_INVISIBLE, forKey: Settings.GAME_MODE_KEY)
        UserDefaults.standard.set(Settings.TEXTURE_KEY_INVISIBLE, forKey: Settings.TEXTURE_KEY_MODE)
        toggleModeButtons()
    }

    func checkForPurchased() {
        let freeunlocked = UserDefaults.standard.bool(forKey: Settings.UNLOCK_FREE_MODES)
        if StageBallsProducts.store.isProductPurchased(StageBallsProducts.MemoryModeProductId) || freeunlocked{
            memoryButton.setImage(#imageLiteral(resourceName: "memoryMode"), for: .normal)
        }

        if StageBallsProducts.store.isProductPurchased(StageBallsProducts.EndlessModeProductId) || freeunlocked {
            endlessButton.setImage(#imageLiteral(resourceName: "endlessMode"), for: .normal)
        }

        if StageBallsProducts.store.isProductPurchased(StageBallsProducts.ReversedModeProductId) || freeunlocked {
            reversedButton.setImage(#imageLiteral(resourceName: "unlockReversedunlocked"), for: .normal)
        }

        if StageBallsProducts.store.isProductPurchased(StageBallsProducts.InvisibleModeProductId) || freeunlocked {
            invisibleButton.setImage(#imageLiteral(resourceName: "unlockInvisible"), for: .normal)
        }
    }

    func setButtonTextures(activeButton: UIButton) {
        let buttons = [stageButton, endlessButton, reversedButton, memoryButton, invisibleButton]
        for button in buttons {
            if let button = button {
                if button == activeButton {
                    if button == invisibleButton {
                        button.alpha = 0.8
                    }else{
                    button.backgroundColor = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
                    }
                } else {
                    button.backgroundColor = UIColor.clear
                    button.alpha = 1.0
                }
            }
        }
    }
  
    func hideTriesLabelsIfNeeded() {
        let modes = GameMode.allModesWithFreeTries()
        for mode in modes {
            if let triesLabel = triesLabelForGameMode(mode: mode),
              let productId = mode.productId() {
                let isPurchased = StageBallsProducts.store.isProductPurchased(productId)
                if isPurchased {
                    triesLabel.alpha = 0
                }
            }
        }
    }

    func toggleModeButtons() {
        UserDefaults.standard.synchronize()

        if let textureMode = UserDefaults.standard.object(forKey: Settings.TEXTURE_KEY_MODE) as? String {
            if textureMode == Settings.TEXTURE_KEY_MEMORY {
                setButtonTextures(activeButton: memoryButton)
            } else if textureMode == Settings.TEXTURE_KEY_ENDLESS{
                setButtonTextures(activeButton: endlessButton)
            } else if textureMode == Settings.TEXTURE_KEY_REVERSED {
                setButtonTextures(activeButton: reversedButton)
            } else if textureMode == Settings.TEXTURE_KEY_INVISIBLE {
                setButtonTextures(activeButton: invisibleButton)
            } else {
                setButtonTextures(activeButton: stageButton)
            }
        }
    }
}
