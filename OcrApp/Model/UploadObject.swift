//
//  UploadObject.swift
//  OcrApp
//
//  Created by JAGVEER on 12/11/21.
//

import Foundation
import ObjectMapper



struct UploadObject : Mappable {
    
    var message : String?
    var success : Int?
    
    init?(map: Map) {
        
    }
    mutating func mapping(map: Map) {
        
        message <- map["message"]
        success <- map["success"]
    }
    
}
