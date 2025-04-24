//
//  NotificationModel.swift
//  OcrApp
//
//  Created by Mudassir Abbas on 04/04/2025.
//

import Foundation
import ObjectMapper



struct NotificationModel : Mappable {
    
    var id : Int?
    var title : String?
    var message : String?
    
    init?(map: Map) {
        
    }
    mutating func mapping(map: Map) {
        
        id <- map["id"]
        title <- map["title"]
        message <- map["message"]
    }
    
}
