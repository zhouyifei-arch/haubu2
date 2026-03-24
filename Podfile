platform :ios, '15.0'
use_frameworks!

target 'huabu2' do
  # 不要写死小版本号，用 ~> 获取兼容的最新版
  pod 'Moya'
  pod 'Kingfisher'
  pod 'MJRefresh'
  pod 'SnapKit'
  pod 'RealmSwift'
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        # 强制所有 Pod 库的编译目标对齐到 15.6
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
      end
    end
  end
end
