
import UIKit
import SpriteKit
import GameplayKit
import GameKit

class GameOverViewControllerNew: UIViewController, StartSceneDelegate, GKGameCenterControllerDelegate {
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: false, completion: nil)
    }
    
    @IBOutlet var RemainingBalls: UILabel!
    var game: Game!
    var modeVC: ModeViewController?
    var ballVC: BallsViewController?
    var endingScore: Int = 0
    var endingStage: Int = 1
    let LEADERBOARD_ID = "stageid"
    let LEADERBOARD_ID_MEMORY = "memoryid"
    let LEADERBOARD_ID_ENDLESS = "endlessid"
    @IBOutlet var stageLabel: UILabel!
    @IBOutlet var showpoints: UILabel!
    @IBOutlet weak var lastStageButton: UIButton!
    @IBOutlet weak var nextStageButton: UIButton!
    
    var scene: GameOverScene!

    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        if Settings.isIphoneX {
            stageLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            RemainingBalls.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            
        }
        stageLabel.textColor = .white
        layoutUI()
        scene = GameOverScene(size: view.bounds.size)
        scene.del = self
        let skView = view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        showpoints.text = scoreFormatter(score: endingScore)
        showpoints.alpha = 0
        RemainingBalls.text = "BALLS \(scoreFormatter(score: endingScore))"
        setStageLabel()
        let scoreGameCenter = defaults.object(forKey: Settings.HIGH_SCORE_KEY)
        let scoreGameCenterMemory = defaults.object(forKey: Settings.HIGH_SCORE_KEY_MEMORY)
//        let scoreGameCenterEndless = defaults.object(forKey: Settings.HIGH_SCORE_KEY_ENDLESS)
        let bestScoreInt = GKScore(leaderboardIdentifier: LEADERBOARD_ID)
        let bestScoreIntMemory = GKScore(leaderboardIdentifier: LEADERBOARD_ID_MEMORY)
//        let bestScoreIntEndless = GKScore(leaderboardIdentifier: LEADERBOARD_ID_ENDLESS)
        
        bestScoreInt.value = scoreGameCenter as! Int64
        GKScore.report([bestScoreInt]) { (error) in
            if error != nil {
                // print(error!.localizedDescription)
            } else {
                // print("Best Score submitted to your Leaderboard!")
            }
        }
        bestScoreIntMemory.value = scoreGameCenterMemory as! Int64
        GKScore.report([bestScoreIntMemory]) { (error) in
            if error != nil {
                // print(error!.localizedDescription)
            } else {
                // print("Best Score submitted to your Leaderboard!")
            }
        }
//        bestScoreIntEndless.value = scoreGameCenterEndless as! Int64
//        GKScore.report([bestScoreIntEndless]) { (error) in
//            if error != nil {
//                // print(error!.localizedDescription)
//            } else {
//                // print("Best Score submitted to your Leaderboard!")
//            }
//        }
        showHideStageButtons()
    }

    func setStageLabel() {
        if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int {
            stageLabel.text = stageFormatter(stage: currentStage)
        } else {
            stageLabel.text = stageFormatter(stage: endingStage)
        }
    }
    func modePressed() {
        launchModeViewController()
    }
    
    func ballsPressed() {
        launchBallsViewController()
    }
    
    func launchModeViewController() {
        modeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "modeVC") as? ModeViewController
        present(modeVC!, animated: false, completion: nil)
    }
    
    func launchBallsViewController() {
        ballVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ballVC") as? BallsViewController
        present(ballVC!, animated: false, completion: nil)
    }
    func showHideStageButtons() {
        if Int(scoreFormatter(score: endingScore))! < 100 {
            showpoints.font = UIFont(name: "Oregon-Regular", size: 140)
        } else if Int(scoreFormatter(score: endingScore))! < 1000 {
            showpoints.font = UIFont(name: "Oregon-Regular", size: 95.0)
        }
        if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY) as? Int, let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int {
            // print("high score", highScore)
            // print("current stage", currentStage)
            if currentStage >= highScore {
                nextStageButton.alpha = 0
                nextStageButton.isUserInteractionEnabled = false
                stageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
              // stageLabel.frame = CGRect(x: view.frame.width - stageLabel.frame.width + 50, y: stageLabel.frame.minY, width: stageLabel.frame.width, height: stageLabel.frame.height)
            } else {
                nextStageButton.alpha = 1
                nextStageButton.isUserInteractionEnabled = true
                stageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
                //stageLabel.frame = CGRect(x: view.frame.width - stageLabel.frame.width - 50, y: stageLabel.frame.minY, width: stageLabel.frame.width, height: stageLabel.frame.height)
            }
            if currentStage <= 1 {
                lastStageButton.alpha = 0
                lastStageButton.isUserInteractionEnabled = false
            } else {
                lastStageButton.alpha = 1
                lastStageButton.isUserInteractionEnabled = true
            }
        } else if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int{
            if currentStage <= 1 {
                lastStageButton.alpha = 0
                lastStageButton.isUserInteractionEnabled = false
            } else {
                lastStageButton.alpha = 1
                lastStageButton.isUserInteractionEnabled = true
            }
        }
    }
    
    @IBAction func goToNextStage(_ sender: Any) {
        if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int {
            let nextStage = currentStage + 1
            defaults.set(nextStage, forKey: Settings.CURRENT_STAGE_KEY)
            defaults.synchronize()
        }
        showHideStageButtons()
        setStageLabel()
    }
    
    @IBAction func goToLastStage(_ sender: Any) {
        if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int {
            let lastStage = currentStage - 1
            defaults.set(lastStage, forKey: Settings.CURRENT_STAGE_KEY)
            defaults.synchronize()
        }
        showHideStageButtons()
        setStageLabel()
    }
    
    // MARK: - AUTHENTICATE LOCAL PL
    func layoutUI() {
        //showpoints.layer.zPosition = -1
        let startY = CGFloat((view.frame.height / 2.8) * 2) - (showpoints.frame.height / 2) // wieso 2.8
        let width = UIScreen.main.bounds.width
        showpoints.frame = CGRect(x: 0, y: startY, width: width, height: showpoints.frame.height)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func scoreFormatter(score: Int) -> String {
        return String(score)
    }

    func stageFormatter(stage: Int) -> String {
        return "STAGE \(stage)"
    }
    
    @IBOutlet var scoreLabel: UILabel!
    
    // start scene delegate protocol methods
    
    func launchGame() {}

    func launchShop() {}

    func ratePressed() {
        // print("works")
        rateApp(appId: "1408563085") { success in
            // print("RateApp \(success)")
        }
    }

    func rateApp(appId: String, completion: @escaping ((_ success: Bool)->())) {
        guard let url = URL(string : "itms-apps://itunes.apple.com/app/stage-balls/id" + appId) else {
            completion(false)
            return
        }
        guard #available(iOS 10, *) else {
            completion(UIApplication.shared.openURL(url))
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }

    func sharePressed() {
        if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY) as? Int {
            let activityVC = UIActivityViewController(activityItems: ["Playing Stage Balls is awesome! I'm at Stage \(highScore) Can you beat my Stage? Get Stage Balls here https://itunes.apple.com/app/stage-balls/id1408563085"], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            self.present(activityVC, animated: true, completion: nil)
        }
        
    }

    
    func gameCenterPressed() {
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = self.LEADERBOARD_ID
        self.present(gcVC, animated: true, completion: nil)
        // print("also in del")
}
    

}
