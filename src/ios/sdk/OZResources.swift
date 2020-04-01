//
//  OZResources.swift
//  OZLivenessSDK
//
//  Created by Igor Ovchinnikov on 03/09/2019.
//

import Foundation

class OZResources {
    
    static var localizationCode: String? {
        return (OZSDK.localizationCode ?? .en).rawValue
    }
    
    private init() { }
    
    private static func bundle(key : String = "OZResourceBundle") -> Bundle {
        let path = Bundle(for: OZResources.self).path(forResource: key, ofType: "bundle")!
        return Bundle(path: path) ?? Bundle.main
    }
    
    static var closeButtonImage : UIImage? {
        return UIImage(named: "closebutton", in: self.bundle(), compatibleWith: nil)
    }
    
    static func localized(key: String) -> String {
        var bundle = self.bundle(key: "OZLocalizationBundle")
        if let languageCode = localizationCode {
            if let path = bundle.path(forResource: languageCode, ofType: "lproj") {
                bundle = Bundle(path: path) ?? bundle
            }
        }
        
        return NSLocalizedString(key, tableName: "Localizable", bundle: bundle, comment: "")
    }
}
