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
    var gameMode = Settings.GAME_MODE_KEY_STAGE
    var gameTexture = Settings.TEXTURE_KEY_COLORS

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
    }
    
    func getRewardMessages() {
        let remoteMessages = remoteConfig[Settings.RewardMessagesConfigKey].stringValue
        if let array = remoteMessages?.split(separator: ",") {
            let strings = array.map({ String($0) })
            rewardnextstageStrings.removeAll()
            rewardnextstageStrings.append(contentsOf: strings)
        }
        // convert string to integer
        // let str = "0"
        // let num = Int(str)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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

        // grab the defaults
        //defaults.set(99, forKey: Settings.HIGH_SCORE_KEY)
        if let modeSetting = defaults.object(forKey: Settings.GAME_MODE_KEY) as? String {
            gameMode = modeSetting
        }

        if let texture = defaults.object(forKey: Settings.TEXTURE_KEY) as? String {
            gameTexture = texture
        }

        //ads
        //      interstitial = createAndLoadInterstitial()
        setcurrentStage()
        listenForNotifications()
        layoutUI()

        if Settings.isIphoneX {
            stageLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            menuBtn.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            menuBtn.imageEdgeInsets.top = 5.0
            menuBtn.imageEdgeInsets.bottom = 25.0
        }

        stageLabel.textColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
        rewardLabel.textColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)

        if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int {
            stageLabel.text = "STAGE \(currentStage)"
            game = Game(
                startingStage: currentStage,
                isEndlessMode: gameMode == Settings.GAME_MODE_KEY_ENDLESS, // if endless mode string, evaluates to true
                isMemoryMode: gameMode == Settings.GAME_MODE_KEY_MEMORY, // if memory string, evaluates true
                isStageMode: gameMode == Settings.GAME_MODE_KEY_STAGE // if stage string, evaluates true
            )
            // print("updatedstage: ------------ \(currentStage)")
        } else {
            // fallback to level 1 (first time players or after a reset)
            game = Game(
                startingStage: 3,
                isEndlessMode: gameMode == Settings.GAME_MODE_KEY_ENDLESS,
                isMemoryMode: gameMode == Settings.GAME_MODE_KEY_MEMORY,
                isStageMode: gameMode == Settings.GAME_MODE_KEY_STAGE
            )
            defaults.set(3, forKey: Settings.CURRENT_STAGE_KEY)
            stageLabel.text = "STAGE 3"
        }

        defaults.synchronize()

        camera = SKCameraNode()
        setupGame(animateBackground: false)
    }
    func setcurrentStage(){
        if let stage = defaults.object(forKey: Settings.HIGH_SCORE_KEY) as? Int {
            Analytics.logEvent("highest_stage", parameters: [
                "stage": stage
                ])
        }
    }
    func createAndLoadInterstitial() -> GADInterstitial {
        // ---> THIS IS FOR ADS AT ADMOB.com
        // interstitial = GADInterstitial(adUnitID: "ca-app-pub-8530735287041699/7915824718")
        // to test
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-8530735287041699/7915824718")
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
        if let modeSetting = defaults.object(forKey: Settings.GAME_MODE_KEY) as? String {
            gameMode = modeSetting
        }
        
        if let texture = defaults.object(forKey: Settings.TEXTURE_KEY) as? String {
            gameTexture = texture
        }

        if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int {
            stageLabel.text = "STAGE \(currentStage)"
            game = Game(
                startingStage: currentStage,
                isEndlessMode: gameMode == Settings.GAME_MODE_KEY_ENDLESS,
                isMemoryMode: gameMode == Settings.GAME_MODE_KEY_MEMORY,
                isStageMode: gameMode == Settings.GAME_MODE_KEY_STAGE
            )
            // print("updatedstage: ------------ \(currentStage)")
        }else {
            // fallback to level 1 (first time players or after a reset)
            game = Game(
                startingStage: 1,
                isEndlessMode: gameMode == Settings.GAME_MODE_KEY_ENDLESS,
                isMemoryMode: gameMode == Settings.GAME_MODE_KEY_MEMORY,
                isStageMode: gameMode == Settings.GAME_MODE_KEY_STAGE
            )
            defaults.set(1, forKey: Settings.CURRENT_STAGE_KEY)
            stageLabel.text = "STAGE 1"
        }
        defaults.synchronize()
        
        camera = SKCameraNode()
       
        stageLabel.textColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
        rewardLabel.textColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
        scene.removeAllChildren()
        scene.removeAllActions()
        scene.removeFromParent()
        camera.removeFromParent()
        camera = SKCameraNode()
            let _ = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false, block: { _ in
                self.gameOverController?.dismiss(animated: false) {
                    self.setupGame(animateBackground: true)
                    // print("animate tooooo true")
                }
            })

    }
    
    func setupGame(animateBackground: Bool) {
        setupScene(setToWhite: !animateBackground)
        if (animateBackground) {
            scene.fadeBackgroundBackToWhite()
            // print("daaaaaaaark")
        }
        setupCamera()
        setupUI()
        addPlayedGame()
        layoutAfterSetup()
        // print("white")
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
        }else if game.stage == 14{
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = "That's your day"
        }else if game.stage == 21{
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = "Fantastic"
        }else if game.stage == 30{
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = "Excellent"
        }else if game.stage == 35{
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = "Well done"
        }else if game.stage > 40{
            self.rewardLabel.alpha = 1.0
            self.rewardLabel.text = randNum
        }else{
            self.rewardLabel.alpha = 0.0
        }
    }

    func setupScene(setToWhite: Bool) {
      //  scoreLabel.text = "\(game.numberBallsInQueue)"
        scoreLabel.format = "%d"
        scoreLabel.method = .linear
        scoreLabel.countFrom(CGFloat(0), to: CGFloat(game.numberBallsInQueue), withDuration: 1.5) //TO-DO: make this a % of how many balls
        checkscorelabelsize()
        scene = GameScene(size: view.frame.size)
        if (setToWhite) {
            scene.backgroundColor = UIColor.white
        } else {
//            scene.backgroundColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
        }
        scene.gameDelegate = self
        scene.scoreKeeper = self
        skView = view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        scene.scaleMode = .resizeFill
        if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int {
            game.setStage(toStage: currentStage)
        }
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
        if game.ballsRemaining < 100 {
            scoreLabel.font = UIFont(name: "Oregon-Regular", size: 140)
        } else if game.ballsRemaining < 1000 {
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

    func gameover() {
        let playspergame = defaults.integer(forKey: Settings.PLAYS_PER_GAME)
        defaults.set(playspergame + 1, forKey: Settings.PLAYS_PER_GAME)
        print("print", playspergame)
        // save the high score if we just set it!
        if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY) as? Int {
            if game.stage > highScore {
                defaults.set(game.stage, forKey: Settings.HIGH_SCORE_KEY)
            }
        } else {
            defaults.set(game.stage, forKey: Settings.HIGH_SCORE_KEY)
        }
        adsShowGameOver = true

        handleAds()

        defaults.synchronize()

        camera.removeFromParent()
    }
    
    func handleAds() {
//ads
        //var shouldShowAds = false
        
//        if let lastAdTime = defaults.object(forKey: Settings.LAST_AD_TIME) as? Double {
//            let now = Date().timeIntervalSince1970
//            // print("=====> last ad time", now, lastAdTime, now - lastAdTime)
//            if now - lastAdTime >= 300 && scene.game.stage >= 13 && interstitial.isReady {
//                shouldShowAds = true
//            }
//        } else if scene.game.stage >= 13 {
//            // print("====> no last ad time found")
//            shouldShowAds = true
//        }
        
//        if interstitial.isReady && shouldShowAds {
//shows ads
//            interstitial.present(fromRootViewController: self)
//            defaults.set(Date().timeIntervalSince1970, forKey: Settings.LAST_AD_TIME)
//            defaults.synchronize()
//        } else {
//            // print("Ad wasn't ready")
            if adsShowGameOver {
                AudioManager.only.playGameOverSOund()
                adsShowGameOver = false
                showGameOverViewController()
            } else if adsShowNextStage {
                AudioManager.only.playNextStageSound()
                adsShowNextStage = false
                startNextStage()
            }
//        }
    }
    
//    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
//        // print("interstitialDidDismissScreen")
//        interstitial = createAndLoadInterstitial()
//        if adsShowGameOver {
//            AudioManager.only.playGameOverSOund()
//            showGameOverViewController()
//            adsShowGameOver = false
//        } else if adsShowNextStage {
//            AudioManager.only.playNextStageSound()
//            startNextStage()
//            adsShowNextStage = false
//        }
//
//    }

    func gameoverdesign() {
        // print("gameoverdesin")
        
        UIView.animate(withDuration: 0.4, delay: 0.0, animations: {
            self.stageLabel.textColor = UIColor.white
            // ASK EMILY IF THAT WORKS FINE
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
        if let stage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int, let played = defaults.object(forKey: Settings.PLAYS_PER_GAME) as? Int {
            print(stage, played)
            Analytics.logEvent("played_nextstage", parameters: [
                "stage": stage,
                "played": played
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
        // create and present the game over view controller
        gameOverController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameOverId2") as? GameOverViewControllerNew
        // set the ending "score" to how many balls you cleared (number fallen)
        gameOverController!.endingScore = scene.game.ballsRemaining
        gameOverController!.endingStage = scene.game.stage
        present(gameOverController!, animated: false, completion: nil)
    }
    
    func startNextStage() {
        game.increaseStage()
        defaults.set(game.stage, forKey: Settings.CURRENT_STAGE_KEY)
        defaults.synchronize()
        stageLabel.text = "STAGE \(game.stage)"
        camera.removeFromParent()
        camera = SKCameraNode()
        setupGame(animateBackground: false)
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
