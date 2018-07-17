//
//  AudioManager.swift
//  ColorBall
//
//  Created by Emily Kolar on 7/6/18.
//  Copyright © 2018 Emily Kolar. All rights reserved.
//

import Foundation
import AVFoundation

class AudioManager {
    static let only = AudioManager()
    
    private var popPlayer: AVAudioPlayer?
    private var clickPlayer: AVAudioPlayer?
    private var nextStagePlayer: AVAudioPlayer?
    private var gameOverPlayer: AVAudioPlayer?

    var volume: Float = 1.0

    private init() {
        let popPath = Bundle.main.path(forResource: "pop1.mp3", ofType: nil)!
        let popUrl = URL(fileURLWithPath: popPath)

        let clickPath = Bundle.main.path(forResource: "click.mp3", ofType: nil)!
        let clickUrl = URL(fileURLWithPath: clickPath)
        
        let nextStagePath = Bundle.main.path(forResource: "click.mp3", ofType: nil)!
        let nextStageUrl = URL(fileURLWithPath: nextStagePath)
        
        let gameOverPath = Bundle.main.path(forResource: "lose.mp3", ofType: nil)!
        let gameOverUrl = URL(fileURLWithPath: gameOverPath)
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            popPlayer = try AVAudioPlayer(contentsOf: popUrl)
            clickPlayer = try AVAudioPlayer(contentsOf: clickUrl)
            nextStagePlayer = try AVAudioPlayer(contentsOf: nextStageUrl)
            gameOverPlayer = try AVAudioPlayer(contentsOf: gameOverUrl)
        } catch let err {
            // print(err.localizedDescription)
        }
        
        if let volumeOn = UserDefaults.standard.object(forKey: Settings.VOLUME_ON_KEY) as? Bool {
            if volumeOn {
                volume = 1.0
            } else {
                volume = 0.0
            }
        } else {
            UserDefaults.standard.set(true, forKey: Settings.VOLUME_ON_KEY)
            UserDefaults.standard.synchronize()
        }
        
        setVolumes()
    }
    
    func setVolumes() {
        popPlayer?.volume = volume
        clickPlayer?.volume = volume
        gameOverPlayer?.volume = volume
        nextStagePlayer?.volume = volume
    }
    
    func toggleVolume() {
        print("toggling volume")
        if (volume == 1.0) { volume = 0.0 }
        else { volume = 1.0 }
        
        if volume == 1.0 {
            UserDefaults.standard.set(true, forKey: Settings.VOLUME_ON_KEY)
        } else {
            UserDefaults.standard.set(false, forKey: Settings.VOLUME_ON_KEY)
        }

        UserDefaults.standard.synchronize()

        setVolumes()
    }
    
    func playClickSound() {
        clickPlayer?.currentTime = 0
        clickPlayer?.play()
    }
    
    func playGameOverSOund() {
        gameOverPlayer?.currentTime = 0
        gameOverPlayer?.play()
    }
    
    func playNextStageSound() {
        nextStagePlayer?.currentTime = 0
        nextStagePlayer?.play()
    }
    
    func playZapSound(iterations: Int) {
        // playing the audio on a background thread seems to smooth things out quite a bit
        // however, we loose access to the popPlayer methods when we move it into the background
        // this means we can't count iterations and then call popPlayer.stop()-- the stop() call won't have any effect
        // thus, instead, we have different sound files for the different numbers of pops
        DispatchQueue.global().async {
            self.popPlayer?.currentTime = 0
            self.popPlayer?.play()
        }
    }
}
