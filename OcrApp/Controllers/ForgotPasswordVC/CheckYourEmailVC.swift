//
//  CheckYourEmailVC.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 06/04/2025.
//

import UIKit

class CheckYourEmailVC: UIViewController {
    
    //MARK: - IBOUTLETS
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    
    var email: String?
    var counter = 120

    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {return}
            guard counter  > 0 else {
//                timer = nil
                resendButton.isUserInteractionEnabled = true
                return
            }
            counter -= 1
            counterLabel.text = "\(counter)"
        }
    }
    
    private func initialSetup() {
        emailLabel.text = email
    }
    
    
    
    // MARK: - Navigation
     
}
