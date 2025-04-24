//
//  EnterEmailVC.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 06/04/2025.
//

import UIKit

class EnterEmailVC: UIViewController {
    
    //MARK: - IBOUTLETS
    
    @IBOutlet weak var emailTextField: UITextField!

    var isValidated: Bool {
        let email = emailTextField.text ?? ""
        var message: String?
        if email.isEmpty {
            message = "Please provide email"
        } else if !email.isValidEmail() {
            message = "Please provide valid email"
        }
        if message != nil {
            Alert.showAlertViewController(title: "Alert", message: message ?? "", viewController: self)
            return false
        }
        return true
    }
    
    //MARK: - CONTROLLER LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    //MARK: - PRIVATE FUNCTIONS
    private func openCheckYourMailVC() {
        let vc = self.storyboard?.instantiateViewController(identifier: CheckYourEmailVC.className) as! CheckYourEmailVC
        vc.email = emailTextField.text
        self.present(vc, animated: true)
    }
    
    // MARK: - IBACTIONS
    
    @IBAction func resetPasswordPressed(_ sender: UIButton) {
        guard isValidated else {return}
        openCheckYourMailVC()
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: false)
    }
}
