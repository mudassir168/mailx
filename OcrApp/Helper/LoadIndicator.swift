//
//  LoadIndicator.swift
//  ConverterPro
//
//  Created by StrongPerry on 30/07/20.
//  Copyright © 2020 StrongPerry. All rights reserved.
//

import Foundation
import SVProgressHUD

public class LoadIndicator : NSObject{
    
    static var shared = LoadIndicator()
    func start()  {
        
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                SVProgressHUD.setContainerView(window)
            }
            SVProgressHUD.show()
        }
    }
    
    func startWithMessage(message:String)  {
        
        DispatchQueue.main.async(execute: {
            SVProgressHUD.show(withStatus: message)
        })

    }
    func startWithProgress(value:CGFloat)  {
        
        DispatchQueue.main.async(execute: {
            
            SVProgressHUD.showProgress(Float(value))
        })

    }
    func stop() {
        
        DispatchQueue.main.async(execute: {
            SVProgressHUD.dismiss()
        })
        
    }

}
