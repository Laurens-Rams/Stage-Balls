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

class GameViewController: UIViewController, StartGameDelegate, GameScoreDelegate {
    
    @IBOutlet var settingButton: UIButton!
    @IBOutlet var pauseButton: UIButton!

    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var menuBtn: UIButton!
    @IBOutlet weak var stageLabel: UILabel!
    
    var scene: GameScene!
    var skView: SKView!
    var camera: SKCameraNode!
    
    var game: Game!
    
    var gameOverController: GameOverViewControllerNew?
    
    let defaults = UserDefaults.standard
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listenForNotifications()
        layoutUI()

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
    
    func layoutUI() {
        let startY = CGFloat((view.frame.height / 3) * 2) - (scoreLabel.frame.height / 2)
        scoreLabel.frame = CGRect(x: 0, y: startY, width: scoreLabel.frame.width, height: scoreLabel.frame.height)
    }
    
    func layoutAfterSetup() {
        view.bringSubview(toFront: pauseButton)
        view.bringSubview(toFront: menuBtn)
        view.layer.zPosition = 0
        pauseButton.layer.zPosition = 1
        menuBtn.layer.zPosition = 2
    }
    
    func listenForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleGameRestartRequest), name: Notification.Name(rawValue: "gameRestartRequested"), object: nil)
    }
    
    @objc func handleGameRestartRequest() {
//        let mb = self.menuBtn
//        let pb = self.pauseButton
        scene.removeAllChildren()
        scene.removeAllActions()
        scene.removeFromParent()
        camera.removeFromParent()
        camera = SKCameraNode()
        let _ = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false, block: { _ in
            self.gameOverController?.dismiss(animated: false) {
                self.setupGame()
//                if let pb = pb { self.view.addSubview(pb) }
//                else { print("no pause button anymore") }
//                if let mb = mb { self.view.addSubview(mb) }
//                else { print("no menu button anymore") }
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
        scoreLabel.text = "\(game.numberBallsInQueue)"
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
        scene.fallTimer.invalidate()
        let pauseView = PauseView.instanceFromNib() as! PauseView
        pauseView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        pauseView.delegate = self
        self.view.addSubview(pauseView)
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
                self.scene.fallTimer.fire()
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

        defaults.synchronize()

        camera.removeFromParent()
        
        // create and present the game over view controller
        gameOverController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameOverId2") as? GameOverViewControllerNew
        // set the ending "score" to how many balls you cleared (number fallen)
        gameOverController!.endingScore = scene.game.ballsRemaining
        gameOverController!.endingStage = scene.game.stage
        present(gameOverController!, animated: false, completion: nil)
    }

    func gameoverdesign() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.pauseButton.alpha = 0.0
        }, completion: nil)
    }
    
    func handleNextStage() {
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
