//
//  Protocols.swift
//  OcrApp
//
//  Created by InnoTech on 07/03/2025.
//

import Foundation

protocol AddressListDelegate: AnyObject {
    func didTapSubmit(isMatched: Bool, text: String)
}

protocol TextUpdateDelegate: AnyObject {
    func didUpdateText(updatedText: String, isMatched: Bool)
}
