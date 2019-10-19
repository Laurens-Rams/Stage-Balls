
import UIKit
import SpriteKit
import GameplayKit
import GameKit

class GameOverViewControllerNew: UIViewController, StartSceneDelegate, GKGameCenterControllerDelegate {
    var game: Game!
    var modeVC: ModeViewController?
    var ballVC: BallsViewController?
    var gameMode = Settings.GAME_MODE_STAGE
    var endingScore: Int = 0
    var endingStage: Int = 1
    var endingScoreEndless: Int = 0
    let LEADERBOARD_ID = "stageid"
    let LEADERBOARD_ID_MEMORY = "memoryid"
    let LEADERBOARD_ID_ENDLESS = "endlessid"
    let LEADERBOARD_ID_REVERSED = "reversedmodeid"
    let LEADERBOARD_ID_INVISIBLE = "invisibleGameCenterid"

    @IBOutlet var RemainingBalls: UILabel!
    @IBOutlet var stageLabel: UILabel!
    @IBOutlet var showpoints: UILabel!
    @IBOutlet weak var lastStageButton: UIButton!
    @IBOutlet weak var nextStageButton: UIButton!
    @IBOutlet weak var StageOverLabel: UILabel!
    
    var scene: GameOverScene!

    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        if Settings.isIphoneX {
            stageLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            RemainingBalls.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        }
        AnimateStageOverLabel()
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
        setRemainingBalls()
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scene.isPaused = false
        checkMode()
        setStageOverLabel()
        checkIfStageIsValidForMode()
        submitGameCenter()
        setStageLabel()
        showHideStageButtons()
        // when thie view controller appears on screen, we should check if we're in a valid game mode:
        getProductData() { modeIsPurchased in
            if !modeIsPurchased {
                self.checkIfModeIsValid()
            }
        }
    }
  
    override func viewWillDisappear(_ animated: Bool) {
        scene.isPaused = true
    }

    func checkIfStageIsValidForMode() {
        var keyForHighestStage: String? = nil

        // decide if we should use a different key to check the current stage in user defaults
        if gameMode == Settings.GAME_MODE_MEMORY {
            keyForHighestStage = Settings.HIGHEST_STAGE_KEY_MEMORY
        } else if gameMode == Settings.GAME_MODE_INVISIBLE {
            keyForHighestStage = Settings.HIGHEST_STAGE_KEY_INVISIBLE
        } else if gameMode == Settings.GAME_MODE_STAGE {
            keyForHighestStage = Settings.HIGHEST_STAGE_KEY
        }
      
        if let keyForHighestStage = keyForHighestStage {
            let highestStage = defaults.integer(forKey: keyForHighestStage)
            if (game.stage > highestStage) {
              game.setStage(toStage: highestStage)
            }
        }
    }

    func AnimateStageOverLabel(){
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.StageOverLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        }, completion: nil)
    }
    

    
    func checkIfModeIsValid() {
        let freeunlocked = UserDefaults.standard.bool(forKey: Settings.UNLOCK_FREE_MODES)
        if Settings.DEV_MODE  || freeunlocked {
            return
        }

        if let mode = GameMode.modeForDefaultsKey(id: gameMode) {
            if let triesLeft = Settings.getTriesLeftForMode(mode: mode) {
                if triesLeft <= 0 {
                    // if we've gotten down to zero tries left, show the mode selection view controller
                    launchModeViewController()
                }
            }
        }
    }
  
    func getProductData(completion: @escaping (Bool) -> Void) {
        StageBallsProducts.store.requestProducts() { success, products in
            if let mode = GameMode.modeForDefaultsKey(id: self.gameMode) {
                if let productId = mode.productId() {
                    completion(StageBallsProducts.store.isProductPurchased(productId))
                    return
                }
            }
            completion(true)
        }
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: false, completion: nil)
    }

    func checkMode(){
        if let savedMode = defaults.object(forKey: Settings.GAME_MODE_KEY) as? String {
            gameMode = savedMode
        }
    }

    func setRemainingBalls(){
        // Balls for Memory and Stage Mode same
        RemainingBalls.text = "BALLS \(scoreFormatter(score: endingScore))"

        if gameMode == Settings.GAME_MODE_ENDLESS || gameMode == Settings.GAME_MODE_REVERSED {
            RemainingBalls.alpha = 0.0
        }
    }

    func setStageOverLabel(){
        if gameMode == Settings.GAME_MODE_ENDLESS || gameMode == Settings.GAME_MODE_REVERSED {
            StageOverLabel.text = "Game Over"
        }else{
             StageOverLabel.text = "Stage Over"
        }
        
    }
    
    func submitGameCenter(){
        //EMILY?
        let freeunlockedStages = UserDefaults.standard.bool(forKey: Settings.UNLOCK_FREE_MODES)
        if freeunlockedStages{
            print("not submitted to GameCenter")
        }else {
        if gameMode == Settings.GAME_MODE_ENDLESS {
            //GC
            if let scoreGameCenterEndless = defaults.object(forKey: Settings.HIGH_SCORE_KEY_ENDLESS) as? Int64 {
                let bestScoreIntEndless = GKScore(leaderboardIdentifier: LEADERBOARD_ID_ENDLESS)
                bestScoreIntEndless.value = scoreGameCenterEndless
                GKScore.report([bestScoreIntEndless]) { (error) in
                    if error != nil {
                        print(error!.localizedDescription)
                    } else {
                        print("Best Score Memory submitted to your Leaderboard!")
                    }
                }
            } else {
              
            }
        } else if gameMode == Settings.GAME_MODE_REVERSED {
            //GC
            if let scoreGameCenterRev = defaults.object(forKey: Settings.HIGH_SCORE_KEY_REVERSED) as? Int64 {
                let bestScoreIntRev = GKScore(leaderboardIdentifier: LEADERBOARD_ID_REVERSED)
                bestScoreIntRev.value = scoreGameCenterRev
                GKScore.report([bestScoreIntRev]) { (error) in
                    if error != nil {
                        print(error!.localizedDescription)
                    } else {
                        print("Best Score Memory submitted to your Leaderboard!")
                    }
                }
            } else {
            
            }
        } else if gameMode == Settings.GAME_MODE_MEMORY {
            //GC
            if let scoreGameCenterMemory = defaults.object(forKey: Settings.HIGH_SCORE_KEY_MEMORY) as? Int64 {
                let bestScoreIntMemory = GKScore(leaderboardIdentifier: LEADERBOARD_ID_MEMORY)
                bestScoreIntMemory.value = scoreGameCenterMemory
                GKScore.report([bestScoreIntMemory]) { (error) in
                    if error != nil {
                        print(error!.localizedDescription)
                    } else {
                        print("Best Score Memory submitted to your Leaderboard!")
                    }
                }
            } else {
            
            }
        } else if gameMode == Settings.GAME_MODE_INVISIBLE {
            //GC
            if let scoreGameCenterInvisible = defaults.object(forKey: Settings.HIGH_SCORE_KEY_INVISIBLE) as? Int64 {
                let bestScoreIntInvisible = GKScore(leaderboardIdentifier: LEADERBOARD_ID_INVISIBLE)
                bestScoreIntInvisible.value = scoreGameCenterInvisible
                GKScore.report([bestScoreIntInvisible]) { (error) in
                    if error != nil {
                        print(error!.localizedDescription)
                    } else {
                        print("Best Score Invisible submitted to your Leaderboard!")
                    }
                }
            } else {
            
            }
        } else if gameMode == Settings.GAME_MODE_STAGE {
            if let scoreGameCenter = defaults.object(forKey: Settings.HIGH_SCORE_KEY) as? Int64 {
                let bestScoreInt = GKScore(leaderboardIdentifier: LEADERBOARD_ID)
                bestScoreInt.value = scoreGameCenter
                GKScore.report([bestScoreInt]) { (error) in
                    if error != nil {
                        print(error!.localizedDescription)
                    } else {
                        print("Best Score Stage submitted to your Leaderboard!")
                    }
                }
            } else {
            
            }
        }
    }
        
    }

    func setStageLabel() {
        if gameMode == Settings.GAME_MODE_ENDLESS {
            if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY_ENDLESS) as? Int {
                stageLabel.text = stageFormatterEndless(scorehigh: highScore)
            }
        } else if gameMode == Settings.GAME_MODE_REVERSED {
            if let highScore = defaults.object(forKey: Settings.HIGH_SCORE_KEY_REVERSED) as? Int {
                stageLabel.text = stageFormatterEndless(scorehigh: highScore)
            }
        } else if gameMode == Settings.GAME_MODE_MEMORY {
            if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY_MEMORY) as? Int {
                stageLabel.text = stageFormatter(stage: currentStage)
            } else {
                stageLabel.text = stageFormatter(stage: endingStage)
            }
        } else if gameMode == Settings.GAME_MODE_INVISIBLE {
            if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY_INVISIBLE) as? Int {
                stageLabel.text = stageFormatter(stage: currentStage)
            } else {
                stageLabel.text = stageFormatter(stage: endingStage)
            }
        }else {
            if let currentStage = defaults.object(forKey: Settings.CURRENT_STAGE_KEY) as? Int {
                stageLabel.text = stageFormatter(stage: currentStage)
            } else {
                stageLabel.text = stageFormatter(stage: endingStage)
            }
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

        if gameMode == Settings.GAME_MODE_ENDLESS || gameMode == Settings.GAME_MODE_REVERSED  {
            nextStageButton.alpha = 0
            lastStageButton.alpha = 0
        } else {
            var keyForCurrentStage = Settings.CURRENT_STAGE_KEY
            var keyForHighestStage: String? = nil
          
            if let mode = GameMode.modeForDefaultsKey(id: gameMode) {
                keyForCurrentStage = mode.currentStageKey()
                keyForHighestStage = mode.highestStageKey()
            }

            if keyForHighestStage != nil {
                let highestStage = defaults.integer(forKey: keyForHighestStage!)
                let currentStage = defaults.integer(forKey: keyForCurrentStage)
                if currentStage >= highestStage {
                    nextStageButton.alpha = 0
                    nextStageButton.isUserInteractionEnabled = false
                    stageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
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
            }
        }
    }
    
    @IBAction func goToNextStage(_ sender: Any) {
        var keyForSavedCurrentStage: String? = nil

        // decide if we should use a different key to check the current stage in user defaults
        if gameMode == Settings.GAME_MODE_MEMORY {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_MEMORY
        } else if gameMode == Settings.GAME_MODE_INVISIBLE {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_INVISIBLE
        } else if gameMode == Settings.GAME_MODE_STAGE {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY
        }

        if keyForSavedCurrentStage != nil, let currentStage = defaults.object(forKey: keyForSavedCurrentStage!) as? Int {
            let nextStage = currentStage + 1
            defaults.set(nextStage, forKey: keyForSavedCurrentStage!)
            defaults.synchronize()
        } else {
            defaults.set(game.stage + 1, forKey: keyForSavedCurrentStage!)
        }
        showHideStageButtons()
        setStageLabel()
    }
    
    @IBAction func goToLastStage(_ sender: Any) {
        var keyForSavedCurrentStage: String? = nil

        // decide if we should use a different key to check the current stage in user defaults
        if gameMode == Settings.GAME_MODE_MEMORY {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_MEMORY
        } else if gameMode == Settings.GAME_MODE_INVISIBLE {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY_INVISIBLE
        } else if gameMode == Settings.GAME_MODE_STAGE {
            keyForSavedCurrentStage = Settings.CURRENT_STAGE_KEY
        }

        if keyForSavedCurrentStage != nil, let currentStage = defaults.object(forKey: keyForSavedCurrentStage!) as? Int {
            let lastStage = currentStage - 1
            defaults.set(lastStage, forKey: keyForSavedCurrentStage!)
            defaults.synchronize()
        }
        showHideStageButtons()
        setStageLabel()
    }

    func layoutUI() {
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
    func stageFormatterEndless(scorehigh: Int) -> String {
        return "HIGH SCORE: \(scorehigh)"
    }
    
    @IBOutlet var scoreLabel: UILabel!
    
    // MARK: StartSceneDelegate protocol methods
    func launchGame() {}

    func launchShop() {}

    func ratePressed() {
        rateApp(appId: "1408563085") { success in
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
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        
        if gameMode == Settings.GAME_MODE_ENDLESS {
            gcVC.leaderboardIdentifier = self.LEADERBOARD_ID_ENDLESS
        }else if gameMode == Settings.GAME_MODE_MEMORY {
            gcVC.leaderboardIdentifier = self.LEADERBOARD_ID_MEMORY
        }else if gameMode == Settings.GAME_MODE_REVERSED {
            gcVC.leaderboardIdentifier = self.LEADERBOARD_ID_REVERSED
        }else if gameMode == Settings.GAME_MODE_INVISIBLE {
            gcVC.leaderboardIdentifier = self.LEADERBOARD_ID_INVISIBLE
        }else {
            gcVC.leaderboardIdentifier = self.LEADERBOARD_ID
        }
        self.present(gcVC, animated: true, completion: nil)
    }
  
  

}




