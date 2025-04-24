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
//    @IBOutlet weak var emailValidStatusLineView: UIView!
    @IBOutlet weak var youDoNotHaveAccountLabel: UILabel!
    
    lazy var validEmailId = false{
        didSet{
            emailTextField.setBorderColor(validEmailId ? .lightGray.withAlphaComponent(0.3) : .red)
        }
        
    }
    
    var isDataValid: Bool {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        var message: String?
        if email.isEmpty {
            message = "Please provide username/email"
        }
//        else if !email.isValidEmail() {
//            message = "Please provide valid email"
//        }
        else
        if password.isEmpty {
            message = "Please provide password"
        }
        if message != nil {
            Alert.showAlertViewController(title: "Alert", message: message ?? "", viewController: self)
            return false
        }
        return true
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
        initialSetup()
        
    }
    
    //MARK: - PRVIATE FUNCTIONS
    
    private func initialSetup() {
        let completeText = "If you do not have an account, please register here. Otherwise, login below."
        let clickableText = "register here"
        let attributedString = NSMutableAttributedString(string: completeText)
        if let range = completeText.range(of: clickableText) {
            let nsRange = NSRange(range, in: completeText)
            let attributes: [NSAttributedString.Key:Any] = [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: UIFont(name: "Inter-Bold", size: 15) ?? UIFont.boldSystemFont(ofSize: 15),
                .foregroundColor: UIColor.black
            ]
            attributedString.addAttributes(attributes, range: nsRange)
        }
        youDoNotHaveAccountLabel.attributedText = attributedString
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnLabel(_:)))
        youDoNotHaveAccountLabel.addGestureRecognizer(tapGesture)
        [emailTextField,passwordTextField].forEach { textField in
            textField?.setBorderColor(.lightGray.withAlphaComponent(0.3))
            textField?.setPlaceholderColor(.lightGray.withAlphaComponent(0.3))
        }
    }
    
    @objc func handleTapOnLabel(_ gesture: UITapGestureRecognizer) {
        guard let text = youDoNotHaveAccountLabel.attributedText?.string else { return }

        let clickableText = "register here"
        let nsText = NSString(string: text)
        let range = nsText.range(of: clickableText)

        if gesture.didTapAttributedTextInLabel(label: youDoNotHaveAccountLabel, inRange: range) {
            // Navigate to Register screen
            print("Tapped 'register here'")
            // navigationController?.pushViewController(RegisterViewController(), animated: true)
        }
    }
    
    //MARK: - IBACTIONS
    
    @IBAction func forgotPasswordPressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Signup", bundle: .main)
        let vc = storyboard.instantiateViewController(withIdentifier: EnterEmailVC.className) as! EnterEmailVC
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @IBAction func loginAction(_ sender: Any) {
        
        passwordTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        if !NetworkReachabilityManager()!.isReachable {
        

            Alert.showInternetUnavailableAlert(viewController: self)
            return
        }
        guard let emailText =  emailTextField.text, let passwordText =  passwordTextField.text else { return }
        guard isDataValid else {return}
        UserDefaults.standard.setValue(emailText, forKey: LoginCreds.UserNameSavedKey)
        UserDefaults.standard.setValue(passwordText, forKey: LoginCreds.PasswordSavedKey)
        LoadIndicator.shared.start()
        ApiCaller.sharedInstance.requestLoginCreds(emailText, passsord: passwordText) { (loggedObject) in
            LoadIndicator.shared.stop()
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

                if !updatedText.isEmpty{
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

extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        guard let attributedText = label.attributedText else { return false }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: attributedText)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )

        let location = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                               y: locationOfTouchInLabel.y - textContainerOffset.y)
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        return NSLocationInRange(characterIndex, targetRange)
    }
}
