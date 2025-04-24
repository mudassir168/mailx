//
//  ViewController.swift
//  OcrApp
//
//  Created by JAGVEER on 01/11/21.
//

import UIKit
import Vision
import TOCropViewController
import AVFoundation

class LogggedUserVC: UIViewController {

    @IBOutlet var textViewText: UITextView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var scanningLabel: UILabel!
    @IBOutlet weak var scanEnvelButton: UIButton!
    @IBOutlet weak var scanBoxButton: UIButton!
    @IBOutlet weak var scanImageView: UIImageView!
    @IBOutlet weak var recipentBtn: UIButton!
    @IBOutlet weak var roundView: UIView!
    @IBOutlet weak var shadedView: UIView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var cityStateZipLabel: UILabel!
    
    
    var isBox : Int = 0
    
    var isHandwritten : Int = 0
    var storeImage : UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        // ToolBar
        let toolBar = UIToolbar()
        // Optional styling
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = .black
        toolBar.layer.borderWidth = 0
        
        toolBar.sizeToFit()
        
        // Buttons
        let buttonOne = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneAction))
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([ spacer,buttonOne], animated: false)
        toolBar.isUserInteractionEnabled = true
        textViewText.inputAccessoryView = toolBar
        initialUiSetup()
    }
    
    func initialUiSetup() {
        shadedView.applyShadow()
        roundView.applyCornerRound(with: 12)
        [scanBoxButton,logoutButton].forEach { button in
            button?.applyShadow()
            button?.applyCornerRound(with: 8)
            
        }
    }
    
    @objc func doneAction(){
        
        textViewText.resignFirstResponder()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let usrName = UserDefaults.standard.value(forKey: Defaults.UserFirstNameKey){
            nameLabel.text = "Welcome \(usrName)"
        }
        if let address = UserDefaults.standard.value(forKey: Defaults.UserAddressKey){
            let (street,city,state,zip)  = extractStreetCityStateZip(from: address as? String ?? "")
            streetLabel.text = street ?? ""
            cityStateZipLabel.text = "\(city ?? ""), \(state ?? "") \(zip ?? "")"
        }
        
    }
    
    func showSuccessPopup() {
        let vc = MailUploadedVC(nibName: MailUploadedVC.className, bundle: .main)
        addChild(vc)
        view.addSubview(vc.view)
        
    }
    
    func openCam(isb : Int = 0){
        
//        let imagePicker =  UIImagePickerController()
//         imagePicker.delegate = self
// //        imagePicker.sourceType = .photoLibrary
//         imagePicker.sourceType = .camera
//         imagePicker.allowsEditing = false
//         imagePicker.modalPresentationStyle = .fullScreen
//         self.isBox = isb
//        self.present(imagePicker, animated: true) { [weak self] in
//        }
        
        if let vc = self.storyboard?.instantiateViewController(identifier: "CameraViewController") as? CameraViewController {
            vc.modalPresentationStyle = .fullScreen
            if let address = UserDefaults.standard.value(forKey: Defaults.UserAddressKey) as? String {
                let addressComponents = extractAddressComponents(from: address)
                vc.searchingString = "\(addressComponents.street ?? ""),\(addressComponents.postal ?? "")"//1825 NW CORPORATE BLVD STE 110"
            }
            vc.imageAndTextReceived = { [weak self] (image,text) in
                vc.dismiss(animated: false)
                guard text != nil, text != "" else {return}
                self?.textViewText.text = text
                self?.storeImage = image
                self?.onlyUploadImageWhenHavingAllData()
            }
            vc.imageAndNotMatchTextReceived = { [weak self] (image,groupsArray) in
                vc.dismiss(animated: false)
                guard groupsArray.count > 0 && image != nil else {return}
                self?.storeImage = image
                self?.UploadImageAndNonMatchedData(image: image!, textGroups: groupsArray)
            }
            self.present(vc, animated: true)
        }
    }
    
    
    func extractAddressComponents(from text: String) -> (street: String?, postal: String?) {
        let addressRegex = #"(\d{1,5}\s[\w\s]+(?:Street|St|Avenue|Ave|Boulevard|Blvd|Road|Rd|Way|Lane|Ln|Drive|Dr|Court|Ct|Square|Sq|Trail|Trl|Parkway|Pkwy|Circle|Cir|Suite|Ste)?(?:\s\d{1,5})?)"#
        let postalRegex = #"(?:[A-Z]{2})\s\d{5}(-\d{4})?"#

        let textRange = NSRange(location: 0, length: text.utf16.count)

        let addressMatch = try? NSRegularExpression(pattern: addressRegex).firstMatch(in: text, range: textRange)
        let postalMatch = try? NSRegularExpression(pattern: postalRegex).firstMatch(in: text, range: textRange)

        let street = addressMatch.flatMap { Range($0.range, in: text).map { String(text[$0]) } }
        let postal = postalMatch.flatMap { Range($0.range, in: text).map { String(text[$0]) } }

        return (street, postal)
    }
    
    func extractStreetCityStateZip(from text: String) -> (street: String?, city: String?, state: String?, zip: String?) {
        let addressRegex = #"(\d{1,5}\s[\w\s]+(?:Street|St|Avenue|Ave|Boulevard|Blvd|Road|Rd|Way|Lane|Ln|Drive|Dr|Court|Ct|Square|Sq|Trail|Trl|Parkway|Pkwy|Circle|Cir))"#
        let cityRegex = #"(?:,\s)?([A-Za-z\s]+?),\s[A-Z]{2}\s\d{5}(?:-\d{4})?"#
        let stateZipRegex = #"([A-Z]{2})\s(\d{5}(?:-\d{4})?)"#

        let textRange = NSRange(location: 0, length: text.utf16.count)

        let streetMatch = try? NSRegularExpression(pattern: addressRegex).firstMatch(in: text, range: textRange)
        let cityMatch = try? NSRegularExpression(pattern: cityRegex).firstMatch(in: text, range: textRange)
        let stateZipMatch = try? NSRegularExpression(pattern: stateZipRegex).firstMatch(in: text, range: textRange)

        let street = streetMatch.flatMap { Range($0.range, in: text).map { String(text[$0]) } }
        let city = cityMatch.flatMap { $0.range(at: 1).location != NSNotFound ? Range($0.range(at: 1), in: text).map { String(text[$0]) } : nil }
        let state = stateZipMatch.flatMap { $0.range(at: 1).location != NSNotFound ? Range($0.range(at: 1), in: text).map { String(text[$0]) } : nil }
        let zip = stateZipMatch.flatMap { $0.range(at: 2).location != NSNotFound ? Range($0.range(at: 2), in: text).map { String(text[$0]) } : nil }

        return (street, city, state, zip)
    }

    
    func getStreetAddress(address: String) -> String? {
        let addressArray = address.components(separatedBy: ",")
        if addressArray.count > 0 {
            return addressArray[0]
        } else {return nil}
    }
    
    @IBAction func scanAction(_ sender: UIButton) {
//        DispatchQueue.main.async {
//            Alert.showAlertViewControllerHandlers(
//                title: "Message", message: "Is this a handwritten envelope?", btnTitle1: "No", btnTitle2: "Yes", handler1: { (action) in
                    self.isHandwritten = 0
                    self.openCam(isb: 0)
//                }, handler2: { (action) in
//                    self.isHandwritten = 1
//                    self.openCam(isb: 0)
//                }, viewController:  self)
//        }
    }
    
    
    @IBAction func scanBoxAction(_ sender: UIButton) {
    
      //  DispatchQueue.main.async {
//            Alert.showAlertViewControllerHandlers(
//                title: "Message", message: "Is this information handwritten?", btnTitle1: "No", btnTitle2: "Yes", handler1: { (action) in
                    self.isHandwritten = 0
                    self.openCam(isb: 1)
//                }, handler2: { (action) in
//                    self.isHandwritten = 1
//                    self.openCam(isb: 1)
//                }, viewController: self)
     //   }
        
    }
    
    
    @IBAction func scanRecipientAction(_ sender: Any) {
        guard let scannedImage = scanImageView.image else {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Alert.showAlertViewController(title: "Message", message: "No Image to Scan Recipient", viewController: self)
            }
            return
        }
    
        let cropController = TOCropViewController(croppingStyle: .default, image: scannedImage)
        cropController.delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.present(cropController, animated: false, completion: nil)
        }
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        
//        let imageUrl = Bundle.main.url(forResource: "imageSample", withExtension: "png")
//        if let image1 = UIImage(contentsOfFile: imageUrl!.path){

        
//
//            ApiCaller.sharedInstance.uploadImageWhenOcrComplete(imageToUpload: image1) { (objImage) in
//                debugPrint(objImage?.message)
//
//                if let validObj  = objImage,let resultSuccess = validObj.success{
//
//                    if resultSuccess == 1{
//
//                        ApiCaller.sharedInstance.uploadTextWhenOcrComplete(imageToUpload: image1) { (obj) in
//
//                            if let validObj  = obj,let messageValid = validObj.message{
//                                debugPrint("message is",messageValid)
//                                debugPrint("success is",validObj.success)
//
//                            }
//
//
//                        }
//
//                    }
//                }
//
//
//
//
//            }

            
//        }
        
            
        Alert.showAlertViewController(title: "Logout", message: "Are you sure you want to logout session ?", btnTitle1: "Yes Logout", btnTitle2: "Dismiss", ok: { (action) in
//            debugPrint("cancel ")

        }, cancel: { (action) in
//            debugPrint("Logout ")

            UserDefaults.standard.setValue(nil, forKey: Defaults.UserFirstNameKey)
            UserDefaults.standard.setValue(nil, forKey: Defaults.UserLastNameKey)
            UserDefaults.standard.setValue(nil, forKey: Defaults.UserAddressKey)
            UserDefaults.standard.setValue(nil, forKey: Defaults.UserLocIdNameKey)

            UserDefaults.standard.setValue(nil, forKey: LoginCreds.UserNameSavedKey)
            UserDefaults.standard.setValue(nil, forKey: LoginCreds.PasswordSavedKey)

            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.userNotLoggedInRoot()
            
        }, viewController: self)
        


    }
    @IBAction func uploadSeprateAction(_ sender: Any) {
        
        guard self.storeImage != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                
                Alert.showAlertViewController(title: "Message", message: "Scan Image again", viewController: self)
            }
            return
        }
        if !self.textViewText.text.isEmpty{
            
            onlyUploadImageWhenHavingAllData()
            
            
            
        }else{
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                
                Alert.showAlertViewController(title: "Message", message: "Image does not Contains any text.Try again", viewController: self)
            }
            
        }
        
    }
    
}
extension LogggedUserVC: UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        debugPrint(String(self.isHandwritten) + " ++++++ ----- ++++++")
        
        if let pickedImage = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.originalImage.rawValue)] as? UIImage {
            
            self.scanImageView.image = pickedImage
            self.storeImage = pickedImage
            self.recipentBtn.isEnabled = true
            recipentBtn.sendActions(for: .touchUpInside)
//            self.recognizeTextInImage(image: pickedImage)


//            let cropController = TOCropViewController(croppingStyle: .default, image: pickedImage)
//            cropController.delegate = self
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                self.present(cropController, animated: false, completion: nil)
//            }

        }
        picker.dismiss(animated: false, completion: nil)

    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
      


    }
    func generateCurrentTimeStamp () -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_hh_mm_ss"
        return (formatter.string(from: Date()) as NSString) as String
    }

    func recognizeTextInImage(image: UIImage?){
        
        var stringAppend =  ""
        guard let cgImage = image?.cgImage else{ return }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else{
                print(error!.localizedDescription)
                return
            }
            
            let text = observations.compactMap({
                $0.topCandidates(1).first?.string
            }).joined(separator: " ")
            print("Results: - \(text)")
            
            for observation in observations {
                guard let bestCandidate = observation.topCandidates(1).first else {
                    print("No candidate")
                    continue
                }
                stringAppend.append(bestCandidate.string)
                stringAppend.append("\n")

                print("Found this candidate: \(bestCandidate.string)")
            }
            
            if !text.isEmpty{
                
//                self.textViewText.text = text
                self.textViewText.text = stringAppend
                self.onlyUploadImageWhenHavingAllData()// uncomment when push API
                
                
            }else{
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    
                    Alert.showAlertViewController(title: "Message", message: "Image does not Contains any text.Try again", viewController: self)
                }
                
            }
            
            
        }
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error:- \(error)")
        }
        
    }
    func onlyUploadImageWhenHavingAllData(){
        let timeStamp = self.generateCurrentTimeStamp()
        
        LoadIndicator.shared.startWithMessage(message: "Uploading Photo")
        ApiCaller.sharedInstance.uploadImageWhenOcrComplete(imageToUpload: self.storeImage!, timeStamp: timeStamp) { (objImage) in
            
            
   
            if let validObj  = objImage,let resultSuccess = validObj.success{
                
                if resultSuccess == 1{
                    
                    LoadIndicator.shared.startWithMessage(message: "Uploading Text")

                    ApiCaller.sharedInstance.uploadTextWhenOcrComplete(ocrText: self.textViewText.text, timeStamp: timeStamp, isbox: self.isBox, ishandwritten : self.isHandwritten) { (obj) in
                        
                        DispatchQueue.main.async {
                            LoadIndicator.shared.stop()
                        }
                        if let validObj  = obj,let messageValid = validObj.message{
                            debugPrint("message is",messageValid)
                            
                            

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.showSuccessPopup()
                           }
                            
                        }
                        
                        
                    }
                    //self.isBox = 0
                }else{
                    LoadIndicator.shared.stop()
                    if let resultMessage = validObj.message{
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            Alert.showAlertViewController(title: "Message", message: resultMessage, viewController: self)
                            
                        }
                    }
                    
                }
            }else{
                LoadIndicator.shared.stop()
            }
            
            
            
            
        }
        
    }
    
    
    func UploadImageAndNonMatchedData(image: UIImage,textGroups: [String]){
        let timeStamp = self.generateCurrentTimeStamp()
        
        LoadIndicator.shared.startWithMessage(message: "Uploading Photo")
        ApiCaller.sharedInstance.uploadImageWhenOcrComplete(imageToUpload: image, timeStamp: timeStamp) { (objImage) in
            
            
   
            if let validObj  = objImage,let resultSuccess = validObj.success{
                
                if resultSuccess == 1{
                    
                    LoadIndicator.shared.startWithMessage(message: "Uploading Text")
                    ApiCaller.sharedInstance.uploadTextWhenAddressNotMatchedComplete(textGroups: textGroups, timeStamp: timeStamp, isbox: self.isBox, ishandwritten: self.isHandwritten) { (obj) in
                        
                        DispatchQueue.main.async {
                            LoadIndicator.shared.stop()
                        }
                        if let validObj  = obj,let messageValid = validObj.message{
                            debugPrint("message is",messageValid)
                            
                            

//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.showSuccessPopup()
//                           }
                            
                        }
                        
                        
                    }
                    //self.isBox = 0
                }else{
                    LoadIndicator.shared.stop()
                    if let resultMessage = validObj.message{
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            Alert.showAlertViewController(title: "Message", message: resultMessage, viewController: self)
                            
                        }
                    }
                    
                }
            }else{
                LoadIndicator.shared.stop()
            }
            
            
            
            
        }
        
    }
    
    func handleDetectedText(request: VNRequest?, error: Error?) {
        if let error = error {
            print("ERROR: \(error)")
            return
        }
        guard let results = request?.results, results.count > 0 else {
            print("No text found")
            return
        }
        var mutableString = ""

        for result in results {
            
            debugPrint("result",result)

            if let observation = result as? VNRecognizedTextObservation {
                
                for text in observation.topCandidates(1) {
                    print(text.string)
                    print(text.confidence)
                    print(observation.boundingBox)
                    print("\n")
                    mutableString = mutableString + (text.string) + (" ")
                }
                
                let text1 = observation.topCandidates(1).first?.string
                print("mutableString: - \(mutableString)")
                
//                let text = observation.compactMap({
//                    $0.topCandidates(1).first?.string
//                }).joined(separator: " ")
//                print("Results: - \(text)")
                
                DispatchQueue.main.async {
                    self.textViewText.text = mutableString
                    
                }

            }
            
//            let text = observation.compactMap({
//                $0.topCandidates(1).first?.string
//            }).joined(separator: " ")

        }
    }

}

extension LogggedUserVC: TOCropViewControllerDelegate{
    
    
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        
        
//        self.scanImageView.image = image
//        self.storeImage = image
        self.recognizeTextInImage(image: image)
     
        cropViewController.dismiss(animated: true, completion: nil)

    }
}

extension UIView {
    func applyShadow(
        color: UIColor = .black,
        opacity: Float = 0.2,
        offset: CGSize = CGSize(width: 0, height: 2),
        radius: CGFloat = 4,
        cornerRadius: CGFloat = 0
    ) {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = false
    }
    
    func applyCornerRound(with radius: CGFloat) {
        self.layer.cornerRadius = radius
    }
}
