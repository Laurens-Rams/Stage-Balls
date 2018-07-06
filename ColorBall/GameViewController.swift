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
//ADS
import GoogleMobileAds

class GameViewController: UIViewController, StartGameDelegate, GameScoreDelegate, GADInterstitialDelegate {
    
    // ---> THIS IS FOR ADS AT ADMOB.com
    var interstitial: GADInterstitial!
    @IBOutlet var settingButton: UIButton!

    @IBOutlet var scoreLabel: EFCountingLabel!
    
    @IBOutlet var menuBtn: UIButton!
    @IBOutlet weak var stageLabel: UILabel!
    
    var scene: GameScene!
    var skView: SKView!
    var camera: SKCameraNode!
    
    var game: Game!
    
    var gameOverController: GameOverViewControllerNew?
    
    let defaults = UserDefaults.standard
    
    var adsShowGameOver = false
    var adsShowNextStage = false
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        interstitial = createAndLoadInterstitial()
        super.viewDidLoad()
        listenForNotifications()
        layoutUI()
        
        if Settings.isIphoneX {
            stageLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            menuBtn.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        }
        stageLabel.textColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
        if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int {
            stageLabel.text = "STAGE \(currentStage)"
            game = Game(startingStage: currentStage)
        } else if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY) as? Int {
            game = Game(startingStage: highScore)
            stageLabel.text = "STAGE \(highScore)"
            defaults.set(highScore, forKey: Settings.CURRENT_STAGE_KEY)
        } else {
            // fallback to level 1 (first time players or after a reset)
            game = Game(startingStage: 1)
            defaults.set(1, forKey: Settings.CURRENT_STAGE_KEY)
            stageLabel.text = "STAGE 1"
        }

        defaults.synchronize()

        camera = SKCameraNode()
        setupGame()
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
    
    func layoutUI() {
        let startY = CGFloat((view.frame.height / 3) * 2) - (scoreLabel.frame.height / 2)
        scoreLabel.frame = CGRect(x: 0, y: startY, width: scoreLabel.frame.width, height: scoreLabel.frame.height)
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
        stageLabel.textColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
        scene.removeAllChildren()
        scene.removeAllActions()
        scene.removeFromParent()
        camera.removeFromParent()
        camera = SKCameraNode()
        let _ = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false, block: { _ in
            self.gameOverController?.dismiss(animated: false) {
                self.setupGame()
            }
        })
    }
    
    func setupGame() {
        setupScene()
        setupCamera()
        setupUI()
        addPlayedGame()
        layoutAfterSetup()
    }
    
    func setupScene() {
      //  scoreLabel.text = "\(game.numberBallsInQueue)"
        scoreLabel.format = "%d"
        scoreLabel.method = .linear
        scoreLabel.countFrom(CGFloat(game.ballsRemaining), to: CGFloat(game.numberBallsInQueue), withDuration: 1.5) //TO-DO: make this a % of how many balls
        scene = GameScene(size: view.frame.size)
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
        scoreLabel.text = scoreFormatter(score: scene.game.ballsRemaining)
        // probably a better way to accomplish this, without knowing how high the score could get, is to say, for every multiple of *10, we decrease the font size by x amount, but not smaller than the smallest size you want to use
        if scene.game.ballsRemaining < 100 {
            scoreLabel.font = UIFont(name: "Oregon-Regular", size: 140)
        } else if scene.game.ballsRemaining < 1000 {
            scoreLabel.font = UIFont(name: "Oregon-Regular", size: 95.0)
        }
    }
    
    func scoreFormatter(score: Int) -> String {
        return "\(score)"
    }
    
    func restartGame() {
        camera.removeFromParent()
        camera = SKCameraNode()
        setupGame()
    }
    
    func pauseGame() {
        // TODO: destroy the pause view
        scene.isPaused = true
        scene.canMove = false
        scene.allowToMove = false
        scene.fallTimer?.invalidate()
        let pauseView = PauseView.instanceFromNib() as! PauseView
        pauseView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        pauseView.delegate = self
        self.view.addSubview(pauseView)
        let startY = CGFloat((view.frame.height / 3) * 2) - (pauseView.playButton.frame.height / 2) - 2
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
            }
        })
    }

    func gameover() {
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
        var shouldShowAds = false
        
        if let lastAdTime = defaults.object(forKey: Settings.LAST_AD_TIME) as? Double {
            let now = Date().timeIntervalSince1970
            print("=====> last ad time", now, lastAdTime, now - lastAdTime)
            if now - lastAdTime >= 300 && scene.game.stage >= 13 && interstitial.isReady {
                shouldShowAds = true
            }
        } else if scene.game.stage >= 13 {
            print("====> no last ad time found")
            shouldShowAds = true
        }
        
        if interstitial.isReady && shouldShowAds {
            interstitial.present(fromRootViewController: self)
            defaults.set(Date().timeIntervalSince1970, forKey: Settings.LAST_AD_TIME)
            defaults.synchronize()
        } else {
            print("Ad wasn't ready")
            if adsShowGameOver {
                adsShowGameOver = false
                showGameOverViewController()
            } else if adsShowNextStage {
                adsShowNextStage = false
                startNextStage()
            }
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        print("interstitialDidDismissScreen")
        interstitial = createAndLoadInterstitial()
        if adsShowGameOver {
            showGameOverViewController()
            adsShowGameOver = false
        } else if adsShowNextStage {
            startNextStage()
            adsShowNextStage = false
        }
        
    }

    func gameoverdesign() {
        print("gameoverdesin")
        UIView.animate(withDuration: 0.4, delay: 0.0, options: [.repeat, .curveEaseOut, .autoreverse], animations: {
            self.stageLabel.textColor = UIColor.white
        }, completion: nil)
    }
    
    func handleNextStage() {
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
        restartGame()
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
        pauseGame()
    }
}
