//
//  AppDelegate.swift
//  OcrApp
//
//  Created by JAGVEER on 01/11/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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

