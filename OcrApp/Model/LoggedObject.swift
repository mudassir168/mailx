//
//  LoggedObject.swift
//  OcrApp
//
//  Created by JAGVEER on 11/11/21.
//

import Foundation
import ObjectMapper

struct LoggedObject : Mappable {
    
    var address : String?
    var firstName : String?
    var lastName : String?
    var locid : Int?
    var message : String?
    var success : Int?
    
    init?(map: Map) {
        
    }
    mutating func mapping(map: Map) {
        
        address <- map["address"]
        firstName <- map["firstName"]
        lastName <- map["lastName"]
        locid <- map["locid"]
        message <- map["message"]
        success <- map["success"]
    }
    
}
