//
//  GameViewController.swift
//  ColorBall
//
//  Created by Emily Kolar on 6/18/17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import EFCountingLabel
import Firebase

//ADS
import GoogleMobileAds

class GameViewController: UIViewController, StartGameDelegate, GameScoreDelegate, GADInterstitialDelegate {
    
    // ---> THIS IS FOR ADS AT ADMOB.com
    var interstitial: GADInterstitial!
    @IBOutlet var settingButton: UIButton!

    @IBOutlet var scoreLabel: EFCountingLabel!
    @IBOutlet var tapRight: UIButton!
    @IBOutlet var tapLeft: UIButton!
    
    @IBOutlet var rewardLabel: UILabel!
    @IBOutlet var menuBtn: UIButton!
    @IBOutlet weak var stageLabel: UILabel!
    @IBOutlet weak var menuImage: UIImageView!
  
    var scene: GameScene!
    var skView: SKView!
    var camera: SKCameraNode!
    var rewardnextstageStrings = ["Good job!", "Well done!", "Fantastic!", "Excellent!"]
    var rewardclose = ["You'r close", "Almost finished", "Just a few more"]
    var game: Game!
    
    var gameOverController: GameOverViewControllerNew?
    
    let defaults = UserDefaults.standard
    
    var adsShowGameOver = false
    var adsShowNextStage = false
    
    var remoteConfig: RemoteConfig!

    // store the game mode type
    var gameMode = Settings.GAME_MODE_STAGE
    var gameTexture = Settings.TEXTURE_COLORS

    override var prefersStatusBarHidden: Bool {
        return true
    }
    func gameoverplayscore(){
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scoreLabel.alpha = 1.0
        scoreLabel.text = String(0)
        rewardLabel.alpha = 0.0
        checkscorelabelsize()
    }
    
    func getRewardMessages() {
        let remoteMessages = remoteConfig[Settings.RewardMessagesConfigKey].stringValue
        if let array = remoteMessages?.split(separator: ",") {
            let strings = array.map({ String($0) })
            rewardnextstageStrings.removeAll()
            rewardnextstageStrings.append(contentsOf: strings)
        }
        // convert string to integer:
        // let str = "0"
        // let num = Int(str)
    }

    func setupRemoteConfig() {
        remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.setDefaults(fromPlist: "RemoteDefaults")
        remoteConfig.fetch { status, error in
            if status == .success {
                self.remoteConfig.activateFetched()
                self.getRewardMessages()
            } else {
                // error happened
            }
        }
    }

    // our viewDidLoad was getting kind of messy from how fast we were working,
    // but if possible, try and keep it clean like this; will save you many headaches, i promise
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // try and fetch message values from the firebase remote config
        setupRemoteConfig()

        // development god-mode
        //defaults.set(99, forKey: Settings.HIGH_SCORE_KEY)

        // grab the game mode and texture we should be using
        // this should be called before a game begins (new game, new level, etc)
        checkUserDefaultsValues()

        // ads
        
        interstitial = createAndLoadInterstitial()

        setcurrentStage()
        listenForNotifications()
        layoutUI()

        // setup the game object
        // this also will set our stage label's text
        initializeGame()

