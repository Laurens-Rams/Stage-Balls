
import UIKit
import SpriteKit
import GameplayKit
import GameKit

class GameOverViewControllerNew: UIViewController, StartSceneDelegate {
    
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
        let notification = Notification(name: Notification.Name.init(rawValue: "gameRestartRequested"), object: nil, userInfo: nil)
        NotificationCenter.default.post(notification)
        dismiss(animated: true, completion: nil)
    }
    
    func launchShop() {
        // launch the shop
    }
    
}

