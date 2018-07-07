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
        let popPath = Bundle.main.path(forResource: "pop.mp3", ofType: nil)!
        let popUrl = URL(fileURLWithPath: popPath)

        let clickPath = Bundle.main.path(forResource: "click.mp3", ofType: nil)!
        let clickUrl = URL(fileURLWithPath: clickPath)
        
        let nextStagePath = Bundle.main.path(forResource: "click.mp3", ofType: nil)!
        let nextStageUrl = URL(fileURLWithPath: nextStagePath)
        
        let gameOverPath = Bundle.main.path(forResource: "pop.mp3", ofType: nil)!
        let gameOverUrl = URL(fileURLWithPath: gameOverPath)
        
        do {
            popPlayer = try AVAudioPlayer(contentsOf: popUrl)
            clickPlayer = try AVAudioPlayer(contentsOf: clickUrl)
            nextStagePlayer = try AVAudioPlayer(contentsOf: nextStageUrl)
            gameOverPlayer = try AVAudioPlayer(contentsOf: gameOverUrl)
        } catch let err {
            print(err.localizedDescription)
        }
        
        if let volumeOn = UserDefaults.standard.object(forKey: Settings.VOLUME_ON_KEY) as? Bool {
            if volumeOn {
                volume = 1.0
            } else {
                volume = 0.0
            }
        }
    }
    
    func setVolumes() {
        popPlayer?.volume = volume
        clickPlayer?.volume = volume
        gameOverPlayer?.volume = volume
        nextStagePlayer?.volume = volume
    }
    
    func toggleVolume() {
        if (volume == 1.0) { volume = 0.0 }
        else { volume = 1.0 }
        
        if let volumeOn = UserDefaults.standard.object(forKey: Settings.VOLUME_ON_KEY) as? Bool {
            let newVolumeOn = !volumeOn
            UserDefaults.standard.set(newVolumeOn, forKey: Settings.VOLUME_ON_KEY)
            UserDefaults.standard.synchronize()
        } else {
            UserDefaults.standard.set(false, forKey: Settings.VOLUME_ON_KEY)
            UserDefaults.standard.synchronize()
        }

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
        let duration = 0.25
        var iterationCount = 0
        
        popPlayer?.play()
        
        Timer.scheduledTimer(withTimeInterval: duration, repeats: true, block: { timer in
            iterationCount += 1
            if (iterationCount == iterations) {
                self.popPlayer?.stop()
                timer.invalidate()
                self.popPlayer?.currentTime = 0
            }
        })
    }
}
