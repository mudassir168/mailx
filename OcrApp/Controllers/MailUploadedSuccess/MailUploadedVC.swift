//
//  MailUploadedVC.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 16/04/2025.
//

import UIKit

class MailUploadedVC: UIViewController {
    
    //MARK: - IBOUTLETS
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var dismissButton: UIButton!
    
    
    override func viewDidLoad() {
        DispatchQueue.main.async { [weak self] in
            self?.bgView.applyCornerRound(with: 5)
            self?.dismissButton.applyCornerRound(with: 8)
        }
    }

    
    @IBAction func crossButtonPressed(_ sender: UIButton) {
        view.removeFromSuperview()
    }

}
