//
//  OZSDK.swift
//  OZLiveness
//
//  Created by Igor Ovchinnikov on 29/07/2019.
//  Copyright © 2019 Igor Ovchinnikov. All rights reserved.
//

import Foundation
import UIKit

private let ovalCustomization: OZOvalCustomization = OZOvalCustomization(strokeWidth: 4.0,
                                                                         successStrokeColor: UIColor.green,
                                                                         failStrokeColor: UIColor.red)

private let frameCustomization: OZFrameCustomization = OZFrameCustomization(backgroundColor: UIColor.black.withAlphaComponent(0.5))

private let cancelButtonCustomization: OZCancelButtonCustomization = OZCancelButtonCustomization(customImage:nil)

struct SDK: OZSDKProtocol {
    
    var localizationCode: OZLocalizationCode? 
    
    var authToken: String?
    
    var host: String = "https://api-d.oz-services.ru"
    
    var customization = OZCustomization(textColor: UIColor.white,
                                        buttonColor: UIColor.white,
                                        ovalCustomization: ovalCustomization,
                                        frameCustomization: frameCustomization,
                                        cancelButtonCustomization: cancelButtonCustomization)
    
    /** Версия SDK. */
    var version : String {
        get { return "1.0.20" }
    }
    
    
    var attemptSettings: OZAttemptSettings = OZAttemptSettings()
    
    var thresholdSettings = OZLivenessThresholdSettings(centerError: 0.08,
                                                        heightError: 0.10,
                                                        smilingProbability: 0.4,
                                                        eyesOpenProbability: 0.1,
                                                        headEulerAngleYAbs: 15,
                                                        startSmilingProbability: 0.2,
                                                        startEyesOpenProbability: 0.3,
                                                        centerEulerAngleY: 15,
                                                        downFaceProbability: 0.2,
                                                        highFaceProbability: 0.3)
    
    
    /** Метод создания контроллера для проведения liveness-проверки. */
    func createVerificationVCWithDelegate(_ delegate: OZVerificationDelegate, actions: [OZVerificationMovement]) -> UIViewController {
        let vc = OZLivenessViewController()
        vc.delegate = delegate
        vc.actions = actions
        return vc
    }
    
    func createTestVerificationVC() -> UIViewController {
        return UIViewController() //OZTestLivenessViewController()
    }
    
    /** Авторизация по логину и паролю. */
    
    func login(_ login: String, password: String, completion: @escaping (_ token : String?, _ error: Error?) -> Void) {
        OZRequestManager.login(login, password: password, completion: completion)
    }
    
    /** Загрузка и анализ видео. */
    
    func analyse(results: [OZVerificationResult], analyseStates: Set<OZAnalysesState>, fileUploadProgress: @escaping ((Progress) -> Void), completion: @escaping ( _ resolution : AnalyseResolutionStatus?, _ error: Error?) -> Void) {
        OZRequestManager.analyse(results: results, analyseStates: analyseStates, fileUploadProgress: fileUploadProgress, completion: completion)
    }
    
    func analyse(folderId: String, results: [OZVerificationResult], analyseStates: Set<OZAnalysesState>, fileUploadProgress: @escaping ((Progress) -> Void), completion: @escaping ( _ resolution : AnalyseResolutionStatus?, _ error: Error?) -> Void) {
        OZRequestManager.analyse(folderId: folderId, results: results, analyseStates: analyseStates, fileUploadProgress: fileUploadProgress, completion: completion)
    }
    
    func addToFolder(results: [OZVerificationResult], analyseStates: Set<OZAnalysesState>, fileUploadProgress: @escaping ((Progress) -> Void), completion: @escaping (_ folderId : String?, _ error: Error?) -> Void) {
        OZRequestManager.addToFolder(results: results, analyseStates: analyseStates, fileUploadProgress: fileUploadProgress, completion: completion)
    }
    
    func addToFolder(folderId: String, results: [OZVerificationResult], analyseStates: Set<OZAnalysesState>, fileUploadProgress: @escaping ((Progress) -> Void), completion: @escaping (_ folderId : String?, _ error: Error?) -> Void) {
        OZRequestManager.addToFolder(folderId: folderId, results: results, analyseStates: analyseStates, fileUploadProgress: fileUploadProgress, completion: completion)
    }
    
    /** Удаление видео из дирректории. */
    func cleanTempDirectory() {
        OZFileVideoManager.cleanTempDirectory()
    }
}
