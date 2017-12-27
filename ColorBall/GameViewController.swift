//
//  GameViewController.swift
//  ColorBall
//
//  Created by Emily Kolar on 6/18/17.
//  Copyright © 2017 Emily Kolar. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, StartGameDelegate, GameScoreDelegate {
    
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var menuBtn: UIButton!
    @IBOutlet var moneyLabel: UILabel!
    
    var playerScore: Int = 0
    
    var scene: Scene2!
    var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startGame()
        
    }
    
    func startGame() {
        scene = Scene2(size: view.frame.size)
        scene.gameoverdelegate = self
        scene.scoreKeeper = self
        skView = view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        menuBtn.isEnabled = true
        moneyLabel.text = scoreFormatter(score: DataManager.main.money)
        DataManager.main.addPlayed()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func increaseScore(byValue: Int) {
        playerScore = playerScore + byValue
        scoreLabel.text = scoreFormatter(score: playerScore)
    }
    
    func scoreFormatter(score: Int) -> String {
        if score < 10 {
            return "0\(score)"
        }
        return String(score)
    }
    
    func restartGame() {
        startGame()
    }
    
    func unpauseGame() {
        scene.isPaused = false
        scene.startTimer()
    }
    func gameover() {
        
        DataManager.main.saveHighScore(newScore: playerScore)
        DataManager.main.addMoney(amount: playerScore)
        
        let  GamveVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameOverId") as! GameOver
        
        GamveVC.endingScore = playerScore
        
        present(GamveVC, animated: false, completion: nil)
        
    }
    // implement zour "show the alt start" function in this class
    
    func showaltmenu() {
        restartGame()
        scene.isPaused = true
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // get a reference to storyboard
        let altVC = storyboard.instantiateViewController(withIdentifier: "menu") as! AlternativStart
        altVC.delegate = self
        present(altVC, animated: false, completion: nil)

        
    }
    
    @IBAction func menuAction(_ sender: Any) {
        scene.isPaused = true
        scene.ballTimer?.invalidate()
        let pauseView = PauseView.instanceFromNib() as! PauseView
        pauseView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        pauseView.delegate = self
        // UIView.animate()
        self.view.addSubview(pauseView)
    }
    
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let middle = view.frame.width / 2
//        if let touch = touches.first {
//            let touchX = touch.location(in: view).x
//            if touchX < middle {
//                // do somkething counterclockwise
//                print("LEFT SIDE")
//            }
//            else {
//                // do something clockwise
//                print("RIGHT SIDE")
//            }
//        }
//    }
//    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        
//    }
}
