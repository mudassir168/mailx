//
//  Alert.swift
//  OcrApp
//
//  Created by JAGVEER on 04/11/21.
//

import Foundation
import  UIKit

@objcMembers class Alert: NSObject {

    static func showInternetUnavailableAlert(viewController: UIViewController){
        let alert = UIAlertController(title: "Internet Unavailable", message: "Please check internet connection", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil));
        viewController.present(alert, animated: true, completion: nil);
    }
    
    //===========================================================================================
    static func showAlertViewController(title: String, message: String, viewController: UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil));
        viewController.present(alert, animated: true, completion: nil);
    }

    static func showAlertViewController(title: String, message: String, buttonTitle: String, viewController: UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .cancel, handler: nil));
        viewController.present(alert, animated: true, completion: nil);
    }

    static func showAlertViewController(title: String, message: String, btnTitle1: String, btnTitle2: String, ok handler: ((UIAlertAction) -> Void)?,cancel handler1: ((UIAlertAction) -> Void)?, viewController: UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: btnTitle1, style: .cancel, handler: handler1));
        var action2: UIAlertAction!
        if btnTitle2 == "Delete"{
            action2 = UIAlertAction(title: btnTitle2, style: .destructive, handler: handler)
        }else{
            action2 = UIAlertAction(title: btnTitle2, style: .default, handler: handler)
        }
        alert.addAction(action2);
        viewController.present(alert, animated: true, completion: nil);
    }
    
    static func showAlertViewController(title: String, message: String, btnTitle1: String, ok handler: ((UIAlertAction) -> Void)?, viewController: UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: btnTitle1, style: .cancel, handler: handler));
        viewController.present(alert, animated: true, completion: nil);
    }
    static func showAlertViewControllerHandlers(title: String, message: String, btnTitle1: String, btnTitle2: String,handler1: ((UIAlertAction) -> Void)?, handler2: ((UIAlertAction) -> Void)?,  viewController: UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var action2: UIAlertAction!
        action2 = UIAlertAction(title: btnTitle2, style: .default, handler: handler2)
        alert.addAction(action2);
        alert.addAction(UIAlertAction(title: btnTitle1, style: .default, handler: handler1));
        viewController.present(alert, animated: true, completion: nil);
    }
    
}

