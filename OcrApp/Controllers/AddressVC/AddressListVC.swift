//
//  AddressListVC.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 06/03/2025.
//

import UIKit

public enum AddressSectionType {
    case matched,selected
}

class AddressListVC: UIViewController {
    
    //MARK: - IBOUTLETS
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - PROPERTIES
    var sectionArray = [String]()
    var selectedAddress: String = ""
    var matchedAddress: String = ""
    
    weak var delegate: AddressListDelegate? = nil

    //MARK: - LIFECYCLES
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialSetup()
    }
    
    //MARK: - PRIVATE FUNCTIONS
    private func initialSetup() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    private func showUpdateTextPopup(text: String,isMatched: Bool) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "TextViewPopupVC") as! TextViewPopupVC
        vc.address = text
        vc.onUpdateText = { [weak self] updatedAddress in
            if isMatched {
                self?.matchedAddress = updatedAddress
            } else {
                self?.selectedAddress = updatedAddress
            }
            self?.tableView.reloadData()
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
        vc.onClosed = {
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
        addChild(vc)
        view.addSubview(vc.view)
    }
}

extension AddressListVC: UITableViewDataSource,UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionArray[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let addressCell = tableView.dequeueReusableCell(withIdentifier: "AddressListCell", for: indexPath) as? AddressListCell {
           
            if indexPath.section == 0 {
                if !matchedAddress.isEmpty {
                    addressCell.setData(address: matchedAddress, isMatched: true)
                } else {
                    addressCell.setData(address: selectedAddress, isMatched: false)
                }
            } else {
                addressCell.setData(address: selectedAddress, isMatched: false)
            }
            
            addressCell.selectButtonTapped = { [weak self] row, addressText, isMatched in
                guard let self = self else { return }
                print("Tapped On the row: \(row) with addressText: \(addressText)")
                Alert.showAlertViewController(title: "Alert", message: "You have selected address: \n\n \(addressText) \n\n Do you wish to rescan, or submit?", btnTitle1: "Rescan", btnTitle2: "Submit", ok: { _ in
                    print("Submit pressed!")
                    self.dismiss(animated: false, completion: {
                        self.delegate?.didTapSubmit(isMatched: isMatched, text: addressText)
                    })
                    
                }, cancel: { _ in
                    print("Rescan pressed!")
                    self.dismiss(animated: false)
                }, viewController: self)
            }
            
            addressCell.editButtonTapped = { [weak self] row, addressText, isMatched in
                print("Tapped On the row: \(row) with addressText: \(addressText)")
                guard let self = self else { return }
                showUpdateTextPopup(text: addressText, isMatched: isMatched)
                //Alert.showAlertWithTextView(title: "Edit", message: addressText, isMatched: isMatched, in: self, delegate: self)
            }
            
            return addressCell
        }
        return UITableViewCell()
    }
}

extension AddressListVC: TextUpdateDelegate {
    func didUpdateText(updatedText: String, isMatched: Bool) {
        if isMatched {
            self.matchedAddress = updatedText
        } else {
            self.selectedAddress = updatedText
        }
        self.tableView.reloadData()
    }
}
