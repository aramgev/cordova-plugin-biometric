/********* BiometricAuth.m Cordova Plugin Implementation *******/
import Foundation
import OZLivenessSDK
//import SwiftMessages


@objc(BiometricAuth) class BiometricAuth : CDVPlugin {
  @objc(analyze:) 
  func analyze(command: CDVInvokedUrlCommand) { 	
    var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "The plugin succeeded")  
    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
  }
  
}