        defaults.synchronize()
        camera = SKCameraNode()
        setupGame(animateBackground: false)
    }

    func checkUserDefaultsValues() {
        // grab the mode we're currently in
        if let savedMode = defaults.object(forKey: Settings.GAME_MODE_KEY) as? String {
            gameMode = savedMode
        }
        
        // grab the texture we're currently using
        if let savedTexture = defaults.object(forKey: Settings.TEXTURE_KEY) as? String {
            gameTexture = savedTexture
        }
    }
    
    func initializeGame() {
        var keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY // use this by default
        var currentStageValue = 0
        let fallbackLevel = 1 // fallback if we find no stage has baen saved yet

        // decide if we should use a different key to check the current stage in user defaults
        if gameMode == Settings.GAME_MODE_ENDLESS {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_ENDLESS
        } else if gameMode == Settings.GAME_MODE_MEMORY {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_MEMORY
        } else if gameMode == Settings.GAME_MODE_REVERSED {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_REVERSED
        } else if gameMode == Settings.GAME_MODE_INVISIBLE {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_INVISIBLE
        }

        if let currentStage = defaults.object(forKey: keyForSavedCurrentStage) as? Int {
            currentStageValue = currentStage
            setStageLabel(currentStage: currentStage)
            // print("updatedstage: ------------ \(currentStage)")
        } else {
            // fallback to level 1 (first time players or after a reset)
            currentStageValue = fallbackLevel
            defaults.set(fallbackLevel, forKey: keyForSavedCurrentStage)
            // maybee not so good?
            UserDefaults.standard.set(Settings.TEXTURE_COLORS, forKey: Settings.TEXTURE_KEY)
        }
      
        var mode: GameMode!

        switch gameMode {
            case Settings.GAME_MODE_ENDLESS:
                mode = .endless
                break
            case Settings.GAME_MODE_MEMORY:
                mode = .memory
                break
            case Settings.GAME_MODE_REVERSED:
                mode = .reversed
                break
            case Settings.GAME_MODE_INVISIBLE:
                mode = .invisible
                break
            default:
                mode = .stage
                break
        }

        if mode == .reversed {
            menuBtn.isHidden = true
            menuImage.alpha = 0
        } else {
            menuBtn.isHidden = false
            menuImage.alpha = 1
        }

        game = Game(
            startingStage: currentStageValue,
            mode: mode
        )

        setStageLabel(currentStage: currentStageValue)
    }
    
    func setStageLabel(currentStage: Int) {
        stageLabel.text = (gameMode == Settings.GAME_MODE_ENDLESS || gameMode == Settings.GAME_MODE_REVERSED) ? "∞" : "STAGE \(currentStage)"
    }

    func setcurrentStage(){
        if let stage = defaults.object(forKey: Settings.HIGH_SCORE_KEY) as? Int {
        }
    }

    func createAndLoadInterstitial() -> GADInterstitial {
        // ---> THIS IS FOR ADS AT ADMOB.com
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-8530735287041699/7825261421")
        let request = GADRequest()
        interstitial.load(request)
        interstitial.delegate = self
        return interstitial
    }
    
    func layoutAfterSetup() {
        view.bringSubview(toFront: menuBtn)
        view.layer.zPosition = 0
        menuBtn.layer.zPosition = 2
    }
    
    func listenForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleGameRestartRequest), name: Notification.Name(rawValue: "gameRestartRequested"), object: nil)
    }

    @objc func handleGameRestartRequest() {
        //background/ color also for this
        
        // check the values in user defaults before we restart
        checkUserDefaultsValues()

        // re-initialize the game
        // also resets the stage label text
        initializeGame()

        defaults.synchronize()
        
        stageLabel.textColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
        rewardLabel.textColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)

        // remove the camera and destroy the current game scene
        teardownScene()
        
        // get the camera ready again
        camera = SKCameraNode()
        
        let _ = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false, block: { _ in
            self.gameOverController?.dismiss(animated: false) {
                // time to setup the new game
                self.setupGame(animateBackground: true)
                self.gameOverController = nil
            }
        })
    }
    
    func teardownScene() {
        scene.removeAllChildren()
        scene.removeAllActions()
        scene.removeFromParent()
        camera.removeFromParent()
    }
    
    func setupGame(animateBackground: Bool) {
        // set game to the correct stage
        setGameStage()

        // create and setup the game scene
        setupScene(setToWhite: !animateBackground)

        if (animateBackground) {
            scene.fadeBackgroundBackToWhite()
        }

        setupCamera()
        setupUI()
        addPlayedGame()
        layoutAfterSetup()
        checkscorelabelsize()
        scoreLabel.countFrom(CGFloat(0), to: CGFloat(game.numberBallsInQueue), withDuration: 1.5) //TO-DO: make this a % of how many balls
      
        if let mode = GameMode.modeForDefaultsKey(id: gameMode) {
            Settings.decrementTriesForMode(mode: mode)
        }
    }
    
    func rewardnextstage(){
        let randoString = Int(arc4random_uniform(UInt32(rewardnextstageStrings.count)))
        let randNum = rewardnextstageStrings[randoString]
        // make sure the number isnt repeated
        if (game.stage == 1){
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = "Perfect"
        }else if game.stage == 7{
            self.rewardLabel.alpha = 1.0
        self.rewardLabel.text = "You Rock"
        }else if game.stage == 10{
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = "That's your day"
        }else if game.stage == 15{
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = "Fantastic"
        }else if game.stage == 25{
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = "Excellent"
        }else if game.stage == 30{
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = "Well done"
        }else if game.stage > 35{
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = randNum
        }else{
            self.rewardLabel.alpha = 0.0
        }
    }
    
    func setGameStage() {
        switch gameMode {
            case Settings.GAME_MODE_MEMORY:
                // if we're in memory mode, grab the stage from user defaults using the memory key
                if let currentStageMemory = defaults.object(forKey: Settings.CURRENT_STAGE_KEY_MEMORY) as? Int {
                    print("current memory stage", currentStageMemory)
                    game.setStage(toStage: currentStageMemory)
                }
                break
            case Settings.GAME_MODE_ENDLESS:
                // if we're in endless mode, grab the stage from user defaults using the endless key
                if let currentStageEndless = defaults.object(forKey: Settings.CURRENT_STAGE_KEY_ENDLESS) as? Int {
                    game.setStage(toStage: currentStageEndless)
                }
                break
            case Settings.GAME_MODE_REVERSED:
                // if we're in reversed mode, grab the stage from user defaults using the reversed key
                if let currentStageReversed = defaults.object(forKey: Settings.CURRENT_STAGE_KEY_REVERSED) as? Int {
                    game.setStage(toStage: currentStageReversed)
                }
                break
            case Settings.GAME_MODE_INVISIBLE:
                // if we're in invisible mode, grab the stage from user defaults using the invisible key
                if let currentStageInvisible = defaults.object(forKey: Settings.CURRENT_STAGE_KEY_INVISIBLE) as? Int {
                    game.setStage(toStage: currentStageInvisible)
                }
                break
            default:
                // if none of the other modes are active, grab the stage from user defaults with the normal key
                if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int {
                    game.setStage(toStage: currentStage)
                }
                break
        }
    }

    func setupScene(setToWhite: Bool) {
        scoreLabel.format = "%d"
        scoreLabel.method = .linear
        checkscorelabelsize()
        scene = GameScene(size: view.frame.size)
        if (setToWhite) {
            scene.BackgroundBackToWhite()
        }
        scene.gameDelegate = self
        scene.scoreKeeper = self
        skView = view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        scene.scaleMode = .resizeFill

        scene.game = game
        skView.presentScene(scene)
    }
    
    func setupCamera() {
        camera.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        scene.addChild(camera)
        scene.camera = camera
    }
    
    func setupUI() {
        menuBtn.isEnabled = true
        
    }
    
    func addPlayedGame() {
         DataManager.main.addPlayed()
    }
    
    func increaseScore(byValue: Int) {
        scene.game.increaseScore(byValue: byValue)
        print(game.ballsRemaining)
        scoreLabel.text = scoreFormatter(score: scene.game.numberBallsInQueue)
        // probably a better way to accomplish this, without knowing how high the score could get, is to say, for every multiple of *10, we decrease the font size by x amount, but not smaller than the smallest size you want to use
        checkscorelabelsize()
    }

    func checkscorelabelsize(){
        if game.numberBallsInQueue < 100 {
            scoreLabel.font = UIFont(name: "Oregon-Regular", size: 140)
        } else if game.numberBallsInQueue < 1000 {
            scoreLabel.font = UIFont(name: "Oregon-Regular", size: 95.0)
        }
    }

    func scoreFormatter(score: Int) -> String {
        return "\(score)"
    }

    func layoutUI() {
        let startY = CGFloat((view.frame.height / 2.8) * 2) - (scoreLabel.frame.height / 2)
        let width = UIScreen.main.bounds.width
        scoreLabel.frame = CGRect(x: 0, y: startY, width: width, height: scoreLabel.frame.height)

        if Settings.isIphoneX {
            stageLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            menuBtn.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            menuBtn.imageEdgeInsets.top = 5.0
            menuBtn.imageEdgeInsets.bottom = 25.0
        }
        
        stageLabel.textColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
        rewardLabel.textColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
    }

    func restartGame() {
        camera.removeFromParent()
        camera = SKCameraNode()
        setupGame(animateBackground: true)
    }
    
    func pauseGame() {
        // TODO: destroy the pause view
        scene.isPaused = true
        scene.canMove = false
        scene.allowToMove = false
        scene.canpresspause = false
        scene.fallTimer?.invalidate()
        let pauseView = PauseView.instanceFromNib() as! PauseView
        pauseView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        pauseView.delegate = self
        self.view.addSubview(pauseView)
        let startY = CGFloat((view.frame.height / 2.8) * 2) - (pauseView.playButton.frame.height / 2) - 2
        let startX = CGFloat(view.frame.width / 2 - pauseView.playButton.frame.width / 2) - 2
        let size = UIScreen.main.bounds.size.width * 0.55
        pauseView.playButton.frame = CGRect(x: startX, y: startY, width: size, height: size)
    }
    
    func unpauseGame() {
        scoreLabel.textColor = UIColor.red

        var countdown = 3

        self.scoreLabel.text = "\(countdown)"

        let _ = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true, block: { timer in
            countdown -= 1
            self.scoreLabel.text = "\(countdown)"
            if countdown == 0 {
                timer.invalidate()
                if let lastBall = self.scene.fallingBalls.last {
                    self.scene.startFallTimer(ball: lastBall)
                }
                self.scene.isPaused = false
                self.scene.canMove = true
                self.scene.allowToMove = true
                self.scene.fallTimer?.fire()
                self.scoreLabel.textColor = UIColor.white
                self.scoreLabel.text = self.scoreFormatter(score: self.scene.game.ballsRemaining)
                self.scene.canpresspause = true
            }
        })
    }

    func setHighScoreIfNeeded() {
        // save the high score if we just set it!
        switch gameMode {
            case Settings.GAME_MODE_MEMORY:
                if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY_MEMORY) as? Int {
                    // if we've saved a high score for memory before, check if this one was higher
                    if game.stage > highScore {
                        defaults.set(game.stage, forKey: Settings.HIGH_SCORE_KEY_MEMORY)
                    }
                } else {
                    // if we've never saved a high score for memory, start saving it now
                    defaults.set(game.stage, forKey: Settings.HIGH_SCORE_KEY_MEMORY)
                }
                break
            case Settings.GAME_MODE_ENDLESS:
                if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY_ENDLESS) as? Int {
                    // if we've saved a high score for endless before, check if this one was higher
                    if game.ballsFallen > highScore {
                        defaults.set(game.ballsFallen, forKey: Settings.HIGH_SCORE_KEY_ENDLESS)
                    }
                } else {
                    // if we've never saved a high score for endless, start saving it now
                    defaults.set(game.ballsFallen, forKey: Settings.HIGH_SCORE_KEY_ENDLESS)
                }
                break
            case Settings.GAME_MODE_REVERSED:
                if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY_REVERSED) as? Int {
                    // if we've saved a high score for reversed before, check if this one was higher
                    if game.ballsFallen > highScore {
                        defaults.set(game.ballsFallen, forKey: Settings.HIGH_SCORE_KEY_REVERSED)
                    }
                } else {
                    // if we've never saved a high score for reversed, start saving it now
                    defaults.set(game.ballsFallen, forKey: Settings.HIGH_SCORE_KEY_REVERSED)
                }
                break
            case Settings.GAME_MODE_INVISIBLE:
                if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY_INVISIBLE) as? Int {
                    // if we've saved a high score for invisible before, check if this one was higher
                    if game.ballsFallen > highScore {
                        defaults.set(game.ballsFallen, forKey: Settings.HIGH_SCORE_KEY_INVISIBLE)
                    }
                } else {
                    // if we've never saved a high score for invisible, start saving it now
                    defaults.set(game.ballsFallen, forKey: Settings.HIGH_SCORE_KEY_INVISIBLE)
                }
                break
            default:
                break;
        }
    }

    func gameover() {
        let playspergame = defaults.integer(forKey: Settings.PLAYS_PER_GAME)
        defaults.set(playspergame + 1, forKey: Settings.PLAYS_PER_GAME)
        print("print", playspergame)

        setHighScoreIfNeeded()

        adsShowGameOver = true

        handleAds()

        defaults.synchronize()

        camera.removeFromParent()
    }
    
    func handleAds() {
        //ads
        var shouldShowAds = false
        
        if let lastAdTime = defaults.object(forKey: Settings.LAST_AD_TIME) as? Double {
            let now = Date().timeIntervalSince1970
            // print("=====> last ad time", now, lastAdTime, now - lastAdTime)
            if now - lastAdTime >= 180 && scene.game.stage >= 4 && interstitial.isReady {
                shouldShowAds = true
            }
        } else if scene.game.stage >= 4 {
            // print("====> no last ad time found")
            shouldShowAds = true
        }
        
        if interstitial.isReady && shouldShowAds {
            interstitial.present(fromRootViewController: self)
            defaults.set(Date().timeIntervalSince1970, forKey: Settings.LAST_AD_TIME)
            defaults.synchronize()
        } else {
            // print("Ad wasn't ready")
            if adsShowGameOver {
                AudioManager.only.playGameOverSOund()
                adsShowGameOver = false
                showGameOverViewController()
            } else if adsShowNextStage {
                AudioManager.only.playNextStageSound()
                adsShowNextStage = false
                startNextStage()
            }
        }
    }
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        // print("interstitialDidDismissScreen")
        interstitial = createAndLoadInterstitial()
        if adsShowGameOver {
            AudioManager.only.playGameOverSOund()
            showGameOverViewController()
            adsShowGameOver = false
        } else if adsShowNextStage {
            AudioManager.only.playNextStageSound()
            startNextStage()
            adsShowNextStage = false
        }

    }

    func gameoverdesign() {
        // print("gameoverdesin")
        
        UIView.animate(withDuration: 0.4, delay: 0.0, animations: {
            self.stageLabel.textColor = UIColor.white
            if ((self.game.numberStartingBalls / 10) >= self.game.ballsRemaining){
                self.rewardLabel.textColor = .white
                self.rewardLabel.alpha = 1.0
                let randoString = Int(arc4random_uniform(UInt32(self.rewardclose.count)))
                let randNum = self.rewardclose[randoString]
                self.rewardLabel.text = randNum
            }
            
        }, completion: nil)
    }
    func scorelabelalpha() {
        scoreLabel.alpha = 0.0
        // print("again")
    }
    func tapleftright(){
        UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseIn, animations: {
            self.tapLeft.alpha = 0.0
            self.tapRight.alpha = 0.0
        }) { (finished) in
            print("finish")
        }
    }

    func handleNextStage() {
        var keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY
        if gameMode == Settings.GAME_MODE_ENDLESS {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_ENDLESS
        } else if gameMode == Settings.GAME_MODE_MEMORY {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_MEMORY
        } else if gameMode == Settings.GAME_MODE_REVERSED {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_REVERSED
        } else if gameMode == Settings.GAME_MODE_INVISIBLE {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_INVISIBLE
        }

        // NOTE: i added a parameter to this analytics call so you can distinguish between modes
        // if this is not desired behavior, just delete that line
        if let stage = defaults.object(forKey: keyForSavedCurrentStage) as? Int {
            Analytics.logEvent(AnalyticsEventLevelUp, parameters: [
                AnalyticsParameterCharacter: gameMode,
                AnalyticsParameterLevel: stage
            ])
        }

        defaults.set(0, forKey: Settings.PLAYS_PER_GAME)
        UIView.animate(withDuration: 0.2, delay: 0.0, animations: {
            self.scoreLabel.alpha = 1.0
            self.rewardLabel.alpha = 0.0
        }, completion: nil)
        adsShowNextStage = true
        handleAds()
    }

    func showGameOverViewController() {
        rememberCurrentStage()
        // create and present the game over view controller
        gameOverController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameOverId2") as? GameOverViewControllerNew
        gameOverController?.game = scene.game
        // set the ending "score" to how many balls you cleared (number fallen)
        gameOverController?.endingScore = scene.game.numberBallsInQueue
        gameOverController?.endingScoreEndless = scene.game.ballsFallen
        gameOverController?.endingStage = scene.game.stage

        if scene.game.isEndlessMode || scene.game.isReversedMode {
            Metadata.shared.trackStageScore(stage: scene.game.stage, score: scene.game.ballsFallen, mode: scene.game.mode)
        } else {
            Metadata.shared.trackStageScore(stage: scene.game.stage, score: scene.game.numberBallsInQueue, mode: scene.game.mode)
        }

        present(gameOverController!, animated: false, completion: nil)
    }

    func rememberCurrentStage() {
        // save the current stage into the correct defaults object
        if gameMode == Settings.GAME_MODE_MEMORY {
            // if we're in memory mode, save stage under the memory key
            defaults.set(game.stage, forKey: Settings.CURRENT_STAGE_KEY_MEMORY)
            let highestStage = defaults.integer(forKey: Settings.HIGHEST_STAGE_KEY_MEMORY)
            if (game.stage > highestStage) {
                defaults.set(game.stage, forKey: Settings.HIGHEST_STAGE_KEY_MEMORY)
            }
        } else if gameMode == Settings.GAME_MODE_ENDLESS {
            // if we're in endless mode, save stage under the endless key
            defaults.set(game.stage, forKey: Settings.CURRENT_STAGE_KEY_ENDLESS)
        } else if gameMode == Settings.GAME_MODE_REVERSED {
            // if we're in reversed mode, save stage under the reversed key
            defaults.set(game.stage, forKey: Settings.CURRENT_STAGE_KEY_REVERSED)
        } else if gameMode == Settings.GAME_MODE_INVISIBLE {
            // if we're in invisible mode, save stage under the invisible key
            defaults.set(game.stage, forKey: Settings.CURRENT_STAGE_KEY_INVISIBLE)
            let highestStage = defaults.integer(forKey: Settings.HIGHEST_STAGE_KEY_INVISIBLE)
            if (game.stage > highestStage) {
                defaults.set(game.stage, forKey: Settings.HIGHEST_STAGE_KEY_INVISIBLE)
            }
        } else {
            // if we're in normal stage mode, save under the normal stage key
            defaults.set(game.stage, forKey: Settings.CURRENT_STAGE_KEY)
            let highestStage = defaults.integer(forKey: Settings.HIGHEST_STAGE_KEY)
            if (game.stage > highestStage) {
                defaults.set(game.stage, forKey: Settings.HIGHEST_STAGE_KEY)
            }
        }
    }

    func startNextStage() {
        game.increaseStage()

        rememberCurrentStage()

        defaults.synchronize()
        stageLabel.text = "STAGE \(game.stage)"
        camera.removeFromParent()
        camera = SKCameraNode()
        setupGame(animateBackground: true)
    }

    func showaltmenu() {
        restartGame()
        scene.isPaused = true
        // get a reference to storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        // create an instance of the alt view controller
        let altVC = storyboard.instantiateViewController(withIdentifier: "menu") as! AlternativStart
        // set the delegate to this object
        altVC.delegate = self
        // present the view controller
        present(altVC, animated: false, completion: nil)
    }
    
    @IBAction func menuAction(_ sender: Any) {
        AudioManager.only.playClickSound()
        if scene.canpresspause {
            pauseGame()
        }else{
            print("no pause")
        }
        
    }
}
