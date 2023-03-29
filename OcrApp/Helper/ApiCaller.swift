//
//  ApiCaller.swift
//  OcrApp
//
//  Created by JAGVEER on 02/11/21.
//

import Foundation
import Alamofire
import SwiftyJSON
import ObjectMapper



class ApiCaller{
    
    static let sharedInstance = ApiCaller()
    
    
    public func requestLoginCreds(_ userName: String,passsord: String, completion: @escaping (LoggedObject?) -> Void) {
        
        
        let parameters: [String: Any] = [
            "username" : userName,
            "password" : passsord,
            "action":"log_in",
            "object":"ocr"
        ]
        
        debugPrint(parameters)
        if NetworkReachabilityManager()!.isReachable {
            
            AF.request(BaseUrlInAPI, method:.post, parameters: parameters,encoding: JSONEncoding.default) .responseJSON { (dataResponse:DataResponse) in
                
                guard let data = dataResponse.data else { return }
                let json = try? JSON(data:data)
                
                print("requestLoginCreds json->",json as Any)
                if let remoteObject = json?.object{
                    
                    if let pixaModel = Mapper<LoggedObject>().map(JSONObject: remoteObject){
                        completion(pixaModel)
                    }
                    
                }else{
                    completion(nil)
                }
            }
            
            
        } else {
            completion(nil)
        }
        
    }

    func uploadImageWhenOcrComplete(imageToUpload:UIImage,timeStamp: String,completion: @escaping (UploadObject?) -> Void){
        //Set Your URL
        let api_url = BaseUrlInAPI
        guard let url = URL(string: api_url) else {
            return
        }
        guard let username = UserDefaults.standard.value(forKey: LoginCreds.UserNameSavedKey) as? String else {
            completion(nil)
           return
        }
        guard let password = UserDefaults.standard.value(forKey: LoginCreds.PasswordSavedKey) as? String else {
            completion(nil)
           return
        }
        guard let locId = UserDefaults.standard.value(forKey: Defaults.UserLocIdNameKey) as? Int else {
            completion(nil)
           return
        }
        
        
        let loginString = NSString(format: "%@:%@", username, password)
        let loginData: NSData = loginString.data(using: String.Encoding.utf8.rawValue)! as NSData
        let base64LoginString = loginData.base64EncodedString(options: [])
        debugPrint("base64LoginString ",base64LoginString)
        
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0 * 1000)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        let parameterDict = NSMutableDictionary()
        parameterDict.setValue("upload", forKey: "action")
        parameterDict.setValue("ocr", forKey: "object")
        //Set Image Data
        let imgData = imageToUpload.jpegData(compressionQuality: 0.5)!
        
        // Now Execute
        AF.upload(multipartFormData: { multiPart in
            for (key, value) in parameterDict {
                if let temp = value as? String {
                    multiPart.append(temp.data(using: .utf8)!, withName: key as! String)
                }
                
            }
            multiPart.append(imgData, withName: "sendimage", fileName: "\(locId).sample\(timeStamp).png", mimeType: "image/png")
        }, with: urlRequest)
        .uploadProgress(queue: .main, closure: { progress in
            //Current upload progress of file
            print("Upload Progress: \(progress.fractionCompleted)")
        })
        
