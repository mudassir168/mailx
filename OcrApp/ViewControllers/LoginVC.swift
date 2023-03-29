//
//  LoginVC.swift
//  OcrApp
//
//  Created by JAGVEER on 02/11/21.
//

import UIKit
import Alamofire

class LoginVC: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailValidStatusLineView: UIView!
    
    lazy var validEmailId = false{
        didSet{
        
            if validEmailId{
                emailValidStatusLineView.backgroundColor = .green
            }else{
                emailValidStatusLineView.backgroundColor = .red
            }
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
           
            DispatchQueue.main.async {
                self.emailTextField.becomeFirstResponder()

            }
        }
        
    }
    
    @IBAction func loginAction(_ sender: Any) {
        
        passwordTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        if !NetworkReachabilityManager()!.isReachable {
        

            Alert.showInternetUnavailableAlert(viewController: self)
            return
        }
        guard let emailText =  emailTextField.text else {
            
            Alert.showAlertViewController(title: "Alert", message: "Please Check Email Field", viewController: self)

            return
        }
        guard let passwordText =  passwordTextField.text else {
            
            Alert.showAlertViewController(title: "Alert", message: "Please Check Password Field", viewController: self)

            return
        }
        UserDefaults.standard.setValue(emailText, forKey: LoginCreds.UserNameSavedKey)
        UserDefaults.standard.setValue(passwordText, forKey: LoginCreds.PasswordSavedKey)

        ApiCaller.sharedInstance.requestLoginCreds(emailText, passsord: passwordText) { (loggedObject) in
            
            if let statusSuccess = loggedObject?.success{
//                print(statusSuccess)

                if statusSuccess == 1{
                    debugPrint("Status success")
  
                    
                    guard let firstName =  loggedObject?.firstName else {
                        return
                    }

                    guard let lastName =  loggedObject?.lastName else {
                        return
                    }

                    guard let addressvalue =  loggedObject?.address else {
                        return
                    }

                    guard let locId =  loggedObject?.locid else {
                        return
                    }

                    
                    UserDefaults.standard.setValue(firstName, forKey: Defaults.UserFirstNameKey)
                    UserDefaults.standard.setValue(lastName, forKey: Defaults.UserLastNameKey)
                    UserDefaults.standard.setValue(addressvalue, forKey: Defaults.UserAddressKey)
                    UserDefaults.standard.setValue(locId, forKey: Defaults.UserLocIdNameKey)
                    

                    let storybd = UIStoryboard(name: "Main", bundle: nil)
                    if let vc = storybd.instantiateViewController(withIdentifier:
                                                                    "LogggedUserVC") as? LogggedUserVC{

                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                    

                }else{
                    
                    debugPrint("Status failed")
                    if let message = loggedObject?.message{
                        Alert.showAlertViewController(title: "Alert", message: message, viewController: self)

                    }
                }
                    
                

            }else{
                debugPrint("Status failed")

                if let message = loggedObject?.message{
                    Alert.showAlertViewController(title: "Alert", message: message, viewController: self)

                }
                
            }
            
        }
    }
    
    


}
extension LoginVC: UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if emailTextField == textField{

            if let text = textField.text,
                let textRange = Range(range, in: text) {
                let updatedText = text.replacingCharacters(in: textRange,
                                                            with: string)

                if updatedText.isValidEmail(){
                    self.validEmailId = true
                }else{
                    self.validEmailId = false
                }
             }
        }else{
            print("something more")
        }
        return true

    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if emailTextField == textField{
            passwordTextField.becomeFirstResponder()
        }else if passwordTextField == textField{
            passwordTextField.resignFirstResponder()
        }
        return true
        
    }
}
extension String {

    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}
