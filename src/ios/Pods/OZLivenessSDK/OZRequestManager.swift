//
//  OZRequestManager.swift
//  OZLiveness
//
//  Created by Igor Ovchinnikov on 24/07/2019.
//  Copyright © 2019 Igor Ovchinnikov. All rights reserved.
//

import Foundation
import Alamofire
import DeviceKit

struct ResponseError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var localizedDescription: String {
        return message
    }
}

struct ConnectionConfigs {
    
    static var host : String {
        get { return OZSDK.host }
    }
    
    fileprivate static var headers : HTTPHeaders {
        get {
            var headers = [
                "Content-Type" : "application/x-www-form-urlencoded"
            ]
            if let authToken = OZSDK.authToken {
                headers["X-Forensic-Access-Token"] = authToken
            }
            return headers
        }
    }
}

struct OZRequestManager {
    
    private init() { }
    
    private static let alamofireManager : SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        return Alamofire.SessionManager(configuration: configuration)
    }()
    
    
    fileprivate static func parseResponseError(data: Data?) -> ResponseError? {
        var error : ResponseError? = nil
        if let data = data, let dict = self.parse(data: data) {
            if let errorMessage = dict["error_message"] as? String {
                error = ResponseError(errorMessage)
            }
        }
        return error
    }
    
    
    static func login(_ login: String, password: String, completion: @escaping (_ token : String?, _ error: Error?) -> Void) {
        let parameters : [String: String] = [
            "email"     : login,
            "password"  : password
        ]
        
        
        let url = ConnectionConfigs.host + "/api/authorize/auth"
        alamofireManager.request(url, method: .post,
                                 parameters: ["credentials" : parameters],
                                 encoding: JSONEncoding.default,
                                 headers: ConnectionConfigs.headers).responseJSON { response in
                                    if let data = response.data, let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                        completion(dict["access_token"] as? String, response.error)
                                    }
                                    else {
                                        completion(nil, response.error)
                                    }
        }
    }
    
    static func analyse(folderId: String? = nil, results: [OZVerificationResult], analyseStates: Set<OZAnalysesState>, fileUploadProgress: @escaping ((Progress) -> Void), completion: @escaping ( _ resolution : AnalyseResolutionStatus?, _ error: Error?) -> Void) {
        self.addToFolder(folderId: folderId, results: results, analyseStates: analyseStates, fileUploadProgress: fileUploadProgress) { (folderId, error) in
            if let folderId = folderId {
                self.addAnalyses(folderID: folderId, states: analyseStates, completion: completion)
            }
            else {
                completion(nil, error)
            }
        }
    }
    
    static func addToFolder(folderId: String? = nil, results: [OZVerificationResult], analyseStates: Set<OZAnalysesState>, fileUploadProgress: @escaping ((Progress) -> Void), completion: @escaping (_ folderId : String?, _ error: Error?) -> Void) {
        var videos : [String : URL] = [:]
        var mediaTags : [String : [String]] = [:]
        for i in 0 ..< results.count {
            let key = "video_\(i)"
            videos[key] = results[i].videoURL
            let actionTag : String
            switch results[i].movement {
            case .far:
                actionTag = "video_selfie_zoom_out"
            case .close:
                actionTag = "video_selfie_zoom_in"
            case .smile:
                actionTag = "video_selfie_smile"
            case .eyes:
                actionTag = "video_selfie_eyes"
            case .up:
                actionTag = "video_selfie_high"
            case .down:
                actionTag = "video_selfie_down"
            case .left:
                actionTag = "video_selfie_left"
            case .right:
                actionTag = "video_selfie_right"
            case .scanning:
                actionTag = "video_selfie_scan"
            }
            mediaTags[key] = [
                "video_selfie",
                actionTag,
                "orientation_portrait"
            ]
        }
        self.addToFolder(folderId: folderId, videos: videos, mediaTags: mediaTags, fileUploadProgress: fileUploadProgress, completion: completion)
    }
    
    private static func addToFolder(folderId: String? = nil, videos: [String: URL], mediaTags: [String:[String]], fileUploadProgress: @escaping ((Progress) -> Void), completion: @escaping (_ folderId : String?, _ error: Error?) -> Void) {
        let url: String

        if let folderId = folderId {
            url = ConnectionConfigs.host + "/api/folders/" + "\(folderId)/" + "media/"
        }
        else {
            url = ConnectionConfigs.host + "/api/folders/?"
        }
        Alamofire.upload(multipartFormData: { multipartFormData in
            for key in videos.keys {
                multipartFormData.append(videos[key]!, withName: key)
            }
            
            let payload = [
                "media:tags" : mediaTags,
                "folder:meta_data" : [
                    "phone_info" : [
                        "manufacturer" : "Apple",
                        "model" : Device.current.model,
                        "device" : Device.current.description,
                        "os_version" : Device.current.systemVersion,
                        "version_liveness_sdk" : OZSDK.version
                    ] as [String : Any]
                ] as [String : Any]
            ] as [String : Any]
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload,
                                                          options: .prettyPrinted) {
                multipartFormData.append(jsonData, withName: "payload")
            }
        },
                 usingThreshold: UInt64.init(),
                 to: url,
                 method: .post,
                 headers: ConnectionConfigs.headers,
                 encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.uploadProgress(closure: fileUploadProgress)
                        upload.responseJSON { response in
                            if let data = response.data {
                                if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                    completion(dict["folder_id"] as? String, response.error)
                                    return
                                }
                                else if let folderId = folderId, let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]], array.count > 0 {
                                    completion(folderId, response.error)
                                    return
                                }
                            }
                            completion(nil, response.error)
                        }
                    case .failure(let encodingError):
                        completion(nil, encodingError)
                    }
        })
    }
    
    private static func addAnalyses(folderID: String, states: Set<OZAnalysesState>, completion: @escaping (_ resolution : AnalyseResolutionStatus?, _ error: Error?) -> Void) {
        guard states.count > 0 else { return completion(nil, nil) }
        let parameters : [[String: String]] = states.map { (state) -> [String: String] in
            return ["type": state.rawValue]
        }
        
        let url = ConnectionConfigs.host + "/api/folders/" + folderID + "/analyses"
        alamofireManager.request(url, method: .post,
                                 parameters: ["analyses" : parameters],
                                 encoding: JSONEncoding.default,
                                 headers: ConnectionConfigs.headers).responseJSON { response in
                                    if  let data = response.data,
                                        let answer = self.parse(data: data)  {
                                        if  let analyseID = answer["analyse_id"] as? String,
                                            let resolution = answer["resolution"] as? String,
                                            let resolutionStatus = AnalyseResolutionStatus(rawValue: resolution) {
                                            if resolutionStatus == .processing || resolutionStatus == .initial {
                                                self.waitAnalysesStatus(analyseID: analyseID, completion: completion)
                                            }
                                            else {
                                                completion(resolutionStatus, response.error)
                                            }
                                        }
                                        else {
                                            completion(nil, response.error)
                                        }
                                    }
                                    else {
                                        completion(nil, response.error)
                                    }
        }
    }
    
    private static func waitAnalysesStatus(analyseID: String,completion: @escaping (_ resolution : AnalyseResolutionStatus?, _ error: Error?) -> Void) {
        let url = ConnectionConfigs.host + "/api/analyses/" + analyseID
        alamofireManager.request(url, method: .get,
                                 encoding: JSONEncoding.default,
                                 headers: ConnectionConfigs.headers).responseJSON { response in
                                    if  let data = response.data,
                                        let answer = self.parse(data: data) {
                                        if  let resolution = answer["resolution"] as? String,
                                            let resolutionStatus = AnalyseResolutionStatus(rawValue: resolution) {
                                            if resolutionStatus == .processing || resolutionStatus == .initial {
                                                completion(resolutionStatus, response.error)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                                    self.waitAnalysesStatus(analyseID: analyseID, completion: completion)
                                                })
                                            }
                                            else {
                                                completion(resolutionStatus, response.error)
                                            }
                                        }
                                        else {
                                            completion(nil, response.error)
                                        }
                                    }
                                    else {
                                        completion(nil, response.error)
                                    }
        }
    }
    
    private static func parse(data: Data) -> [String: Any]? {
        if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return dict
        }
        else if let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any], let dict = array.last as? [String: Any]  {
            return dict
        }
        return nil
    }
}

extension DataResponse {
    var error: Error? {
        return OZRequestManager.parseResponseError(data: self.data) ?? result.error
    }
}

public extension Error {
    public var ozErrorMessage: String {
        get {
            return (self as? ResponseError)?.localizedDescription ?? self.localizedDescription
        }
    }
}
