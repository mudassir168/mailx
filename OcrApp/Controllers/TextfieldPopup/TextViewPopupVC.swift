//
//  TextViewPopupVC.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 09/03/2025.
//

import UIKit

class TextViewPopupVC: UIViewController {
    
    //MARK: - IBOUTLETS
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var roundBgView: UIView!
    
    //MARK: - PROPERTIES
    var address: String?
    var onUpdateText: ((String)->Void)?
    var onClosed: (()->Void)?
    
    //MARK: - LIFECYCLES

    override func viewDidLoad() {
        super.viewDidLoad()
        initialUiSetup()
        dataSetup()
    }
    
    //MARK: - PRIVATE FUNCTIONS
    
    private func initialUiSetup() {
        textView.layer.cornerRadius = 5
        roundBgView.layer.cornerRadius = 5
    }
    
    private func dataSetup() {
        textView.text = address ?? ""
    }
    
    //MARK: - IBACTIONS
    
    @IBAction func updateButtonPressed(_ sender: UIButton) {
        onUpdateText?(textView.text)
    }
    
    @IBAction func crossButtonPressed(_ sender: UIButton) {
        onClosed?()
    }
}
