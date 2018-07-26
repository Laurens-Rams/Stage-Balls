//
//  TutorialViewController.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/25/18.
//  Copyright © 2018 Laurens Ramsenthaler. All rights reserved.
//

import UIKit
import SpriteKit

class TutorialViewController: UIViewController {
    
    var scene: TutorialScene!
    var skView: SKView!
    var camera: SKCameraNode!
    var instructions = [
        "Tap to move",
        "Clear the ball",
        "Hold to spin",
        "Clear it again"
    ]
    var tutorial: Tutorial!
    
    let defaults = UserDefaults.standard
    
    var adsShowGameOver = false
    var adsShowNextStage = false
    
    @IBOutlet weak var instructLabel: UILabel!

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        defaults.set(99, forKey: Settings.HIGH_SCORE_KEY)
        defaults.synchronize()
        camera = SKCameraNode()
        setupGame(animateBackground: false)
        setupInstructions()
    }
    
    func listenForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleTutorialStageOneComplete), name: Settings.TutorialStageOneCompletedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTutorialStageTwoComplete), name: Settings.TutorialStageTwoCompletedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateInstructionsAfterTaps), name: Settings.TutorialTapsCompletedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateInstructionsAfterSpins), name: Settings.TutorialSpinsCompletedNotification, object: nil)
    }

    func removeNotificationListeners() {
        NotificationCenter.default.removeObserver(self, name: Settings.TutorialStageOneCompletedNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Settings.TutorialStageTwoCompletedNotification, object: nil)
    }
    
    @objc func updateInstructionsAfterTaps() {
        instructLabel.text = instructions[1]
    }
    
    @objc func updateInstructionsAfterSpins() {
        instructLabel.text = instructions[3]
    }
    
    @objc func handleTutorialStageOneComplete() {
        print("completed a tutorial stage")
        // handler function (calls other functions that do things)
        nextStageOrStartRealGame(startGame: false)
    }
    
    @objc func handleTutorialStageTwoComplete() {
        print("completed a tutorial stage")
        // handler function (calls other functions that do things)
        nextStageOrStartRealGame(startGame: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        listenForNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
       removeNotificationListeners()
    }

    func setupInstructions() {
        let message = instructions[tutorial.stage - 1]
        instructLabel.text = message
    }
    
    func nextStageOrStartRealGame(startGame: Bool) {
        // make decisions about whether we should continue in the tutorial, or whether it's game time
        if startGame {
            startRealGame()
        } else {
            tutorial.increaseStage()
            teardownGame()
            setupInstructions()
            setupGame(animateBackground: false)
        }
    }
    
    func startRealGame() {
        // post a notification that tells the start view controller to show the game now
        NotificationCenter.default.post(Notification(name: Settings.PresentGameControllerNotification))
    }
    
    func teardownGame() {
        camera.removeFromParent()
    }

    func setupGame(animateBackground: Bool) {
        tutorial = Tutorial()
        setupScene(setToWhite: !animateBackground)
        if (animateBackground) {
            scene.fadeBackgroundBackToWhite()
        }
        setupCamera()
    }
    
    func setupScene(setToWhite: Bool) {
        scene = TutorialScene(size: view.frame.size)
        if (setToWhite) {
            scene.backgroundColor = UIColor.white
        }
        skView = view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        scene.scaleMode = .resizeFill
        scene.game = tutorial
        skView.presentScene(scene)
    }
    
    func setupCamera() {
        camera.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        scene.addChild(camera)
        scene.camera = camera
    }

}
