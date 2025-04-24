//
//  UITextfield+Extension.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 06/04/2025.
//
import UIKit

extension UITextField {
    func setBorderColor(_ color: UIColor, width: CGFloat = 1.0, cornerRadius: CGFloat = 5.0) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }
    
        func setPlaceholderColor(_ color: UIColor) {
            if let placeholder = self.placeholder {
                self.attributedPlaceholder = NSAttributedString(
                    string: placeholder,
                    attributes: [.foregroundColor: color]
                )
            }
        }
    
}
