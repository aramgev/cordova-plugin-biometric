import UIKit
import Firebase
//import SVProgressHUD

var isFirebaseConfigured = false

enum BiometricAuthenticationError: Error {
    case credentialsNotProvided
}


@objc(BiometricAuthentication)
class BiometricAuthentication : CDVPlugin {
    
    private var apiUrl: String?
    private var username: String?
    private var password: String?
    private var currentCommand: CDVInvokedUrlCommand!
    
    private var rootViewController: UIViewController? {
        let window = UIApplication.shared.keyWindow
        return window?.rootViewController
    }
    
    @objc(analyze:)
    func analyze(_ command: CDVInvokedUrlCommand) {
        initialize(command: command)
         
        let livenessViewController = OZSDK.createVerificationVCWithDelegate(self, actions: [.smile, .scanning])
        rootViewController?.present(livenessViewController, animated: true)
    }
    
    @objc private func initialize(command: CDVInvokedUrlCommand) {
        currentCommand = command
        
        OZSDK.attemptSettings = OZAttemptSettings(singleCount: 2, commonCount: 3)
        
        apiUrl = commandDelegate.settings["BIOMETRIC_AUTHENTICATION_API_URL"] as? String
        username = commandDelegate.settings["BIOMETRIC_AUTHENTICATION_CREDENTIAL_USERNAME"] as? String
        password = commandDelegate.settings["BIOMETRIC_AUTHENTICATION_CREDENTIAL_PASSWORD"] as? String
        
        print(#function, "apiUrl: \(String(describing: apiUrl))")
        print(#function, "username: \(String(describing: username))")
        print(#function, "authToken: \(password)")
                
        apiUrl = apiUrl ?? "https://api-d.oz-services.ru/"
        username = username ?? "Artur.kartshikyan@evocabank.am"
        password = password ?? "g9Ub@dP7$am"
        
        if (isFirebaseConfigured == false) {
            FirebaseApp.configure()
            isFirebaseConfigured = true
        }
        
        login()
        
//        SVProgressHUD.setHapticsEnabled(false)
//        SVProgressHUD.setForegroundColor(UIColor.hex(0x6400dc))
//        SVProgressHUD.setDefaultMaskType(.custom)
//        SVProgressHUD.setBackgroundLayerColor(UIColor(white: 0, alpha: 0.2))
//        SVProgressHUD.setRingThickness(4.0)
//        SVProgressHUD.setRingRadius(24.0)
//        SVProgressHUD.setMinimumSize(CGSize(width: 120, height: 120))
    }
    
    private func login(completionHandler:  Optional<(Result<String, Error>)->Void> = nil) {
        // Check for existing auth token
        if let authToken = OZSDK.authToken {
            completionHandler?(.success(authToken))
            return
        }
        // Check for credentials
        guard let username = username, let password = password else {
            completionHandler?(.failure(BiometricAuthenticationError.credentialsNotProvided))
            return
        }
        // Log in
        OZSDK.login(username, password: password) { (authToken, error) in
            guard let authToken = authToken, error == nil else {
                completionHandler?(.failure(error!))
                return
            }
            OZSDK.authToken = authToken
            completionHandler?(.success(authToken))
        }
    }
}

// MARK: - OZVerificationDelegate

extension BiometricAuthentication: OZVerificationDelegate {
    
    func onOZVerificationResult(results: [OZVerificationResult]) {
        print(#function, "results: \(results)")
        
        var analyseResults = results.filter({ $0.status == .userProcessedSuccessfully })
        if analyseResults.isEmpty {
            self.commandDelegate.send(CDVPluginResult(status: .noResult), callbackId: currentCommand.callbackId)
            return
        }
        
//        SVProgressHUD.show(withStatus: "Uploading..")
//        
//        login { (result) in
//            switch result {
//            case .success:
//                OZSDK.analyse(results: analyseResults, analyseStates: [.quality], fileUploadProgress: { (progress) in
//                    print("Progress: \(progress)")
//                }) { (analyseStatus, error) in
//                    SVProgressHUD.show(withStatus: "Processing..")
//                    print("analyseStatus: \(String(describing: analyseStatus)) error: \(String(describing: error))")
//                    if let analyseStatus = analyseStatus, analyseStatus == .success {
//                        SVProgressHUD.showSuccess(withStatus: "Success")
//                        SVProgressHUD.dismiss(withDelay: 2.0) {
//                            self.commandDelegate.send(CDVPluginResult(status: .ok), callbackId: self.currentCommand.callbackId)
//                        }
//                    }
//                }
//            case .failure:
//                self.commandDelegate.send(CDVPluginResult(status: .noResult), callbackId: self.currentCommand.callbackId)
//            }
//        }
    }
}