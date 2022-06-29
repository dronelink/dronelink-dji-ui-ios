platform :ios, '12.0'
inhibit_all_warnings!
use_frameworks!

target 'DronelinkDJIUI' do
  pod 'DronelinkCore', :path => '../../private/dronelink-core-ios'
  pod 'DronelinkDJI', :path => '../dronelink-dji-ios'
  pod 'DronelinkCoreUI', :path => '../dronelink-core-ui-ios'
  pod 'DJI-UXSDK-iOS', '~> 4.14'
  pod 'DJIWidget', '~> 1.6.7'
  pod 'SwiftyUserDefaults', '~> 5.3.0'
  pod 'SnapKit', '~> 5.0.1'
  pod 'MaterialComponents/Palettes', '~> 124.2.0'
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] = 'NO'
      end
    end
  end
end