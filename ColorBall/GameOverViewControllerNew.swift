
import UIKit
import SpriteKit
import GameplayKit
import GameKit

class GameOverViewControllerNew: UIViewController, StartSceneDelegate, GKGameCenterControllerDelegate {
    
    deinit {
        print("game over view controller deinit")
    }
    
    var endingScore: Int = 0

    @IBOutlet var stageLabel: UILabel!
    @IBOutlet var showpoints: UILabel!
    
    var scene: GameOverScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameOverScene(size: view.bounds.size)
        scene.del = self
        let skView = view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)

        showpoints.text = scoreFormatter(score: endingScore)
        stageLabel.text = stageFormatter(stage: endingScore)
    }
    
    //GAMECENTER
    
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    let LEADERBOARD_ID = "identity"
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: false, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if let err = error { print(err.localizedDescription)
                    } else { self.gcDefaultLeaderBoard = leaderboardIdentifer! }
                })
                
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated!")
                if let err = error {
                    print(err.localizedDescription)
                }
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func scoreFormatter(score: Int) -> String {
        if score < 10 {
            return "0\(score)"
        }
        return String(score)
    }

    func stageFormatter(stage: Int) -> String {
        return String(stage)
    }
    
    @IBOutlet var scoreLabel: UILabel!
    
    // start scene delegate protocol methods
    
    func launchGame() {
//        let notification = Notification(name: Notification.Name.init(rawValue: "gameRestartRequested"), object: nil, userInfo: nil)
//        NotificationCenter.default.post(notification)
//        dismiss(animated: true, completion: nil)
    }

    func launchShop() {
        // launch the shop
    }

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
        let activityVC = UIActivityViewController(activityItems: ["Playing Stage Ballz is awesome! My best score is 23. Can you beat my score? Get Stage Ballz here https://itunes.apple.com/app/Stage Ballz/id"], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
    }
   func gameCenterPressed() {
        let score = 10
        // Submit score to GC leaderboard
        let bestScoreInt = GKScore(leaderboardIdentifier: LEADERBOARD_ID)
        bestScoreInt.value = Int64(score)
        GKScore.report([bestScoreInt]) { (error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Best Score submitted to your Leaderboard!")
            }
        }
        //open leadboard
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = LEADERBOARD_ID
        present(gcVC, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
}


