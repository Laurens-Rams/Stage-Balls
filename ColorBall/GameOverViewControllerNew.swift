
import UIKit
import SpriteKit
import GameplayKit
import GameKit

class GameOverViewControllerNew: UIViewController, StartSceneDelegate, GKGameCenterControllerDelegate {
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    }
    
    
    /* Variables */
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    var score = 0
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    let LEADERBOARD_ID = "stageid"
    
    
    var endingScore: Int = 0
    var endingStage: Int = 1

    @IBOutlet var stageLabel: UILabel!
    @IBOutlet var showpoints: UILabel!
    
    var scene: GameOverScene!

    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        //GameCenter
        authenticateLocalPlayer()
        super.viewDidLoad()
        layoutUI()
        scene = GameOverScene(size: view.bounds.size)
        scene.del = self
        let skView = view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        showpoints.text = scoreFormatter(score: endingScore)
        if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY) as? Int {
             stageLabel.text = stageFormatter(stage: highScore)
        } else {
            stageLabel.text = stageFormatter(stage: endingStage)
        }
    }
    
    // MARK: - AUTHENTICATE LOCAL PLAYER
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil { print(error)
                    } else { self.gcDefaultLeaderBoard = leaderboardIdentifer! }
                })
                
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated!")
                print(error)
            }
        }
    }
    func layoutUI() {
        let startY = CGFloat((view.frame.height / 3) * 2) - (showpoints.frame.height / 2)
        showpoints.frame = CGRect(x: 0, y: startY, width: showpoints.frame.width, height: showpoints.frame.height)
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
        print("works")
        rateApp(appId: "idfprStageBallz") { success in
            print("RateApp \(success)")
        }
    }

    func rateApp(appId: String, completion: @escaping ((_ success: Bool)->())) {
        guard let url = URL(string : "itms-apps://itunes.apple.com/app/" + appId) else {
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
        let activityVC = UIActivityViewController(activityItems: ["Playing Stage Ballz is awesome! Im at Stage \(scoreFormatter(score: endingStage)) Can you beat my Stage? Get Stage Ballz here https://itunes.apple.com/app/Stage Ballz/id"], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
    }

    
    func gameCenterPressed() {
        let score = scoreFormatter(score: endingStage)
        // Submit score to GC leaderboard
        let bestScoreInt = GKScore(leaderboardIdentifier: LEADERBOARD_ID)
        bestScoreInt.value = Int64(score)!
        GKScore.report([bestScoreInt]) { (error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Best Score submitted to your Leaderboard!")
            }
        }
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = LEADERBOARD_ID
        present(gcVC, animated: true, completion: nil)
}

}
