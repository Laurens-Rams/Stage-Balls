//
//  AppDelegate.swift
//  ColorBall
//
//  Created by Emily Kolar on 6/18/17.
//  Copyright © 2017 Laurens-Art Ramsenthaler. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleMobileAds
import AVFoundation
import Mixpanel

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        GADMobileAds.configure(withApplicationID: "ca-app-pub-8530735287041699~2180707337")
        FirebaseApp.configure()
        setupAudio()

        Mixpanel.initialize(token: "f0dba7d0cae51844515005b108706b06")

        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { authResult, error in
                Metadata.shared.setUser(user: authResult?.user)
            }
        } else {
            Metadata.shared.setUser(user: Auth.auth().currentUser)
        }
    
        print("app started!")
        // Override point for customization after application launch.
        return true
    }
    
    func setupAudio() {
        let sess = AVAudioSession.sharedInstance()
        do {
            try sess.setCategory(AVAudioSessionCategoryAmbient)
            try sess.setActive(true)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        teardown()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        teardown()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        setup()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        setup()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        teardown()
    }
    
    // MARK: app startup and app shutdown methods
    
    func setup() {
        PresentManager.main.start()
    }
    
    func teardown() {
        PresentManager.main.pause()
    }
    
}

