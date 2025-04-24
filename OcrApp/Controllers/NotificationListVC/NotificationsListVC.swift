//
//  NotificationsListVC.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 04/04/2025.
//

import UIKit

class NotificationsListVC: UIViewController {
    
    //MARK: - IBOUTLETS
    
    @IBOutlet weak var tableView: UITableView!
    private var notificationsArray = [NotificationModel]()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
}

extension NotificationsListVC: UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notificationsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationsListCell", for: indexPath) as! NotificationsListCell
        return cell
    }
}
