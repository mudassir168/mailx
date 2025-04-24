//
//  UIViewController+Extension.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 07/04/2025.
//

import UIKit

extension UIViewController {
    var className: String {
        return String(describing: type(of: self))
    }

    static var className: String {
        return String(describing: self)
    }
}
