//
//  ImageViewerVC.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 21/04/2025.
//

import UIKit

class ImageViewerVC: UIViewController {
    
    //MARK: - IBOUTLETS
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!

    var image: UIImage?
    var completion: ((_ retake: Bool,_ confirm: Bool)->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
    }
    
    private func initialSetup() {
        if let img = image {
            imageView.image = img
        }
        [retakeButton,confirmButton].forEach { button in
            button?.applyCornerRound(with: 5)
        }
    }
    
    
    @IBAction func retakePressed(_ sender: UIButton) {
        self.dismiss(animated: false)
        completion?(true,false)
    }
    
    @IBAction func confirmPressed(_ sender: UIButton) {
        self.dismiss(animated: false)
        completion?(false,true)
    }
}
