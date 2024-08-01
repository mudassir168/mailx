//
//  AppDelegate.swift
//  OcrApp
//
//  Created by JAGVEER on 01/11/21.
//

import UIKit
import Sentry


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SentrySDK.start { options in
            options.dsn = "https://48005a93a236f1e3e23f0e0f80a538bb@o4507419638824960.ingest.us.sentry.io/4507702607478784"
            options.debug = false // Enabled debug when first installing is always helpful
//            options.enableTracing = true 
            options.tracesSampleRate = 1.0

            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // This adds a screenshot to the error events
            // options.attachViewHierarchy = true // This adds the view hierarchy to the error events
        }
        // Remove the next line after confirming that your Sentry integration is working.
//        SentrySDK.capture(message: "This app uses Sentry! :)")

        // Override point for customization after application launch.
        
        
        if let _ = UserDefaults.standard.value(forKey: Defaults.UserFirstNameKey){

            userLoggedInRoot()
            
        }else{
            
            userNotLoggedInRoot()

        }
        return true
    }



    func userLoggedInRoot(){
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let storyBd = UIStoryboard(name: "Main", bundle: nil)

        guard let rootVC = storyBd.instantiateViewController(withIdentifier: "LogggedUserVC") as? LogggedUserVC else {
            print("Root VC not found")
            return
        }
        let rootNC = UINavigationController(rootViewController: rootVC)
        rootNC.isNavigationBarHidden = true
        window?.rootViewController = rootNC
        window?.makeKeyAndVisible()
    }
    
    func userNotLoggedInRoot(){
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let storyBd = UIStoryboard(name: "Main", bundle: nil)

        guard let rootVC = storyBd.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC else {
            print("Root VC not found")
            return
        }
        let rootNC = UINavigationController(rootViewController: rootVC)
        rootNC.isNavigationBarHidden = true
        window?.rootViewController = rootNC
        window?.makeKeyAndVisible()
    }
}

