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

    var volume: Float = 1.0

    private init() {
        let popPath = Bundle.main.path(forResource: "pop.mp3", ofType: nil)!
        let popUrl = URL(fileURLWithPath: popPath)
        let clickPath = Bundle.main.path(forResource: "click.mp3", ofType: nil)!
        let clickUrl = URL(fileURLWithPath: clickPath)
        
        do {
            popPlayer = try AVAudioPlayer(contentsOf: popUrl)
            clickPlayer = try AVAudioPlayer(contentsOf: clickUrl)
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
    }
    
    func toggleVolume() {
        if (volume == 1.0) { volume = 0.0 }
        else { volume = 1.0 }

        setVolumes()
    }
    
    func playClickSound() {
        clickPlayer?.currentTime = 0
        clickPlayer?.play()
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
