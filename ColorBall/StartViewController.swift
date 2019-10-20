
import UIKit
import SpriteKit
import GameplayKit
import GameKit

class StartViewController: UIViewController, StartSceneDelegate, GKGameCenterControllerDelegate {
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: false, completion: nil)
    }
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardI
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    let LEADERBOARD_ID = "stageid"
    let LEADERBOARD_ID_MEMORY = "memoryid"
    let LEADERBOARD_ID_ENDLESS = "endlessid"
    let LEADERBOARD_ID_REVERSED = "reversedmodeid"
    deinit {
    }
    let defaults = UserDefaults.standard
    @IBOutlet var moneyLabel: UILabel!
    @IBOutlet var logo2: UIImageView!
    
    var scene: MenuScene!
    var gameMode = Settings.GAME_MODE_STAGE
    var gameVC: GameViewController?
    var tutorialVC: TutorialViewController?
    var modeVC: ModeViewController?
    var ballVC: BallsViewController?
    var longGesture = UILongPressGestureRecognizer()
    @IBOutlet weak var skView: SKView!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        view.backgroundColor = .white
        scene = MenuScene(size: view.bounds.size)
//        scene.position = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        scene.del = self
        skView.showsFPS = false
        skView.showsNodeCount = false
        scene.scaleMode = .fill
        skView.presentScene(scene)
        //unlock modes
        longGesture = UILongPressGestureRecognizer(target: self, action: #selector(StartViewController.unlockMode(_:)))
        longGesture.minimumPressDuration = 3
        //unlock all stages
        skView.addGestureRecognizer(longGesture)
        timerGameCenter()
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scene.isPaused = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scene.isPaused = false
    }

    func listenForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleSwitchTutorialForGame), name: Settings.PresentGameControllerNotification, object: nil)
    }
    @objc func unlockMode(_ sender: UILongPressGestureRecognizer) {
        unlockforfree()
    }
    @objc func handleSwitchTutorialForGame() {
        UserDefaults.standard.set(true, forKey: Settings.LAUNCHED_BEFORE_KEY)
        UserDefaults.standard.synchronize()
    
        dismissTutorial {
            self.launchGameViewController()
        }
    }
    
    func timerGameCenter(){
        let _ = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false, block: { _ in
            self.listenForNotifications()
            self.authenticateLocalPlayer()

        })
    }
    func unlockforfree(){
            let alert = UIAlertController(title: "Stage Balls",
                                      message: "Unlock all modes for free.",
                                      preferredStyle: .alert)
        
            let submitAction = UIAlertAction(title: "Submit", style: .default, handler: { (action) -> Void in
            let textField = alert.textFields![0]
            if textField.text! == "ART" {
                UserDefaults.standard.set(true, forKey: Settings.UNLOCK_FREE_MODES)
                let alert = UIAlertController(title: "Succesfully unlocked", message: "Have fun!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }else {
                let alert = UIAlertController(title: "Wrong password", message: "Try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        })
        
        alert.addTextField { (textField: UITextField) in
            textField.keyboardAppearance = .dark
            textField.keyboardType = .default
            textField.autocorrectionType = .default
            textField.placeholder = "Type in password"
            textField.clearButtonMode = .whileEditing
        }
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in })
        alert.addAction(submitAction)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func dismissTutorial(completion: @escaping () -> Void) {
        tutorialVC?.dismiss(animated: false, completion: completion)
    }

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
                    if error != nil { // print(error)
                    } else { self.gcDefaultLeaderBoard = leaderboardIdentifer! }
                })
                
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                // print("Local player could not be authenticated!")
                // print(error)
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
    
    
    @IBOutlet var scoreLabel: UILabel!
    
    
    var score = 51
    @IBOutlet var volume: UIButton!
    var tonANAUS = 0
    
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect

    func launchGameViewController() {
//        if let _ = UserDefaults.standard.object(forKey: Settings.LAUNCHED_BEFORE_KEY) as? Bool {
            gameVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "gameVC") as? GameViewController
            scene.isPaused = true
            present(gameVC!, animated: false, completion: nil)
//        } else {
//            tutorialVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "tutorialVC") as? TutorialViewController
//            scene.isPaused = true
//            present(tutorialVC!, animated: false){
//                self.skView.alpha = 0
//                self.scene.alpha = 0
//            }
//        }
    }
    
    @IBAction func volumeONOFF(_ sender: AnyObject) {
        tonANAUS = tonANAUS + 2
        if(tonANAUS == 2){
            volume.setBackgroundImage(UIImage(named: "Icon-2.png"), for: UIControlState())
        }else{
            tonANAUS = 0
            volume.setBackgroundImage(UIImage(named: "OFF.png"), for: UIControlState())
        }
    }
    
    // start scene delegate protocol methods
    
    func modePressed() {
        launchModeViewController()
    }
    
    func ballsPressed() {
        launchBallsViewController()
    }
    
    func launchGame() {
        launchGameViewController()
    }
    
    func launchModeViewController() {
        modeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "modeVC") as? ModeViewController
        present(modeVC!, animated: false, completion: nil)
    }
    
    func launchBallsViewController() {
        ballVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ballVC") as? BallsViewController
        present(ballVC!, animated: false, completion: nil)
    }
    
    func launchShop() {
        // launch the shop
    }
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
            let activityVC = UIActivityViewController(activityItems: ["Playing Stage Balls is awesome! Can you beat me? Get Stage Balls here https://itunes.apple.com/app/stage-balls/id1408563085"], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            self.present(activityVC, animated: true, completion: nil)
        
    }
    
    
    func gameCenterPressed() {
        
        listenForNotifications()
        authenticateLocalPlayer()
        
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        
        if gameMode == Settings.GAME_MODE_ENDLESS {
            gcVC.leaderboardIdentifier = self.LEADERBOARD_ID_ENDLESS
        }else if gameMode == Settings.GAME_MODE_MEMORY {
            gcVC.leaderboardIdentifier = self.LEADERBOARD_ID_MEMORY
        }else if gameMode == Settings.GAME_MODE_REVERSED {
            gcVC.leaderboardIdentifier = self.LEADERBOARD_ID_REVERSED
        }else {
            gcVC.leaderboardIdentifier = self.LEADERBOARD_ID
        }
        self.present(gcVC, animated: true, completion: nil)
    }

}
