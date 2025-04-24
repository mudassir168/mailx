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
    
    static func showAlertWithTextView(title: String, message: String, isMatched: Bool, in viewController: UIViewController, delegate: TextUpdateDelegate?) {
        // Create UIAlertController with a text view
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        // Add the UITextView to the alert controller's view
        let textView = UITextView(frame: CGRect(x: 10, y: 50, width: 250, height: viewController.view.frame.height * 0.20))
        textView.text = message // Set initial text
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 5.0
        textView.keyboardType
        alertController.view.addSubview(textView)
        
        let originalHeight = alertController.view.frame.height
            var newFrame = alertController.view.frame
            newFrame.size.height = originalHeight + 100 // Add space to the alert view to accommodate the text view
            alertController.view.frame = newFrame
        
        var height:NSLayoutConstraint = NSLayoutConstraint(
                item: alertController.view!, attribute: NSLayoutConstraint.Attribute.height,
                relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil,
                attribute: NSLayoutConstraint.Attribute.notAnAttribute,
                multiplier: 1, constant: viewController.view.frame.height * 0.35)
            alertController.view.addConstraint(height)
        
        // Add a "Save" action
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            // Get the updated text
            let updatedText = textView.text ?? ""
            
            // Pass the updated text to the delegate (or closure)
            delegate?.didUpdateText(updatedText: updatedText, isMatched: isMatched)
        }
        alertController.addAction(saveAction)
        
        // Add a "Cancel" action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Present the alert
        viewController.present(alertController, animated: true, completion: nil)
    }
    
}