                .responseJSON(completionHandler: { (dataResponse:DataResponse) in
        
                    guard let data = dataResponse.data else { return }
                    let json = try? JSON(data:data)
        
                    print("requestLoginCreds json->",json as Any)
        
//                    debugPrint("uplload response->",dataResponse.response)
        
                    if let remoteObject = json?.object{
        
                        print("remoteObject json->",remoteObject as Any)
        
                        if let pixaModel = Mapper<UploadObject>().map(JSONObject: remoteObject){
                            completion(pixaModel)
                        }
        
                    }else{
                        completion(nil)
                    }
        
        
                })
        
    }
    
    
    func uploadTextWhenOcrComplete(ocrText:String,timeStamp: String, isbox : Int, ishandwritten: Int, completion: @escaping (UploadObject?) -> Void){
        //Set Your URL
        let api_url = BaseUrlInAPI
        guard let url = URL(string: api_url) else {
            return
        }
        guard let username = UserDefaults.standard.value(forKey: LoginCreds.UserNameSavedKey) as? String else {
            completion(nil)
           return
        }
        guard let password = UserDefaults.standard.value(forKey: LoginCreds.PasswordSavedKey) as? String else {
            completion(nil)
           return
        }
        guard let locId = UserDefaults.standard.value(forKey: Defaults.UserLocIdNameKey) as? Int else {
            completion(nil)
           return
        }
        let loginString = NSString(format: "%@:%@", username, password)
        let loginData: NSData = loginString.data(using: String.Encoding.utf8.rawValue)! as NSData
        let base64LoginString = loginData.base64EncodedString(options: [])
        debugPrint("base64LoginString ",base64LoginString)
            
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0 * 1000)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        let parameterDict = NSMutableDictionary()
        parameterDict.setValue("text", forKey: "action")
        parameterDict.setValue("ocr", forKey: "object")
        parameterDict.setValue("\(locId).sample\(timeStamp).png", forKey: "imagename")
        parameterDict.setValue(ocrText, forKey: "ocrtext")
        parameterDict.setValue(String(isbox), forKey: "isbox")
        parameterDict.setValue(String(ishandwritten), forKey: "ishand")
        
        //Set Image Data
        
        // Now Execute
        AF.upload(multipartFormData: { multiPart in
            for (key, value) in parameterDict {
                if let temp = value as? String {
                    multiPart.append(temp.data(using: .utf8)!, withName: key as! String)
                }
            }
        }, with: urlRequest)
        .uploadProgress(queue: .main, closure: { progress in
            //Current upload progress of file
            print("Upload Progress: \(progress.fractionCompleted)")
        })

                .responseJSON(completionHandler: { (dataResponse:DataResponse) in
        
                    guard let data = dataResponse.data else { return }
                    let json = try? JSON(data:data)
        
                    print("requestLoginCreds json->",json as Any)
        
//                    debugPrint("uplload response->",dataResponse.response)
        
                    if let remoteObject = json?.object{
        
                        print("remoteObject json->",remoteObject as Any)
        
                        if let pixaModel = Mapper<UploadObject>().map(JSONObject: remoteObject){
                            completion(pixaModel)
                        }
        
                    }else{
                        completion(nil)
                    }
        
        
                })
        
    }
}


//    func uploadImage(imageToUpload:UIImage,completion: @escaping (UploadObject?) -> Void){
//
//
//        var semaphore = DispatchSemaphore (value: 0)
//
//        let parameters = [
//            [
//                "key": "sendimage",
//                "src": "803.sometetext1.png",
//                "type": "file"
//            ],
//            [
//                "key": "action",
//                "value": "upload",
//                "type": "text"
//            ],
//            [
//                "key": "object",
//                "value": "ocr",
//                "type": "text"
//            ]] as [[String : Any]]
//
//        let boundary = "Boundary-\(UUID().uuidString)"
//        var body = ""
//        let username = "803@amir.com"
//        let password = "tempPass##"
//        let loginString = NSString(format: "%@:%@", username, password)
//        let loginData: NSData = loginString.data(using: String.Encoding.utf8.rawValue)! as NSData
//        let base64LoginString = loginData.base64EncodedString(options: [])
//
//        //        var error: Error? = nil
//        for param in parameters {
//            if param["disabled"] == nil {
//                let paramName = param["key"]!
//                body += "--\(boundary)\r\n"
//                body += "Content-Disposition:form-data; name=\"\(paramName)\""
//                if param["contentType"] != nil {
//                    body += "\r\nContent-Type: \(param["contentType"] as! String)"
//                }
//                let paramType = param["type"] as! String
//                if paramType == "text" {
//                    let paramValue = param["value"] as! String
//                    body += "\r\n\r\n\(paramValue)\r\n"
//                } else {
//                    let paramSrc = param["src"] as! String
//                    let imgData = imageToUpload.pngData()!
//
//                    let strBase64:String = imgData.base64EncodedString()
//
//                    body += "; filename=\"\(paramSrc)\"\r\n"
//                        + "Content-Type: \"content-type header\"\r\n\r\n\(strBase64)\r\n"
//                }
//            }
//        }
//        body += "--\(boundary)--\r\n";
//        let postData = body.data(using: .utf8)
//
//        var request = URLRequest(url: URL(string: "https://www.opusvirtualoffices.com/voapi/v1/index.php")!,timeoutInterval: Double.infinity)
//        request.addValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
//        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//        request.httpMethod = "POST"
//        request.httpBody = postData
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data else {
//                print(String(describing: error))
//                semaphore.signal()
//                return
//            }
//
//
//
//            print(String(data: data, encoding: .utf8)!)
//
//
//
//            semaphore.signal()
//        }
//
//        task.resume()
//        semaphore.wait()
//    }
