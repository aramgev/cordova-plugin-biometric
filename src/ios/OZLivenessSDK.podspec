Pod::Spec.new do |s|
  s.name = 'OZLivenessSDK'
  s.version = '1.0.20'
  s.summary = 'OZLivenessSDK'
  s.homepage = 'https://gitlab.com/oz-forensics/liveness_sdk'
  s.authors = { 'oz-forensics' => 'info@oz-forensics.org' }
  s.source = { :git => 'git@gitlab.com:oz-forensics/liveness_sdk.git', :branch => 'develop'}
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = "OZLivenessSDK/*.swift"
	
  s.resource_bundle = { 
	"OZResourceBundle" => "OZLivenessSDK/Resources/*",
	"OZLocalizationBundle" => "OZLivenessSDK/Localization/*.lproj/*.strings"
  }

  s.frameworks = 'AVFoundation'
  s.static_framework = true

  s.dependency 'Alamofire', '4.9.0'
  s.dependency 'DeviceKit', '2.1.0'
  s.dependency 'Firebase', '5.2.0'
  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/MLVision'
  s.dependency 'Firebase/MLVisionFaceModel'
end