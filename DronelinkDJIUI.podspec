Pod::Spec.new do |s|
  s.name = "DronelinkDJIUI"
  s.version = "2.1.0"
  s.summary = "Dronelink DJI UI components"
  s.homepage = "https://dronelink.com/"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Dronelink" => "dev@dronelink.com" }
  s.swift_version = "5.0"
  s.platform = :ios
  s.ios.deployment_target  = "12.0"
  s.source = { :git => "https://github.com/dronelink/dronelink-dji-ui-ios.git", :tag => "#{s.version}" }
  s.source_files  = "DronelinkDJIUI/**/*.swift"
  s.resources = "DronelinkDJIUI/**/*.{strings,xcassets}"
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.dependency "DronelinkCore", "~> 2.1.0"
  s.dependency "DronelinkCoreUI", "~> 2.1.0"
  s.dependency "DronelinkDJI", "~> 2.1.0"
  s.dependency "DJI-SDK-iOS", "~> 4.13"
  s.dependency "DJIWidget", "~> 1.6.4"
  s.dependency "DJI-UXSDK-iOS", "~> 4.13"
  s.dependency "SwiftyUserDefaults", "~> 5.0.0"
  s.dependency "SnapKit", "~> 5.0.1"
  s.dependency "MaterialComponents/Palettes", "~> 119.0.0"
end

