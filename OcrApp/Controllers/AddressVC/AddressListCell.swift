//
//  AddressListCell.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 06/03/2025.
//

import UIKit

class AddressListCell: UITableViewCell {
    
    //MARK: - IBOUTLETS
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var btnSelect: UIButton!
    @IBOutlet weak var btnEdit: UIButton!
    
    var selectButtonTapped: ((Int, String, Bool) -> Void)?
    var editButtonTapped: ((Int, String, Bool) -> Void)?
    var isMatched: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        btnSelect.layer.cornerRadius = 5
        btnEdit.layer.cornerRadius = 5
    }

    func setData(address: String, isMatched: Bool) {
        self.addressLabel.text = address
        self.isMatched = isMatched
    }
    
    //MARK: - IBACTIONS
    
    @IBAction func selectedButtonTapped(_ sender: UIButton) {
        self.selectButtonTapped?(0, self.addressLabel.text ?? "", isMatched)
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        self.editButtonTapped?(1, self.addressLabel.text ?? "", isMatched)
    }
}
